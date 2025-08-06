#!/bin/bash

# ================================================================================
# clearvoice_auto_full.sh
# Batch per lanciare clearvocie_auto.sh su multipli MKV in una cartella.
# Ctrl+C interrompe tutto: batch e processi figli.
# ================================================================================

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
SCRIPT_DA_ESEGUIRE="./clearvoice_auto_full.sh"

# Verifica che lo script principale esista e sia eseguibile
if [ ! -f "$SCRIPT_DA_ESEGUIRE" ] || [ ! -x "$SCRIPT_DA_ESEGUIRE" ]; then
    echo "Houston, problema! $SCRIPT_DA_ESEGUIRE non trovato o non eseguibile. Controlla il tuo setup JARVIS."
    exit 1
fi

# Accetta bitrate e preset override come argomenti (opzionali)
BITRATE="$1"
PRESET_OVERRIDE="$2"

# TIMER GLOBALE - START
batch_start_time=$(date +%s)
processed_files=0
total_files=0

# Crea un array con tutti i file MKV, escludendo quelli già processati
mapfile -t mkv_files < <(find . -maxdepth 1 -type f -name "*.mkv" ! -name "*_clearvoice_auto.mkv" -print0 | sort -zV | tr '\0' '\n')
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
    
    # Esegue lo script principale con argomenti opzionali
    if [ ! -z "$PRESET_OVERRIDE" ]; then
        "$SCRIPT_DA_ESEGUIRE" "$file" "$BITRATE" "$PRESET_OVERRIDE"
    elif [ ! -z "$BITRATE" ]; then
        "$SCRIPT_DA_ESEGUIRE" "$file" "$BITRATE"
    else
        "$SCRIPT_DA_ESEGUIRE" "$file"
    fi
    
    echo ">>> Completato: ${file##*/}"
    echo "---------------------------------"
done

# TIMER GLOBALE - END
batch_duration=$((($(date +%s) - batch_start_time)))
batch_minuti=$((batch_duration / 60))
batch_secondi=$((batch_duration % 60))

echo "MISSIONE COMPIUTA!"
echo "Tempo totale: ${batch_minuti}m ${batch_secondi}s"
echo "File processati: ${processed_files}"
echo "File totali: ${total_files}"
echo "Batch terminato – 'Doppia Libidine con il fiocco!!!" 🚀
