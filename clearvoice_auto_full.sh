#!/bin/bash

# ==============================================================================
# ClearVoice Auto (Full Version) v3.0 - Audio Processing Universale
# ==============================================================================
# Questo script analizza e normalizza l'audio di qualsiasi file video (film, 
# serie TV, cartoni animati) per migliorare la chiarezza dei dialoghi, 
# mantenendo al contempo un'esperienza audio bilanciata e cinematografica.
#
# Autore: D@mocle77 - 2025
#
# Caratteristiche:
# - Analisi automatica dei livelli audio (LUFS, True Peak, LRA).
# - Rilevamento automatico del tipo di contenuto (film/serie TV/corto).
# - Aumento dinamico del volume del canale centrale (dialoghi).
# - Controllo e pulizia del canale LFE (bassi).
# - Boost controllato dei canali surround per maggiore immersività.
# - Riduzione dinamica dei canali frontali per evitare clipping e dare spazio alla voce.
# - Logica adattiva che modifica i parametri in base alle caratteristiche del file sorgente.
# - Mappatura completa delle tracce per preservare audio, sottotitoli e capitoli originali.
# - Spinner grafico con barra di progresso e stima del tempo (ETA) migliorata.
# - Protezione contro sovrascrittura accidentale.
#
# Uso: ./clearvoice_auto_full.sh "<file_input>" [bitrate] [originale]
# Esempio: ./clearvoice_auto_full.sh "mio_film.mkv" 768k
# Esempio: ./clearvoice_auto_full.sh "mio_film.mkv" 768k no
# Bitrate supportati: 256k, 320k, 384k, 448k, 512k, 640k, 768k (default)
# Traccia originale: yes/no (default: yes - include traccia originale)
# ==============================================================================

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
    for i in {1..5}; do
        if ! pgrep -f "ffmpeg" >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Forza la terminazione se necessario
    if pgrep -f "ffmpeg" >/dev/null 2>&1; then
        pkill -9 -f "ffmpeg" 2>/dev/null
    fi
    
    echo "Pulizia completata."
    exit 130
}

# Imposta la trap per gestire l'interruzione Ctrl+C
trap cleanup SIGINT

# --- Funzioni per Spinner e Barra di Progresso ---

# Funzione per verificare i requisiti di sistema
check_system_requirements() {
    echo "Verifica requisiti di sistema..."
    
    # Controlla la disponibilità di FFmpeg e ffprobe
    if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
        echo "ERRORE: FFmpeg o ffprobe non trovati nel PATH. Assicurati che FFmpeg sia installato correttamente."
        exit 1
    fi
    
    echo "Controlli completati."
}

# Funzione migliorata per lo spinner con gestione robusta
show_spinner() {
    local MESSAGE="${1:-Scansione in corso}"
    local SPIN_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏" # Spinner animato Unicode
    local FALLBACK_CHARS="/-|\\*" # Fallback ASCII
    
    # Test supporto Unicode più robusto
    if ! echo "⠋" | grep -q "⠋" 2>/dev/null; then
        SPIN_CHARS="$FALLBACK_CHARS"
    fi
    
    local CHAR_COUNT=${#SPIN_CHARS}
    local COUNTER=0

    while true; do
        local CHAR_INDEX=$((COUNTER % CHAR_COUNT))
        printf "\r%s: %s " "$MESSAGE" "${SPIN_CHARS:$CHAR_INDEX:1}"
        sleep 0.12
        ((COUNTER++))
    done
}

# Spinner avanzato con progress bar per operazioni con durata stimata
show_spinner_with_progress() {
    local MESSAGE="$1"
    local ESTIMATED_DURATION="$2"  # durata stimata in secondi
    local START_TIME=$(date +%s)
    
    local SPIN_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local FALLBACK_CHARS="/-|\\*"
    
    # Test supporto Unicode
    if ! echo "⠋" | grep -q "⠋" 2>/dev/null; then
        SPIN_CHARS="$FALLBACK_CHARS"
    fi
    
    local CHAR_COUNT=${#SPIN_CHARS}
    local COUNTER=0
    
    while true; do
        local CHAR_INDEX=$((COUNTER % CHAR_COUNT))
        local ELAPSED=$(($(date +%s) - START_TIME))
        
        if [ "$ESTIMATED_DURATION" -gt 0 ]; then
            local PERCENTAGE=$((ELAPSED * 100 / ESTIMATED_DURATION))
            # Limita al 95% per evitare che vada oltre durante l'operazione
            if [ "$PERCENTAGE" -gt 95 ]; then
                PERCENTAGE=95
            fi
            
            local PROGRESS_BAR=$(create_progress_bar "$PERCENTAGE" 20)
            local ETA=$((ESTIMATED_DURATION - ELAPSED))
            if [ "$ETA" -lt 0 ]; then ETA=0; fi
            local ETA_MIN=$((ETA / 60))
            local ETA_SEC=$((ETA % 60))
            local ELAPSED_MIN=$((ELAPSED / 60))
            local ELAPSED_SEC=$((ELAPSED % 60))
            
            printf "\r%s: %s %s %d%% | %dm%02ds | ETA: %dm%02ds " \
                "$MESSAGE" "${SPIN_CHARS:$CHAR_INDEX:1}" "$PROGRESS_BAR" "$PERCENTAGE" "$ELAPSED_MIN" "$ELAPSED_SEC" "$ETA_MIN" "$ETA_SEC"
        else
            # Fallback senza progress se durata non disponibile
            local ELAPSED_MIN=$((ELAPSED / 60))
            local ELAPSED_SEC=$((ELAPSED % 60))
            printf "\r%s: %s | %dm%02ds " "$MESSAGE" "${SPIN_CHARS:$CHAR_INDEX:1}" "$ELAPSED_MIN" "$ELAPSED_SEC"
        fi
        
        sleep 0.15
        ((COUNTER++))
    done
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

# Funzione per rilevare il tipo di contenuto
detect_content_type() {
    local FILE="$1"
    local DURATION="$2"
    local FILENAME=$(basename "$FILE")
    
    # Rilevamento basato sul nome del file
    if echo "$FILENAME" | grep -qi -E "(S[0-9]+E[0-9]+|[0-9]+x[0-9]+|episode|episodio|capitolo|puntata|ep[0-9]+)"; then
        echo "series"
    elif echo "$FILENAME" | grep -qi -E "(movie|film|dvdrip|bluray|bdrip|webrip|hdtv)"; then
        echo "movie"
    elif echo "$FILENAME" | grep -qi -E "(trailer|teaser|clip|promo|short)"; then
        echo "short"
    elif [ "$DURATION" -lt 1800 ]; then
        # Meno di 30 minuti, probabilmente episodio o contenuto breve
        echo "short"
    elif [ "$DURATION" -gt 6000 ]; then
        # Più di 100 minuti, probabilmente film
        echo "movie"
    else
        # Tra 30-100 minuti, probabilmente episodio
        echo "series"
    fi
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
echo "======================= ANALISI SPETTRALE ============================"
DURATION=$(get_video_duration "$INPUT_FILE")
[ -z "$DURATION" ] && DURATION=7200  # Fallback a 2 ore se non riesce a determinare

echo "Durata file: $(($DURATION / 60)) minuti ($(($DURATION / 3600))h $(((DURATION % 3600) / 60))m)"
echo "Analisi loudnorm EBU R128 in corso..."

# Stima il tempo di analisi
ESTIMATED_ANALYSIS_TIME=$(estimate_analysis_time "$INPUT_FILE")
if [ "$ESTIMATED_ANALYSIS_TIME" -gt 0 ]; then
    echo "ETA stimato per analisi: $((ESTIMATED_ANALYSIS_TIME / 60))m $((ESTIMATED_ANALYSIS_TIME % 60))s"
    
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

echo "======================= RISULTATI ANALISI ==========================="
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
    echo "AVVISO: Headroom limitato. Margine di sicurezza ridotto per elaborazioni successive."
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
echo "======================= LOGICA ADATTIVA ==========================="

# Rileva il tipo di contenuto
CONTENT_TYPE=$(detect_content_type "$INPUT_FILE" "$DURATION")
echo "Tipo di contenuto rilevato: $CONTENT_TYPE"

# Parametri di default ottimizzati per chiarezza vocale e DSP moderni
DEFAULT_VOICE_BOOST=3.5         # Voice boost incrementato leggermente per maggiore chiarezza
DEFAULT_LFE_REDUCTION=0.77      # LFE ridotto equilibrato per bilanciamento ottimale
DEFAULT_SURROUND_BOOST=2.7      # boost incrementato per maggiore immersività (aumentato)
DEFAULT_MAKEUP_GAIN=1.3         # Makeup gain ottimizzato (+0.3dB incremento conservativo)
DEFAULT_FRONT_REDUCTION=0.77    # Riduzione front ottimizzata per chiarezza vocale

# Inizializza i parametri di lavoro con i valori di default
VOICE_BOOST=$DEFAULT_VOICE_BOOST
LFE_REDUCTION=$DEFAULT_LFE_REDUCTION
SURROUND_BOOST=$DEFAULT_SURROUND_BOOST
MAKEUP_GAIN=$DEFAULT_MAKEUP_GAIN
FRONT_REDUCTION=$DEFAULT_FRONT_REDUCTION

# Logica adattiva basata sui risultati dell'analisi - usando awk per compatibilità

# ==================== ADATTAMENTO BASATO SUL TIPO DI CONTENUTO ====================
if [ "$CONTENT_TYPE" = "series" ]; then
    echo "OTTIMIZZAZIONE SERIE TV: Parametri ottimizzati per episodi TV"
    # Serie TV tendono ad avere dialoghi più importanti e meno effetti
    VOICE_BOOST=3.8               # Voice boost incrementato per serie TV (dialoghi cruciali)
    FRONT_REDUCTION=0.74          # Riduzione front più aggressiva per dare massimo spazio ai dialoghi
    SURROUND_BOOST=2.6            # Surround boost aumentato per maggiore immersività
    echo "Parametri serie TV: Voice +${VOICE_BOOST}dB, Front ${FRONT_REDUCTION}x, Surround ${SURROUND_BOOST}x"
elif [ "$CONTENT_TYPE" = "movie" ]; then
    echo "OTTIMIZZAZIONE FILM: Parametri ottimizzati per contenuti cinematografici"
    # Film mantengono valori default per bilanciamento cinematografico ottimale
    VOICE_BOOST=$DEFAULT_VOICE_BOOST      # Voice boost cinematografico standard
    FRONT_REDUCTION=$DEFAULT_FRONT_REDUCTION    # Riduzione front cinematografica
    SURROUND_BOOST=2.7      # Surround boost cinematografico aumentato
    echo "Parametri film: Voice +${VOICE_BOOST}dB, Front ${FRONT_REDUCTION}x, Surround ${SURROUND_BOOST}x"
elif [ "$CONTENT_TYPE" = "short" ]; then
    echo "OTTIMIZZAZIONE CONTENUTO BREVE: Parametri per clip/trailer"
    VOICE_BOOST=3.4               # Voice boost moderato per contenuti brevi
    FRONT_REDUCTION=0.76          # Riduzione front bilanciata per clip
    SURROUND_BOOST=2.5            # Surround boost aumentato per contenuti brevi
    MAKEUP_GAIN=1.1               # Makeup gain ottimizzato per contenuti brevi (+0.3dB incremento)
    echo "Parametri contenuto breve: Voice +${VOICE_BOOST}dB, Front ${FRONT_REDUCTION}x, Surround ${SURROUND_BOOST}x"
else
    echo "TIPO CONTENUTO SCONOSCIUTO: Applicazione parametri default"
    # Fallback ai valori default per contenuti non riconosciuti
    SURROUND_BOOST=2.7
    echo "Parametri default: Voice +${VOICE_BOOST}dB, Front ${FRONT_REDUCTION}x, Surround ${SURROUND_BOOST}x"
fi

# ==================== ADATTAMENTO LFE INTELLIGENTE ====================
# Analisi del profilo contenuto per adattare la riduzione LFE
echo "Analisi profilo contenuto per ottimizzazione LFE..."

# ==================== ADATTAMENTO VOCE E FRONT INTELLIGENTE ====================
# Logica per contenuti ad alta dinamica (film d'azione, thriller, sci-fi)
if [ $(awk "BEGIN {print ($LRA > 15) ? 1 : 0}") -eq 1 ] && [ $(awk "BEGIN {print ($LUFS < -20) ? 1 : 0}") -eq 1 ]; then
    echo "PROFILO RILEVATO: Film ad alta dinamica (action/thriller/sci-fi)"
    LFE_REDUCTION=0.74        # Riduzione precisa per film d'azione (-2.3dB)
    VOICE_BOOST=3.6           # Voice boost ottimizzato per contenuti cinematografici di qualità
    FRONT_REDUCTION=0.76      # Riduzione front aggressiva per dare massimo spazio alla voce (-2.5dB)
    SURROUND_BOOST=2.9        # +9.2dB per mantenere l'immersività cinematografica incrementata (aumentato)
    MAKEUP_GAIN=1.3           # Makeup gain ottimizzato per contenuti dinamici (+0.3dB incremento)
    echo "LFE ottimizzato per impatto dinamico controllato: ${LFE_REDUCTION}x"
    echo "Voice ottimizzata per contenuti cinematografici: +${VOICE_BOOST}dB"

# Logica per contenuti musicali/musical (criteri ampliati per Disney/Broadway)
elif [ $(awk "BEGIN {print ($LRA < 8) ? 1 : 0}") -eq 1 ] && [ $(awk "BEGIN {print ($LUFS > -20) ? 1 : 0}") -eq 1 ]; then
    echo "PROFILO RILEVATO: Contenuto musicale/musical compresso (Disney, Broadway style)"
    LFE_REDUCTION=0.76        # Riduzione bilanciata per preservare musicalità (-2.1dB)
    VOICE_BOOST=3.4           # Voice boost ottimizzato per dialoghi/canto sopra orchestrazione
    FRONT_REDUCTION=0.77      # Front ridotti per dare spazio alla voce nei contenuti musicali (-1.4dB)
    SURROUND_BOOST=2.8        # +9.0dB surround potenziato per atmosfera musicale (aumentato)
    MAKEUP_GAIN=1.1           # Makeup gain ottimizzato per contenuti già compressi (+0.3dB incremento)
    echo "LFE ottimizzato per contenuti musicali controllati: ${LFE_REDUCTION}x"
    echo "Voice ottimizzata per contenuti musicali: +${VOICE_BOOST}dB"

# Nuova logica per musical cinematografici (dinamica più ampia ma riconoscibili)
elif echo "$(basename "$INPUT_FILE")" | grep -qi -E "(musical|wicked|frozen|moana|encanto|beauty|beast|lion king|aladdin|mamma mia|chicago|rent|hairspray|greatest showman)" || 
     ([ $(awk "BEGIN {print ($LRA > 12) ? 1 : 0}") -eq 1 ] && [ $(awk "BEGIN {print ($LUFS > -18) ? 1 : 0}") -eq 1 ] && [ "$CONTENT_TYPE" = "movie" ]); then
    echo "PROFILO RILEVATO: Musical cinematografico (Disney/Broadway dinamico)"
    # Controllo aggiuntivo per True Peak critico nei musical
    if [ $(awk "BEGIN {print ($PEAK > -0.5) ? 1 : 0}") -eq 1 ]; then
        echo "APPLICAZIONE: Sicurezza musical per True Peak critico"
        LFE_REDUCTION=0.76        # LFE più conservativo per musical con peak critici
        VOICE_BOOST=3.5           # Voice boost ridotto per sicurezza ma efficace per musical
        FRONT_REDUCTION=0.75      # Front ridotti con maggiore sicurezza
        SURROUND_BOOST=2.8        # Surround boost aumentato per musical con peak critici
        MAKEUP_GAIN=1.0           # Makeup gain conservativo per sicurezza (+0.3dB incremento)
    else
        LFE_REDUCTION=0.78        # LFE più presente per orchestrazioni musicali (-1.9dB)
        VOICE_BOOST=3.7           # Voice boost incrementato per dialoghi/canti sopra orchestrazione
        FRONT_REDUCTION=0.77      # Front leggermente ridotti per bilanciare voce e musica (-2.0dB)
        SURROUND_BOOST=3.0        # +9.5dB surround incrementato per atmosfera musicale immersiva (aumentato)
        MAKEUP_GAIN=1.2           # Makeup gain ottimizzato per musical cinematografici (+0.3dB incremento)
    fi
    echo "LFE ottimizzato per orchestrazioni musicali: ${LFE_REDUCTION}x"
    echo "Voice ottimizzata per musical cinematografico: +${VOICE_BOOST}dB"

# Logica per contenuti con picchi critici (modalità sicurezza bilanciata) - correzione conservativa
elif [ $(awk "BEGIN {print ($PEAK > -0.5) ? 1 : 0}") -eq 1 ]; then
    echo "PROFILO RILEVATO: Contenuto con picchi critici - modalità sicurezza bilanciata"
    LFE_REDUCTION=0.75        # Riduzione moderata per mantenere corpo audio (-1.9dB)
    VOICE_BOOST=3.6           # Voice boost sicuro e bilanciato
    FRONT_REDUCTION=0.79      # Riduzione front moderata per mantenere bilanciamento (-1.9dB)
    SURROUND_BOOST=2.8        # +9.0dB surround mantenuto per immersività (aumentato)
    MAKEUP_GAIN=1.3           # Makeup gain incrementato per compensare picchi critici (+1.1dB)
    echo "LFE bilanciato per sicurezza: ${LFE_REDUCTION}x"
    echo "Voice sicura per compensare picchi critici: +${VOICE_BOOST}dB"

# Logica per contenuti con picchi moderati (modalità bilanciata con protezione anti-distorsione)
elif [ $(awk "BEGIN {print ($PEAK > -2) ? 1 : 0}") -eq 1 ]; then
    echo "PROFILO RILEVATO: Contenuto con picchi moderati - modalità bilanciata protetta"
    LFE_REDUCTION=0.77        # Riduzione leggera per mantenere corpo audio (-1.6dB)
    VOICE_BOOST=3.8           # Voice boost efficace ma sicuro
    FRONT_REDUCTION=0.78      # Riduzione front leggera per mantenere bilanciamento (-1.6dB)
    SURROUND_BOOST=2.9        # +9.2dB surround per immersività (aumentato)
    MAKEUP_GAIN=1.2           # Makeup gain bilanciato per sicurezza (+1.0dB)
    echo "LFE bilanciato per contenuti moderni: ${LFE_REDUCTION}x"
    echo "Voice bilanciata per chiarezza e sicurezza: +${VOICE_BOOST}dB"

# Default per contenuti standard
else
    echo "PROFILO RILEVATO: Contenuto standard bilanciato"
    SURROUND_BOOST=2.7
    echo "LFE mantenuto al valore base ottimale: ${LFE_REDUCTION}x"
    echo "Voice mantenuta al valore base ottimale: +${VOICE_BOOST}dB"
fi

# Microvariazione Subwoofer: abbassa LFE_REDUCTION di 0.03 per sicurezza
LFE_REDUCTION=$(awk -v x="$LFE_REDUCTION" 'BEGIN {printf "%.2f", x-0.03}')


# ==================== VALIDAZIONE PARAMETRI FINALI ====================
# Limita voice boost a massimo 3.8 (accetta anche 3.8)
if ! awk -v v="$VOICE_BOOST" 'BEGIN {exit (v<=3.8) ? 0 : 1}'; then
    echo "Voice boost troppo alto (${VOICE_BOOST}), imposto a 3.8dB per sicurezza."
    VOICE_BOOST=3.8
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
# Validazione parametri: accetta valori tra 0.5 e 3.8 (compatibile con awk -v)
for param in VOICE_BOOST LFE_REDUCTION FRONT_REDUCTION SURROUND_BOOST MAKEUP_GAIN; do
    value=$(eval echo \$$param | sed 's/,/./')
    if ! awk -v v="$value" 'BEGIN {exit (v>=0.5 && v<=3.8) ? 0 : 1}'; then
        echo "Parametro $param fuori range sicuro ($value), imposto valore minimo sicuro 1.0."
        eval $param=1.0
    else
        eval $param=$value
    fi
done

# --- DIAGNOSTICA PARAMETRI FINALI ---
echo "--- DIAGNOSTICA PARAMETRI AUDIO ---"
echo "VOICE_BOOST: $VOICE_BOOST"
echo "LFE_REDUCTION: $LFE_REDUCTION"
echo "FRONT_REDUCTION: $FRONT_REDUCTION"
echo "SURROUND_BOOST: $SURROUND_BOOST"
echo "MAKEUP_GAIN: $MAKEUP_GAIN"
echo "-----------------------------------"

# --- Preparazione filtri FFmpeg ottimizzati per DSP moderni ---
# Filtro vocale pulito per evitare artefatti
FC_FILTER="volume=${VOICE_BOOST}"

# Filtro LFE con SOLO subsonico essenziale (come richiesto) + volume
LFE_FILTER="highpass=f=25:poles=2,volume=${LFE_REDUCTION}"

# Filtro surround essenziale - SOLO volume (DSP gestisce tutto il resto)
SURROUND_FILTER="volume=${SURROUND_BOOST}"

# Filtro finale con limiter più dolce per evitare distorsioni
FINAL_FILTER="volume=${MAKEUP_GAIN},alimiter=level_in=1:level_out=1:limit=0.95:attack=10:release=150:asc=1,aformat=channel_layouts=5.1"

# --- Esecuzione FFmpeg ---
echo
echo "==============================================================="
echo "Avvio ClearVoice Auto processing universale..."
echo "Contenuto: $CONTENT_TYPE | Profilo: $(basename "$INPUT_FILE")"
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
show_spinner_with_progress "ClearVoice Auto processing" "$ESTIMATED_PROCESSING_TIME" &
SPIN_PID=$!

# Esegui FFmpeg con i filtri e le impostazioni definite
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

# -------------------- OUTPUT FINALE --------------------
# Cattura l'exit code di FFmpeg
ffmpeg_exit_code=$?

# Ferma lo spinner in modo sicuro
stop_spinner
echo "Elaborazione completata!                                                          "
echo "Elaborazione terminata alle: $(date +%H:%M:%S)"

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
    echo "========================================================"
    exit $ffmpeg_exit_code
fi

# Calcola il tempo totale di elaborazione
DURATION_FINAL=$(( $(date +%s) - START_TIME ))
MINUTI=$((DURATION_FINAL / 60))
SECONDI=$((DURATION_FINAL % 60))

if [ $ffmpeg_exit_code -eq 0 ]; then
    echo
    echo "==================== ELABORAZIONE COMPLETATA ====================="
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
    echo "Tipo Contenuto: $CONTENT_TYPE | Voice Enhancement: ${VOICE_BOOST}dB (adattivo, senza deesser) | Front Control: ${FRONT_REDUCTION}x (FL/FR bilanciati)"
    echo "LFE Control: Adattivo (HPF Subsonico 25Hz / Reduction ${LFE_REDUCTION}x)"
    echo "Surround Boost: +$(awk -v s="$SURROUND_BOOST" 'BEGIN {printf "%.1f", 20*log(s)/log(10)}')dB (${SURROUND_BOOST}x) | Makeup Gain: $MAKEUP_GAIN dB"
    echo "CONFIGURAZIONE: Architettura adattiva con controlli di volume intelligenti per $CONTENT_TYPE."
    echo
    echo "ANALISI SORGENTE:"
    echo "Integrated Loudness: $LUFS LUFS | True Peak: $PEAK dBTP | Loudness Range: $LRA LU"
    echo "==================================================================="
else
    echo "ERRORE - Gestito dalla sezione precedente del codice."
    exit $ffmpeg_exit_code
fi