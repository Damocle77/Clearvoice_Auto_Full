#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------------
#  CLEARVOICE 0.75 - OTTIMIZZAZIONE AUDIO 5.1 PER LG MERIDIAN SP7 5.1.2 
#  Script avanzato per miglioramento dialoghi e controllo LFE (C)2025
#  Autore: [Sandro "D@mocle77" Sabbioni]
# -----------------------------------------------------------------------------------------------
# DESCRIZIONE:
#   Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE.
#   Specificamente calibrato per sistemi LG Meridian SP7 e soundbar o AVR compatibili.
#
# USO BASE:
#   ./clearvoice075_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
#
# PRESET DISPONIBILI:
#   --film     : Ottimizzato per contenuti cinematografici con action e dialoghi.
#                Parametri: VOICE_VOL=8.5, LFE=0.24, SURR=3.6, COMP=0.35:1.30:40:390
#                Filtri FC: Highpass 115Hz, Lowpass 7900Hz, EQ 2800Hz/3000Hz, Compressore, Softclipper
#                Ideale per: Film d'azione, thriller, drammi con effetti sonori intensi
#
#   --serie    : Bilanciato per serie TV con dialoghi sussurrati e problematici.
#                Parametri: VOICE_VOL=8.6, LFE=0.24, SURR=3.4, COMP=0.32:1.18:50:380
#                Filtri FC: Highpass 120Hz, Lowpass 7600Hz, EQ 2800Hz/3000Hz, Compressore delicato
#                Ideale per: Serie TV, documentari, contenuti con dialoghi difficili
#
#   --cartoni  : Leggero per animazione con preservazione musicale e dinamica.
#                Parametri: VOICE_VOL=8.2, LFE=0.26, SURR=3.5, COMP=0.40:1.15:50:330
#                Filtri FC: Highpass 110Hz, Lowpass 6900Hz, EQ 2800Hz/3000Hz, Compressione minima
#                Ideale per: Cartoni animati, anime, contenuti con colonne sonore elaborate
#
# CODEC SUPPORTATI:
#   eac3      : Enhanced AC3 (DD+), default 768k - Raccomandato per serie TV
#   ac3       : Dolby Digital, default 640k - Compatibilità universale
#   dts       : DTS, default 756k - Qualità premium per film e Blu-ray
#
# ESEMPI D'USO:
#   ./clearvoice075_preset.sh --serie eac3 384k "Serie.mkv"    # Singolo file serie TV
#   ./clearvoice075_preset.sh --film dts 768k *.mkv            # Batch film alta qualità  
#   ./clearvoice075_preset.sh --cartoni ac3 448k               # Tutti i .mkv, preset cartoni
#   ./clearvoice075_preset.sh                                  # Auto: serie, eac3, 384k
#
# ELABORAZIONE:
#   ✓ Separazione e ottimizzazione individuale di ogni canale 5.1
#   ✓ Boost intelligente canale centrale (FC) con EQ specifico SP7
#   ✓ Controllo LFE anti-boom (riduzione 8-20% secondo preset)
#   ✓ Compressione dinamica per intelligibilità senza distorsione
#   ✓ Preservazione stereofonía FL/FR e surround BL/BR
#   ✓ Output: filename_[preset]_clearvoice0.mkv
#
# CARATTERISTICHE TECNICHE:
#   - Gestione robusta file con layout audio "unknown"
#   - Accelerazione hardware GPU quando disponibile
#   - Preservazione video, tracce audio aggiuntive e sottotitoli
#   - Metadata ottimizzati: lingua ITA, traccia predefinita
#   - Dipendenze: ffmpeg 4.0+, awk
#
# VERSIONE: 0.75 | TESTATO SU: LG SP7 5.1.2, Windows 11, ffmpeg 7.x
# -----------------------------------------------------------------------------------------------

set -euo pipefail

# -----------------------------------------------------------------------------------------------
#  CONFIGURAZIONE GLOBALE
# -----------------------------------------------------------------------------------------------
FRONT_VOL=1.0         # Volume canali frontali (FL/FR) - NON MODIFICARE
VERSION="0.75"        # Versione script
MIN_FFMPEG_VER="4.0"  # Versione minima ffmpeg richiesta

# Verifica dipendenze e versioni
for cmd in ffmpeg awk; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Errore: Il comando richiesto '$cmd' non è stato trovato. Assicurati che sia installato e nel PATH." >&2
    exit 1
  fi
done

# -----------------------------------------------------------------------------------------------
#  ANALISI CLI
# -----------------------------------------------------------------------------------------------
PRESET="serie"  # preset di default
CODEC=""; BR=""; INPUTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --film) PRESET="film"; shift;;
    --serie) PRESET="serie"; shift;;
    --cartoni) PRESET="cartoni"; shift;;
    -c) CODEC="$2"; shift 2;;
    -b) BR="$2";   shift 2;;
    -h|--help)
      sed -n '5,22p' "$0"; exit 0;;
    -*) echo "Unknown option $1"; exit 1;;
    *) INPUTS+=("$1"); shift;;
  esac
done

# -----------------------------------------------------------------------------------------------
#  IMPOSTAZIONI PRESET EAC3
# -----------------------------------------------------------------------------------------------
set_preset_params() {
    case "$PRESET" in
        film)
            # PRESET FILM: Bilanciato per contenuti cinematografici
            # Voce presente ma non invadente, LFE controllato per action scenes
            VOICE_VOL=8.5; LFE_VOL=0.24; SURROUND_VOL=3.6  
            VOICE_COMP="0.35:1.30:40:390"  # Compressione moderata
            HP_FREQ=115; LP_FREQ=7900      # Range frequenze voce ottimale
            ;;
        serie)
            # PRESET SERIE TV: Massima intelligibilità dialoghi
            # Ideale per contenuti con dialoghi sussurrati o problematici
            VOICE_VOL=8.6; LFE_VOL=0.24; SURROUND_VOL=3.4
            VOICE_COMP="0.32:1.18:50:380"  # Compressione delicata anti-vibrazione
            HP_FREQ=120; LP_FREQ=7600      # Pulizia maggiore dei bassi
            ;;
        cartoni)
            # PRESET CARTONI: Preserva musicalità e dinamica
            # Bilanciato per voci chiare + colonne sonore elaborate
            VOICE_VOL=8.2; LFE_VOL=0.26; SURROUND_VOL=3.5  
            VOICE_COMP="0.40:1.15:50:330"  # Compressione leggera
            HP_FREQ=110; LP_FREQ=6900      # Range esteso per musica
            ;;
        *) echo "Preset sconosciuto: $PRESET"; exit 1;;
    esac
    # Parsing parametri compressione dinamica   
    IFS=':' read -r VC_THRESHOLD VC_RATIO VC_ATTACK VC_RELEASE <<< "$VOICE_COMP"
    COMPRESSOR_SETTINGS="acompressor=threshold=${VC_THRESHOLD}:ratio=${VC_RATIO}:attack=${VC_ATTACK}:release=${VC_RELEASE}"
    # Soft-clipping per prevenire distorsione digitale
    SOFTCLIP_SETTINGS="asoftclip=type=exp:param=0.7:oversample=8"
}

set_preset_params

# Ripiego posizionale per CODEC e BR
if [[ -z $CODEC && ${#INPUTS[@]} -ge 1 ]]; then
  CODEC="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
if [[ -z $BR && ${#INPUTS[@]} -ge 1 && "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
  BR="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
# Se non sono specificati input, prendi tutti i file .mkv in cartella
if [[ ${#INPUTS[@]} -eq 0 ]]; then
  shopt -s nullglob
  for f in *.mkv; do INPUTS+=("$f"); done
  shopt -u nullglob
fi
[[ ${#INPUTS[@]} -eq 0 ]] && { echo "Error: nessun file o cartella specificato!"; exit 1; }

# -----------------------------------------------------------------------------------------------
#  SELEZIONE CODEC
# -----------------------------------------------------------------------------------------------  
CODEC="${CODEC:-eac3}"
case "${CODEC,,}" in
  eac3) ENC=eac3; BR=${BR:-384k}; TITLE="EAC3 Clearvoice 5.1";;
  ac3)  ENC=ac3;  BR=${BR:-448k}; TITLE="AC3 Clearvoice 5.1";;
  dts)  ENC=dts;  BR=${BR:-768k}; TITLE="DTS Clearvoice 5.1"; EXTRA="-strict -2 -ar 48000";;
  *) echo "Unsupported codec $CODEC"; exit 1;;
esac
EXTRA=${EXTRA:-""}

# -----------------------------------------------------------------------------------------------
#  IMPOSTAZIONI PRESET DTS 
# -----------------------------------------------------------------------------------------------
build_audio_filter() {
    local voice_vol_adj front_vol_adj lfe_vol_adj surround_vol_adj
    local hp_freq=${HP_FREQ} lp_freq=${LP_FREQ}
    
    if [[ "${CODEC,,}" == "dts" ]]; then
        case "$PRESET" in
            film)
                # DTS Film: sub molto più controllato per eliminare boom eccessivo
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.5}") 
                front_vol_adj="0.85"                                     
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.82}")    
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.82}")
                hp_freq=135; lp_freq=7700                                
                ;;
            serie)
                # DTS Serie: sub molto ridotto, voce massima sub minimale
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.0}")
                front_vol_adj="0.80"                                     
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.85}")       
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.78}") 
                hp_freq=130; lp_freq=7500
                ;;
            cartoni)
                # DTS Cartoni: Bilanciamento musicale
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.7}")    
                front_vol_adj="0.87"                                     
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.92}")      
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.85}") 
                hp_freq=125
                ;;
        esac
        
        # Filtro DTS con EQ ottimizzato per SP7
        ADV_FILTER=$(cat <<EOF | tr -d '\n'
[0:a]channelmap=channel_layout=5.1[audio5dot1];
[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},equalizer=f=3000:t=h:width=1000:g=2.5,volume=${voice_vol_adj},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
[FL]volume=${front_vol_adj}[left];
[FR]volume=${front_vol_adj}[right];
[LFE]highpass=f=25,lowpass=f=120,volume=${lfe_vol_adj}[bass];
[BL]volume=${surround_vol_adj}[surroundL];
[BR]volume=${surround_vol_adj}[surroundR];
[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[joined];
[joined]aresample=48000,asetnsamples=n=1152:p=0,aformat=sample_fmts=s32:channel_layouts=5.1[out]
EOF
)
     # ===== RAMO EAC3/AC3: Parametri per codec Dolby =====
    else
        case "$PRESET" in
            film)
                # EAC3/AC3 Film: Voce presente ma non eccessiva
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.2}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.12}")
                ;;
            serie)
                # EAC3/AC3 Serie: Ottimizzato per dialoghi TV
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 1.5}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.08}")
                ;;
            cartoni)
                # EAC3/AC3 Cartoni: Bilanciato per contenuti misti
                voice_vol_adj=$(awk "BEGIN {print $VOICE_VOL + 0.8}")
                front_vol_adj=$(awk "BEGIN {print $FRONT_VOL - 0.02}")
                ;;
        esac
        # Calcolo riduzione LFE specifica per preset
        case "$PRESET" in
            serie)
                # Serie TV: Sub molto controllato per SP7 
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.80}")       # -20% per dialoghi TV
                surround_vol_adj=$(awk "BEGIN {print $SURROUND_VOL * 0.92}")
                ;;
            film)
                # Film: Sub più controllato come richiesto
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.83}")       # -17% bilanciato
                surround_vol_adj=${SURROUND_VOL}
                ;;
            cartoni)
                # Cartoni: LFE leggermente controllato per bilanciamento
                lfe_vol_adj=$(awk "BEGIN {print $LFE_VOL * 0.92}")       # -8% preserva impatto 
                surround_vol_adj=${SURROUND_VOL}
                ;;
            *)
                lfe_vol_adj=${LFE_VOL}  # Fallback sicuro
                surround_vol_adj=${SURROUND_VOL}
                ;;
        esac
        
        # Filtro standard con EQ presenza vocale per SP7
        ADV_FILTER=$(cat <<EOF | tr -d '\n'
[0:a]channelmap=channel_layout=5.1[audio5dot1];
[audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
[FC]highpass=f=${hp_freq},lowpass=f=${lp_freq},equalizer=f=2800:t=h:width=1200:g=3.0,volume=${voice_vol_adj},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
[FL]volume=${front_vol_adj}[left];
[FR]volume=${front_vol_adj}[right];
[LFE]highpass=f=20,lowpass=f=110,volume=${lfe_vol_adj}[bass];
[BL]volume=${surround_vol_adj}[surroundL];
[BR]volume=${surround_vol_adj}[surroundR];
[left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1[out]
EOF
)
    fi
}

build_audio_filter

# -----------------------------------------------------------------------------------------------
#  PROCESSING SU FILES
# -----------------------------------------------------------------------------------------------
PROCESSED_FILES=()

process() {
    local input_file="$1"
    local out="${input_file%.*}_${PRESET}_clearvoice0.mkv"
    
    if [[ ! -f "$input_file" ]]; then
        echo "Errore: File '$input_file' non trovato!" >&2
        return 1
    fi
    
    # ===== RILEVAMENTO TRACCIA AUDIO 5.1 =====
    # Supporta layout standard "5.1" e file con layout "unknown" ma 6 canali
    local channel_layout=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channel_layout -of csv=p=0 "$input_file" 2>/dev/null)
    local channels=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$input_file" 2>/dev/null)

     # Validazione formato audio   
    if [[ "$channel_layout" != "5.1" && "$channels" != "6" ]]; then
        echo "Avviso: '$input_file' non ha audio 5.1 (layout: $channel_layout, canali: $channels), saltato." >&2
        return 1
    fi
    
    # ===== CORREZIONE LAYOUT AUDIO =====
    # Fix per file con layout "unknown" ma effettivamente 5.1
    if [[ "$channel_layout" == "unknown" && "$channels" == "6" ]]; then
        echo "Info: File con 6 canali ma layout sconosciuto, assumo 5.1"
        # Sostituisce channelmap con aformat per forzare il layout
        ADV_FILTER="${ADV_FILTER//channelmap=channel_layout=5.1/aformat=channel_layouts=5.1}"
    fi
    
    echo -e "\n→ Processing: $input_file"
    # Controllo sovrascrittura file output
    if [[ -e "$out" ]]; then
        read -p "Output file '$out' presente! Sovrascrivere? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            echo "Skipping $input_file"
            return 0
        fi
    fi

    # ===== ESECUZIONE FFMPEG =====
    # Parametri ottimizzati per performance e qualità
    ffmpeg -hwaccel auto -y -hide_banner -avoid_negative_ts make_zero -fflags +genpts+discardcorrupt \
        -threads $(nproc 2>/dev/null || echo 4) -filter_threads $(nproc 2>/dev/null || echo 4) \
        -i "$input_file" -filter_complex "$ADV_FILTER" \
        -map 0:v -map "[out]" -map 0:a? -map 0:s? \
        -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
        -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:a:1 copy -c:s copy \
        -movflags +faststart "$out"

    # Verifica risultato elaborazione    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        PROCESSED_FILES+=("$input_file")
        echo "✓ Completato: $out"
        return 0
    else
        echo "✗ Errore durante l'elaborazione di $input_file (exit code: $exit_code)" >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------------------------
#  LOOP SUI FILE DI INPUT
# -----------------------------------------------------------------------------------------------
for path in "${INPUTS[@]}"; do
  if [[ -d $path ]]; then
    shopt -s nullglob
    for f in "$path"/*.mkv; do process "$f"; done
    shopt -u nullglob
  else
    process "$path"
  fi
done

# -----------------------------------------------------------------------------------------------
#  STATISTICHE FINALI E RIEPILOGO
# -----------------------------------------------------------------------------------------------
print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "  CLEARVOICE 0.75 - ELABORAZIONE CORRETTAMENTE COMPLETATA ✓"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Preset utilizzato: $PRESET"
    echo "Codec output: $CODEC ($BR)"
    echo "File processati: ${#PROCESSED_FILES[@]}"
    
    if [[ ${#PROCESSED_FILES[@]} -gt 0 ]]; then
        echo ""
        echo "📁 File elaborati con successo:"
        for file in "${PROCESSED_FILES[@]}"; do
            local output_file="${file%.*}_${PRESET}_clearvoice0.mkv"
            echo "   ✓ $(basename "$file") → $(basename "$output_file")"
        done
        echo ""
        echo "💡 Testa l'audio <Clearvoiced>:"
        echo "   - Il preset '$PRESET' è ottimizzato per questo tipo di contenuto"
        echo "   - Per serie TV o film sussurrati, usa volume TV leggermente più alto"
    else
        echo ""
        echo "⚠️  Nessun file elaborato. Verifica:"
        echo "   - Presenza di file .mkv nella directory"
        echo "   - Tracce audio 5.1 nei file di input"
        echo "   - Permissions di lettura/scrittura nella directory"
    fi
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Chiamata alla funzione di riepilogo
print_summary