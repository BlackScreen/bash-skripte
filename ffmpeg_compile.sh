#!/bin/bash

# User definieren
USER=username

# Lokales Ziel-Verzeichnis definieren
DESTINATION_DIR=/home/$USER/ffmpeg_bins

# Lokales Ziel-Verzeichnis erstellen, falls dies nicht existiert
mkdir -p $DESTINATION_DIR

# FFmpeg-Builder-Verzeichnis definieren
BUILDER_DIR=/home/$USER/ffmpeg/ffmpeg-windows-build-helpers

# Sandbox-Verzeichnis definieren
SANDBOX_DIR=$BUILDER_DIR/sandbox/win64

# Pfad und Namen der Log-Datei definieren
LOG_NAME=compile.log
LOG_FILE=$DESTINATION_DIR/$LOG_NAME

# Log-Datei leeren
truncate -s 0 $LOG_FILE

# Pakete aktualisieren
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Paket-Updates gestartet. | tee -a $LOG_FILE
apt update
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y
apt autoclean -y
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Paket-Updates beendet. | tee -a $LOG_FILE

# WSL-Fix für "libdsndfile" anwenden
# Quelle: https://github.com/rdp/ffmpeg-windows-build-helpers/issues/452#issuecomment-638639182
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] WSL-Fix wird angewendet. | tee -a $LOG_FILE
dpkg -r --force-depends "libgc1c2"
cd /home/$USER
git clone https://github.com/ivmai/bdwgc.git
cd /home/$USER/bdwgc
./autogen.sh
./configure --prefix=/usr && make -j
make install
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] WSL-Fix wurde installiert. | tee -a $LOG_FILE

# In lokales Ziel-Verzeichnis wechseln
cd $DESTINATION_DIR

# Limit für fehlgeschlagene Konvertierungen definieren
FAILED_FOLDERS_LIMIT=14

# Aktuelle Anzahl der fehlgeschlagenen Konvertierungen zählen
FAILED_FOLDERS_COUNTER=$(printf 'x%.0s' *FAILED* | grep -o "x" | wc -l)

# Aktuelle Anzahl der fehlgeschlagenen Konvertierungen mit dem entsprechenden Limit abgleichen
if ((FAILED_FOLDERS_COUNTER > FAILED_FOLDERS_LIMIT))
then
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] ACHTUNG! Das Limit für die Anzahl der fehlgeschlagenen Konvertierungen wurde erreicht. | tee -a $LOG_FILE
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Aktuelle Anzahl der fehlgeschlagenen Konvertierungen: $FAILED_FOLDERS_COUNTER | tee -a $LOG_FILE
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Limit für fehlgeschlagene Konvertierungen: $FAILED_FOLDERS_LIMIT | tee -a $LOG_FILE

    # Lokales Ziel-Verzeichnis aufräumen (alle "FAILED"-Verzeichnisse werden gelöscht)
    find $DESTINATION_DIR/*FAILED* | xargs rm -rf

    # Sandbox-Verzeichnis leeren
    rm -rf $SANDBOX_DIR && mkdir $SANDBOX_DIR
else
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Das Limit für die Anzahl der fehlgeschlagenen Konvertierungen wurde NICHT erreicht. | tee -a $LOG_FILE
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Aktuelle Anzahl der fehlgeschlagenen Konvertierungen: $FAILED_FOLDERS_COUNTER | tee -a $LOG_FILE
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Limit für fehlgeschlagene Konvertierungen: $FAILED_FOLDERS_LIMIT | tee -a $LOG_FILE
fi

# In FFmpeg-Builder-Verzeichnis wechseln
cd $BUILDER_DIR

# FFmpeg-Builder aktualisieren
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Git-Update gestartet. | tee -a $LOG_FILE
git pull origin master | tee -a $LOG_FILE
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Git-Update beendet. | tee -a $LOG_FILE

# WSL-Kommando setzen
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] WSL-Kommando setzen. | tee -a $LOG_FILE
bash -c 'echo 0 > /proc/sys/fs/binfmt_misc/WSLInterop'

# FFmpeg-Kompilierung starten
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] FFmpeg-Kompilierung starten. | tee -a $LOG_FILE
./cross_compile_ffmpeg.sh --disable-nonfree=n --compiler-flavors=win64 --build-mp4box=y --build-x264-with-libav=y | tee -a $LOG_FILE
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] FFmpeg-Kompilierung beendet. | tee -a $LOG_FILE

# Prüfung, ob FFmpeg-Kompilierung erfolgreich durchgeführt wurde
if grep -q "searching for all local exe's" $LOG_FILE
then
    # FFmpeg-Kompilierung wurde erfolgreich durchgeführt
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] FFmpeg-Kompilierung wurde erfolgreich beendet. | tee -a $LOG_FILE

    # POST-Kompilierung-Tasks ausführen
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren der kompilierten Dateien gestartet. | tee -a $LOG_FILE

    # Lokales Ziel-Verzeichnis (mit Timestamp) definieren
    TIMESTAMPED_DIR=$DESTINATION_DIR/ffmpeg_$(date +"%Y-%m-%d")_$(date +"%H-%M-%S")

    # Lokales Ziel-Verzeichnis (mit Timestamp) erstellen, falls dies nicht existiert
    mkdir -p $TIMESTAMPED_DIR

    # Lokales Ziel-Verzeichnis aufräumen (alle Verzeichnisse älter als 14 Tage werden gelöscht)
    find $DESTINATION_DIR/* -type d -ctime +14 | xargs rm -rf

    # Speichere die Pfade zu den selbst kompilierten EXE-Dateien in eigene Variablen ab
    FFMPEG_EXE_PATH=$SANDBOX_DIR/ffmpeg_git_with_fdk_aac_master
    LAME_EXE_PATH=$SANDBOX_DIR/lame_svn/frontend
    MP4BOX_EXE_PATH=$SANDBOX_DIR/mp4box_gpac_git/bin/gcc
    X264_EXE_PATH=$SANDBOX_DIR/x264_with_libav_all_bitdepth
    X265_EXE_PATH=$SANDBOX_DIR/x265_all_bitdepth/8bit

    # Kopiere die selbst kompilierten Dateien (Audio - Lame) in die lokalen Ziel-Verzeichnisse
    cp --preserve $LAME_EXE_PATH/lame.exe $DESTINATION_DIR/lame.exe
    cp --preserve $LAME_EXE_PATH/lame.exe $TIMESTAMPED_DIR/lame.exe

    # Kopiere die selbst kompilierten Dateien (Video - FFmpeg) in die lokalen Ziel-Verzeichnisse
    cp --preserve $FFMPEG_EXE_PATH/ffmpeg.exe $DESTINATION_DIR/ffmpeg.exe
    cp --preserve $FFMPEG_EXE_PATH/ffmpeg.exe $TIMESTAMPED_DIR/ffmpeg.exe

    # Kopiere die selbst kompilierten Dateien (Video - FFplay) in die lokalen Ziel-Verzeichnisse
    cp --preserve $FFMPEG_EXE_PATH/ffplay.exe $DESTINATION_DIR/ffplay.exe
    cp --preserve $FFMPEG_EXE_PATH/ffplay.exe $TIMESTAMPED_DIR/ffplay.exe

    # Kopiere die selbst kompilierten Dateien (Video - FFprobe) in die lokalen Ziel-Verzeichnisse
    cp --preserve $FFMPEG_EXE_PATH/ffprobe.exe $DESTINATION_DIR/ffprobe.exe
    cp --preserve $FFMPEG_EXE_PATH/ffprobe.exe $TIMESTAMPED_DIR/ffprobe.exe

    # Kopiere die selbst kompilierten Dateien (Video - MP4Box) in die lokalen Ziel-Verzeichnisse
    cp --preserve $MP4BOX_EXE_PATH/MP4Box.exe $DESTINATION_DIR/MP4Box.exe
    cp --preserve $MP4BOX_EXE_PATH/MP4Box.exe $TIMESTAMPED_DIR/MP4Box.exe

    # Kopiere die selbst kompilierten Dateien (Video - x264) in die lokalen Ziel-Verzeichnisse
    cp --preserve $X264_EXE_PATH/x264.exe $DESTINATION_DIR/x264.exe
    cp --preserve $X264_EXE_PATH/x264.exe $TIMESTAMPED_DIR/x264.exe

    # Kopiere die selbst kompilierten Dateien (Video - x265) in die lokalen Ziel-Verzeichnisse
    cp --preserve $X265_EXE_PATH/x265.exe $DESTINATION_DIR/x265.exe
    cp --preserve $X265_EXE_PATH/x265.exe $TIMESTAMPED_DIR/x265.exe

    # Kopiere Log-Datei in Ziel-Verzeichnis (mit Timestamp)
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren der kompilierten Dateien beendet. | tee -a $LOG_FILE
    cp $LOG_FILE $TIMESTAMPED_DIR/$LOG_NAME
else
    # FFmpeg-Kompilierung wurde NICHT erfolgreich durchgeführt
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] FFmpeg-Kompilierung wurde NICHT erfolgreich beendet. | tee -a $LOG_FILE

    # FFmpeg-Verzeichnisse entfernen
    rm -rf $SANDBOX_DIR/ffmpeg_git_pre_x264_with_fdk_aac
    rm -rf $SANDBOX_DIR/ffmpeg_git_with_fdk_aac_master

    # POST-Kompilierung-Tasks ausführen
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren der Log-Datei gestartet. | tee -a $LOG_FILE

    # Lokales Ziel-Verzeichnis (mit Timestamp) definieren
    TIMESTAMPED_DIR=$DESTINATION_DIR/ffmpeg_$(date +"%Y-%m-%d")_$(date +"%H-%M-%S")_FAILED

    # Lokales Ziel-Verzeichnis (mit Timestamp) erstellen, falls dies nicht existiert
    mkdir -p $TIMESTAMPED_DIR

    # Kopiere Log-Datei in Ziel-Verzeichnis (mit Timestamp)
    echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren der Log-Datei beendet. | tee -a $LOG_FILE
    cp $LOG_FILE $TIMESTAMPED_DIR/$LOG_NAME
fi

# Entferntes Ziel-Verzeichnis definieren
REMOTE_DIR=/mnt/c/Development/RDP_CC

# Lokales BIN-Verzeichnis mit entferntem BIN-Verzeichnis synchronisieren
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren in entferntes BIN-Verzeichnis gestartet. | tee -a $LOG_FILE
rsync -avu --delete "$DESTINATION_DIR/" "$REMOTE_DIR" | tee -a $LOG_FILE
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren in entferntes BIN-Verzeichnis beendet. | tee -a $LOG_FILE

# WSL-Fix für "libdsndfile" entfernen
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] WSL-Fix wird entfernt. | tee -a $LOG_FILE
apt --fix-broken install -y
rm -rf /home/$USER/bdwgc
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] WSL-Fix wurde entfernt. | tee -a $LOG_FILE

# Kopiere dieses Skript in entferntes BIN-Verzeichnis
cp /home/$USER/ffmpeg_compile.sh $REMOTE_DIR/ffmpeg_compile.sh
