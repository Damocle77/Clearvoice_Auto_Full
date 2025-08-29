#!/bin/bash
# ================================================================================
# clearvoice_batch_auto_full_4.0.sh
# ================================================================================
# Batch per lanciare clearvoice_auto_full.sh su multipli MKV nella cartella.
# Ctrl+C interrompe tutto: batch e processi figli.
# -------------------------------------------------------------------------------
# USO:
#   ./clearvoice_batch_auto_full.sh [bitrate] [originale] [formato]
#
#   - bitrate: Bitrate audio di output (opzionale, default: 768k)
#   - originale: yes/no (includi traccia originale, default: yes)
#   - formato: eac3/ac3 (default: eac3)
#
# ESEMPI:
#   ./clearvoice_batch_auto_full.sh
#   ./clearvoice_batch_auto_full.sh 384k no
#   ./clearvoice_batch_auto_full.sh 384k no ac3
#
# Output: file *_clearvoice_auto.eac3 oppure *_clearvoice_auto.ac3
# -------------------------------------------------------------------------------

# Funzione di pulizia da attivare con Ctrl+C
cleanup() {
    echo -e "\n\n** SEGNALE DI INTERRUZIONE RICEVUTO! **"
    echo "Avvio protocollo di arresto totale... Addio e grazie per tutto il pesce!."
    # Uccide tutti i processi figli di questo script (incluso ffmpeg)
    pkill -P $$
    # Aspetta un secondo per pulire
    sleep 1
    echo "Tutti i sistemi offline. Batch terminato."
    exit 130  # Uscita standard per Ctrl+C
}

# Intercetta Ctrl+C e chiama cleanup
trap cleanup SIGINT

# NOME DELLO SCRIPT DA ESEGUIRE
SCRIPT_DA_ESEGUIRE="./clearvoice_auto_full_4.0.sh"

# Verifica che lo script principale esista e sia eseguibile
if [ ! -f "$SCRIPT_DA_ESEGUIRE" ] || [ ! -x "$SCRIPT_DA_ESEGUIRE" ]; then
    echo "Houston, problema! $SCRIPT_DA_ESEGUIRE non trovato o non eseguibile. Controlla il tuo setup JARVIS."
    exit 1
fi

# Accetta bitrate, include_original, formato audio come argomenti (opzionali)
BITRATE="$1"
INCLUDE_ORIGINAL="$2"
FORMAT="$3"

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

    # Esegue lo script principale con tutti gli argomenti batch
    if [ ! -z "$FORMAT" ]; then
        "$SCRIPT_DA_ESEGUIRE" "$file" "$BITRATE" "$INCLUDE_ORIGINAL" "$FORMAT"
    elif [ ! -z "$INCLUDE_ORIGINAL" ]; then
        "$SCRIPT_DA_ESEGUIRE" "$file" "$BITRATE" "$INCLUDE_ORIGINAL"
    elif [ ! -z "$BITRATE" ]; then
        "$SCRIPT_DA_ESEGUIRE" "$file" "$BITRATE"
    else
        "$SCRIPT_DA_ESEGUIRE" "$file"
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
