#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------------
#  CLEARVOICE 0.89 - OTTIMIZZAZIONE AUDIO 5.1 + LFE DUCKING + SOXR
#  Script avanzato per miglioramento dialoghi e controllo LFE dinamico (C)2025
#  Autore: [Sandro "D@mocle77" Sabbioni]
# -----------------------------------------------------------------------------------------------
# CARATTERISTICHE PRINCIPALI:
# • Voice boost intelligente con compressione multi-banda
# • LFE Ducking: Il subwoofer reagisce automaticamente alla voce (sidechain REALE o EMULATO)
# • Soundstage spaziale: Delay temporali PERCETTIBILI per profondità stereofonica e surround
#   (OPZIONALE - Attualmente DISATTIVATO per massima intelligibilità dialoghi)
#   → Per AVR statici: Impostare FRONT_DELAY_SAMPLES="192" SURROUND_DELAY_SAMPLES="1200"
#   → Effetto: 4ms frontali + 25ms surround creano profondità tridimensionale
# • Limitatore anti-clipping con soft-clipping adattivo
# • Crossover LFE professionale per controllo frequenze
# • Preset ottimizzati per diversi contenuti (Film, Serie, TV, Cartoni)
# • Supporto codec multipli: EAC3, AC3, DTS con parametri qualità ottimizzati
# • Gestione robusta formati audio con fallback intelligenti
# • SoXR resampler per qualità audio superiore (richiede build FFmpeg con SoXR)
# -----------------------------------------------------------------------------------------------
# ANALISI TECNICA DETTAGLIATA:
#
# 1. EQUALIZZAZIONE VOCE ITALIANA (Ottimizzata per tutti i preset)
#    • FILM: Boost 3000Hz (+1.5dB, Q=1.5), taglio 5000Hz (-1dB)
#           Ideale per dialoghi in scene d'azione con colonne sonore potenti
#    • SERIE: Boost 2500Hz (+2dB, Q=1.8), taglio 4500Hz (-1.5dB), boost 1500Hz (+1dB)
#            Configurazione avanzata per dialoghi complessi e scene con audio variabile
#    • TV: Boost 1000Hz (+2.5dB) e 3000Hz (+2dB) con larghezze ampie, limite 5500Hz
#         Ultra-intelligibilità per trasmissioni di bassa qualità e voci registrate male
#    • CARTONI: Boost 3500Hz (+1dB, Q=2), taglio leggero 6000Hz (-0.5dB)
#              Ideale per voci animate dal timbro più acuto e vocalizzazione enfatizzata
#    → Risultato: Dialoghi italiani più chiari e bilanciati adattati al tipo di contenuto
#
# 2. SUBWOOFER INTELLIGIBILE
#    • Crossover LFE 25-110Hz (filtri 2° ordine): Evita invasione banda vocale
#    • Boost 40Hz (+2.5dB, Q=1.2): Mantiene impatto sui suoni molto bassi
#    • Boost 70Hz (+1.5dB, Q=1.8): Aggiunge calore senza invadere gamma vocale
#    • Attenuazione globale LFE (0.22x): Previene mascheramento voci
#    → Risultato: Bassi potenti ma controllati che non coprono mai i dialoghi
#
# 3. SOUNDSTAGING SPAZIALE (CONFIGURABILE)
#    • STATO ATTUALE: DISATTIVATO (delay = 0) per massima chiarezza dialoghi
#    • PRESET OPZIONALI per AVR con DSP limitato:
#      - MINIMO (0/4ms): FRONT="0" SURROUND="192" → Depth sottile
#      - LEGGERO (8/12ms): FRONT="384" SURROUND="576" → Bilanciato  
#      - STANDARD (4/25ms): FRONT="192" SURROUND="1200" → Cinematografico
#      - IMMERSIVO (12/35ms): FRONT="576" SURROUND="1680" → Massima spazialità
#    • CALCOLO: samples = millisecondi × 48 (per audio @48kHz)
#    → Risultato POTENZIALE: Immagine sonora 3D con localizzazione dialoghi al centro
#
# 4. VOICE STRONGER (POTENZIAMENTO VOCE)
#    • Aumento livello +8.7dB: Significativo ma non eccessivo
#    • Compressione ratio 3.5:1, threshold 0.15: Calibrata per dialoghi italiani
#    • Attack 15ms, release 200ms: Ottimizzati per prosodia italiana
#    • Softclipping con threshold 0.97: Protezione anti-distorsione con intensità preservata
#    → Risultato: Voci molto più presenti e costanti senza fatica d'ascolto
#
# 5. LFE DUCKING INTELLIGENTE
#    • Threshold -25dB: Si attiva solo su dialoghi chiari
#    • Ratio 6:1: Riduzione decisa ma non innaturale
#    • Attack 20ms: Permette l'attacco iniziale dei bassi prima dell'attenuazione
#    • Release 250ms: Evita "pompaggio" udibile, transizione naturale
#    • Implementazione sidechain reale (quando supportata) o emulata
#    → Risultato: Subwoofer che "rispetta" automaticamente i dialoghi quando presenti
#
# 6. SOXR RESAMPLING PROFESSIONALE
#    • Utilizzo del resampler SoXR di qualità superiore (quando disponibile)
#    • Precision differenziata per preset:
#      - FILM: 28 bit (massima qualità audiofila)
#      - SERIE/TV: 20 bit (bilanciamento qualità/prestazioni)
#      - CARTONI: 15 bit (qualità standard, minore impatto CPU)
#    • Algoritmo matematicamente superiore al resampler standard SWR di FFmpeg
#    • Fallback automatico a SWR se SoXR non è disponibile nella build di FFmpeg
#    • Minimizza artefatti di conversione frequenza e garantisce fedeltà alle alte frequenze
#    → Risultato: Qualità audio complessiva migliorata con minore distorsione digitale
#
# 7. RIDUZIONE RUMORE AVANZATA (PRESET TV)
#    • Doppio stage di denoise:
#      - FFT Denoiser: Rimuove rumore di fondo a banda larga
#      - Non-Local Means Denoiser: Preserva dettagli vocali
#    • Threshold adattivo: Interviene solo sul rumore, non sui dialoghi
#    • Applicato solo al preset TV, ideale per materiale di bassa qualità
#    → Risultato: Dialoghi più puliti con preservazione della naturalezza vocale
# -----------------------------------------------------------------------------------------------

set -euo pipefail

# -----------------------------------------------------------------------------------------------
#  CONFIGURAZIONE GLOBALE
# -----------------------------------------------------------------------------------------------
FRONT_VOL=1.0               # Volume canali frontali (FL/FR)
VERSION="0.89"              # Versione script corrente
MIN_FFMPEG_VER="6.0"        # Versione minima ffmpeg richiesta
DEFAULT_THREADS=4           # Numero di thread di default se nproc non è disponibile o fallisce
OVERWRITE="false"           # Valore predefinito: non sovrascrivere file esistenti
VALIDATED_FILES_GLOBAL=()   # File che hanno superato i controlli di compatibilità 5.1

# Array per gestione dei file e statistiche
FAILED_FILES=()              # Memorizza i file che hanno generato errori durante l'elaborazione
PROCESSED_FILES_INFO=()      # Dettagli sui file elaborati con successo (nome, tempo, dimensione)
VALIDATED_FILES_GLOBAL=()    # File che hanno superato i controlli di compatibilità 5.1

# Contatori per statistiche formato audio
MONO_COUNT=0
STEREO_COUNT=0
SURROUND71_COUNT=0
OTHER_FORMAT_COUNT=0

# Variabili globali per parametri preset (saranno popolate da set_preset_params)
PRESET=""                    # Tipo di ottimizzazione: film, serie, tv o cartoni
CODEC="eac3"                 # Codec audio predefinito (eac3, ac3, dts)
BR="384k"                    # Bitrate audio predefinito
INPUTS=()                    # Percorsi input specificati dall'utente (file o directory)

# Parametri audio che saranno configurati in base al preset selezionato
VOICE_VOL=""                 # Amplificazione canale centrale (dialoghi)
LFE_VOL=""                   # Volume LFE (subwoofer)
SURROUND_VOL=""              # Volume canali surround
HP_FREQ=""                   # Frequenza di taglio filtro passa-alto per dialoghi
LP_FREQ=""                   # Frequenza di taglio filtro passa-basso per dialoghi
COMPRESSOR_SETTINGS=""       # Parametri compressione dinamica per voce
FRONT_FILTER=""              # Filtri canali frontali
SOFTCLIP_SETTINGS=""         # Configurazione limitatore anti-distorsione
FRONT_DELAY_SAMPLES=""       # Ritardo canali frontali per effetto soundstage
SURROUND_DELAY_SAMPLES=""    # Ritardo canali surround per effetto avvolgente
LFE_HP_FREQ=""               # Frequenza minima LFE (passa-alto subwoofer)
LFE_LP_FREQ=""               # Frequenza massima LFE (passa-basso subwoofer)
LFE_CROSS_POLES=""           # Ordine filtri LFE (pendenza)
SC_ATTACK=""                 # Tempo attacco per ducking LFE
SC_RELEASE=""                # Tempo rilascio per ducking LFE
SC_THRESHOLD=""              # Soglia attivazione ducking
SC_RATIO=""                  # Rapporto di compressione ducking
SC_MAKEUP=""                 # Compensazione volume post-ducking
FC_EQ_PARAMS=""              # Equalizzazione canale centrale (dialoghi)
FLFR_EQ_PARAMS=""            # Equalizzazione canali frontali
LFE_EQ_PARAMS=""             # Equalizzazione subwoofer
ENC=""                       # Codifica finale (copia di CODEC)
EXTRA=""                     # Parametri extra codec-specifici
TITLE=""                     # Titolo metadata per la traccia audio
DENOISE_FILTER=""            # Filtro riduzione rumore (solo preset TV)

# Inizializza tempo globale per statistiche finali
TOTAL_START_TIME=$(date +%s) # Memorizza timestamp per calcolare durata totale dell'elaborazione

# -----------------------------------------------------------------------------------------------
#  FUNZIONI HELPER
# -----------------------------------------------------------------------------------------------

# Funzione per chiedere conferma all'utente (sì/no)
ask_yes_no() {
    local prompt="$1"
    local response
    
    # Continua a chiedere finché non si ottiene una risposta valida
    while true; do
        echo -n "$prompt [s/n]: "
        read -r response < /dev/tty
        case "$response" in
            [Ss]* ) return 0;; # Restituisce 0 (true) per "sì"
            [Nn]* ) return 1;; # Restituisce 1 (false) per "no"
            * ) echo "   Per favore, rispondi con 's' o 'n'.";;
        esac
    done
}

# Verifica versione ffmpeg
check_ffmpeg_version() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "❌ FFmpeg non trovato! Installa FFmpeg per utilizzare questo script." >&2
        exit 1
    fi
    
    local current_version
    current_version=$(ffmpeg -version | head -n1 | awk -F'[ -]' '{print $3}')
    
    if awk -v v1="$current_version" -v v2="$MIN_FFMPEG_VER" 'BEGIN {
        n1 = split(v1, a, ".");
        n2 = split(v2, b, ".");
        for (i = 1; i <= (n1 > n2 ? n1 : n2); i++) {
            a[i] = a[i] ? a[i] : 0;
            b[i] = b[i] ? b[i] : 0;
            if (a[i] < b[i]) exit 1;
            if (a[i] > b[i]) exit 0;
        }
        exit 0;
    }'; then
        echo "✅ FFmpeg versione $current_version compatibile." >&2
    else
        echo "❌ FFmpeg versione $current_version non compatibile. Richiesta almeno $MIN_FFMPEG_VER." >&2
        exit 1
    fi
}

# Calcolo sicuro con awk (con gestione errori)
safe_awk_calc() {
    local expr="$1"
    local result
    
    if ! result=$(awk "BEGIN { printf \"%.6f\", $expr }" 2>/dev/null); then
        echo "1.0" # Default fallback in caso di errore
        return 1
    fi
    
    # Gestione NaN e infinito
    if [[ "$result" == "nan" || "$result" == "inf" || "$result" == "-inf" ]]; then
        echo "1.0" # Default fallback
        return 1
    fi
    
    echo "$result"
    return 0
}

# Parsing argomenti da linea di comando
parse_arguments() {
    # Controllo argomenti minimi
    if [[ $# -lt 3 ]]; then
        echo "❌ Errore: Argomenti insufficienti!" >&2
        echo "Uso: $0 --preset codec bitrate [--overwrite] file1.mkv [file2.mkv ...]" >&2
        echo "Preset supportati: film, serie, tv, cartoni" >&2
        echo "Codec supportati: eac3 (default), ac3, dts" >&2
        echo "Bitrate suggeriti: 384k (eac3), 640k (ac3), 756k/1536k (dts)" >&2
        echo "Esempio: $0 --serie eac3 384k movie.mkv" >&2
        echo "Esempio con sovrascrittura: $0 --serie eac3 384k --overwrite movie.mkv" >&2
        exit 1
    fi

    # Parsing del preset (obbligatorio)
    case "$1" in
        --film|--serie|--tv|--cartoni)
            PRESET="${1#--}" # Rimuove il prefisso --
            shift
            ;;
        *)
            echo "❌ Preset '$1' non valido! Usa uno tra: --film, --serie, --tv, --cartoni" >&2
            exit 1
            ;;
    esac

    # Parsing codec e bitrate (obbligatori)
    CODEC="$1"
    shift
    BR="$1"
    shift

    # Parsing argomenti rimanenti - MODIFICATO: Gestione corretta di --overwrite
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --overwrite)
                OVERWRITE="true"
                shift
                ;;
            -*)
                echo "❌ Opzione '$1' non riconosciuta!" >&2
                exit 1
                ;;
            *)
                INPUTS+=("$1")
                shift
                ;;
        esac
    done

    # Validazione inputs
    if [[ ${#INPUTS[@]} -eq 0 ]]; then
        echo "❌ Nessun file/directory specificato!" >&2
        exit 1
    fi

    # Validazione codec
    case "${CODEC,,}" in
        eac3|ac3|dts) ;; # Validi, non fare nulla
        *)
            echo "❌ Codec '$CODEC' non supportato! Usa uno tra: eac3, ac3, dts" >&2
            exit 1
            ;;
    esac

    # Validazione bitrate (solo formato, non valore specifico)
    if ! [[ "$BR" =~ ^[0-9]+[km]$ ]]; then
        echo "❌ Formato bitrate '$BR' non valido! Usa formato: 384k, 640k, ecc." >&2
        exit 1
    fi
}

# Impostazione parametri dinamici basati sul preset selezionato
set_preset_params() {
    local preset_choice="$1"
    echo "ℹ️  Configurazione preset: $preset_choice" >&2

    case "$preset_choice" in
        film) # Ottimizzato per contenuti cinematografici
            VOICE_VOL="8.7" LFE_VOL="0.20" SURROUND_VOL="4.5" 
            HP_FREQ="115" LP_FREQ="7900"
            COMPRESSOR_SETTINGS="acompressor=threshold=0.15:ratio=4.2:attack=12:release=250:makeup=2.0"
            FRONT_FILTER="highpass=f=22:poles=2,lowpass=f=20000:poles=1"
            SOFTCLIP_SETTINGS="asoftclip=type=atan:threshold=0.95:output=1.0"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="20" LFE_LP_FREQ="120" LFE_CROSS_POLES="2"
            SC_ATTACK="15" SC_RELEASE="300" SC_THRESHOLD="-32dB" SC_RATIO="5.5" SC_MAKEUP="0dB"
            FC_EQ_PARAMS="equalizer=f=3000:width_type=q:w=1.5:g=1.5,equalizer=f=5000:width_type=q:w=2:g=-1"
            FLFR_EQ_PARAMS="" 
            LFE_EQ_PARAMS="equalizer=f=35:width_type=q:w=1:g=2,equalizer=f=60:width_type=q:w=2:g=1"
            DENOISE_FILTER="" 
            ;;
        serie) # Bilanciato per serie TV, dialoghi difficili
            VOICE_VOL="8.7" LFE_VOL="0.20" SURROUND_VOL="4.5" 
            HP_FREQ="130" LP_FREQ="7800"
            COMPRESSOR_SETTINGS="acompressor=threshold=0.17:ratio=4.0:attack=15:release=220:makeup=1.9"
            FRONT_FILTER="highpass=f=28:poles=2,lowpass=f=18000:poles=1"
            SOFTCLIP_SETTINGS="asoftclip=type=atan:threshold=0.97:output=1.0"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="25" LFE_LP_FREQ="110" LFE_CROSS_POLES="2"
            SC_ATTACK="15" SC_RELEASE="300" SC_THRESHOLD="-32dB" SC_RATIO="5.5" SC_MAKEUP="0dB"
            FC_EQ_PARAMS="equalizer=f=2500:width_type=q:w=1.8:g=2,equalizer=f=4500:width_type=q:w=2.2:g=-1.5,equalizer=f=1500:width_type=h:w=200:g=1"
            FLFR_EQ_PARAMS="equalizer=f=300:width_type=q:w=2:g=-1"
            LFE_EQ_PARAMS="equalizer=f=40:width_type=q:w=1.2:g=2.5,equalizer=f=70:width_type=q:w=1.8:g=1.5"
            DENOISE_FILTER="" 
            ;;
        tv) # Ultra-conservativo per materiale di bassa qualità
            VOICE_VOL="7.6" LFE_VOL="0.20" SURROUND_VOL="3.9" 
            HP_FREQ="450" LP_FREQ="5000"
            COMPRESSOR_SETTINGS="acompressor=threshold=0.20:ratio=3.2:attack=10:release=180:makeup=2.1"
            FRONT_FILTER="highpass=f=100:poles=1,lowpass=f=8000:poles=1"
            SOFTCLIP_SETTINGS="asoftclip=type=tanh:threshold=0.9:output=0.95"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="30" LFE_LP_FREQ="100" LFE_CROSS_POLES="1"
            SC_ATTACK="15" SC_RELEASE="300" SC_THRESHOLD="-32dB" SC_RATIO="5.5" SC_MAKEUP="0dB"
            FC_EQ_PARAMS="equalizer=f=1000:width_type=h:w=400:g=2.5,equalizer=f=3000:width_type=h:w=1000:g=2,lowpass=f=5500"
            FLFR_EQ_PARAMS="equalizer=f=1500:width_type=h:w=500:g=1.5"
            LFE_EQ_PARAMS="equalizer=f=50:width_type=q:w=1.5:g=2"
            DENOISE_FILTER="afftdn=nr=20:nf=-42:tn=1,anlmdn=s=0.0001:p=0.002:r=0.005"
            ;;
        cartoni) # Leggero per animazione, preservazione musicale
            VOICE_VOL="8.6" LFE_VOL="0.20" SURROUND_VOL="4.5" 
            HP_FREQ="100" LP_FREQ="8500"
            COMPRESSOR_SETTINGS="acompressor=threshold=0.18:ratio=3.5:attack=10:release=160:makeup=2.0"
            FRONT_FILTER="highpass=f=20:poles=2,lowpass=f=21000:poles=1"
            SOFTCLIP_SETTINGS="asoftclip=type=sin:threshold=0.98:output=1.0"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="18" LFE_LP_FREQ="130" LFE_CROSS_POLES="2"
            SC_ATTACK="15" SC_RELEASE="300" SC_THRESHOLD="-32dB" SC_RATIO="5.5" SC_MAKEUP="0dB"
            FC_EQ_PARAMS="equalizer=f=3500:width_type=q:w=2:g=1,equalizer=f=6000:width_type=q:w=2.5:g=-0.5"
            FLFR_EQ_PARAMS="" 
            LFE_EQ_PARAMS="equalizer=f=30:width_type=q:w=1:g=1.5,equalizer=f=80:width_type=q:w=1.5:g=1"
            DENOISE_FILTER="" 
            ;;
        *) echo "❌ Preset '$preset_choice' non valido!" >&2; exit 1;;
    esac

    # Impostazioni globali codec e titolo
    ENC="$CODEC"
    EXTRA=""
    if [[ "${CODEC,,}" == "dts" ]]; then
        EXTRA="-strict -2 -ar 48000 -channel_layout 5.1(side) -compression_level 2"
    fi
    TITLE="ClearVoice $VERSION - $preset_choice ($CODEC $BR)"
}

# SoxR resampler (richiede FFmpeg compilato con SoxR)
apply_soxr_resampling() {
    local soxr_params=""
    if ffmpeg -filters 2>&1 | grep -q soxr; then
        case "$PRESET" in # Usa PRESET globale
            film)    soxr_params=":precision=28";; # Massima qualità
            serie|tv)soxr_params=":precision=20";;  # Bilanciato
            cartoni) soxr_params=":precision=15";;  # Standard
        esac
        echo "aresample=resampler=soxr${soxr_params}"
    else
        echo "aresample=resampler=swr" # Fallback a swresample standard
    fi
}

# Controllo supporto sidechain (per ducking LFE)
check_sidechain_support() {
    if ffmpeg -filters 2>&1 | grep -q sidechaincompress; then
        echo "REALE" # Supporto sidechaincompress nativo
    else
        echo "EMULATO" # Fallback a sidechain emulato
    fi
}

# -----------------------------------------------------------------------------------------------
#  ELABORAZIONE AUDIO
# -----------------------------------------------------------------------------------------------

# Funzione principale di elaborazione audio per singolo file
process() {
    local input_file="$1"
    local filename log_file input_dir
    
    if [[ ! -f "$input_file" ]]; then
        echo "❌ File input non trovato: $input_file" >&2
        return 1 
    fi
    if [[ ! -r "$input_file" ]]; then
        echo "❌ File input non leggibile: $input_file" >&2
        return 1 
    fi
    
    # Ottieni la directory e il nome del file
    input_dir=$(dirname "$input_file")
    filename=$(basename "$input_file")
    
    # Crea il percorso completo per il file di output
    local out="${input_dir}/${filename%.*}_${PRESET}_clearvoice${VERSION}.mkv"
    log_file="${input_dir}/${filename%.*}_${PRESET}_clearvoice${VERSION}.log"
    
    echo "🔄 Preparazione elaborazione per: $filename" >&2
    echo "   Preset: $PRESET | Codec: $ENC ($BR)" >&2
    echo "   Output previsto: $(basename "$out")" >&2
    echo "   Log file: $(basename "$log_file")" >&2
    
    # Test esplicito di scrittura del file di log
    if ! touch "$log_file" 2>/dev/null; then
        echo "⚠️ Impossibile creare il file di log: $log_file" >&2
        echo "   Continuazione senza logging..." >&2
        log_file=""
    else
        # Inizializza il file di log
        {
            echo "===== CLEARVOICE $VERSION - LOG DI ELABORAZIONE ====="
            echo "File originale: $input_file"
            echo "Preset: $PRESET | Codec: $ENC ($BR)"
            echo "File output: $out"
            echo "Data e ora: $(date)"
            echo "----------------------------------------"
        } > "$log_file"
        
        echo "   📝 File di log creato: $(basename "$log_file")" >&2
    fi
    
    # Controllo esistenza file output con richiesta di conferma
    if [[ -f "$out" ]]; then
        if [[ "$OVERWRITE" == "true" ]]; then
            echo "⚠️ File output già esistente: $(basename "$out") (sovrascrittura automatica)" >&2
            if [[ -n "$log_file" && -w "$log_file" ]]; then
                echo "NOTA: File output già esistente - sovrascrittura automatica attivata" >> "$log_file"
            fi
        else
            echo "⚠️ File output già esistente: $(basename "$out")" >&2
            echo -n "   Vuoi sovrascrivere il file esistente? [s/n]: "
            
            local user_response
            read -r user_response < /dev/tty
            
            case "$user_response" in
                [Ss]* )
                    echo "   ✅ Sovrascrittura confermata." >&2
                    if [[ -n "$log_file" && -w "$log_file" ]]; then
                        echo "NOTA: File output già esistente - sovrascrittura confermata dall'utente" >> "$log_file"
                    fi
                    ;;
                * )
                    echo "   ❌ Sovrascrittura rifiutata. Elaborazione annullata." >&2
                    if [[ -n "$log_file" && -w "$log_file" ]]; then
                        echo "NOTA: File output già esistente - sovrascrittura rifiutata dall'utente" >> "$log_file"
                        echo "ELABORAZIONE ANNULLATA" >> "$log_file"
                    fi
                    FAILED_FILES+=("$(basename "$input_file") (Sovrascrittura rifiutata)")
                    return 1
                    ;;
            esac
        fi
    fi
    
    # Costruzione filtergraph
    local LOCAL_FILTER_GRAPH
    if ! LOCAL_FILTER_GRAPH=$(build_audio_filter "$input_file"); then
        if [[ -n "$log_file" && -w "$log_file" ]]; then
            echo "ERRORE: Impossibile costruire l'audio filter." >> "$log_file"
        fi
        return 1
    fi
    
    if [[ -n "$log_file" && -w "$log_file" ]]; then
        echo "Filtergraph FFmpeg:" >> "$log_file"
        echo "$LOCAL_FILTER_GRAPH" >> "$log_file"
        echo "----------------------------------------" >> "$log_file"
        echo "Inizio elaborazione FFmpeg: $(date)" >> "$log_file"
    fi
    
    # Registra l'inizio dell'elaborazione
    local file_start_time=$(date +%s)
    
    # Esecuzione del comando FFmpeg
    echo "🎬 Avvio elaborazione FFmpeg..." >&2

    # Determina numero di threads
    local threads_count=0
    if command -v nproc &> /dev/null; then
        threads_count=$(nproc)
    elif command -v sysctl &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
        threads_count=$(sysctl -n hw.ncpu)
    else
        threads_count=$DEFAULT_THREADS
    fi

    # Costruzione comando FFmpeg con gestione sicura di $EXTRA
    if [[ -n "$EXTRA" ]]; then
        # Converti EXTRA in array per gestire correttamente gli spazi
        local extra_args
        IFS=' ' read -ra extra_args <<< "$EXTRA"
        
        ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero \
          -threads "$threads_count" -filter_threads "$threads_count" -thread_queue_size 512 \
          -i "$input_file" \
          -filter_complex "$LOCAL_FILTER_GRAPH" \
          -map "[out]" -map 0:a -c:a:0 "$ENC" -b:a:0 "$BR" "${extra_args[@]}" \
          -c:a:1 copy \
          -metadata:s:a:0 title="Italiano 5.1 ClearVoice $PRESET ($ENC $BR)" \
          -metadata:s:a:0 language=ita -disposition:a:0 default \
          -map 0:v -c:v copy -map 0:s? -c:s copy \
          -movflags +faststart "$out" 2> >(if [[ -n "$log_file" && -w "$log_file" ]]; then tee -a "$log_file" >&2; else cat >&2; fi)
    else
        ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero \
          -threads "$threads_count" -filter_threads "$threads_count" -thread_queue_size 512 \
          -i "$input_file" \
          -filter_complex "$LOCAL_FILTER_GRAPH" \
          -map "[out]" -map 0:a -c:a:0 "$ENC" -b:a:0 "$BR" \
          -c:a:1 copy \
          -metadata:s:a:0 title="Italiano 5.1 ClearVoice $PRESET ($ENC $BR)" \
          -metadata:s:a:0 language=ita -disposition:a:0 default \
          -map 0:v -c:v copy -map 0:s? -c:s copy \
          -movflags +faststart "$out" 2> >(if [[ -n "$log_file" && -w "$log_file" ]]; then tee -a "$log_file" >&2; else cat >&2; fi)
    fi
    
    local FFMPEG_RESULT_CODE=$?
    
    # Verifica risultato FFmpeg
    if [ $FFMPEG_RESULT_CODE -eq 0 ]; then
        local file_elapsed_time_secs=$(($(date +%s) - file_start_time))
        local output_size_bytes_val
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
             output_size_bytes_val=$(powershell -Command "(Get-Item \"$out\").Length" 2>/dev/null || echo "0")
        else
             output_size_bytes_val=$(stat -c%s "$out" 2>/dev/null || echo "0")
        fi
        
        if [[ -n "$log_file" && -w "$log_file" ]]; then
            echo "✅ SUCCESSO: Elaborazione completata" >> "$log_file"
            echo "Tempo impiegato: $file_elapsed_time_secs secondi" >> "$log_file"
            echo "Dimensione file output: $output_size_bytes_val bytes" >> "$log_file"
            echo "===== FINE ELABORAZIONE =====" >> "$log_file"
        fi
        
        echo "✅ Elaborazione completata con successo per $filename!" >&2
        echo "   File generato: $(basename "$out") ($output_size_bytes_val bytes)" >&2
        echo "   Tempo impiegato: $file_elapsed_time_secs secondi" >&2
        
        if [[ -n "$log_file" && -f "$log_file" ]]; then
            echo "   Log salvato in: $(basename "$log_file")" >&2
        fi
        
        PROCESSED_FILES_INFO+=("$(basename "$input_file") -> $(basename "$out") | ${file_elapsed_time_secs}s | $output_size_bytes_val bytes")
        return 0
    else
        if [[ -n "$log_file" && -w "$log_file" ]]; then
            echo "❌ ERRORE: FFmpeg ha fallito con codice $FFMPEG_RESULT_CODE" >> "$log_file"
            echo "Possibili cause: spazio disco, codec non supportati, file danneggiato, permessi" >> "$log_file"
            echo "===== ELABORAZIONE FALLITA =====" >> "$log_file"
        fi
        
        echo "❌ Errore FFmpeg durante l'elaborazione di $filename (Codice: $FFMPEG_RESULT_CODE)" >&2
        
        if [[ -n "$log_file" && -f "$log_file" ]]; then
            echo "   Log dettagli errore in: $(basename "$log_file")" >&2
        fi
        
        echo "   💡 Verifica: spazio disco, codec supportati, integrità file input, permessi." >&2
        
        if [[ -f "$out" ]]; then
            rm -f "$out"
            if [[ -n "$log_file" && -w "$log_file" ]]; then
                echo "🗑️ File di output parziale rimosso: $out" >> "$log_file"
            fi
            echo "   🗑️ File di output parziale rimosso: $(basename "$out")" >&2
        fi
        
        FAILED_FILES+=("$(basename "$input_file") (FFmpeg error $FFMPEG_RESULT_CODE)")
        return 1
    fi
}

# Costruisce il complesso filtergraph audio per l'elaborazione avanzata
build_audio_filter() {
    local file="$1"
    local ducking_type_actual
    ducking_type_actual=$(check_sidechain_support)

    # Adattamenti volume e filtri per DTS
    local voice_vol_adj="$VOICE_VOL" front_vol_adj="$FRONT_VOL" 
    local lfe_vol_adj="$LFE_VOL" surround_vol_adj="$SURROUND_VOL"
    local current_hp_freq="$HP_FREQ" current_lp_freq="$LP_FREQ"

    # Processamento canali surround BL/BR con compressore per tutti i preset
    local bl_br_filters=""

    if [[ "${CODEC,,}" == "dts" ]]; then
        echo "ℹ️  Adattamento parametri per codec DTS (volume frontale non ridotto)" >&2
        case "$PRESET" in
            film)
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 0.3")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.9565")
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.85")
                current_hp_freq="120"; current_lp_freq="7700"
                [[ -n "$LFE_EQ_PARAMS" ]] && LFE_EQ_PARAMS="equalizer=f=35:width_type=q:w=1:g=0.5,equalizer=f=60:width_type=q:w=2:g=0"
                ;;
            serie)
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 0.1")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.9524")
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.88")
                current_hp_freq="135"; current_lp_freq="8000"
                ;;
            tv)
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 0.3")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.9524")
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.88")
                current_hp_freq="420"; current_lp_freq="5200"
                ;;
            cartoni)
                voice_vol_adj=$(safe_awk_calc "$VOICE_VOL + 0.2")
                lfe_vol_adj=$(safe_awk_calc "$LFE_VOL * 0.9524")
                surround_vol_adj=$(safe_awk_calc "$SURROUND_VOL * 0.9")
                current_hp_freq="90"; current_lp_freq="8700"
                ;;
        esac
    fi

    echo "🎯 Filtro applicato: Voice + LFE Ducking $ducking_type_actual" >&2
    echo "🔊 Voice: +${voice_vol_adj}dB | LFE Vol: ${lfe_vol_adj}x | Front Vol: ${front_vol_adj}x" >&2
    echo "🎞️ Codec: $ENC ($BR) | Preset: $PRESET" >&2

    # Costruzione filtro LFE ducking
    local lfe_ducking_filter_str
    if [[ "$ducking_type_actual" == "REALE" ]]; then
        echo "🎯 Ducking LFE REALE attivo" >&2
        lfe_ducking_filter_str="sidechaincompress=threshold=${SC_THRESHOLD}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=${SC_MAKEUP}"
    else
        echo "⚠️  Ducking LFE EMULATO (sidechaincompress non supportato)" >&2
        lfe_ducking_filter_str="acompressor=threshold=-18dB:ratio=4:attack=30:release=200:makeup=0dB"
    fi

    # Costruzione filtergraph
    local filter_graph=""
    
    # Conversione e split canali
    filter_graph="[0:a]aformat=channel_layouts=5.1[audio5dot1];"
    filter_graph+="[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE_orig][BL][BR];"

    # Processamento canale centrale (voce) con denoise opzionale
    local fc_filters="highpass=f=${current_hp_freq},lowpass=f=${current_lp_freq}"
    [[ -n "$DENOISE_FILTER" ]] && fc_filters="${DENOISE_FILTER},${fc_filters}"
    [[ -n "$FC_EQ_PARAMS" ]] && fc_filters="${fc_filters},${FC_EQ_PARAMS}"
    fc_filters="${fc_filters},volume=${voice_vol_adj},${COMPRESSOR_SETTINGS}"
    
    filter_graph+="[FC]${fc_filters}[fc_compressed];"

    # Split per sidechain se supportato
    if [[ "$ducking_type_actual" == "REALE" ]]; then
        filter_graph+="[fc_compressed]asplit=2[voice_final][voice_for_sidechain];"
    else
        filter_graph+="[fc_compressed]acopy[voice_final];"
    fi

    # Softclip finale sulla voce
    filter_graph+="[voice_final]${SOFTCLIP_SETTINGS}[center_out];"

    # Processamento canali frontali FL/FR con compressore opzionale per film
    local fl_fr_filters=""
    [[ -n "$FLFR_EQ_PARAMS" ]] && fl_fr_filters="${FLFR_EQ_PARAMS},"
    if [[ "$PRESET" == "film" ]]; then
        fl_fr_filters="${fl_fr_filters}acompressor=threshold=0.3:ratio=2.5:attack=20:release=350,asoftclip=threshold=0.95,"
    fi
    fl_fr_filters="${fl_fr_filters}volume=${front_vol_adj}"
    [[ "$FRONT_DELAY_SAMPLES" != "0" ]] && fl_fr_filters="${fl_fr_filters},adelay=${FRONT_DELAY_SAMPLES}"

    filter_graph+="[FL]${fl_fr_filters}[fl_out];"
    filter_graph+="[FR]${fl_fr_filters}[fr_out];"

    # Processamento LFE con crossover ed EQ
    local lfe_filters="highpass=f=${LFE_HP_FREQ}:poles=${LFE_CROSS_POLES},lowpass=f=${LFE_LP_FREQ}:poles=${LFE_CROSS_POLES}"
    if [[ -n "$LFE_EQ_PARAMS" ]]; then
        lfe_filters="${lfe_filters},${LFE_EQ_PARAMS}"
    fi
    lfe_filters="${lfe_filters},volume=${lfe_vol_adj}"
    
    filter_graph+="[LFE_orig]${lfe_filters}[lfe_processed];"

    # Applicazione ducking LFE
    if [[ "$ducking_type_actual" == "REALE" ]]; then
        filter_graph+="[lfe_processed][voice_for_sidechain]${lfe_ducking_filter_str}[lfe_out];"
    else
        filter_graph+="[lfe_processed]${lfe_ducking_filter_str}[lfe_out];"
    fi

    # Compressore per effetti - ora applicato a tutti i preset
    case "$PRESET" in
        film)
            # Film: Moderato: Preserva l'impatto cinematografico degli effetti
            bl_br_filters="acompressor=threshold=0.3:ratio=2.5:attack=20:release=350,asoftclip=threshold=0.95,"
            ;;
        serie)
            # Serie: Più aggressivo: Ideale per dialoghi TV con effetti fastidiosi
            bl_br_filters="acompressor=threshold=0.25:ratio=3:attack=15:release=250,asoftclip=threshold=0.92,"
            ;;
        tv)
            # TV: Molto aggressivo: Perfetto per contenuti di bassa qualità
            bl_br_filters="acompressor=threshold=0.2:ratio=4:attack=10:release=200,asoftclip=threshold=0.90,"
            ;;
        cartoni)
            # Cartoni: Delicato: Preserva la musicalità tipica dei cartoni
            bl_br_filters="acompressor=threshold=0.4:ratio=2:attack=30:release=400,asoftclip=threshold=0.97,"
            ;;
    esac
    
    bl_br_filters="${bl_br_filters}volume=${surround_vol_adj}"
    [[ "$SURROUND_DELAY_SAMPLES" != "0" ]] && bl_br_filters="${bl_br_filters},adelay=${SURROUND_DELAY_SAMPLES}"

    filter_graph+="[BL]${bl_br_filters}[bl_out];"
    filter_graph+="[BR]${bl_br_filters}[br_out];"

    # Join finale e resampling
    filter_graph+="[fl_out][fr_out][center_out][lfe_out][bl_out][br_out]join=inputs=6:channel_layout=5.1[joined];"
    
    # SoxR resampling opzionale
    local soxr_filter
    soxr_filter=$(apply_soxr_resampling)
    filter_graph+="[joined]${soxr_filter}[out]"

    echo "$filter_graph"
}

validate_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo "   🔎 Controllo: $filename" >&2
    
    # Controllo esistenza e leggibilità
    if [[ ! -f "$file" ]]; then
        echo "      ❌ File non trovato." >&2
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        echo "      ❌ File non leggibile (permessi)." >&2
        return 1
    fi
    
    # Analisi stream audio con ffprobe
    local audio_info
    if ! audio_info=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=codec_name,channels,channel_layout -of csv=p=0 "$file" 2>/dev/null); then
        echo "      ❌ Impossibile analizzare stream audio." >&2
        return 1
    fi
    
    # Parsing delle informazioni audio
    local codec_name channels channel_layout
    IFS=',' read -r codec_name channels channel_layout <<< "$audio_info"
    
    # Verifica codec audio supportato
    case "${codec_name,,}" in
        aac|ac3|eac3|dts|truehd|flac|pcm_*|mp3)
            ;; # Codec supportati
        *)
            echo "      ❌ Codec audio '$codec_name' non supportato." >&2
            return 1
            ;;
    esac
    
    # Verifica configurazione 5.1
    if [[ "$channels" == "6" ]] || [[ "$channel_layout" =~ 5\.1 ]]; then
        echo "      ✅ Audio 5.1 compatibile ($codec_name, layout: ${channel_layout:-unknown}). Aggiunto alla coda." >&2
        VALIDATED_FILES_GLOBAL+=("$file")
        return 0
    else
        # Incrementa contatori per statistiche
        case "$channels" in
            1) ((MONO_COUNT++));;
            2) ((STEREO_COUNT++));;
            8) ((SURROUND71_COUNT++));;
            *) ((OTHER_FORMAT_COUNT++));;
        esac
        
        echo "      ❌ Audio non 5.1 ($channels canali, layout: ${channel_layout:-unknown}). Saltato." >&2
        return 1
    fi
}

# Verifica se un percorso è valido e lo elabora appropriatamente
validate_inputs() {
    local total_candidates=0
    local validated_count=0
    
    for input in "${INPUTS[@]}"; do
        if [[ -f "$input" ]]; then
            # Singolo file
            ((total_candidates++))
            validate_file "$input" && ((validated_count++))
        elif [[ -d "$input" ]]; then
            # Directory: verifica solo file .mkv
            local files=()
            mapfile -t files < <(find "$input" -maxdepth 1 -type f -name "*.mkv" -o -name "*.mp4" -o -name "*.m4v" | sort)
            
            if [[ ${#files[@]} -eq 0 ]]; then
                echo "   ⚠️ Nessun file video trovato in: $input" >&2
            else
                for file in "${files[@]}"; do
                    ((total_candidates++))
                    validate_file "$file" && ((validated_count++))
                done
            fi
        else
            echo "   ⚠️ Percorso non valido (non file né directory): $input" >&2
        fi
    done
    
    # Report di validazione
    echo "🔍 Validazione di $total_candidates file potenziali..." >&2
    
    # Controlla se ci sono file validati
    if [[ $validated_count -eq 0 ]]; then
        echo "📊 Risultati validazione: 0/$total_candidates file compatibili." >&2
        
        # Suggerimenti per conversione in base al formato trovato
        if [[ $MONO_COUNT -gt 0 || $STEREO_COUNT -gt 0 || $SURROUND71_COUNT -gt 0 ]]; then
            echo "" >&2
            echo "💡 SUGGERIMENTI PER CONVERSIONE IN 5.1:" >&2
            
            if [[ $MONO_COUNT -gt 0 ]]; then
                echo "   🎙️ Per convertire audio MONO in 5.1:" >&2
                echo "   ffmpeg -i \"file.mkv\" -af \"pan=5.1|FL=FC|FR=FC|FC=FC|LFE=0|BL=0|BR=0\" -c:v copy output_51.mkv" >&2
            fi
            
            if [[ $STEREO_COUNT -gt 0 ]]; then
                echo "   🔄 Per convertire audio STEREO in 5.1:" >&2
                echo "   ffmpeg -i \"file.mkv\" -af \"surround\" -c:v copy output_51.mkv" >&2
            fi
            
            if [[ $SURROUND71_COUNT -gt 0 ]]; then
                echo "   🎭 Per convertire audio 7.1 in 5.1:" >&2
                echo "   ffmpeg -i \"file.mkv\" -af \"pan=5.1|FL=0.5*FL+0.707*FLC|FR=0.5*FR+0.707*FRC|FC=FC|LFE=LFE|BL=BL|BR=BR\" -c:v copy output_51.mkv" >&2
            fi
            
            echo "" >&2
        fi
        
        return 1
    fi
    
    echo "📊 Risultati validazione: $validated_count/$total_candidates file compatibili." >&2
    return 0
}

# Stampa riepilogo finale operazioni
print_summary() {
    local total_elapsed_time=$(($(date +%s) - TOTAL_START_TIME))
    
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "📊 RIEPILOGO ELABORAZIONE CLEARVOICE $VERSION" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    if [[ ${#PROCESSED_FILES_INFO[@]} -gt 0 ]]; then
        echo "✅ File elaborati con successo: ${#PROCESSED_FILES_INFO[@]}" >&2
        for info in "${PROCESSED_FILES_INFO[@]}"; do
            echo "   - $info" >&2
        done
    else
        echo "ℹ️ Nessun file elaborato con successo." >&2
    fi
    
    echo "" >&2
    
    if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
        echo "❌ File falliti: ${#FAILED_FILES[@]}" >&2
        for fail in "${FAILED_FILES[@]}"; do
            echo "   - $fail" >&2
        done
    else
        echo "🎉 Nessun file ha generato errori!" >&2
    fi
    
    # Statistiche formati audio non compatibili
    if [[ $MONO_COUNT -gt 0 || $STEREO_COUNT -gt 0 || $SURROUND71_COUNT -gt 0 || $OTHER_FORMAT_COUNT -gt 0 ]]; then
        echo "" >&2
        echo "📈 Formati rilevati non compatibili:" >&2
        [[ $MONO_COUNT -gt 0 ]] && echo "   🎙️  Mono: $MONO_COUNT file" >&2
        [[ $STEREO_COUNT -gt 0 ]] && echo "   🔄 Stereo: $STEREO_COUNT file" >&2
        [[ $SURROUND71_COUNT -gt 0 ]] && echo "   🎭 7.1 Surround: $SURROUND71_COUNT file" >&2
        [[ $OTHER_FORMAT_COUNT -gt 0 ]] && echo "   ❓ Altri formati: $OTHER_FORMAT_COUNT file" >&2
    fi
    
    echo "" >&2
    echo "⏱️  Tempo totale di esecuzione script: $total_elapsed_time secondi." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
}

# -----------------------------------------------------------------------------------------------
#  FUNZIONE MAIN E AVVIO SCRIPT
# -----------------------------------------------------------------------------------------------

main() {
    # Verifica dipendenze iniziali
    check_ffmpeg_version
    if ! command -v awk &> /dev/null; then echo "❌ awk non trovato!" >&2; exit 1; fi
    if ! command -v ffprobe &> /dev/null; then echo "❌ ffprobe non trovato!" >&2; exit 1; fi

    # Parsing argomenti
    parse_arguments "$@"

    # Configurazione preset
    set_preset_params "$PRESET"

    # Validazione input
    if ! validate_inputs; then
        print_summary # Mostra riepilogo anche se non ci sono file validi
        exit 1
    fi

    echo "" >&2
    echo "🎬 INIZIO ELABORAZIONE DI ${#VALIDATED_FILES_GLOBAL[@]} FILE VALIDATI..." >&2
    echo "   Preset: $PRESET | Codec: $ENC ($BR)" >&2
    echo "   Ogni file verrà elaborato con LFE Ducking attivo." >&2
    if [[ "$OVERWRITE" == "true" ]]; then
        echo "   Sovrascrittura automatica: ATTIVA" >&2
    else
        echo "   Sovrascrittura automatica: DISATTIVA (richiesta conferma)" >&2
    fi
    echo "" >&2
    
    # Loop per elaborazione file
    local i=0
    local total_files=${#VALIDATED_FILES_GLOBAL[@]}
    
    while [ $i -lt $total_files ]; do
        local current_file="${VALIDATED_FILES_GLOBAL[$i]}"
        local file_number=$((i+1))
        
        echo "--------------------------------------------------------------------------------------------" >&2
        echo " Elaborazione file $file_number/$total_files: $(basename "$current_file")" >&2
        echo "--------------------------------------------------------------------------------------------" >&2
        
        if process "$current_file"; then
            echo "   🎉 Successo per: $(basename "$current_file")" >&2
        else
            echo "   ⚠️  Fallimento per: $(basename "$current_file") (dettagli sopra)" >&2
        fi
        echo "" >&2
        
        i=$((i+1))
    done

    print_summary
    
    if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
        exit 1 # Esce con errore se ci sono stati fallimenti
    fi
}

# Esegui lo script
main "$@"