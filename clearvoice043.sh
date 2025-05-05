#!/usr/bin/env bash
# ------------------------------------------------------------------
# CLEARVOICE - 5.1 dialog-enhancer (SP7-optimized)
# ------------------------------------------------------------------
#  ===== ESEMPIO SINOTTICO D'USO =========================================
# ./clearvoice04.sh [dts|eac3|ac3] 384k "Film.mkv"  (singolo file in EAC3 384 kbps)
# ./clearvoice04.sh [dts|eac3|ac3] 448k  (tutti i .mkv in cartella in AC3 448 kbps)
# ./clearvoice04.sh --no-keep-old dts 768k "Doc.mkv"  (esclusione tracce originali)
# KEEP_OLD (true/false) modificabile anche nel blocco PARAMETRI
# ========================================================================

set -euo pipefail

# =========================================================================
#  SINOTTICO OTTIMIZZAZIONE CLEARVOICE per LGSP7 5.1.2 (2025-05)
# =========================================================================
# VOCE (Center):
#   VOICE_VOL = 4.25   	# circa +12.6 dB sul centro (intelligibile anche a volumi bassi)
#   HPF 100 Hz         	# taglia i rimbombi infrasonici
#   COMPAND            	# -35dB 20dB lift, gain 6dB (rialza i passaggi deboli)
#   COMPRESSOR 4:1    	# soglia -22dB, attack 6ms (controlla i picchi)
#   LIMITER 0.92       	# ceiling -0.8 dBFS (mai clipping)
#   DE-ESS / PRESENCE  	# EQ 6kHz -3dB, 4kHz -0.8dB, 2kHz +1dB, 1.5kHz +1.2dB
#   BODY               	# EQ 300 Hz +0.1 dB, 250 Hz +0.8 dB – calore senza impasto
#
# SUBWOOFER (LFE):
#   LFE_VOL  = 0.58     # ≈ –4.7 dB – “gentle woofer”
#   HPF 28 Hz          	# lascia un velo di vibrato, taglia l’infrabasso spurio
#   EQ  40 Hz –5 dB    	# riduce i rimbombi
#   EQ  60 Hz +1.5 dB  	# mid‑bass caldo
#   EQ  80 Hz +1.0 dB  	# punch aggiuntivo
#   LPF 95 Hz          	# roll‑off dolce (fino a ~100 Hz)
#   Shelf 75 Hz +2 dB  	# corpo tenue
#   LIMITER 0.75       	# attack 3 ms / release 200 ms – smorza i transienti duri
#
# FRONT L/R:
#   FRONT_VOL = 1.12   		# +1 dB – driver da 45 W, senza bass‑shelf
#
# SURROUND L/R:
#   SURROUND_VOL = 2.24 	# +7 dB – rear avvolgenti ma non invadenti
#
# SOUND‑STAGE (delay):
#   Front  :  FL 8 ms  –  FR 4 ms   → scena larga, dialogo centrato
#   Rear   :  SL 8 ms  –  SR 4 ms   → retro avvolgente e coerente
#
# GESTIONE CANALI:
#   • Rimappa 5.1(side) ↔︎ 5.1(rear) per piena compatibilità
#   • Split → process singolarmente → join in 5.1
#
# MOTIVAZIONE:
#   ▸ Il sub da 220 W gestisce in scioltezza < 100 Hz; tagli e limiter evitano vibrazioni.
#   ▸ I piccoli driver front/surround (45 W) lavorano solo > 100 Hz → massima chiarezza.
#   ▸ Delay asimmetrici (8/4 ms) sfruttano la larghezza ~1 m della barra, ampliando il palco.
#   ▸ Compand+compressor rendono i dialoghi sempre presenti; EQ mirata li mantiene caldi ma nitidi.
#   ▸ Configurazione universale: action, sci‑fi, horror e musical Disney suonano bilanciati.
# =========================================================================

# =========================================================================

# ----------------------------
#  TUNING PARAMETRI
# ----------------------------
KEEP_OLD=true         # true = mantieni l'audio originale, false = solo Clearvoice
VOICE_VOL=4.25        # circa +12.6dB su dialoghi
LFE_VOL=0.58          # circa -4.7dB su subwoofer
LFE_LIMIT=0.75        # limitazione ceiling LFE (0-1)
FRONT_VOL=1.12        # +1dB sui frontali L/R (no bass-shelf)
SURROUND_VOL=2.24     # +6dB sui surround (pure volume boost)
FL_DELAY=8            # ms front-left ritardo (wide sound-stage)
FR_DELAY=4            # ms front-right ritardo
SL_DELAY=4            # ms surround-left ritardo (wide rear)
SR_DELAY=2            # ms surround-right ritardo

# ----------------------------
#  ANALISI CLI
# ----------------------------
CODEC=""; BR=""; INPUTS=(); EXTRA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c) CODEC="$2"; shift 2;;
    -b) BR="$2";   shift 2;;
    --no-keep-old) KEEP_OLD=false; shift;;
    --keep-old)    KEEP_OLD=true;  shift;;
    -h|--help)
      sed -n '5,22p' "$0"; exit 0;;
    -*) echo "Unknown option $1"; exit 1;;
    *) INPUTS+=("$1"); shift;;
  esac
done

# ripiego posizionale
if [[ -z $CODEC && ${#INPUTS[@]} -ge 1 ]]; then
  CODEC="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi
if [[ -z $BR && ${#INPUTS[@]} -ge 1 && "${INPUTS[0]}" =~ ^[0-9]+[kK]$ ]]; then
  BR="${INPUTS[0]}"; INPUTS=("${INPUTS[@]:1}")
fi

# per impostazione predefinita tutti i file .mkv in cwd se non vengono specificati input
if [[ ${#INPUTS[@]} -eq 0 ]]; then
  shopt -s nullglob
  for f in *.mkv; do INPUTS+=("$f"); done
  shopt -u nullglob
fi
[[ ${#INPUTS[@]} -eq 0 ]] && { echo "Error: no input file or directory specified"; exit 1; }

# selezione codec
CODEC="${CODEC:-eac3}"
case "${CODEC,,}" in
  eac3) ENC=eac3; BR=${BR:-384k}; TITLE="EAC3 Clearvoice 5.1";;
  ac3)  ENC=ac3;  BR=${BR:-448k}; TITLE="AC3 Clearvoice 5.1";;
  dts)  ENC=dts;  BR=${BR:-768k}; TITLE="DTS Clearvoice 5.1"; EXTRA="-strict -2 -ar 48000";;
  *) echo "Unsupported codec $CODEC"; exit 1;;
esac

# ----------------------------
#  PIPELINE FILTRI AUDIO
# ----------------------------
ADV_FILTER=$(cat <<EOF
[0:a]channelmap=channel_layout=5.1:channel_layout=5.1,channelsplit=channel_layout=5.1[fl][fr][fc][lfe][sl][sr];

[fc]highpass=f=100,compand=attacks=5:decays=200:points=-80/-80|-35/-20|-15/-8|0/0:soft-knee=6:gain=6,\
  acompressor=threshold=-22dB:ratio=4:attack=6:release=120:knee=4dB,\
  alimiter=limit=0.92:attack=3:release=30,\
  equalizer=f=6000:t=q:w=1.6:g=-3,\
  equalizer=f=4000:t=q:w=1.2:g=-0.8,\
  equalizer=f=3500:t=q:w=1.2:g=+0.5,\
  equalizer=f=2000:t=q:w=1.2:g=+0.8,\
  equalizer=f=1500:t=q:w=1:g=+1.2,\
  equalizer=f=300:t=q:w=1.2:g=+0.1,\
  equalizer=f=250:t=q:w=1.2:g=+0.8,\
  volume=${VOICE_VOL}[fc_p];

[lfe]highpass=f=28:t=q:w=1.2,\
  equalizer=f=40:t=q:w=1.0:g=-5,\
  equalizer=f=60:t=q:w=1.0:g=+1.5,\
  equalizer=f=80:t=q:w=1.5:g=+1.0,\
  lowpass=f=100,\
  bass=g=2:f=75:t=q:w=1.2,\
  volume=${LFE_VOL},\
  alimiter=limit=${LFE_LIMIT}:attack=3:release=200[lfe_p];

[fl]adelay=delays=${FL_DELAY}:all=1,volume=${FRONT_VOL}[fl_p];
[fr]adelay=delays=${FR_DELAY}:all=1,volume=${FRONT_VOL}[fr_p];

[sl]adelay=delays=${SL_DELAY}:all=1,volume=${SURROUND_VOL}[sl_p];
[sr]adelay=delays=${SR_DELAY}:all=1,volume=${SURROUND_VOL}[sr_p];

[fl_p][fr_p][fc_p][lfe_p][sl_p][sr_p]join=inputs=6:channel_layout=5.1[joined];
[joined]asetpts=PTS-STARTPTS[out]
EOF
)

# ----------------------------
#  PROCESSING SU FILES
# ----------------------------
process() {
  local input_file="$1"
  local out="${input_file%.*}_clearvoice0.mkv"
  echo -e "\n→ Processing: $input_file"
  if [[ -e $out ]]; then
    read -p "Output exists. Overwrite? (y/n): " r
    [[ $r != y ]] && return
  fi

  if [[ "$KEEP_OLD" == true ]]; then
    ffmpeg -y -hide_banner -hwaccel cuda -threads 0 -filter_threads 0 -filter_complex_threads 0 -i "$input_file" -filter_complex "$ADV_FILTER" \
      -map 0:v -map "[out]" -map 0:a? -map 0:s? \
      -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
      -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:a:1 copy -c:s copy "$out"
  else
    ffmpeg -y -hide_banner -hwaccel cuda -threads 0 -filter_threads 0 -filter_complex_threads 0 -i "$input_file" -filter_complex "$ADV_FILTER" \
      -map 0:v -map "[out]" -map 0:s? \
      -metadata:s:a:0 title="$TITLE" -metadata:s:a:0 language=ita -disposition:a:0 default \
      -c:v copy -c:a:0 $ENC $EXTRA -b:a:0 $BR -c:s copy "$out"
  fi
}

# ----------------------------
#  LOOP CATENA FILES
# ----------------------------
for path in "${INPUTS[@]}"; do
  if [[ -d $path ]]; then
    shopt -s nullglob
    for f in "$path"/*.mkv; do process "$f"; done
    shopt -u nullglob
  else
    process "$path"
  fi
done

echo "All done!"
