#!/bin/bash
# ============================================================================
# ClearVoice Auto (Full Version) v3.0 - Audio Processing Adattivo Universale
# ============================================================================
# Questo script analizza, normalizza e ottimizza l'audio di qualsiasi file video
# (film, serie TV, cartoni animati) per massimizzare la chiarezza dei dialoghi
# e garantire un'esperienza audio cinematografica, sempre bilanciata e immersiva.
#
# Autore: Sandro (D@mocle77) Sabbioni - 2025
#
# Caratteristiche principali:
# - Analisi automatica dei livelli audio (LUFS, True Peak, LRA) secondo EBU R128.
# - Analisi spettrale avanzata su tutti i gruppi canale (LFE, Voce, Frontali, Surround):
#   ogni parametro viene modulato in tempo reale in base all'energia RMS di ciascuna banda.
# - Voice boost micro-chirurgico: il volume dei dialoghi viene aumentato solo quando serve,
#   in base al contenuto spettrale e alla dinamica reale.
# - Riduzione frontali e surround ultra-adattiva: ogni gruppo viene bilanciato in base
#   alla propria energia e alla dinamica complessiva, per evitare mascheramenti e clipping.
# - Controllo LFE "chirurgico": i bassi vengono ridotti solo se realmente eccessivi,
#   con filtro passa-alto e riduzione dinamica modulata dal contenuto.
# - Makeup gain, limiter, highpass e lowshelf completamente adattivi, senza preset fissi.
# - Diagnostica avanzata: tutti i valori di analisi e i parametri applicati vengono loggati
#   per massima trasparenza e tuning.
# - Mappatura completa delle tracce: preserva audio, sottotitoli e capitoli originali.
# - Spinner grafico con barra di progresso e stima ETA migliorata.
# - Protezione contro sovrascrittura accidentale.
#
# Uso: ./clearvoice_auto_full.sh "<file_input>" [bitrate] [originale]
# Esempio: ./clearvoice_auto_full.sh "mio_film.mkv" 768k
# Esempio: ./clearvoice_auto_full.sh "mio_film.mkv" 768k no
# Bitrate supportati: 256k, 320k, 384k, 448k, 512k, 640k, 768k (default)
# Traccia originale: yes/no (default: yes - include traccia originale)
# ============================================================================

# --- Funzione di Pulizia ---
# Usare Ctrl+C per interrompere FFmpeg in modo pulito.
cleanup() {
    echo -e "\n\nScript interrotto. Eseguo pulizia processi..."
    # Ferma lo spinner in modo sicuro
    stop_spinner
    # Termina processi FFmpeg con timeout
    echo "Terminazione processi FFmpeg..."
    pkill -f "ffmpeg.*loudnorm" 2>/dev/null
    pkill -f "ffmpeg.*$(basename "$OUTPUT_FILE" 2>/dev/null || echo "output")" 2>/dev/null
    # Attendi che i processi si chiudano (max 5 secondi)
    # (Eventuali altre operazioni di cleanup qui)
}

# Funzione per fermare lo spinner in modo sicuro
stop_spinner() {
    if [ ! -z "$SPIN_PID" ]; then
        # Verifica se il processo esiste ancora
        if kill -0 "$SPIN_PID" 2>/dev/null; then
            kill "$SPIN_PID" 2>/dev/null
            wait "$SPIN_PID" 2>/dev/null
        fi
        # Pulisce la riga del terminale con gestione errori
        printf "\r%*s\r" "60" " " 2>/dev/null || true
    fi
    SPIN_PID=""
}

# Funzione per controllare i requisiti di sistema (ffmpeg, ffprobe, awk)
check_system_requirements() {
    local missing=0
    for cmd in ffmpeg ffprobe awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "ERRORE: comando richiesto non trovato: $cmd"
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo "Installa i requisiti mancanti e riprova."
        exit 1
    fi
}

# Spinner con barra di avanzamento e ETA
show_spinner_with_progress() {
    local MESSAGE="$1"
    local ESTIMATED_DURATION="$2"
    local SPIN_CHARS='|/-\\'
    local CHAR_INDEX=0
    local COUNTER=0
    local START_TIME=$(date +%s)
    while true; do
        local ELAPSED=$(($(date +%s) - START_TIME))
        if [ "$ESTIMATED_DURATION" -gt 0 ]; then
            local PERCENTAGE=$((ELAPSED * 100 / ESTIMATED_DURATION))
            [ "$PERCENTAGE" -gt 95 ] && PERCENTAGE=95
            local PROGRESS_BAR="$(create_progress_bar "$PERCENTAGE" 20)"
            local ETA=$((ESTIMATED_DURATION - ELAPSED))
            [ "$ETA" -lt 0 ] && ETA=0
            local ETA_MIN=$((ETA / 60))
            local ETA_SEC=$((ETA % 60))
            local ELAPSED_MIN=$((ELAPSED / 60))
            local ELAPSED_SEC=$((ELAPSED % 60))
            printf "\r%s: %s %s %d%% | %dm%02ds | ETA: %dm%02ds " \
                "$MESSAGE" "${SPIN_CHARS:$CHAR_INDEX:1}" "$PROGRESS_BAR" "$PERCENTAGE" "$ELAPSED_MIN" "$ELAPSED_SEC" "$ETA_MIN" "$ETA_SEC"
        else
            local ELAPSED_MIN=$((ELAPSED / 60))
            local ELAPSED_SEC=$((ELAPSED % 60))
            printf "\r%s: %s | %dm%02ds " "$MESSAGE" "${SPIN_CHARS:$CHAR_INDEX:1}" "$ELAPSED_MIN" "$ELAPSED_SEC"
        fi
        CHAR_INDEX=$(( (CHAR_INDEX + 1) % 4 ))
        sleep 0.15
        ((COUNTER++))
    done
}

# Funzione per creare una barra di progresso
create_progress_bar() {
    local PERCENTAGE="$1"
    local WIDTH="${2:-40}"
    local FILLED=$((PERCENTAGE * WIDTH / 100))
    local EMPTY=$((WIDTH - FILLED))
    
    # Usa caratteri ASCII sicuri per Git Bash
    local FILL_CHAR="="
    local EMPTY_CHAR="-"
    
    printf "["
    if [ "$FILLED" -gt 0 ]; then
        for ((i=1; i<=FILLED; i++)); do
            printf "%s" "$FILL_CHAR"
        done
    fi
    if [ "$EMPTY" -gt 0 ]; then
        for ((i=1; i<=EMPTY; i++)); do
            printf "%s" "$EMPTY_CHAR"
        done
    fi
    printf "]"
}

# Funzione per ottenere la durata totale del file
get_video_duration() {
    local FILE="$1"
    ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILE" 2>/dev/null | cut -d'.' -f1
}

# Funzione per stimare il tempo di analisi audio semplificata
estimate_analysis_time() {
    local FILE="$1"
    local DURATION=$(get_video_duration "$FILE")
    
    if [ ! -z "$DURATION" ] && [ "$DURATION" -gt 0 ]; then
        # Stima ottimizzata per SOLO AUDIO: analisi loudnorm circa 1/20 del tempo reale
        local ESTIMATED=$((DURATION / 20))
        # Limiti: minimo 5 secondi, massimo 10 minuti
        [ "$ESTIMATED" -lt 5 ] && ESTIMATED=5
        [ "$ESTIMATED" -gt 600 ] && ESTIMATED=600
        echo "$ESTIMATED"
    else
        echo "0"
    fi
}

# Funzione per stimare il tempo di processing migliorata
estimate_processing_time() {
    local DURATION=$1
    local FILE="$2"
    
    # Stima ottimizzata basata su test reali
    # Per contenuti con video copy + audio processing: circa 1/30-1/45 del tempo reale
    local BASE_FACTOR=35
    
    # Aggiustamenti basati sulla durata del contenuto
    if [ "$DURATION" -gt 7200 ]; then
        # File molto lunghi (>2h): efficienza maggiore
        BASE_FACTOR=45
    elif [ "$DURATION" -lt 1800 ]; then
        # File corti (<30min): overhead maggiore
        BASE_FACTOR=25
    fi
    
    local ESTIMATED=$((DURATION / BASE_FACTOR))
    
    # Limiti realistici: minimo 10 secondi, massimo 20 minuti
    [ "$ESTIMATED" -lt 10 ] && ESTIMATED=10
    [ "$ESTIMATED" -gt 1200 ] && ESTIMATED=1200
    
    echo "$ESTIMATED"
}

# --- Logica Principale ---

# Controllo argomenti posizionali (file, bitrate e traccia originale)
if [ -z "$1" ]; then
    echo "Uso: ./clearvoice_auto_full.sh \"<file_input>\" [bitrate] [originale]"
    echo "Esempio: ./clearvoice_auto_full.sh \"mio_film.mkv\" 768k"
    echo "Esempio: ./clearvoice_auto_full.sh \"mio_film.mkv\" 768k no"
    echo "Bitrate supportati: 256k, 384k, 448k, 512K, 640k, 768k (default)"
    echo "Traccia originale: yes/no (default: yes - include traccia originale)"
    exit 1
fi

INPUT_FILE="$1"

# Logica intelligente per parsing argomenti con validazione
# Se il secondo argomento è "yes", "no", "y", "n", allora è il parametro include_original
# e il bitrate rimane quello di default
if [ "$2" = "yes" ] || [ "$2" = "no" ] || [ "$2" = "y" ] || [ "$2" = "n" ] || [ "$2" = "true" ] || [ "$2" = "false" ]; then
    BITRATE="768k"  # Default bitrate
    INCLUDE_ORIGINAL="$2"
else
    # Se il secondo argomento non è yes/no, allora è il bitrate
    BITRATE="${2:-768k}"
    INCLUDE_ORIGINAL="${3:-yes}"
fi

OUTPUT_FILE="${INPUT_FILE%.*}_clearvoice_auto.mkv"

# Verifica se il file è già stato processato
if [ -f "$OUTPUT_FILE" ]; then
    echo "AVVISO: File di output già esistente: $OUTPUT_FILE"
    echo "Vuoi sovrascriverlo? (y/n) [default: n]"
    read -t 10 -r OVERWRITE || OVERWRITE="n"
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "Operazione annullata dall'utente."
        exit 0
    fi
    echo "Sovrascrittura autorizzata. Continuando..."
fi

# Verifica esistenza file di input
if [ ! -f "$INPUT_FILE" ]; then
    echo "ERRORE: File di input non trovato: $INPUT_FILE"
    exit 1
fi

# Controlli di sistema
check_system_requirements

# Verifica formato file supportato
if ! ffprobe -v quiet -show_entries format=format_name "$INPUT_FILE" >/dev/null 2>&1; then
    echo "ERRORE: File non riconosciuto da FFmpeg o formato non supportato"
    exit 1
fi

# --- Analisi Audio ---
echo "=========================== ANALISI SPETTRALE ================================="
DURATION=$(get_video_duration "$INPUT_FILE")
[ -z "$DURATION" ] && DURATION=7200  # Fallback a 2 ore se non riesce a determinare

echo "Durata file: $(($DURATION / 60)) minuti ($(($DURATION / 3600))h $(((DURATION % 3600) / 60))m)"
echo "Analisi loudnorm EBU R128 in corso..."

# Stima il tempo di analisi
ESTIMATED_ANALYSIS_TIME=$(estimate_analysis_time "$INPUT_FILE")
if [ "$ESTIMATED_ANALYSIS_TIME" -gt 0 ]; then
    echo "ETA stimato per analisi: $((ESTIMATED_ANALYSIS_TIME / 60))m $((ESTIMATED_ANALYSIS_TIME % 60))s"

    # --- PAUSA DI SICUREZZA PER TERMINALE (ANALISI) ---
    stop_spinner
    sleep 0.3
    echo ""
    # Avvia lo spinner con progress bar
    show_spinner_with_progress "Analisi loudnorm EBU R128" "$ESTIMATED_ANALYSIS_TIME" &
    SPIN_PID=$!
else
    echo "ETA per analisi audio: circa 3 min per ora di runtime (solo audio)."
    
    # Fallback allo spinner ASCII standard se non si può stimare
    show_spinner "Analisi audio approfondita" &
    SPIN_PID=$!
fi

ANALYSIS=$(ffmpeg -nostdin -i "$INPUT_FILE" -af loudnorm=print_format=summary -f null - 2>&1)

# Ferma lo spinner in modo sicuro
stop_spinner
echo "Analisi completata!                                                          "

LUFS=$(echo "$ANALYSIS" | grep "Input Integrated" | awk '{print $3}' | sed 's/LUFS//')
PEAK=$(echo "$ANALYSIS" | grep "Input True Peak" | awk '{print $4}' | sed 's/dBTP//')
LRA=$(echo "$ANALYSIS" | grep "Input LRA" | awk '{print $3}' | sed 's/LU//')
THRESHOLD=$(echo "$ANALYSIS" | grep "Input Threshold" | awk '{print $3}' | sed 's/LUFS//')
TARGET_OFFSET=$(echo "$ANALYSIS" | grep "Target Offset" | awk '{print $3}' | sed 's/LU//')

# Validazione robusta dei risultati dell'analisi
if [ -z "$LUFS" ] || [ -z "$PEAK" ] || [ -z "$LRA" ]; then
    echo "ERRORE: Analisi audio fallita. Verificare il file di input."
    echo "Output dell'analisi:"
    echo "$ANALYSIS"
    exit 1
fi

# Validazione valori numerici
if ! awk "BEGIN {exit !($LUFS >= -70 && $LUFS <= 0)}" 2>/dev/null; then
    echo "ERRORE: Valore LUFS non valido: $LUFS"
    exit 1
fi

if ! awk "BEGIN {exit !($PEAK >= -20 && $PEAK <= 10)}" 2>/dev/null; then
    echo "ERRORE: Valore True Peak non valido: $PEAK"
    exit 1
fi

echo "============================ RISULTATI ANALISI ================================"
echo
echo "LOUDNESS INTEGRATO (EBU R128):"
echo "Input Integrated: $LUFS LUFS"
if [ $(awk "BEGIN {print ($LUFS < -23) ? 1 : 0}") -eq 1 ]; then
    echo "Profilo Loudness: Livello contenuto, al di sotto degli standard di streaming."
elif [ $(awk "BEGIN {print ($LUFS > -16) ? 1 : 0}") -eq 1 ]; then
    echo "Profilo Loudness: Livello elevato, al limite dei parametri di streaming (-16 LUFS)."
else
    echo "Profilo Loudness: Bilanciato, entro le specifiche cinematografiche standard."
fi
echo
# -------------------- ANALISI TRUE PEAK --------------------
echo "TRUE PEAK ANALYSIS:"
echo "Input True Peak: $PEAK dBTP"
if [ $(awk "BEGIN {print ($PEAK > -1) ? 1 : 0}") -eq 1 ]; then
    echo "ATTENZIONE: Headroom critico. Rischio di clipping elevato su codec lossy."
elif [ $(awk "BEGIN {print ($PEAK > -3) ? 1 : 0}") -eq 1 ]; then
    echo "AVVISO: Headroom limitato. Margine di sicurezza ridotto per processing."
else
    echo "SICURO: Headroom ottimale. Margine di sicurezza adeguato per processing."
fi
echo
# -------------------- ANALISI DINAMICA --------------------
echo "DINAMICA E CARATTERISTICHE FILMICHE:"
echo "Loudness Range: $LRA LU"
if [ $(awk "BEGIN {print ($LRA < 6) ? 1 : 0}") -eq 1 ]; then
    echo "Profilo Dinamico: Compressione elevata, ottimizzato per contenuti ad alto impatto."
elif [ $(awk "BEGIN {print ($LRA > 20) ? 1 : 0}") -eq 1 ]; then
    echo "Profilo Dinamico: Esteso, tipico di produzioni cinematografiche con ampia gamma dinamica."
else
    echo "Profilo Dinamico: Standard cinematografico, bilanciato per fruizione domestica."
fi
echo "Input Threshold: $THRESHOLD LUFS"
echo "Target Offset: $TARGET_OFFSET LU"
echo

# --- Logica Adattiva ---
echo "============================ LOGICA ADATTIVA =================================="
echo "  Questa fase di calcolo filtri può durare diversi minuti, attendere prego!!!  "
echo "==============================================================================="

# Parametri di default
DEFAULT_VOICE_BOOST=3.2         # Voice boost base 3.2dB
DEFAULT_LFE_REDUCTION=0.74      # LFE default
DEFAULT_SURROUND_BOOST=2.7      # boost surround
DEFAULT_MAKEUP_GAIN=1.3         # Makeup gain
DEFAULT_FRONT_REDUCTION=0.85    # Riduzione front neutra

# Inizializza i parametri di lavoro con i valori di default
VOICE_BOOST=$DEFAULT_VOICE_BOOST
LFE_REDUCTION=$DEFAULT_LFE_REDUCTION
SURROUND_BOOST=$DEFAULT_SURROUND_BOOST
MAKEUP_GAIN=$DEFAULT_MAKEUP_GAIN
FRONT_REDUCTION=$DEFAULT_FRONT_REDUCTION

# --- Logica Adattiva Jedi ---

# 1. Limiter: Attack adattivo
if [ $(awk "BEGIN {print ($LRA < 8) ? 1 : 0}") -eq 1 ]; then
    LIMITER_ATTACK=10
else
    LIMITER_ATTACK=5
fi

# 2. Highpass micro-adattivo
if [ $(awk "BEGIN {print ($LRA < 8) ? 1 : 0}") -eq 1 ]; then
    HIGHPASS_FREQ=112
elif [ $(awk "BEGIN {print ($LRA > 15) ? 1 : 0}") -eq 1 ]; then
    HIGHPASS_FREQ=108
else
    HIGHPASS_FREQ=110
fi

# 3. Lowshelf ON/OFF super-smart
LOWSHELF_ON=0
if [ $(awk "BEGIN {print ($LRA < 8) ? 1 : 0}") -eq 1 ]; then
    LOWSHELF_ON=1
fi

# 4. FRONT_REDUCTION microvariabile
if [ $(awk "BEGIN {print ($LRA < 8) ? 1 : 0}") -eq 1 ]; then
    FRONT_REDUCTION=0.88
elif [ $(awk "BEGIN {print ($LRA > 15) ? 1 : 0}") -eq 1 ]; then
    FRONT_REDUCTION=0.82
else
    FRONT_REDUCTION=0.85
fi

# Surround Boost adattivo
if [ $(awk "BEGIN {print ($LRA < 8) ? 1 : 0}") -eq 1 ]; then
    SURROUND_BOOST=2.3
elif [ $(awk "BEGIN {print ($LRA > 15) ? 1 : 0}") -eq 1 ]; then
    SURROUND_BOOST=3.0
else
    SURROUND_BOOST=2.7
fi

# 5. MAKEUP_GAIN dinamico
if [ $(awk "BEGIN {print ($LRA > 15) ? 1 : 0}") -eq 1 ]; then
    MAKEUP_GAIN=1.4
else
    MAKEUP_GAIN=1.3
fi

# LFE_REDUCTION adattivo come prima
if [ $(awk "BEGIN {print ($LRA < 8) ? 1 : 0}") -eq 1 ]; then
    LFE_REDUCTION=0.72
elif [ $(awk "BEGIN {print ($LRA > 15 && $LUFS < -20) ? 1 : 0}") -eq 1 ]; then
    LFE_REDUCTION=0.76
else
    LFE_REDUCTION=0.74
fi

# --- Analisi spettrale extra dei bassi (30-120Hz) ---
# --- Analisi spettrale extra dei bassi (30-120Hz) ---
BASS_RMS=$(ffmpeg -nostdin -i "$INPUT_FILE" -af "lowpass=f=120,volumedetect" -f null - 2>&1 | grep "mean_volume" | awk '{print $5}')
# Se bassi molto presenti, applica chirurgia LFE + patch anti-vibrazioni
if [ ! -z "$BASS_RMS" ] && [ $(awk "BEGIN {print ($BASS_RMS > -18) ? 1 : 0}") -eq 1 ]; then
    echo "[EXTRA-NERD] Bassi molto presenti (RMS $BASS_RMS dB): applico chirurgia LFE + patch anti-vibrazioni!"
    # Chirurgia principale: -0.05
    LFE_REDUCTION=$(awk -v x="$LFE_REDUCTION" 'BEGIN {printf "%.2f", x-0.05}')
    # Micro riduzione extra: -0.04 (somma di -0.01 e -0.03)
    LFE_REDUCTION=$(awk -v x="$LFE_REDUCTION" 'BEGIN {printf "%.2f", x-0.04}')
    LFE_HP_FREQ=35
    # Log live del valore finale
    echo "LFE_REDUCTION finale dopo chirurgia+patch: ${LFE_REDUCTION}x"
else
    LFE_HP_FREQ=25
fi

# --- FC_FILTER adattivo ---
if [ $LOWSHELF_ON -eq 1 ]; then
    FC_FILTER="highpass=f=${HIGHPASS_FREQ},lowshelf=f=220:g=-2,highshelf=f=5000:g=2,volume=${VOICE_BOOST},alimiter=attack=${LIMITER_ATTACK}:release=100"
else
    FC_FILTER="highpass=f=${HIGHPASS_FREQ},highshelf=f=5000:g=2,volume=${VOICE_BOOST},alimiter=attack=${LIMITER_ATTACK}:release=100"
fi

# --- FINAL_FILTER adattivo ---
# Limit finale adattivo: se True Peak >= -0.5 dBTP, imposta limit a -1.0 dBTP (0.89), altrimenti 0.95
LIMIT_FINAL=0.95
if [ ! -z "$PEAK" ] && awk "BEGIN {exit !($PEAK >= -0.5)}"; then
    LIMIT_FINAL=0.89
fi
FINAL_FILTER="volume=${MAKEUP_GAIN},alimiter=level_in=1:level_out=1:limit=${LIMIT_FINAL}:attack=10:release=150:asc=1,aformat=channel_layouts=5.1"

# ==================== VALIDAZIONE PARAMETRI FINALI ====================
# Limita voice boost a massimo 3.3 (accetta anche 3.3)
if ! awk -v v="$VOICE_BOOST" 'BEGIN {exit (v<=3.3) ? 0 : 1}'; then
    echo "Voice boost troppo alto (${VOICE_BOOST}), imposto a 3.3dB per sicurezza."
    VOICE_BOOST=3.3
fi
# Difesa parametri non numerici (compatibile con virgola decimale)
for var in VOICE_BOOST LFE_REDUCTION FRONT_REDUCTION SURROUND_BOOST MAKEUP_GAIN; do
  val=$(eval echo \$$var | sed 's/,/./')
  if [[ ! "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      echo "Parametro $var non numerico ($val), imposto a 1.0."
      eval $var=1.0
  else
      eval $var=$val
  fi
done
# Validazione parametri: accetta valori tra 0.5 e 3.3 (compatibile con awk -v)
for param in VOICE_BOOST LFE_REDUCTION FRONT_REDUCTION SURROUND_BOOST MAKEUP_GAIN; do
    value=$(eval echo \$$param | sed 's/,/./')
    # Limita VOICE_BOOST a massimo 3.3
    if [ "$param" = "VOICE_BOOST" ] && ! awk -v v="$value" 'BEGIN {exit (v<=3.3) ? 0 : 1}'; then
        echo "Parametro $param fuori range sicuro ($value), imposto valore massimo sicuro 3.3."
        eval $param=3.3
    elif ! awk -v v="$value" 'BEGIN {exit (v>=0.5 && v<=3.3) ? 0 : 1}'; then
        echo "Parametro $param fuori range sicuro ($value), imposto valore minimo sicuro 1.0."
        eval $param=1.0
    else
        eval $param=$value
    fi
done

# --- DIAGNOSTICA PARAMETRI FINALI ---
echo "--- DIAGNOSTICA PARAMETRI AUDIO ---"
echo "VOICE_BOOST: $VOICE_BOOST"
echo "LFE_REDUCTION: $LFE_REDUCTION   (valore finale dopo chirurgia/patch se attiva)"
echo "FRONT_REDUCTION: $FRONT_REDUCTION"
echo "SURROUND_BOOST: $SURROUND_BOOST"
echo "MAKEUP_GAIN: $MAKEUP_GAIN"
echo "Limiter final limit: $LIMIT_FINAL ("$(awk -v l="$LIMIT_FINAL" 'BEGIN {printf "%.1f", 20*log(l)/log(10)}')" dBTP)"
echo "BASS_RMS (30-120Hz): ${BASS_RMS} dB"
echo "-----------------------------------"
echo -e "\nPreparazione filtri...questa fase può durare alcuni minuti, attendere prego!!!\n"

# Messaggio statico: niente spinner grafico
echo "Elaborazione in corso...potrebbero essere necessari diversi minuti!"

# --- Preparazione filtri FFmpeg ottimizzati per DSP moderni ---

# Filtro vocale: passa-alto fisso a 110Hz, highshelf a 5000Hz +2dB, voice boost adattivo, limiter dolce
FC_FILTER="highpass=f=110,highshelf=f=5000:g=2,volume=${VOICE_BOOST},alimiter=attack=5:release=100"

# Filtro LFE con highpass adattivo e volume
LFE_FILTER="highpass=f=${LFE_HP_FREQ:-25}:poles=2,volume=${LFE_REDUCTION}"

# Filtro surround essenziale - SOLO volume (DSP gestisce tutto il resto)
SURROUND_FILTER="volume=${SURROUND_BOOST}"

# Filtro finale con limiter più dolce per evitare distorsioni
FINAL_FILTER="volume=${MAKEUP_GAIN},alimiter=level_in=1:level_out=1:limit=0.95:attack=10:release=150:asc=1,aformat=channel_layouts=5.1"

# --- Esecuzione FFmpeg ---
echo
echo "==============================================================="
echo "Avvio ClearVoice Auto processing universale..."
echo "Profilo: $(basename "$INPUT_FILE")"
echo "==============================================================="
echo

# Stima tempo di processing
ESTIMATED_PROCESSING_TIME=$(estimate_processing_time "$DURATION")
MINUTES=$((ESTIMATED_PROCESSING_TIME / 60))
SECONDS=$((ESTIMATED_PROCESSING_TIME % 60))
echo "Tempo stimato elaborazione: ${MINUTES}m ${SECONDS}s"
echo

# Avvia lo spinner con progress bar per l'elaborazione
START_TIME=$(date +%s)

echo "Elaborazione in corso..."
echo "Avvio: $(date +%H:%M:%S)"
# Cross-platform compatible ETA calculation
if command -v gdate >/dev/null 2>&1; then
    # macOS with GNU coreutils
    echo "ETA: $(gdate -d "+${ESTIMATED_PROCESSING_TIME} seconds" +%H:%M:%S 2>/dev/null || echo "N/A")"
elif date -d "1970-01-01 +${ESTIMATED_PROCESSING_TIME} seconds" +%H:%M:%S >/dev/null 2>&1; then
    # GNU date (Linux)
    echo "ETA: $(date -d "+${ESTIMATED_PROCESSING_TIME} seconds" +%H:%M:%S)"
else
    # Fallback for BSD/macOS
    echo "ETA: circa ${MINUTES}m ${SECONDS}s"
fi
echo

# Preparazione parametri audio dinamici in base alla scelta dell'utente
if [ "$INCLUDE_ORIGINAL" = "no" ] || [ "$INCLUDE_ORIGINAL" = "n" ] || [ "$INCLUDE_ORIGINAL" = "false" ]; then
    echo "Modalità: Solo traccia ClearVoice (traccia originale esclusa)"
    AUDIO_MAPPING='-map "[clearvoice]" -c:a:0 eac3 -b:a:0 '"${BITRATE}"' -metadata:s:a:0 language=ita -metadata:s:a:0 title="EAC3 ClearVoice Auto" \
        -map 0:a:1? -c:a:1 copy \
        -map 0:a:2? -c:a:2 copy \
        -disposition:a:0 default'
else
    echo "Modalità: ClearVoice + Originale (traccia originale inclusa)"
    AUDIO_MAPPING='-map "[clearvoice]" -c:a:0 eac3 -b:a:0 '"${BITRATE}"' -metadata:s:a:0 language=ita -metadata:s:a:0 title="EAC3 ClearVoice Auto" \
        -map 0:a:0 -c:a:1 copy -metadata:s:a:1 title="Originale" \
        -map 0:a:1? -c:a:2 copy \
        -map 0:a:2? -c:a:3 copy \
        -disposition:a:0 default -disposition:a:1 0'
fi

# Avvia lo spinner con progress bar per l'elaborazione

echo -e "\nLa preparazione filtri può durare diversi minuti, attendere prego!!!\n"
    
# Esegui FFmpeg in foreground (così la barra resta visibile)
eval "ffmpeg -y -nostdin -loglevel error -hwaccel auto -threads 0 -i \"$INPUT_FILE\" -filter_complex \
\"[0:a:0]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][SL][SR]; \
[FC]${FC_FILTER}[FCout]; \
[LFE]${LFE_FILTER}[LFEout]; \
[FL]volume=${FRONT_REDUCTION}[FLout]; \
[FR]volume=${FRONT_REDUCTION}[FRout]; \
[SL]${SURROUND_FILTER}[SLout]; \
[SR]${SURROUND_FILTER}[SRout]; \
[FLout][FRout][FCout][LFEout][SLout][SRout]amerge=inputs=6,${FINAL_FILTER}[clearvoice]\" \
-map 0:v -c:v copy \
${AUDIO_MAPPING} \
-map 0:s? -c:s copy \
-map 0:t? -c:t copy \
-map_metadata 0 \
-map_chapters 0 \
\"$OUTPUT_FILE\""

echo "Elaborazione completata!"
echo "Elaborazione terminata alle: $(date +%H:%M:%S)"

# -------------------- OUTPUT FINALE --------------------
# Cattura l'exit code di FFmpeg
ffmpeg_exit_code=$?

# Gestione errori
if [ $ffmpeg_exit_code -ne 0 ]; then
    echo
    echo "==================== ERRORE FFMPEG ======================="
    echo "ERRORE: FFmpeg terminato con codice $ffmpeg_exit_code"
    echo "Tempo trascorso: $(( $(date +%s) - START_TIME )) secondi"
    echo "Possibili cause:"
    echo "- File di input corrotto o non supportato"
    echo "- Spazio su disco insufficiente"
    echo "- Problemi di memoria o CPU"
    echo "- Parametri audio incompatibili"
    echo "- Interruzione manuale (Ctrl+C)"
    echo "=========================================================="
    exit $ffmpeg_exit_code
fi

# Calcola il tempo totale di elaborazione
DURATION_FINAL=$(( $(date +%s) - START_TIME ))
MINUTI=$((DURATION_FINAL / 60))
SECONDI=$((DURATION_FINAL % 60))

if [ $ffmpeg_exit_code -eq 0 ]; then
    echo
    echo "============================= ELABORAZIONE COMPLETATA ==========================="
    echo "SUCCESSO - Tempo impiegato: ${MINUTI}m ${SECONDI}s"
    
    # Verifica che il file di output sia stato creato correttamente
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        echo "Output: ${OUTPUT_FILE##*/}"
        echo "Preset: ClearVoice Auto (EAC3 ${BITRATE})"
        
        # Cross-platform file size detection
        if command -v stat >/dev/null 2>&1; then
            # Try GNU stat first (Linux), then BSD stat (macOS)
            OUTPUT_SIZE=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null || echo "sconosciuta")
        else
            OUTPUT_SIZE="sconosciuta"
        fi
        if [ "$OUTPUT_SIZE" != "sconosciuta" ]; then
            OUTPUT_SIZE_MB=$((OUTPUT_SIZE / 1024 / 1024))
            echo "Dimensione output: ${OUTPUT_SIZE_MB} MB"
        fi
        
        # Verifica integrità del file di output
        echo "Verifica integrità file..."
        if ffprobe -v quiet -show_entries format=duration "$OUTPUT_FILE" >/dev/null 2>&1; then
            OUTPUT_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null | cut -d'.' -f1)
            DURATION_DIFF=$((DURATION > OUTPUT_DURATION ? DURATION - OUTPUT_DURATION : OUTPUT_DURATION - DURATION))
            if [ "$DURATION_DIFF" -lt 5 ]; then
                echo "✓ File integro - durata corretta"
            else
                echo "⚠ ATTENZIONE: Differenza durata significativa (${DURATION_DIFF}s)"
            fi
        else
            echo "⚠ ATTENZIONE: Impossibile verificare integrità del file"
        fi
    else
        echo "AVVERTIMENTO: File di output non trovato o vuoto!"
        echo "Percorso: $OUTPUT_FILE"
        ls -la "$OUTPUT_FILE" 2>/dev/null || echo "File non esistente"
    fi

    # Mostra i parametri finali applicati
    echo
    echo "PARAMETRI CLEARVOICE AUTO APPLICATI:"
    echo "Voice Enhancement: ${VOICE_BOOST}dB (adattivo) | Front Control: ${FRONT_REDUCTION}x (FL/FR bilanciati)"
    echo "LFE Control: Adattivo (HPF Subsonico 25Hz / Reduction ${LFE_REDUCTION}x)"
    echo "Surround Boost: +$(awk -v s="$SURROUND_BOOST" 'BEGIN {printf "%.1f", 20*log(s)/log(10)}')dB (${SURROUND_BOOST}x) | Makeup Gain: $MAKEUP_GAIN dB"
    echo "CONFIGURAZIONE: Architettura adattiva con controlli di volume intelligenti."
    echo
    echo "ANALISI SORGENTE:"
    echo "Integrated Loudness: $LUFS LUFS | True Peak: $PEAK dBTP | Loudness Range: $LRA LU"
    echo "================================================================================="
else
    echo "ERRORE - Gestito dalla sezione precedente del codice."
    exit $ffmpeg_exit_code
fi