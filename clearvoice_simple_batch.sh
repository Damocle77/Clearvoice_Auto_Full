#!/bin/bash
# ================================================================================
# clearvoice_simple_batch.sh
# ================================================================================
# Batch per lanciare clearvoice_simple.sh su multipli MKV nella cartella (compatibile Windows/Bash).
# Ctrl+C interrompe tutto: batch e processi figli.
# -------------------------------------------------------------------------------
# USO:
#   bash clearvoice_simple_batch.sh [bitrate] [originale] [formato]
#
#   - bitrate: Bitrate audio di output (opzionale, default: 768k)
#   - originale: yes/no (includi traccia originale, default: yes)
#   - formato: eac3/ac3 (default: eac3)
#
# ESEMPI:
#   bash clearvoice_simple_batch.sh                     # Elabora tutti i file MKV nella cartella
#   bash clearvoice_simple_batch.sh 384k no             # Con bitrate e opzione originale
#   bash clearvoice_simple_batch.sh 384k no ac3         # Con bitrate, opzione originale e formato
#   bash clearvoice_simple_batch.sh "nome file.mkv" 448k no eac3  # Elabora solo un file specifico
#
# Output: file *_clearvoice.eac3 oppure *_clearvoice.ac3
# -------------------------------------------------------------------------------

# Funzione di pulizia da attivare con Ctrl+C - CORRETTA PER GIT BASH WINDOWS
## Rimosso trap SIGINT: ora Ctrl+C interrompe immediatamente lo script e i processi figli

# NOME DELLO SCRIPT DA ESEGUIRE
SCRIPT_DA_ESEGUIRE="clearvoice_simple.sh"

# Verifica che lo script principale esista
if [ ! -f "$SCRIPT_DA_ESEGUIRE" ]; then
    echo "Houston, problema! $SCRIPT_DA_ESEGUIRE non trovato. Controlla il tuo setup JARVIS."
    exit 1
fi

# Accetta file specifico (opzionale), bitrate, include_original, formato audio come argomenti
SPECIFIC_FILE="$1"
BITRATE="$2"
INCLUDE_ORIGINAL="$3"
FORMAT="$4"

# Se è stato specificato un file, elabora solo quello e termina
if [[ "$SPECIFIC_FILE" == *.mkv ]]; then
    echo ">>> Elaborazione di un singolo file specificato: ${SPECIFIC_FILE}"
    # Esegue lo script principale con chiamata esplicita Bash per singolo file
    bash "$SCRIPT_DA_ESEGUIRE" "$SPECIFIC_FILE" "$BITRATE" "$INCLUDE_ORIGINAL" "$FORMAT"
    echo ">>> Completato: ${SPECIFIC_FILE}"
    exit 0
fi

# Se non è stato specificato un file MKV, prendi gli altri argomenti come di consueto
if [[ "$SPECIFIC_FILE" != *.mkv ]]; then
    BITRATE="$SPECIFIC_FILE"
    INCLUDE_ORIGINAL="$2"
    FORMAT="$3"
fi

# TIMER GLOBALE - START
batch_start_time=$(date +%s)
processed_files=0
total_files=0

# Crea un array con tutti i file MKV, escludendo quelli già processati
mapfile -t mkv_files < <(find . -maxdepth 1 -type f -name "*.mkv" ! -name "*_clearvoice.*" -print0 | sort -zV | tr '\0' '\n')
total_files=${#mkv_files[@]}

if [ $total_files -eq 0 ]; then
    echo "Nessun MKV da processare. Missione annullata, R2-D2."
    exit 0
fi

echo "Trovati $total_files file da processare. Attivazione protocollo 'doppia Libidine' in corso..."
echo "---------------------------------"

# Processa ogni file nell'array
for file in "${mkv_files[@]}"; do
    [ -z "$file" ] && continue  # Salta righe vuote
    ((processed_files++))
    echo ">>> Inizio elaborazione file $processed_files di $total_files: ${file##*/}"

    # Esegue lo script principale con chiamata esplicita Bash (compatibile Windows)
    # Usa più livelli di quotazione per gestire i nomi file con spazi su Windows/MINGW
    if [ ! -z "$FORMAT" ]; then
        bash "$SCRIPT_DA_ESEGUIRE" "${file}" "$BITRATE" "$INCLUDE_ORIGINAL" "$FORMAT"
    elif [ ! -z "$INCLUDE_ORIGINAL" ]; then
        bash "$SCRIPT_DA_ESEGUIRE" "${file}" "$BITRATE" "$INCLUDE_ORIGINAL"
    elif [ ! -z "$BITRATE" ]; then
        bash "$SCRIPT_DA_ESEGUIRE" "${file}" "$BITRATE"
    else
        bash "$SCRIPT_DA_ESEGUIRE" "${file}"
    fi

    echo ">>> Completato: ${file##*/}"
    echo "---------------------------------"
done

# TIMER GLOBALE
batch_duration=$((($(date +%s) - batch_start_time)))
batch_minuti=$((batch_duration / 60))
batch_secondi=$((batch_duration % 60))
# FINE TIMER GLOBALE
echo "MISSIONE COMPIUTA!"
echo "Tempo totale: ${batch_minuti}m ${batch_secondi}s"
echo "File processati: ${processed_files}"
echo "File totali: ${total_files}"
echo "Batch terminato – 'Doppia Libidine con il fiocco!!! 🚀"
