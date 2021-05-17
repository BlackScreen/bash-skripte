#!/bin/bash

# Pfad und Namen der Log-Datei definieren
LOG_NAME=compile.log
LOG_FILE=/home/$USER/ffmpeg_bins/$LOG_NAME

# Log-Datei leeren
truncate -s 0 $LOG_FILE

# In FFmpeg-Builder-Verzeichnis wechseln
cd /home/$USER/ffmpeg/ffmpeg-windows-build-helpers

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

# POST-Kompilierung-Tasks ausführen
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren der kompilierten Dateien ins Home-Verzeichnis gestartet. | tee -a $LOG_FILE

# Sandbox-Verzeichnis definieren
SANDBOX_DIR=/home/$USER/ffmpeg/ffmpeg-windows-build-helpers/sandbox/win64

# Lokale Ziel-Verzeichnisse definieren
DESTINATION_DIR=/home/$USER/ffmpeg_bins
TIMESTAMPED_DIR=$DESTINATION_DIR/ffmpeg_$(date +"%Y-%m-%d")_$(date +"%H-%M-%S")

# Speichere die Pfade zu den selbst kompilierten EXE-Dateien in eigene Variablen ab
FFMPEG_EXE_PATH=$SANDBOX_DIR/ffmpeg_git_with_fdk_aac_master
LAME_EXE_PATH=$SANDBOX_DIR/lame_svn/frontend
MP4BOX_EXE_PATH=$SANDBOX_DIR/mp4box_gpac_git/bin/gcc
X264_EXE_PATH=$SANDBOX_DIR/x264_with_libav_all_bitdepth
X265_EXE_PATH=$SANDBOX_DIR/x265_all_bitdepth/8bit

# Lokales Ziel-Verzeichnis erstellen, falls dies nicht existiert
mkdir -p $DESTINATION_DIR

# Lokales Ziel-Verzeichnis (mit Timestamp) erstellen, falls dies nicht existiert
mkdir -p $TIMESTAMPED_DIR

# Lokales Ziel-Verzeichnis aufräumen (alle Verzeichnisse älter als 14 Tage werden gelöscht)
find $DESTINATION_DIR/* -type d -ctime +14 | xargs rm -rf

# Kopiere die selbst kompilierten Dateien (Audio - Lame) in die lokalen Ziel-Verzeichnisse
cp $LAME_EXE_PATH/lame.exe $DESTINATION_DIR/lame.exe
cp $LAME_EXE_PATH/lame.exe $TIMESTAMPED_DIR/lame.exe

# Kopiere die selbst kompilierten Dateien (Video - FFmpeg) in die lokalen Ziel-Verzeichnisse
cp $FFMPEG_EXE_PATH/ffmpeg.exe $DESTINATION_DIR/ffmpeg.exe
cp $FFMPEG_EXE_PATH/ffmpeg.exe $TIMESTAMPED_DIR/ffmpeg.exe

# Kopiere die selbst kompilierten Dateien (Video - FFplay) in die lokalen Ziel-Verzeichnisse
cp $FFMPEG_EXE_PATH/ffplay.exe $DESTINATION_DIR/ffplay.exe
cp $FFMPEG_EXE_PATH/ffplay.exe $TIMESTAMPED_DIR/ffplay.exe

# Kopiere die selbst kompilierten Dateien (Video - FFprobe) in die lokalen Ziel-Verzeichnisse
cp $FFMPEG_EXE_PATH/ffprobe.exe $DESTINATION_DIR/ffprobe.exe
cp $FFMPEG_EXE_PATH/ffprobe.exe $TIMESTAMPED_DIR/ffprobe.exe

# Kopiere die selbst kompilierten Dateien (Video - MP4Box) in die lokalen Ziel-Verzeichnisse
cp $MP4BOX_EXE_PATH/MP4Box.exe $DESTINATION_DIR/MP4Box.exe
cp $MP4BOX_EXE_PATH/MP4Box.exe $TIMESTAMPED_DIR/MP4Box.exe

# Kopiere die selbst kompilierten Dateien (Video - x264) in die lokalen Ziel-Verzeichnisse
cp $X264_EXE_PATH/x264.exe $DESTINATION_DIR/x264.exe
cp $X264_EXE_PATH/x264.exe $TIMESTAMPED_DIR/x264.exe

# Kopiere die selbst kompilierten Dateien (Video - x265) in die lokalen Ziel-Verzeichnisse
cp $X265_EXE_PATH/x265.exe $DESTINATION_DIR/x265.exe
cp $X265_EXE_PATH/x265.exe $TIMESTAMPED_DIR/x265.exe

# Kopiere Log-Datei in Ziel-Verzeichnis (mit Timestamp)
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren der kompilierten Dateien ins Home-Verzeichnis beendet. | tee -a $LOG_FILE
cp $LOG_FILE $TIMESTAMPED_DIR/$LOG_NAME

# Entferntes Ziel-Verzeichnis definieren
REMOTE_DIR=/mnt/c/Development/RDP_CC

# Lokales BIN-Verzeichnis mit entferntem BIN-Verzeichnis synchronisieren
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren in entferntes BIN-Verzeichnis gestartet. | tee -a $LOG_FILE
rsync -avu --delete "$DESTINATION_DIR/" "$REMOTE_DIR" | tee -a $LOG_FILE
echo [$(date +"%d.%m.%Y")] [$(date +"%H:%M:%S")] Kopieren in entferntes BIN-Verzeichnis beendet. | tee -a $LOG_FILE

# Kopiere dieses Skript in entferntes BIN-Verzeichnis
cp /home/$USER/ffmpeg_compile.sh $REMOTE_DIR/ffmpeg_compile.sh
