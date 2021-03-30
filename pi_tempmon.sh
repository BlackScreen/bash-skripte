#!/bin/bash

# Starte Endlosschleife
while true
do
	# Speichere aktuelle Zeit in Variable ab
	CURRENT_DATE=$(date +"%d.%m.%Y")
	CURRENT_TIME=$(date +"%H:%M:%S")

	# Speichere aktuelle Temperatur in Variable ab
	CURRENT_TEMP=$(vcgencmd measure_temp | egrep -o '[0-9]*\.[0-9]*')

	# Speichere aktuellen Throttle-Zustand in Variable ab
	CURRENT_THROTTLED=$(vcgencmd get_throttled | egrep -o '[0-9]*x{1}[0-9]*')

	# Ausgabe der aktuellen Temperatur
	echo "Temperatur am $CURRENT_DATE um $CURRENT_TIME: $CURRENT_TEMP°C (Throttle: $CURRENT_THROTTLED)"

	# Warte die weitere Verarbeitung um x Sekunden ab
	sleep 1

# Beende Endlosschleife
done