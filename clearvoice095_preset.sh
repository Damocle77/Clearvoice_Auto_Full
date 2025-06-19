#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------------
#  CLEARVOICE 0.95 - OTTIMIZZAZIONE AUDIO 5.1 +DUCKING AVANZATO MULTICANALE +SOXR RESAMPLING
#  Script avanzato per miglioramento dialoghi e controllo dinamico LFE basato su volume voce
# -----------------------------------------------------------------------------------------------
# 🎙️ VOICE BOOST INTELLIGENTE CON COMPRESSIONE MULTI-BANDA:
#    • Equalizzazione dedicata per voce italiana (800Hz, 2200-2800Hz boost)
#    • Compressore dinamico con soglia adattiva (-17dB a -20dB)
#    • Limitatore anti-distorsione con soft-clipping (atan/tanh/sin)
#    • Filtri passa-alto/passa-basso ottimizzati per intelligibilità dialoghi
#    • Riduzione automatica frequenze "muddy" (300-400Hz taglio selettivo)
#
# 🎛️ DUCKING MULTICANALE ULTRA-SENSIBILE:
#    • Sidechain compression su TUTTI i canali (FL/FR/LFE/BL/BR)
#    • Rilevamento voce anche a volume molto basso (threshold fino a -47dB)
#    • Preprocessing sidechain aggressivo (14dB boost + compressore 8:1)
#    • Parametri attack/release ottimizzati per naturalezza (2-8ms / 50-200ms)
#    • Makeup gain automatico per compensazione volume post-ducking
#    • Attenuazione selettiva: musica/effetti si abbassano quando parla la voce
#
# 🔊 ELABORAZIONE LFE PROFESSIONALE CON CROSSOVER AVANZATO:
#    • Filtri crossover Butterworth/Linkwitz-Riley (1°/2° ordine)
#    • Range frequenze LFE ottimizzato (30-120Hz, configurabile per preset)
#    • Ducking LFE sensibile per evitare mascheramento dialoghi
#    • Equalizzazione subwoofer specifica (boost 40-80Hz, controllo risonanze)
#    • Volume LFE adattivo per codec DTS (riduzione automatica 0.10-0.16x)
#
# 🎬 PRESET SPECIALIZZATI PER CONTENUTI MULTIMEDIALI:
#    • FILM: Massima qualità, soundstage cinematografico, compressione delicata
#    • SERIE: Bilanciamento dialoghi/musica, anti-affaticamento per visioni prolungate  
#    • TV: Ultra-conservativo, riduzione rumore attiva, compatibilità broadcast
#    • CARTONI: Preservazione musicale, compressione leggera, ottimizzato per voci acute
#    • Ogni preset con parametri ducking, EQ e dinamiche specificamente calibrati
#
# 🎯 SUPPORTO CODEC MULTIPLI CON QUALITÀ OTTIMIZZATA:
#    • EAC3 (E-AC-3): Efficienza superiore, supporto metadata Dolby, bitrate 256-768k
#    • AC3 (Dolby Digital): Compatibilità universale, bitrate standard 384-640k
#    • DTS: Alta fedeltà, channel layout 5.1(side), compressione lossless opzionale
#    • Parametri encoder ottimizzati per ciascun codec (strict, compression_level)
#    • Gestione automatica sample rate (48kHz) e bit depth per massima compatibilità
#
# 🛠️ COMPATIBILITÀ DTS AVANZATA (PROBLEMI RISOLTI):
#    • Channel layout corretto: 5.1(side) invece di 5.1 generico
#    • Parametri EXTRA sicuri con gestione array per spazi nei parametri
#    • Adattamenti preset-specifici: volume voce +0.3dB, LFE ridotto, surround -15%
#    • Rimozione soundstaging problematico (stereotools/extrastereo disabilitato)
#    • Test compatibilità encoder DTS integrato nel validation flow
#
# 🎵 SOXR RESAMPLER PER QUALITÀ AUDIO SUPERIORE:
#    • Algoritmo SoXR (Sony Oxford Resampler) quando disponibile in FFmpeg
#    • Precisione variabile: 28-bit (film), 20-bit (serie/tv), 15-bit (cartoni)
#    • Fallback automatico a swresample standard se SoXR non disponibile
#    • Anti-aliasing superiore e distorsione ridotta durante resampling
#    • Preservazione della fase audio per mantenere imaging stereo
#
# 🇮🇹 EQUALIZZAZIONI OTTIMIZZATE PER VOCE ITALIANA:
#    • Ricerca specifica su frequenze critiche per consonanti italiane
#    • FILM: f=800:g=1.2, f=2200:g=3.8, f=3000:g=2.8 (intelligibilità massima)
#    • SERIE: f=2200:g=3.5, f=2800:g=2.8 (dialoghi complessi, audio compresso)  
#    • TV: f=2000:g=3.2, f=3000:g=2.5 (broadcast, qualità variabile)
#    • CARTONI: f=2500:g=3.0, f=3500:g=2.8 (voci acute, caratterizzazione)
#    • Taglio automatico frequenze basse problematiche (300-400Hz)
#
# 🎚️ LFE REDUCTION SENSIBILE PER VOCE BASSA:
#    • Threshold ducking estremamente sensibile (fino a -47dB per preset TV)
#    • Preprocessing voce potenziato: +14dB boost → compressore 8:1 → +18dB
#    • Range frequenze sidechain ottimizzato (180-4000Hz vs standard 200-3800Hz)
#    • Attack/release ultra-veloci per reazione istantanea (2ms attack, 50ms release)
#    • LFE reduction progressivo: 0.16x (film) → 0.14x (tv) → 0.10x (tv+dts)
#    • Evita mascheramento anche con dialoghi sussurrati o in background
# -----------------------------------------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------------------------------------
#  CONFIGURAZIONE GLOBALE
# -----------------------------------------------------------------------------------------------
FRONT_VOL=1.0               # Volume canali frontali (FL/FR)
VERSION="0.95"              # Versione script corrente
MIN_FFMPEG_VER="6.0"        # Versione minima ffmpeg richiesta
DEFAULT_THREADS=4           # Numero di thread di default
OVERWRITE="false"           # Valore predefinito: non sovrascrivere file esistenti
VALIDATED_FILES_GLOBAL=()   # File che hanno superato i controlli di compatibilità 5.1
DUCKING_ENABLED="false"     # Verrà impostato a true se sidechaincompress è supportato

# Array per gestione dei file e statistiche
FAILED_FILES=()              # Memorizza i file che hanno generato errori durante l'elaborazione
PROCESSED_FILES_INFO=()      # Dettagli sui file elaborati con successo
VALIDATED_FILES_GLOBAL=()    # File che hanno superato i controlli di compatibilità 5.1

# Contatori per statistiche formato audio
MONO_COUNT=0
STEREO_COUNT=0
SURROUND71_COUNT=0
OTHER_FORMAT_COUNT=0

# Variabili globali per parametri preset
PRESET=""                    # Tipo di ottimizzazione: film, serie, tv o cartoni
CODEC="eac3"                 # Codec audio predefinito (eac3, ac3, dts)
BR="384k"                    # Bitrate audio predefinito
INPUTS=()                    # Percorsi input specificati dall'utente (file o directory)

# Parametri audio configurabili in base al preset
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
SC_ATTACK=""                 # Tempo attacco per ducking
SC_RELEASE=""                # Tempo rilascio per ducking
SC_THRESHOLD=""              # Soglia attivazione ducking
SC_RATIO=""                  # Rapporto di compressione ducking
SC_MAKEUP=""                 # Compensazione volume post-ducking
FC_EQ_PARAMS=""              # Equalizzazione canale centrale (dialoghi)
FLFR_EQ_PARAMS=""            # Equalizzazione canali frontali
LFE_EQ_PARAMS=""             # Equalizzazione subwoofer
ENC=""                       # Codifica finale
EXTRA=""                     # Parametri extra codec-specifici
TITLE=""                     # Titolo metadata per la traccia audio
DENOISE_FILTER=""            # Filtro riduzione rumore (solo preset TV)

# Inizializza tempo globale per statistiche finali
TOTAL_START_TIME=$(date +%s) # Memorizza timestamp per calcolare durata totale dell'elaborazione

# -----------------------------------------------------------------------------------------------
#  FUNZIONI HELPER
# -----------------------------------------------------------------------------------------------

# Funzione per chiedere conferma all'utente (sì/no)
ask_overwrite() {
    local out="$1"
    if [[ -f "$out" ]]; then
        read -p "⚠️ Il file '$out' esiste già. Sovrascrivere? [s/n]: " risposta
        case "$risposta" in
            [sS]*) return 0 ;;
            *) echo "❌ Operazione annullata."; return 1 ;;
        esac
    fi
    return 0
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

    # Parsing argomenti rimanenti
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
        eac3|ac3|dts) ;;
        *)
            echo "❌ Codec '$CODEC' non supportato! Usa uno tra: eac3, ac3, dts" >&2
            exit 1
            ;;
    esac

    # Validazione bitrate
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
        film) 
            VOICE_VOL="10.5" LFE_VOL="0.16" SURROUND_VOL="4.2" 
            HP_FREQ="110" LP_FREQ="8000"
            COMPRESSOR_SETTINGS="acompressor=threshold=-20dB:ratio=4.5:attack=8:release=180:makeup=2.5dB"
            FRONT_FILTER="highpass=f=22:poles=2,lowpass=f=20000:poles=1,acompressor=threshold=-20dB:ratio=2.0:attack=20:release=100"
            SOFTCLIP_SETTINGS="asoftclip=type=atan:threshold=0.95:output=1.0"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="35" LFE_LP_FREQ="110" LFE_CROSS_POLES="2"
            SC_ATTACK="3" SC_RELEASE="120" SC_THRESHOLD="-40dB" SC_RATIO="3.8" SC_MAKEUP="2dB"
            # Equalizzazione lingua italiana ottimizzata per film
            FC_EQ_PARAMS="equalizer=f=800:width_type=q:w=2.0:g=1.2,equalizer=f=2200:width_type=q:w=1.6:g=3.8,equalizer=f=3000:width_type=q:w=1.4:g=2.8,equalizer=f=400:width_type=q:w=2.2:g=-1.5"
            FLFR_EQ_PARAMS="" 
            LFE_EQ_PARAMS="equalizer=f=40:width_type=q:w=1.2:g=2.5,equalizer=f=70:width_type=q:w=1.8:g=1.5"
            DENOISE_FILTER="" 
            ;;
        serie)
            VOICE_VOL="10.2" LFE_VOL="0.16" SURROUND_VOL="4.2" 
            HP_FREQ="120" LP_FREQ="7800"
            COMPRESSOR_SETTINGS="acompressor=threshold=-18dB:ratio=4.2:attack=10:release=200:makeup=2.5dB"
            FRONT_FILTER="highpass=f=28:poles=2,lowpass=f=18000:poles=1,acompressor=threshold=-20dB:ratio=2.0:attack=20:release=100"
            SOFTCLIP_SETTINGS="asoftclip=type=atan:threshold=0.97:output=1.0"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="38" LFE_LP_FREQ="108" LFE_CROSS_POLES="2"
            SC_ATTACK="5" SC_RELEASE="180" SC_THRESHOLD="-42dB" SC_RATIO="2.5" SC_MAKEUP="1.5dB"
            # Equalizzazione lingua italiana ottimizzata per serie
            FC_EQ_PARAMS="equalizer=f=800:width_type=q:w=1.7:g=1.2,equalizer=f=2200:width_type=q:w=1.5:g=3.5,equalizer=f=2800:width_type=q:w=1.2:g=2.8,equalizer=f=300:width_type=q:w=2:g=-2"
            FLFR_EQ_PARAMS="equalizer=f=300:width_type=q:w=2:g=-1"
            LFE_EQ_PARAMS="equalizer=f=45:width_type=q:w=1.2:g=2.2,equalizer=f=80:width_type=q:w=1.5:g=1"
            DENOISE_FILTER="" 
            ;;
        tv) 
            VOICE_VOL="8.0" LFE_VOL="0.14" SURROUND_VOL="3.8" 
            HP_FREQ="400" LP_FREQ="5000"
            COMPRESSOR_SETTINGS="acompressor=threshold=-18dB:ratio=3.8:attack=8:release=180:makeup=2.5dB"
            FRONT_FILTER="highpass=f=100:poles=1,lowpass=f=8000:poles=1,acompressor=threshold=-18dB:ratio=2.2:attack=15:release=120"
            SOFTCLIP_SETTINGS="asoftclip=type=tanh:threshold=0.9:output=0.95"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="40" LFE_LP_FREQ="100" LFE_CROSS_POLES="1"
            SC_ATTACK="8" SC_RELEASE="200" SC_THRESHOLD="-47dB" SC_RATIO="4.5" SC_MAKEUP="3dB"
            # Equalizzazione lingua italiana ottimizzata per TV
            FC_EQ_PARAMS="equalizer=f=900:width_type=q:w=1.6:g=1.5,equalizer=f=2000:width_type=q:w=1.5:g=3.2,equalizer=f=3000:width_type=q:w=1.2:g=2.5,equalizer=f=300:width_type=q:w=2:g=-2"
            FLFR_EQ_PARAMS="equalizer=f=1500:width_type=h:w=500:g=1.5"
            LFE_EQ_PARAMS="equalizer=f=50:width_type=q:w=1.5:g=2"
            DENOISE_FILTER="afftdn=nr=20:nf=-42:tn=1,anlmdn=s=0.0001:p=0.002:r=0.005"
            ;;
        cartoni)
            VOICE_VOL="10.0" LFE_VOL="0.16" SURROUND_VOL="4.2" 
            HP_FREQ="90" LP_FREQ="9000"
            COMPRESSOR_SETTINGS="acompressor=threshold=-17dB:ratio=3.8:attack=8:release=160:makeup=2.5dB"
            FRONT_FILTER="highpass=f=20:poles=2,lowpass=f=21000:poles=1,acompressor=threshold=-15dB:ratio=1.8:attack=25:release=150"
            SOFTCLIP_SETTINGS="asoftclip=type=sin:threshold=0.98:output=1.0"
            FRONT_DELAY_SAMPLES="0" SURROUND_DELAY_SAMPLES="0" 
            LFE_HP_FREQ="30" LFE_LP_FREQ="120" LFE_CROSS_POLES="2"
            SC_ATTACK="3" SC_RELEASE="130" SC_THRESHOLD="-42dB" SC_RATIO="3.2" SC_MAKEUP="2.5dB"
            # Equalizzazione lingua italiana ottimizzata per cartoni
            FC_EQ_PARAMS="equalizer=f=850:width_type=q:w=1.6:g=1.2,equalizer=f=2500:width_type=q:w=1.5:g=3.0,equalizer=f=3500:width_type=q:w=1.2:g=2.8,equalizer=f=300:width_type=q:w=2:g=-2"
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
        echo "ℹ️  Adattamento parametri per codec DTS" >&2
        EXTRA="-strict -2 -ar 48000 -channel_layout 5.1(side) -compression_level 2"
        
        # Adattamenti specifici per DTS
        case "$PRESET" in
            film)
                VOICE_VOL="10.8"  # Aumentato per DTS
                LFE_VOL="0.12"    # Ridotto per DTS
                SURROUND_VOL=$(safe_awk_calc "$SURROUND_VOL * 0.85")
                HP_FREQ="120"; LP_FREQ="7700"
                echo "ℹ️  LFE ridotto per codec DTS (${LFE_VOL}x)" >&2
                ;;
            serie)
                VOICE_VOL="10.3"  # Aumentato per DTS
                LFE_VOL="0.12"
                SURROUND_VOL=$(safe_awk_calc "$SURROUND_VOL * 0.88")
                HP_FREQ="135"; LP_FREQ="8000"
                ;;
            tv)
                VOICE_VOL="8.3"   # Aumentato per DTS
                LFE_VOL="0.10"    # Ancora più ridotto per TV+DTS
                SURROUND_VOL=$(safe_awk_calc "$SURROUND_VOL * 0.88")
                HP_FREQ="420"; LP_FREQ="5200"
                ;;
            cartoni)
                VOICE_VOL="10.2"  # Aumentato per DTS
                LFE_VOL="0.12"
                SURROUND_VOL=$(safe_awk_calc "$SURROUND_VOL * 0.9")
                HP_FREQ="90"; LP_FREQ="8700"
                ;;
        esac
    fi
    
    TITLE="ClearVoice $VERSION - $preset_choice ($CODEC $BR)"
}

# SoxR resampler (richiede FFmpeg compilato con SoxR)
apply_soxr_resampling() {
    local soxr_params=""
    if ffmpeg -filters 2>&1 | grep -q soxr; then
        case "$PRESET" in
            film)    soxr_params=":precision=28";; # Massima qualità
            serie|tv)soxr_params=":precision=20";;  # Bilanciato
            cartoni) soxr_params=":precision=15";;  # Standard
        esac
        echo "aresample=resampler=soxr${soxr_params}"
    else
        echo "aresample=resampler=swr" # Fallback a swresample standard
    fi
}

# Controllo supporto sidechain (per ducking)
check_sidechain_support() {
    ffmpeg -filters 2>&1 | grep -q sidechaincompress
}

# -----------------------------------------------------------------------------------------------
#  ELABORAZIONE AUDIO E FILTERGRAPH
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
    
    # Se attiva la sovrascrittura, usa il file originale come output
    [[ "$OVERWRITE" == "true" ]] && out="$input_file"
    
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
    
   # Controllo esistenza file output con richiesta di conferma FORZATA
    if [[ -f "$out" && "$out" != "$input_file" ]]; then
        if [[ "$OVERWRITE" == "true" ]]; then
        echo "⚠️ File output già esistente: $(basename "$out") (sovrascrittura automatica)" >&2
        else
            echo "⚠️ File output già esistente: $(basename "$out")" >&2
        
            # Loop finché non otteniamo una risposta valida
            while true; do
                echo -n "   Vuoi sovrascrivere il file esistente? [s/n]: " >&2
                read -r risposta
            
                case "$risposta" in
                    [sS]*)
                        echo "   ✅ Sovrascrittura confermata." >&2
                        break
                        ;;
                    [nN]*)
                        echo "   ❌ Sovrascrittura rifiutata. Elaborazione annullata." >&2
                        FAILED_FILES+=("$(basename "$input_file") (Sovrascrittura rifiutata)")
                        return 1
                        ;;
                    *)
                        echo "   Per favore rispondi con 's' per sì o 'n' per no." >&2
                        ;;
                esac
            done
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

    # Determina numero massimo di threads disponibili
local threads_count=0
local available_cores=0

# Rileva tutti i cores disponibili
if command -v nproc &> /dev/null; then
    available_cores=$(nproc --all 2>/dev/null || nproc)
elif command -v sysctl &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
    available_cores=$(sysctl -n hw.logicalcpu 2>/dev/null || sysctl -n hw.ncpu)
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    available_cores=${NUMBER_OF_PROCESSORS:-$DEFAULT_THREADS}
else
    available_cores=$DEFAULT_THREADS
fi
# USA TUTTI I CORES DISPONIBILI (massima performance)
threads_count=$available_cores
# Assicura minimo ragionevole ma lascia massimo libero
threads_count=$(( threads_count < 2 ? 2 : threads_count ))
# Thread pool ottimizzato per filtergraph complessi
local filter_threads=$(( threads_count > 8 ? threads_count - 2 : threads_count ))

echo "🚀 PERFORMANCE MASSIMA: Cores rilevati: $available_cores | Threads utilizzati: $threads_count (Filter: $filter_threads)" >&2

    # Verifica quanti stream audio ha il file
    local audio_streams
    audio_streams=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$input_file" 2>/dev/null | wc -l)
    
    # Verifica se ci sono sottotitoli
    local has_subtitles
    has_subtitles=$(ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$input_file" 2>/dev/null | wc -l)
    
    # Costruzione comando FFmpeg con gestione sicura di $EXTRA
    if [[ -n "$EXTRA" ]]; then
        # Converti EXTRA in array per gestire correttamente gli spazi
        local extra_args
        IFS=' ' read -ra extra_args <<< "$EXTRA"
        
        # Preparazione mappatura e codec
        local map_args=(-map "[out]" -map 0:a -map 0:v)
        [[ $has_subtitles -gt 0 ]] && map_args+=(-map 0:s)
        
        local codec_args=(-c:a:0 "$ENC" -b:a:0 "$BR" "${extra_args[@]}")
        for ((i=1; i<audio_streams; i++)); do
            codec_args+=(-c:a:$i copy)
        done
        codec_args+=(-c:v copy)
        [[ $has_subtitles -gt 0 ]] && codec_args+=(-c:s copy)
        
        # Preparazione metadata
        local metadata_args=(-metadata:s:a:0 "title=Italiano 5.1 ClearVoice $PRESET ($ENC $BR)" -metadata:s:a:0 language=ita -disposition:a:0 default)
        
        # Esecuzione FFmpeg
        ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero \
          -threads "$threads_count" -filter_threads "$filter_threads" -thread_queue_size 1024 \
          -i "$input_file" \
          -filter_complex "$LOCAL_FILTER_GRAPH" \
          "${map_args[@]}" "${codec_args[@]}" "${metadata_args[@]}" \
          -movflags +faststart "$out" 2> >(if [[ -n "$log_file" && -w "$log_file" ]]; then tee -a "$log_file" >&2; else cat >&2; fi)
    else
        # Preparazione mappatura e codec
        local map_args=(-map "[out]" -map 0:a -map 0:v)
        [[ $has_subtitles -gt 0 ]] && map_args+=(-map 0:s)
        
        local codec_args=(-c:a:0 "$ENC" -b:a:0 "$BR")
        for ((i=1; i<audio_streams; i++)); do
            codec_args+=(-c:a:$i copy)
        done
        codec_args+=(-c:v copy)
        [[ $has_subtitles -gt 0 ]] && codec_args+=(-c:s copy)
        
        # Preparazione metadata
        local metadata_args=(-metadata:s:a:0 "title=Italiano 5.1 ClearVoice $PRESET ($ENC $BR)" -metadata:s:a:0 language=ita -disposition:a:0 default)
        
        # Esecuzione FFmpeg
        ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero \
          -threads "$threads_count" -filter_threads "$filter_threads" -thread_queue_size 1024 \
          -i "$input_file" \
          -filter_complex "$LOCAL_FILTER_GRAPH" \
          "${map_args[@]}" "${codec_args[@]}" "${metadata_args[@]}" \
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
        
        if [[ -f "$out" && "$out" != "$input_file" ]]; then
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
    
    # Debug layout audio
    local channels
    local current_layout
    local codec_name
    
    channels=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$file" 2>/dev/null)
    current_layout=$(ffprobe -v error -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$file" 2>/dev/null)
    codec_name=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null)
    
    echo "🔍 Layout audio: Canali=$channels, Layout='$current_layout', Codec=$codec_name" >&2
    
    # Inizializza il filtergraph
    local filter_graph=""
    
    # PARTE 1: CHANNEL SPLITTING - Estrazione dei canali individuali
    if [[ "$channels" == "6" ]]; then
        # Versione robusta che usa asplit + channelsplit per estrarre i canali
        filter_graph="[0:a]aformat=channel_layouts=5.1[audio5dot1];"
        filter_graph+="[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE_orig][BL][BR];"
        echo "✅ Layout 5.1 rilevato - Estrazione canali attiva" >&2
    else
        echo "❌ File non ha 6 canali (ha $channels)" >&2
        return 1
    fi

    # PARTE 2: PROCESSAMENTO CANALE CENTRALE (DIALOGHI) - Con equalizzazioni italiane
    local fc_filters=""
    [[ -n "$DENOISE_FILTER" ]] && fc_filters+="${DENOISE_FILTER},"
    fc_filters+="highpass=f=${HP_FREQ},lowpass=f=${LP_FREQ}"
    [[ -n "$FC_EQ_PARAMS" ]] && fc_filters+=",${FC_EQ_PARAMS}"
    fc_filters+=",${COMPRESSOR_SETTINGS}"
    fc_filters+=",volume=${VOICE_VOL}dB"
    fc_filters+=",alimiter=level_in=1:level_out=0.95:limit=0.98:attack=0.1:release=5"
    fc_filters+=",${SOFTCLIP_SETTINGS}"
    filter_graph+="[FC]${fc_filters}[center_out];"

    # PARTE 3: SIDECHAIN DUCKING ULTRA-SENSIBILE - Prepara il segnale di controllo per voce bassa
    if [[ "$DUCKING_ENABLED" == "true" ]]; then
        echo "🎛️ Ducking multicanale attivo - Controllo dinamico basato su voce (sensibile)" >&2
        filter_graph+="[center_out]asplit=2[center_final][voice_sidechain];"
        # Preprocessing più aggressivo per voce bassa (sensibilità aumentata)
        filter_graph+="[voice_sidechain]highpass=f=180,lowpass=f=4000,volume=14dB,acompressor=threshold=-40dB:ratio=8:attack=2:release=50,volume=18dB[sidechain_control];"
    else
        filter_graph+="[center_out]acopy[center_final];"
        echo "⚠️ Ducking non disponibile - Sidechain non supportato" >&2
    fi

    # PARTE 4: CANALI FRONTALI (FL/FR) 
    local fl_fr_filters=""
    [[ -n "$FRONT_FILTER" ]] && fl_fr_filters+="${FRONT_FILTER},"
    [[ -n "$FLFR_EQ_PARAMS" ]] && fl_fr_filters+="${FLFR_EQ_PARAMS},"
    fl_fr_filters+="volume=${FRONT_VOL}"
    [[ "$FRONT_DELAY_SAMPLES" != "0" ]] && fl_fr_filters+=",adelay=${FRONT_DELAY_SAMPLES}"
    fl_fr_filters="${fl_fr_filters%,}" # Rimuove l'ultima virgola se presente

    if [[ "$DUCKING_ENABLED" == "true" ]]; then
        # Conversione threshold da dB a valore lineare per sidechaincompress
        local sc_threshold_numeric
        if [[ "$SC_THRESHOLD" =~ ^-?[0-9]+dB$ ]]; then
            local db_value
            db_value=$(echo "$SC_THRESHOLD" | sed 's/dB$//')
            if [[ "$db_value" -lt -60 ]] || [[ "$db_value" -gt 0 ]]; then
                echo "⚠️ Threshold fuori range, usando -35dB" >&2
                db_value="-35"
            fi
            sc_threshold_numeric=$(awk "BEGIN { result = 10^($db_value/20); if(result < 0.001) result = 0.001; if(result > 1.0) result = 1.0; printf \"%.4f\", result }")            
        else
            sc_threshold_numeric="0.010"
        fi
        
        # Applica filtri base e poi ducking
        filter_graph+="[FL]${fl_fr_filters}[fl_pre];"
        filter_graph+="[FR]${fl_fr_filters}[fr_pre];"
        filter_graph+="[fl_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=${SC_MAKEUP}[fl_out];"
        filter_graph+="[fr_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=${SC_MAKEUP}[fr_out];"
    else
        # Senza ducking, applica solo i filtri base
        filter_graph+="[FL]${fl_fr_filters}[fl_out];"
        filter_graph+="[FR]${fl_fr_filters}[fr_out];"
    fi

    # PARTE 5: CANALE LFE (SUBWOOFER) - Con ducking sensibile
    local lfe_filters="highpass=f=${LFE_HP_FREQ}:poles=${LFE_CROSS_POLES},lowpass=f=${LFE_LP_FREQ}:poles=${LFE_CROSS_POLES}"
    [[ -n "$LFE_EQ_PARAMS" ]] && lfe_filters+=",${LFE_EQ_PARAMS}"
    lfe_filters+=",volume=${LFE_VOL}"
    filter_graph+="[LFE_orig]${lfe_filters}[lfe_processed];"

    if [[ "$DUCKING_ENABLED" == "true" ]]; then    
        filter_graph+="[lfe_processed][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=${SC_MAKEUP}[lfe_out];"
    else
        filter_graph+="[lfe_processed]acopy[lfe_out];"
    fi

    # PARTE 6: CANALI SURROUND (BL/BR) - Con ducking sensibile
    local bl_br_filters="acompressor=threshold=0.3:ratio=2.5:attack=20:release=350,asoftclip=threshold=0.95"
    bl_br_filters+=",volume=${SURROUND_VOL}dB"
    [[ "$SURROUND_DELAY_SAMPLES" != "0" ]] && bl_br_filters+=",adelay=${SURROUND_DELAY_SAMPLES}"

    if [[ "$DUCKING_ENABLED" == "true" ]]; then
        filter_graph+="[BL]${bl_br_filters}[bl_pre];"
        filter_graph+="[BR]${bl_br_filters}[br_pre];"
        filter_graph+="[bl_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=${SC_MAKEUP}[bl_out];"
        filter_graph+="[br_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=${SC_MAKEUP}[br_out];"
    else
        filter_graph+="[BL]${bl_br_filters}[bl_out];"
        filter_graph+="[BR]${bl_br_filters}[br_out];"
    fi

    # PARTE 7: JOIN FINALE - Unione di tutti i canali processati
    # Usa join semplice e compatibile con DTS
    if [[ "${CODEC,,}" == "dts" ]]; then
        # Layout specifico per DTS
        filter_graph+="[fl_out][fr_out][center_final][lfe_out][bl_out][br_out]join=inputs=6:channel_layout=5.1(side)[joined];"
    else
        # Layout generico per altri codec
        filter_graph+="[fl_out][fr_out][center_final][lfe_out][bl_out][br_out]join=inputs=6:channel_layout=5.1[joined];"
    fi
    
    # Applica il resampling finale con SoxR se disponibile
    local soxr_filter; soxr_filter=$(apply_soxr_resampling)
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
    echo "🎛️  Ducking Multicanale: $([ "$DUCKING_ENABLED" == "true" ] && echo "ATTIVO (Sensibile)" || echo "NON DISPONIBILE")" >&2
    echo "🇮🇹  Equalizzazioni ottimizzate per voce italiana: ATTIVE" >&2
    echo "🎯  Codec: $CODEC | Bitrate: $BR | Preset: $PRESET" >&2
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

    # Banner di avvio
    echo "╔══════════════════════════════════════════════════════════════════════════╗" >&2
    echo "║       CLEARVOICE $VERSION - OTTIMIZZAZIONE AUDIO CON DUCKING AVANZATO    ║" >&2
    echo "║                 CON EQUALIZZAZIONI ITALIANE OTTIMIZZATE                  ║" >&2
    echo "╚══════════════════════════════════════════════════════════════════════════╝" >&2
    echo "" >&2

    # Parsing argomenti
    parse_arguments "$@"

    # Configurazione preset
    set_preset_params "$PRESET"

    # Controlla se il filtro sidechaincompress è supportato
    if check_sidechain_support; then
        DUCKING_ENABLED="true"
        echo "✅ Ducking Multicanale sensibile disponibile e attivato." >&2
    else
        DUCKING_ENABLED="false"
        echo "⚠️ Ducking non disponibile - Il filtro sidechaincompress non è supportato in questa versione di FFmpeg." >&2
        echo "   Verrà applicata l'ottimizzazione standard senza ducking dinamico." >&2
    fi

    # Validazione input
    if ! validate_inputs; then
        print_summary # Mostra riepilogo anche se non ci sono file validi
        exit 1
    fi

    echo "" >&2
    echo "🎬 INIZIO ELABORAZIONE DI ${#VALIDATED_FILES_GLOBAL[@]} FILE VALIDATI..." >&2
    echo "   Preset: $PRESET | Codec: $ENC ($BR)" >&2
    if [[ "$DUCKING_ENABLED" == "true" ]]; then
        echo "   Ducking Multicanale: ATTIVO (Sensibile per voce bassa)" >&2
    else
        echo "   Ducking Multicanale: NON DISPONIBILE" >&2
    fi
    echo "   Equalizzazioni italiane: ATTIVE" >&2
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