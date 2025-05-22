#!/usr/bin/env bash

# -----------------------------------------------------------------------------------------------
#  SINOTTICO CLEARVOICE  
# -----------------------------------------------------------------------------------------------
# DESCRIZIONE:
#   ClearVoice è uno script per l'ottimizzazione audio 5.1.2 con focus sulla chiarezza dei dialoghi
#   e bilanciamento dei canali surround. Ottimizzato per sistemi LG Meridian e compatibili.
#
# USO BASE:
#   ./clearvoice070_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
#
# PRESET DISPONIBILI:
#   --film     : Ottimizzato per film con compressione mirata e maggior dettaglio vocale.
#                Parametri: VOICE_VOL=7.4, LFE=0.30, SURR=3.5, COMP=0.48:1.15:45:450
#                Filtri FC: Highpass 100Hz, Lowpass 7500Hz, Compressore, Softclipper.
#                (DTS Film aggiunge EQ specifici)
#
#   --serie    : Bilanciato per serie TV con compressione media e ottima intelligibilità.
#                Parametri: VOICE_VOL=7.3, LFE=0.29, SURR=3.4, COMP=0.44:1.18:50:400
#                Filtri FC: Highpass 100Hz, Lowpass 7000Hz, Compressore, Softclipper. 
#
#   --cartoni  : Leggero per cartoni animati con compressione minima per colonne sonore.
#                Parametri: VOICE_VOL=6.5, LFE=0.31, SURR=3.6, COMP=0.47:1.12:40:300
#                Filtri FC: Highpass 110Hz, Lowpass 6800Hz, Compressore, Softclipper.
#
# CODEC SUPPORTATI:
#   eac3      : Enhanced AC3 (DD+), default 384k (come da script)
#   ac3       : Dolby Digital, default 448k (come da script)
#   dts       : DTS, default 768k (come da script)
#
# ESEMPI:
#   ./clearvoice070_preset.sh --serie eac3 384k "Serie.mkv"  # Singolo file, preset serie, DD+ 384k
#   ./clearvoice070_preset.sh --film dts 768k                # Tutti i .mkv in dir, preset film, DTS 768k
#   ./clearvoice070_preset.sh --cartoni ac3 448k             # Tutti i .mkv, preset cartoni, AC3 448k
#
# ELABORAZIONE:
#   - Processa file MKV con tracce audio 5.1
#   - Separa e processa individualmente ogni canale audio
#   - Ottimizza il canale centrale (FC) secondo il preset selezionato
#   - Ribilancia i volumi relativi dei canali
#   - Produce un nuovo file con suffisso _[PRESET]_clearvoice0.mkv
#
# NOTE:
#   - Processa file .mkv. Se non specificati, elabora tutti i .mkv nella dir corrente.
#   - Output: file con suffisso _[PRESET]_clearvoice0.mkv. Chiede conferma per sovrascrittura.
#   - Elabora la prima traccia audio 5.1. Questa diventa traccia audio predefinita,
#     lingua "ita", titolo "[CODEC] Clearvoice 5.1".
#   - Video, altre tracce audio e sottotitoli vengono copiati dall'originale.
#   - Per preset "serie", bitrate consigliato per traccia audio processata: >= 384k.
#   - Dipendenze: ffmpeg, awk.
#   - Nota su CUDA: L'accelerazione hardware CUDA non è esplicitamente abilitata
#     da questo script nel comando ffmpeg.
# -----------------------------------------------------------------------------------------------

set -euo pipefail

# -----------------------------------------------------------------------------------------------
#  PARAMETRI COMUNI
# -----------------------------------------------------------------------------------------------
FRONT_VOL=1.0         # Front volume (costante)

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
#  IMPOSTAZIONI PRESET
# -----------------------------------------------------------------------------------------------
case "$PRESET" in
  film)
    # Pipeline parametri film con compressione mirata
    VOICE_VOL=7.4; LFE_VOL=0.30; SURROUND_VOL=3.5; 
    # Compressione aggressiva per film ad alto dinamismo
    VOICE_COMP="0.42:1.25:45:450";;
  serie)
    # Pipeline parametri serie
    VOICE_VOL=7.3; LFE_VOL=0.29; SURROUND_VOL=3.4;
    # Compressione media bilanciata per dialoghi TV
    VOICE_COMP="0.35:1.3:50:400";;
  cartoni)
    # Pipeline parametri cartoni con compressione leggera
    VOICE_VOL=6.8; LFE_VOL=0.31; SURROUND_VOL=3.6;
    # Compressione molto leggera, solo per uniformare
    VOICE_COMP="0.43:1.20:40:300";; 
  *)
    echo "Preset sconosciuto: $PRESET"; exit 1;;
esac

# Parse VOICE_COMP per i parametri del compressore sonoro
IFS=':' read -r VC_THRESHOLD VC_RATIO VC_ATTACK VC_RELEASE <<< "$VOICE_COMP"
COMPRESSOR_SETTINGS="acompressor=threshold=${VC_THRESHOLD}:ratio=${VC_RATIO}:attack=${VC_ATTACK}:release=${VC_RELEASE}"
SOFTCLIP_SETTINGS="asoftclip=type=cubic:oversample=16"

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
#  PIPELINE FILTRI AUDIO
# -----------------------------------------------------------------------------------------------
if [[ "$PRESET" == "film" ]]; then
# Calcoli aritmetici con awk per mantenere la parametrizzazione
  VOICE_VOL_ADJ=$(awk "BEGIN {print $VOICE_VOL + 2.0}") 
  FRONT_VOL_ADJ=$(awk "BEGIN {print $FRONT_VOL - 0.2}") 
  SURROUND_VOL_ADJ=$SURROUND_VOL 

# PIPELINE PER FILM
  ADV_FILTER=$(cat <<EOF | tr -d '\n'
  [0:a]channelmap=channel_layout=5.1[audio5dot1];
  [audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
  [FC]highpass=f=110,lowpass=f=8000,volume=${VOICE_VOL},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
  [FL]volume=$(awk "BEGIN {print $FRONT_VOL - 0.3}")[left];
  [FR]volume=$(awk "BEGIN {print $FRONT_VOL - 0.3}")[right];
  [LFE]volume=${LFE_VOL}[bass];
  [BL]volume=${SURROUND_VOL_ADJ}[surroundL];
  [BR]volume=${SURROUND_VOL_ADJ}[surroundR];
  [left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1[out]
EOF
)

elif [[ "$PRESET" == "serie" ]]; then
# Calcoli aritmetici con awk per mantenere la parametrizzazione
  VOICE_VOL_ADJ=$(awk "BEGIN {print $VOICE_VOL + 0.8}")
  FRONT_VOL_ADJ=$(awk "BEGIN {print $FRONT_VOL - 0.2}")
  SURROUND_VOL_ADJ=$SURROUND_VOL  

# PIPELINE PER SERIE TV
  ADV_FILTER=$(cat <<EOF | tr -d '\n'
  [0:a]channelmap=channel_layout=5.1[audio5dot1];
  [audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];  
  [FC]highpass=f=100,lowpass=f=7800,volume=$(awk "BEGIN {print $VOICE_VOL + 0.2}"),${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
  [FL]volume=0.8[left];
  [FR]volume=0.8[right];
  [LFE]volume=$(awk "BEGIN {print $LFE_VOL * 0.9}")[bass];
  [BL]volume=$(awk "BEGIN {print $SURROUND_VOL_ADJ * 0.95}")[surroundL];
  [BR]volume=$(awk "BEGIN {print $SURROUND_VOL_ADJ * 0.95}")[surroundR];
  [left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1[out]
EOF
)

elif [[ "$PRESET" == "cartoni" ]]; then
# Calcoli aritmetici con awk per mantenere la parametrizzazione
  VOICE_VOL_ADJ=$(awk "BEGIN {print $VOICE_VOL + 0.3}")
  FRONT_VOL_ADJ=$(awk "BEGIN {print $FRONT_VOL - 0.1}") # Questo calcola 0.9 se FRONT_VOL è 1.0
  SURROUND_VOL_ADJ=$SURROUND_VOL  

# PIPELINE PER CARTONI/MUSICAL
  ADV_FILTER=$(cat <<EOF | tr -d '\n'
  [0:a]channelmap=channel_layout=5.1[audio5dot1];
  [audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
  [FC]highpass=f=110,lowpass=f=6800,volume=${VOICE_VOL},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
  [FL]volume=0.9[left];
  [FR]volume=0.9[right];
  [LFE]volume=${LFE_VOL}[bass];
  [BL]volume=${SURROUND_VOL_ADJ}[surroundL];
  [BR]volume=${SURROUND_VOL_ADJ}[surroundR];
  [left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1[out]
EOF
)
fi

# Applica modifiche specifiche per DTS (se selezionato)
if [[ "${CODEC,,}" == "dts" ]]; then
# Regolazione LFE specifica per DTS
  if [[ "$PRESET" == "film" ]]; then
    LFE_BOOST=0.91 # Ulteriore riduzione di 0.02 per film DTS (era 0.93)
  elif [[ "$PRESET" == "serie" ]]; then
    LFE_BOOST=0.92 # Ulteriore riduzione di 0.02 per serie DTS
  else             # Gestisce 'cartoni' e altri eventuali preset DTS
    LFE_BOOST=1.02 # Mantenuto come da logica precedente per 'else'
  fi
  
# Calcola il volume LFE per DTS
  LFE_VOL_DTS=$(awk "BEGIN {print $LFE_VOL * $LFE_BOOST}")

# Determina il volume dei canali frontali per DTS in base al PRESET
  DTS_FRONT_FL_VOLUME=""
  DTS_FRONT_FR_VOLUME=""
  if [[ "$PRESET" == "film" ]]; then
    DTS_FRONT_FL_VOLUME=$(awk "BEGIN {print $FRONT_VOL - 0.3}") 
    DTS_FRONT_FR_VOLUME=$(awk "BEGIN {print $FRONT_VOL - 0.3}") 
  elif [[ "$PRESET" == "serie" ]]; then
    DTS_FRONT_FL_VOLUME="0.75"
    DTS_FRONT_FR_VOLUME="0.75"
  elif [[ "$PRESET" == "cartoni" ]]; then
    DTS_FRONT_FL_VOLUME="0.9" 
    DTS_FRONT_FR_VOLUME="0.9"
  else 
    DTS_FRONT_FL_VOLUME=$(awk "BEGIN {print $FRONT_VOL - 0.3}")
    DTS_FRONT_FR_VOLUME=$(awk "BEGIN {print $FRONT_VOL - 0.3}")
  fi

# Gestione specifica del volume voce per DTS film
  DTS_EFFECTIVE_VOICE_VOL=$VOICE_VOL 
  if [[ "$PRESET" == "film" ]]; then
# Riduce il volume della voce per film DTS per mitigare vibrazioni
    DTS_EFFECTIVE_VOICE_VOL=$(awk "BEGIN {print $VOICE_VOL - 0.3}") # Era -0.4
  elif [[ "$PRESET" == "serie" ]]; then
# Alza il volume della voce per serie DTS
    DTS_EFFECTIVE_VOICE_VOL=$(awk "BEGIN {print $VOICE_VOL + 0.3}") # Era +0.2
  fi
  
# Imposta la frequenza base dell'highpass per DTS
  FC_DTS_HP_FREQ=100 
  if [[ "$PRESET" == "film" ]]; then 
      # Per film DTS, usa un highpass più aggressivo
      FC_DTS_HP_FREQ=135 
  elif [[ "$PRESET" == "serie" ]]; then
      FC_DTS_HP_FREQ=100 
  elif [[ "$PRESET" == "cartoni" ]]; then
      FC_DTS_HP_FREQ=110
  fi

  FC_DTS_FILTERS_BASE="highpass=f=${FC_DTS_HP_FREQ}"

# Aggiunge Lowpass e EQ specifici per preset DTS
  if [[ "$PRESET" == "film" ]]; then 
      FC_DTS_FILTERS="${FC_DTS_FILTERS_BASE},lowpass=f=7800"
  elif [[ "$PRESET" == "serie" ]]; then 
      FC_DTS_FILTERS="${FC_DTS_FILTERS_BASE},lowpass=f=7500"
  elif [[ "$PRESET" == "cartoni" ]]; then
      FC_DTS_FILTERS="${FC_DTS_FILTERS_BASE},lowpass=f=6800"
  else # Fallback nel caso di preset non gestito (improbabile)
      FC_DTS_FILTERS="${FC_DTS_FILTERS_BASE},lowpass=f=7000"
  fi
# PIPELINE PER DTS (o preset corrente se DTS)
FILTER_PRE=$(cat <<EOF | tr -d '\n'
  [0:a]channelmap=channel_layout=5.1[audio5dot1];
  [audio5dot1]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR];
  [FC]${FC_DTS_FILTERS},volume=${DTS_EFFECTIVE_VOICE_VOL},${COMPRESSOR_SETTINGS},${SOFTCLIP_SETTINGS}[center];
  [FL]volume=${DTS_FRONT_FL_VOLUME}[left];
  [FR]volume=${DTS_FRONT_FR_VOLUME}[right];
  [LFE]volume=${LFE_VOL_DTS}[bass];
  [BL]volume=$(awk "BEGIN {print $SURROUND_VOL * 0.75}")[surroundL];
  [BR]volume=$(awk "BEGIN {print $SURROUND_VOL * 0.75}")[surroundR];
EOF
)
# Aggiunge il join finale per DTS  
  # Costruisce la parte finale del filtro complesso per DTS
  ADV_FILTER_SUFFIX="  [left][right][center][bass][surroundL][surroundR]join=inputs=6:channel_layout=5.1"
  ADV_FILTER_SUFFIX+=":map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[joined];"
  ADV_FILTER_SUFFIX+=" [joined]aresample=48000"
  ADV_FILTER_SUFFIX+=",asetnsamples=n=1152:p=0"
  ADV_FILTER_SUFFIX+=",aformat=sample_fmts=s32:channel_layouts=5.1[out]"
# Fine catena e output finale
  ADV_FILTER="${FILTER_PRE}${ADV_FILTER_SUFFIX}"
fi

# -----------------------------------------------------------------------------------------------
#  PROCESSING SU FILES
# -----------------------------------------------------------------------------------------------
PROCESSED_FILES=()
# Array per tracciare i file elaborati
process() {
  local input_file="$1"
  local out="${input_file%.*}_${PRESET}_clearvoice0.mkv"
  echo -e "\n→ Processing: $input_file"
# Verifica se il file di output esiste già
  if [[ -e "$out" ]]; then
    read -p "Output file '$out' file presente! Sovrascrivere? (y/n): " choice
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
      echo "Skipping $input_file"
      return
    fi
  fi
# Applica i filtri e ricodifica la traccia mantenendo l'originale (opzionale ffmpeg -hwaccel cuda)
  ffmpeg -y -hide_banner -avoid_negative_ts make_zero -fflags +genpts \
    -threads 0 -filter_threads 0 -filter_complex_threads 0 \
    -i "$input_file" -filter_complex "$ADV_FILTER" \
    -map 0:v -map "[out]" -map 0:a? -map 0:s? \
    -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
    -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:a:1 copy -c:s copy "$out"
# Aggiunge il file elaborato all'array
  PROCESSED_FILES+=("$input_file")
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
# Stampa il messaggio di completamento
echo "Processo Clearvoice completato!"

# Stampa il sinottico dei file elaborati
if [[ ${#PROCESSED_FILES[@]} -gt 0 ]]; then
  echo -e "\nElenco dei file elaborati:"
  for file in "${PROCESSED_FILES[@]}"; do
    echo " - Elaborato file: $file"
  done
else
  echo "Nessun file elaborato."
fi