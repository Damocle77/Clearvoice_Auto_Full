#!/usr/bin/env bash

# ===========================================================================================
# CLEARVOICE 0.93 - ADVANCED AUDIO OPTIMIZATION FOR 5.1 SURROUND CONTENT
# ===========================================================================================

set -euo pipefail

# -------------------------------------------- CONFIGURAZIONE GLOBALE -----------------------------------------------
VERSION="0.93"
MIN_FFMPEG_VER="6.0"
DEFAULT_THREADS=4
OVERWRITE="false"
FAILED_FILES=()
PROCESSED_FILES_INFO=()
VALIDATED_FILES_GLOBAL=()
MONO_COUNT=0
STEREO_COUNT=0
SURROUND71_COUNT=0
OTHER_FORMAT_COUNT=0
PRESET=""
CODEC="eac3"
BR="384k"
INPUTS=()
DUCKING_ENABLED="false"

# Parametri audio (popolati dai preset)
VOICE_VOL="" LFE_VOL="0.16" SURROUND_VOL="4.2" HP_FREQ="" LP_FREQ="" COMPRESSOR_SETTINGS=""
FRONT_FILTER="" SOFTCLIP_SETTINGS="" FRONT_DELAY_SAMPLES="" SURROUND_DELAY_SAMPLES=""
LFE_HP_FREQ="" LFE_LP_FREQ="" LFE_CROSS_POLES="" SC_ATTACK="15" SC_RELEASE="300"
SC_THRESHOLD="-32dB" SC_RATIO="5.5" SC_MAKEUP="0dB" FC_EQ_PARAMS="" FLFR_EQ_PARAMS=""
LFE_EQ_PARAMS="" SURROUND_COMP="" ENC="" EXTRA="" TITLE="" DENOISE_FILTER=""
SOUNDSTAGE_FILTER="" FRONT_VOL="1.0"

TOTAL_START_TIME=$(date +%s)

# ------------------------------------------ FUNZIONI HELPER --------------------------------------------------------
# Funzioni di utilità per l'interazione con l'utente e la gestione dei file
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
# Funzione per chiedere conferma all'utente
ask_yes_no() {
    local prompt="$1"; local response
    while true; do
        echo -n "$prompt [s/n]: "; read -r response < /dev/tty
        case "$response" in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo " Per favore, rispondi con 's' o 'n'.";;
        esac
    done
}
# Funzione per controllare la versione di FFmpeg
check_ffmpeg_version() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "❌ FFmpeg non trovato!" >&2
        exit 1
    fi
    local current_version
    current_version=$(ffmpeg -version | head -n1 | awk -F'[ -]' '{print $3}')
    if ! awk -v v1="$current_version" -v v2="$MIN_FFMPEG_VER" 'BEGIN {
        n1=split(v1,a,"."); n2=split(v2,b,".");
        for(i=1;i<=(n1>n2?n1:n2);i++){a[i]=a[i]?a[i]:0; b[i]=b[i]?b[i]:0;
        if(a[i]<b[i])exit 1; if(a[i]>b[i])exit 0;} exit 0; }'; then
        echo "❌ FFmpeg versione $current_version non compatibile. Richiesta almeno $MIN_FFMPEG_VER." >&2
        exit 1
    fi
    echo "✅ FFmpeg versione $current_version compatibile." >&2
}
# Funzione per calcolare in modo sicuro con awk, evitando NaN e inf
safe_awk_calc() {
    local expr="$1"; local result
    if ! result=$(awk "BEGIN { printf \"%.6f\", $expr }" 2>/dev/null) || [[ "$result" == "nan" || "$result" == "inf" || "$result" == "-inf" ]]; then
        echo "1.0"; return 1
    fi
    echo "$result"; return 0
}
# Funzione per validare i file di input
validate_file() {
    local file="$1"
 
    # Estrae il numero di canali audio del primo stream audio
    local channels
    channels=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$file" 2>/dev/null || echo "0")
    
    # Accetta solo file con 6 canali (5.1), conta e scarta gli altri formati
    if [[ "$channels" == "6" ]]; then
        VALIDATED_FILES_GLOBAL+=("$file")
        return 0
    elif [[ "$channels" == "1" ]]; then
        ((MONO_COUNT++))
    elif [[ "$channels" == "2" ]]; then
        ((STEREO_COUNT++))
    elif [[ "$channels" == "8" ]]; then
        ((SURROUND71_COUNT++))
    else
        ((OTHER_FORMAT_COUNT++))
    fi
    return 1
}
# Funzione per analizzare gli argomenti della riga di comando
parse_arguments() {
    if [[ $# -lt 3 ]]; then
        echo "❌ Errore: Argomenti insufficienti!" >&2
        echo "Uso: $0 --preset codec bitrate [--overwrite] file1.mkv [file2.mkv ...]" >&2
        exit 1
    fi
    # Validazione del preset
    case "$1" in
        --film|--serie|--tv|--cartoni) PRESET="${1#--}"; shift;;
        *) echo "❌ Preset '$1' non valido!" >&2; exit 1;;
    esac
    # Validazione del codec e bitrate
    CODEC="$1"; shift; BR="$1"; shift
    # Gestione opzioni aggiuntive
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --overwrite) OVERWRITE="true"; shift;;
            -*) echo "❌ Opzione '$1' non riconosciuta!" >&2; exit 1;;
            *) INPUTS+=("$1"); shift;;
        esac
    done
    # Validazione degli input
    if [[ ${#INPUTS[@]} -eq 0 ]]; then echo "❌ Nessun file/directory specificato!" >&2; exit 1; fi
    # Validazione del codec
    case "${CODEC,,}" in
        eac3|ac3|dts) ;;
        *) echo "❌ Codec '$CODEC' non supportato!" >&2; exit 1;;
    esac
    # Validazione del bitrate
    if ! [[ "$BR" =~ ^[0-9]+[kmKM]?$ ]]; then 
        echo "❌ Formato bitrate '$BR' non valido! Usa formato: 756k, 1536k, 1M, etc." >&2
        exit 1
    fi
    # Normalizza il bitrate
    if [[ "$BR" =~ ^[0-9]+$ ]]; then
        BR="${BR}k"
        echo "ℹ️ Bitrate normalizzato a: $BR" >&2
    fi
}
# Funzione per impostare i parametri di default
set_default_params() {
    FRONT_VOL="1.0"
    FRONT_DELAY_SAMPLES="0"
    SURROUND_DELAY_SAMPLES="0"
    LFE_CROSS_POLES="2"
    FLFR_EQ_PARAMS=""
    LFE_EQ_PARAMS=""
    DENOISE_FILTER=""
    SURROUND_COMP=""
    SOUNDSTAGE_FILTER=""
}
# Funzione per impostare i parametri del preset selezionato
set_preset_params() {
    local preset_choice="$1"
    echo "ℹ️ Configurazione preset: $preset_choice" >&2
    set_default_params

    case "$preset_choice" in
        film)
            VOICE_VOL="10.5"
            HP_FREQ="110"
            LP_FREQ="8000"
            SURROUND_VOL="4.2"
            LFE_VOL="0.16"
            FC_EQ_PARAMS="equalizer=f=2500:width_type=q:w=1.5:g=4.0,equalizer=f=3200:width_type=q:w=1.2:g=3.0,equalizer=f=300:width_type=q:w=2:g=-2"
            COMPRESSOR_SETTINGS="acompressor=threshold=-20dB:ratio=4.5:attack=10:release=220:makeup=2.2dB"
            FRONT_FILTER="highpass=f=22:poles=2,lowpass=f=20000:poles=1,acompressor=threshold=-20dB:ratio=2.0:attack=20:release=100"
            SOFTCLIP_SETTINGS="asoftclip=type=atan:threshold=0.95:output=1.0"
            LFE_HP_FREQ="35"
            LFE_LP_FREQ="110"
            LFE_EQ_PARAMS="equalizer=f=40:width_type=q:w=1.2:g=2.5,equalizer=f=70:width_type=q:w=1.8:g=1.5"
            if check_stereotools_support; then
                SOUNDSTAGE_FILTER="stereotools=mode=lr>lr:slev=1.5:sbal=0.0:mlev=0.02:mpan=0.0:base=0.8:delay=20.0:phase=0.0"
                echo "🎭 Soundstage avanzato (stereotools) configurato per film" >&2
            else
                SOUNDSTAGE_FILTER="extrastereo=m=1.2"
                echo "🎭 Soundstage base (extrastereo) configurato per film" >&2
            fi
            SC_ATTACK="5"           # Ridotto da 8 per iniziare l'attenuazione più rapidamente
            SC_RELEASE="150"        # Ridotto da 250 per un rilascio più veloce
            SC_THRESHOLD="-28dB"    # Aumentato da -30dB per iniziare l'attenuazione prima
            SC_RATIO="6.0"          # Aumentato da 3.5 per un'attenuazione più pronunciata
            SC_MAKEUP="0dB"  
            ;;
        
        serie)
            VOICE_VOL="10.2"
            HP_FREQ="120"
            LP_FREQ="7800"
            SURROUND_VOL="4.2"
            LFE_VOL="0.16"
            FC_EQ_PARAMS="equalizer=f=2200:width_type=q:w=1.7:g=3,equalizer=f=2800:width_type=q:w=1.2:g=2.2,equalizer=f=300:width_type=q:w=2:g=-2"
            COMPRESSOR_SETTINGS="acompressor=threshold=-18dB:ratio=4.2:attack=12:release=200:makeup=2.0dB"
            FRONT_FILTER="highpass=f=28:poles=2,lowpass=f=18000:poles=1,acompressor=threshold=-20dB:ratio=2.0:attack=20:release=100"
            SOFTCLIP_SETTINGS="asoftclip=type=atan:threshold=0.97:output=1.0"
            LFE_HP_FREQ="38"
            LFE_LP_FREQ="108"
            LFE_EQ_PARAMS="equalizer=f=45:width_type=q:w=1.2:g=2.2,equalizer=f=80:width_type=q:w=1.5:g=1"
            if check_stereotools_support; then
                SOUNDSTAGE_FILTER="stereotools=mode=lr>lr:slev=1.2:sbal=0.0:mlev=0.02:mpan=0.0:base=0.6:delay=15.0:phase=0.0"
                echo "🎭 Soundstage avanzato (stereotools) configurato per serie" >&2
            else
                SOUNDSTAGE_FILTER="extrastereo=m=0.8"
                echo "🎭 Soundstage base (extrastereo) configurato per serie" >&2
            fi
            SC_ATTACK="10"       
            SC_RELEASE="280"    
            SC_THRESHOLD="-29dB" 
            SC_RATIO="3.2"       
            SC_MAKEUP="1.5dB"   
            ;;
        
        tv)
            VOICE_VOL="7.8"
            HP_FREQ="400"
            LP_FREQ="5000"
            SURROUND_VOL="3.8"
            LFE_VOL="0.16"
            FC_EQ_PARAMS="equalizer=f=2000:width_type=q:w=1.5:g=2.5,equalizer=f=3000:width_type=q:w=1.2:g=2,equalizer=f=300:width_type=q:w=2:g=-2"
            COMPRESSOR_SETTINGS="acompressor=threshold=-16dB:ratio=3.8:attack=10:release=180:makeup=2.1dB"
            FRONT_FILTER="highpass=f=100:poles=1,lowpass=f=8000:poles=1,acompressor=threshold=-18dB:ratio=2.2:attack=15:release=120"
            SOFTCLIP_SETTINGS="asoftclip=type=tanh:threshold=0.9:output=0.95"
            LFE_HP_FREQ="40"
            LFE_LP_FREQ="100"
            LFE_EQ_PARAMS="equalizer=f=50:width_type=q:w=1.5:g=2"
            DENOISE_FILTER="afftdn=nr=20:nf=-42:tn=1,anlmdn=s=0.0001:p=0.002:r=0.005"
            SC_ATTACK="15"
            SC_RELEASE="350"
            SC_THRESHOLD="-35dB"
            SC_RATIO="6.0"
            SC_MAKEUP="0dB" 
            ;;
        
        cartoni)
            VOICE_VOL="10.0"
            HP_FREQ="90"
            LP_FREQ="9000"
            SURROUND_VOL="4.2"
            LFE_VOL="0.16"
            FC_EQ_PARAMS="equalizer=f=2500:width_type=q:w=1.5:g=2.5,equalizer=f=3500:width_type=q:w=1.2:g=2"
            COMPRESSOR_SETTINGS="acompressor=threshold=-17dB:ratio=3.5:attack=10:release=160:makeup=2.0dB"
            FRONT_FILTER="highpass=f=20:poles=2,lowpass=f=21000:poles=1,acompressor=threshold=-15dB:ratio=1.8:attack=25:release=150"
            SOFTCLIP_SETTINGS="asoftclip=type=sin:threshold=0.98:output=1.0"
            LFE_HP_FREQ="30"
            LFE_LP_FREQ="120"
            LFE_EQ_PARAMS="equalizer=f=30:width_type=q:w=1:g=1.5,equalizer=f=80:width_type=q:w=1.5:g=1"
            SC_ATTACK="8"
            SC_RELEASE="200"
            SC_THRESHOLD="-28dB"
            SC_RATIO="3.5"
            SC_MAKEUP="2dB"
            ;;
        
        *) echo "❌ Preset '$preset_choice' non valido!" >&2; exit 1;;
    esac

    ENC="$CODEC"; EXTRA=""
    if [[ "${CODEC,,}" == "dts" ]]; then
        EXTRA="-strict -2 -ar 48000 -channel_layout 5.1(side) -compression_level 2"
        echo "ℹ️ Adattamento parametri per codec DTS" >&2
    fi

    TITLE="ClearVoice $VERSION ($preset_choice) - $CODEC $BR"
}
# Funzione per applicare il resampling con soxr se disponibile
apply_soxr_resampling() {
    local soxr_params=""
    if ffmpeg -filters 2>&1 | grep -q soxr; then
        case "$PRESET" in
            film) soxr_params=":precision=28";;
            serie|tv) soxr_params=":precision=20";;
            cartoni) soxr_params=":precision=15";;
        esac
        echo "aresample=resampler=soxr${soxr_params}"
    else
        echo "aresample=resampler=swr"
    fi
}
# Funzione per verificare se FFmpeg supporta il filtro sidechain
check_sidechain_support() {
    ffmpeg -filters 2>&1 | grep -q sidechaincompress
}
# Funzione per verificare se FFmpeg supporta StereoTools
check_stereotools_support() {
    ffmpeg -filters 2>&1 | grep -q "stereotools"
}

# FILTERGRAPH CORRETTO
build_audio_filter() {
    local file="$1"
    echo "🎯 Configurazione audio attiva:" >&2
    echo "🔊 Voice: +${VOICE_VOL}dB | LFE Vol: ${LFE_VOL}x | Surround Vol: ${SURROUND_VOL}x" >&2
    echo "🎞️ Codec: $ENC ($BR) | Preset: $PRESET" >&2
       
    # Gestisce layout specifico per DTS
    local channel_layout="5.1"
    if [[ "${CODEC,,}" == "dts" ]]; then
        channel_layout="5.1(side)"
    fi
    
    # Inizializza il filtro audio
    local filter_graph="[0:a]channelsplit=channel_layout=${channel_layout}[FL_orig][FR_orig][FC][LFE_orig][BL][BR];"

    # Determina se applicare soundstage
    local apply_soundstage="false"
    if [[ ("$PRESET" == "film" || "$PRESET" == "serie") && -n "${SOUNDSTAGE_FILTER:-}" ]]; then
        apply_soundstage="true"
        echo "🎭 Soundstage attivo per preset $PRESET" >&2
    fi

    # CANALE CENTRALE (VOCE) - Processamento sempre presente
    local fc_filters=""
    [[ -n "$DENOISE_FILTER" ]] && fc_filters+="${DENOISE_FILTER},"
    fc_filters+="highpass=f=${HP_FREQ},lowpass=f=${LP_FREQ}"
    [[ -n "$FC_EQ_PARAMS" ]] && fc_filters+=",${FC_EQ_PARAMS}"
    fc_filters+=",${COMPRESSOR_SETTINGS}"
    fc_filters+=",volume=${VOICE_VOL}dB"
    fc_filters+=",alimiter=level_in=1:level_out=0.95"
    fc_filters+=",${SOFTCLIP_SETTINGS}"
    filter_graph+="[FC]${fc_filters}[center_out];"

    # DUCKING - Crea sidechain dalla voce processata
    if [[ "$DUCKING_ENABLED" == "true" ]]; then
        echo "🎛️ Ducking multicanale attivo - Controllo dinamico basato su voce" >&2
        filter_graph+="[center_out]asplit=2[center_final][voice_sidechain];"
        # Inverte la logica del sidechain per correggere il ducking     
        filter_graph+="[voice_sidechain]highpass=f=200,lowpass=f=3800,volume=10dB,acompressor=threshold=-30dB:ratio=4:attack=5:release=80,volume=12dB[sidechain_control];"
    else
        filter_graph+="[center_out]acopy[center_final];"
        echo "⚠️ Ducking non disponibile" >&2
    fi

    # CANALI FRONTALI (FL/FR) - Con ducking opzionale
    local fl_fr_filters=""
    [[ -n "$FRONT_FILTER" ]] && fl_fr_filters+="${FRONT_FILTER},"
    [[ -n "$FLFR_EQ_PARAMS" ]] && fl_fr_filters+="${FLFR_EQ_PARAMS},"
    fl_fr_filters+="volume=${FRONT_VOL}"
    [[ "$FRONT_DELAY_SAMPLES" != "0" ]] && fl_fr_filters+=",adelay=${FRONT_DELAY_SAMPLES}"
    fl_fr_filters="${fl_fr_filters%,}"
    # Aggiunge il filtro di soft clipping
    if [[ "$DUCKING_ENABLED" == "true" ]]; then
        # Conversione threshold da dB a valore lineare
        local sc_threshold_numeric
        if [[ "$SC_THRESHOLD" =~ ^-?[0-9]+dB$ ]]; then
            local db_value
            db_value=$(echo "$SC_THRESHOLD" | sed 's/dB$//')
            sc_threshold_numeric=$(awk "BEGIN { printf \"%.3f\", 10^($db_value/20) }")
        else
            sc_threshold_numeric="0.3"
        fi
        # Aggiunge i filtri per FL e FR
        if [[ "$apply_soundstage" == "true" ]]; then
            # Con soundstage e ducking
            filter_graph+="[FL_orig]${fl_fr_filters}[fl_pre];"
            filter_graph+="[FR_orig]${fl_fr_filters}[fr_pre];"
            # Applica ducking PRIMA del soundstage
            filter_graph+="[fl_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=0dB:link=maximum[fl_ducked];"
            filter_graph+="[fr_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=0dB:link=maximum[fr_ducked];"
            # Poi applica soundstage ai canali ducked
            filter_graph+="[fl_ducked][fr_ducked]amerge=inputs=2,${SOUNDSTAGE_FILTER},pan=stereo|c0=c0|c1=c1,asplit=2[fl_out][fr_out];"
        else
            # Solo ducking senza soundstage
            filter_graph+="[FL_orig]${fl_fr_filters}[fl_pre];"
            filter_graph+="[FR_orig]${fl_fr_filters}[fr_pre];"
            filter_graph+="[fl_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=0dB:link=maximum[fl_ducked];"
            filter_graph+="[fr_pre][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}:makeup=0dB:link=maximum[fr_ducked];"
        fi
    else
        # Senza ducking - comportamento originale
        if [[ "$apply_soundstage" == "true" ]]; then
            filter_graph+="[FL_orig]${fl_fr_filters}[fl_pre];"
            filter_graph+="[FR_orig]${fl_fr_filters}[fr_pre];"
            filter_graph+="[fl_pre][fr_pre]amerge=inputs=2,${SOUNDSTAGE_FILTER},pan=stereo|c0=c0|c1=c1,asplit=2[fl_out][fr_out];"
        else
            filter_graph+="[FL_orig]${fl_fr_filters}[fl_out];"
            filter_graph+="[FR_orig]${fl_fr_filters}[fr_out];"
        fi
    fi
    # CANALE LFE - Con ducking opzionale
    local lfe_filters="highpass=f=${LFE_HP_FREQ}:poles=${LFE_CROSS_POLES},lowpass=f=${LFE_LP_FREQ}:poles=${LFE_CROSS_POLES}"
    [[ -n "$LFE_EQ_PARAMS" ]] && lfe_filters+=",${LFE_EQ_PARAMS}"
    lfe_filters+=",volume=${LFE_VOL}"
    filter_graph+="[LFE_orig]${lfe_filters}[lfe_processed];"
    # Aggiunge il filtro di soft clipping
    if [[ "$DUCKING_ENABLED" == "true" ]]; then
        filter_graph+="[lfe_processed][sidechain_control]sidechaincompress=threshold=${sc_threshold_numeric}:ratio=${SC_RATIO}:attack=${SC_ATTACK}:release=${SC_RELEASE}[lfe_out];"
    else
        filter_graph+="[lfe_processed]acopy[lfe_out];"
    fi
    # CANALI SURROUND - Processamento standard
    local bl_br_filters="acompressor=threshold=0.3:ratio=2.5:attack=20:release=350,asoftclip=threshold=0.95"
    bl_br_filters+=",volume=${SURROUND_VOL}dB"
    [[ "$SURROUND_DELAY_SAMPLES" != "0" ]] && bl_br_filters+=",adelay=${SURROUND_DELAY_SAMPLES}"
    # Aggiunge il filtro di soft clipping
    filter_graph+="[BL]${bl_br_filters}[bl_out];"
    filter_graph+="[BR]${bl_br_filters}[br_out];"
    # JOIN FINALE con layout corretto
    local soxr_filter; soxr_filter=$(apply_soxr_resampling)
    filter_graph+="[fl_out][fr_out][center_final][lfe_out][bl_out][br_out]join=inputs=6:channel_layout=${channel_layout}[joined];"
    filter_graph+="[joined]${soxr_filter}[out]"

    echo "$filter_graph"
}
# Funzione principale per processare i file
process_file() {
    local file="$1"
    local out="${file%.*}_${PRESET}_clearvoice${VERSION}.mkv"
    [[ "$OVERWRITE" == "true" ]] && out="$file"
    local filter; filter=$(build_audio_filter "$file")
    echo "▶️ Processing: $file"
    # Controlla se il file di output esiste già
    if ! ask_overwrite "$out"; then
        FAILED_FILES+=("$file")
        return 1
    fi
    # Verifica se il file di output esiste già
    local audio_streams
    audio_streams=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$file" 2>/dev/null | wc -l)
    # Se non ci sono stream audio, salta il file
    local map_args=(-map 0:v -map "[out]")
    local codec_args=(-c:v copy -c:a:0 "$ENC" -b:a:0 "$BR")
    # Aggiunge codec e bitrate per il primo stream audio
    if [[ -n "$EXTRA" ]]; then
        local extra_array
        read -ra extra_array <<< "$EXTRA"
        codec_args+=("${extra_array[@]}")
    fi
    # Aggiunge mappatura e codec per gli altri stream audio
    for ((i=0; i<audio_streams; i++)); do
        map_args+=(-map "0:a:$i")
        codec_args+=(-c:a:$((i+1)) copy)
    done
    # Aggiunge il filtro di resampling se necessario
    local subtitle_streams
    subtitle_streams=$(ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$file" 2>/dev/null | wc -l)
    [[ $subtitle_streams -gt 0 ]] && map_args+=(-map 0:s) && codec_args+=(-c:s copy)
    # Aggiunge la mappatura per il filtro audio
    local disposition_args=()
    disposition_args+=(-disposition:a:0 default)
    for ((i=1; i<audio_streams; i++)); do
        disposition_args+=(-disposition:a:$i 0)
    done
    # Aggiunge metadata per il primo stream audio
    local metadata_args=()
    metadata_args+=(-metadata:s:a:0 title="Clearvoice - $PRESET ($CODEC)")
    metadata_args+=(-metadata:s:a:0 language="ita")
    for ((i=1; i<audio_streams; i++)); do
        metadata_args+=(-metadata:s:a:$i title="Audio Originale $i")
        metadata_args+=(-metadata:s:a:$i language="ita")
    done
    # Aggiunge metadata per i sottotitoli se presenti
    ffmpeg -y -threads "$DEFAULT_THREADS" -i "$file" \
           -filter_complex "$filter" \
           "${map_args[@]}" "${codec_args[@]}" \
           "${disposition_args[@]}" "${metadata_args[@]}" \
           -metadata title="$TITLE" "$out" || {
        echo "❌ Errore nel processing di $file" >&2
        FAILED_FILES+=("$file")
        return 1
    }

    PROCESSED_FILES_INFO+=("$file -> $out")
    echo "✅ Completato: $out" >&2
}
# Funzione per stampare un riepilogo al termine del processing
print_summary() {
    echo "===================================="
    echo " ClearVoice $VERSION - SUMMARY "
    echo "===================================="
    echo "Totale file validati: ${#VALIDATED_FILES_GLOBAL[@]}"
    echo "File scartati per formato incompatibile:"
    echo " Mono: $MONO_COUNT | Stereo: $STEREO_COUNT | 7.1: $SURROUND71_COUNT | Altri: $OTHER_FORMAT_COUNT"
    echo "File processati con successo:"
    for info in "${PROCESSED_FILES_INFO[@]}"; do echo " ✅ $info"; done
    if [[ "${#FAILED_FILES[@]}" -gt 0 ]]; then
        echo "❌ File falliti durante l'elaborazione:"
        for f in "${FAILED_FILES[@]}"; do echo " ❌ $f"; done
    fi
    echo "⏱️ Tempo totale elaborazione: $(( $(date +%s) - $TOTAL_START_TIME )) secondi"
    echo "🔧 Preset utilizzato: $PRESET | Codec: $CODEC | Bitrate: $BR"
    echo "🎚️ LFE Ducking: $([ "$DUCKING_ENABLED" == "true" ] && echo "ATTIVO" || echo "NON DISPONIBILE")"
    echo "🇮🇹 Equalizzazione ottimizzata per lingua italiana applicata"
    echo "📊 Soundstage: $([ "$PRESET" == "film" ] || [ "$PRESET" == "serie" ] && echo "ATTIVO" || echo "DISATTIVATO")"
    echo "📋 Tracce multiple e sottotitoli preservati"
    echo "🏷️ Metadata e labeling tracce applicato"
    echo "========================================="
}
# Funzione principale che gestisce l'intero processo
main() {
    echo "🎬 ClearVoice $VERSION - Avvio processing..."
    # Controlla la versione di FFmpeg
    check_ffmpeg_version
    parse_arguments "$@"
    set_preset_params "$PRESET"
    # Regolazione condizionale del LFE in base al codec
    if [[ "$PRESET" == "film" ]]; then
        if [[ "${CODEC,,}" == "eac3" ]]; then
            LFE_VOL="0.25"  # Aumentato per eac3
            echo "ℹ️ LFE aumentato per codec eac3 (${LFE_VOL}x)" >&2
        elif [[ "${CODEC,,}" == "dts" ]]; then
            LFE_VOL="0.11"  # Diminuito per dts
            echo "ℹ️ LFE ridotto per codec dts (${LFE_VOL}x)" >&2
        else
            LFE_VOL="0.16"  # Valore predefinito per altri codec
        fi
    fi
    # Controlla se il codec è supportato
    if check_sidechain_support; then
        DUCKING_ENABLED="true"
        echo "✅ Ducking LFE disponibile e attivato."
    else
        DUCKING_ENABLED="false"
        echo "⚠️ Ducking LFE non disponibile su questa versione di FFmpeg."
    fi
    # Controlla se StereoTools è supportato
    if check_stereotools_support; then
        echo "✅ StereoTools avanzato disponibile per soundstaging."
    else
        echo "⚠️ StereoTools non disponibile - usando extrastereo."
    fi
    # Stampa i parametri del preset selezionato
    echo "🎛️ Parametri preset $PRESET:"
    echo " Voice: +${VOICE_VOL}dB | HPF: ${HP_FREQ}Hz | LPF: ${LP_FREQ}Hz"
    echo " LFE: ${LFE_VOL}x | Surround: ${SURROUND_VOL}x"
    echo " Soundstage: ${SOUNDSTAGE_FILTER:-"None"}"

    echo "🔍 Validazione file in corso..."
    for input in "${INPUTS[@]}"; do
        if [[ -f "$input" ]]; then
            validate_file "$input"
        elif [[ -d "$input" ]]; then
            while IFS= read -r -d '' file; do
                validate_file "$file"
            done < <(find "$input" -type f -iname '*.mkv' -print0)
        fi
    done
    # Se non sono stati trovati file validi, esci con errore
    if [[ ${#VALIDATED_FILES_GLOBAL[@]} -eq 0 ]]; then
        echo "❌ Nessun file 5.1 valido trovato!"
        echo " Files found - Mono: $MONO_COUNT | Stereo: $STEREO_COUNT | 7.1: $SURROUND71_COUNT | Altri: $OTHER_FORMAT_COUNT"
        exit 1
    fi
    # Se sono stati trovati file validi, inizia il processing
    echo "🎯 Inizio processing di ${#VALIDATED_FILES_GLOBAL[@]} file..."
    for file in "${VALIDATED_FILES_GLOBAL[@]}"; do
        process_file "$file"
    done

    print_summary
}
# Avvio dello script
main "$@"