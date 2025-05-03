#!/bin/bash
chmod +x "$0"

# ===================================================
#        SCRIPT DI ELABORAZIONE AUDIO 5.1
# ===================================================
# Descrizione:
# Questo script elabora file MKV contenenti audio 5.1 per adattarli a una
# soundbar LG Meridian SP7 5.1.2. Le principali operazioni eseguite dallo script sono:
#
# 1. Separare i 6 canali audio (Front Left, Front Right, Centrale/Voce, LFE, Surround Left, Surround Right)
#    utilizzando il filtro "channelsplit".
#
# 2. Applicare ritardi personalizzati a ciascuno dei canali frontali e surround per creare
#    uno soundstage spaziale (utilizzando "adelay") e regolare il loro livello tramite "volume".
#
# 3. Processare il canale centrale (voce) con una catena di filtri:
#    - Rimozione delle frequenze basse indesiderate tramite "highpass f=90".
#    - Normalizzazione del parlato tramite "speechnorm".
#    - Modellazione del timbro applicando una serie di equalizzazioni.
#    - Regolazione del volume con la variabile VOICE_VOL.
#
# 4. Processare il canale LFE (subwoofer) con:
#    - Un filtro "lowpass" per limitare le frequenze alte.
#    - Equalizzazione specifica per attenuare il sub.
#    - Compressione e limitazione per prevenire picchi e distorsioni,
#      con controllo tramite le variabili LFE_VOL e LFE_LIMIT.
#
# 5. Unire tutti i canali processati in un unico flusso con "join" e applicare
#    ulteriori processi se necessari.
#
# 6. Mappare le tracce video, audio, sottotitoli ed eventuali capitoli.
#
# Utilizzo:
#   ./clearvoice0.sh <codec> <bitrate> [file]
#
# Esempi:
#  ./clearvoice0.sh dts 756k file.mkv   ./clearvoice0.sh eac3 768k file.mkv   -> Per elaborare un singolo file
#  ./clearvoice0.sh eac3 384k           ./clearvoice0.sh dts 512k             -> Per elaborare tutti i file .mkv in cartella

# -------------------------------------------------------------------
# PARAMETRI DI CONTROLLO PER TRACCIE E SUBTITOLI
# -------------------------------------------------------------------
KEEP_ORIGINAL_AUDIO=true  # true = Mantiene le tracce audio originali; false = le rimuove
KEEP_SUBTITLES=true       # true = Mantiene sottotitoli e capitoli; false = li rimuove

# -------------------------------------------------------------------
# IMPOSTAZIONI CODEC E BITRATE
# -------------------------------------------------------------------
DEFAULT_CODEC="eac3"
AUDIO_CODEC="${1:-$DEFAULT_CODEC}"

if [[ "$AUDIO_CODEC" == "eac3" ]]; then
    DEFAULT_BITRATE="768k"
    EXTRA_AUDIO_FLAGS=""
elif [[ "$AUDIO_CODEC" == "dts" ]]; then
    DEFAULT_BITRATE="756k"
    EXTRA_AUDIO_FLAGS="-strict -2"  # Abilita codec sperimentali per DTS
else
    echo "Errore: Codec non valido ($AUDIO_CODEC). Usa 'eac3' o 'dts'."
    exit 1
fi

TARGET_BITRATE="${2:-$DEFAULT_BITRATE}"
FILE_ARG="$3"
EXT="mkv"

# -------------------------------------------------------------------
# IMPOSTAZIONI SOUNDSTAGE E MIX AUDIO
# -------------------------------------------------------------------
FRONT_LEFT_DELAY=5          # soundstage FRONT delay FL
FRONT_RIGHT_DELAY=7         # soundstage FRONT delay FR
SURROUND_LEFT_DELAY=8       # soundstage REAR delay fl
SURROUND_RIGHT_DELAY=10     # soundstage REAR delay fr

VOICE_VOL=4.0               # Volume voce canale FC
LFE_VOL=0.10                # Volume canale LFE 
LFE_LIMIT=0.7               # Non scendere sotto 0.7
SURROUND_VOL=4.5            # Volume per i canali surround

# -------------------------------------------------------------------
# CATENA DI FILTRI AVANZATI
# -------------------------------------------------------------------
ADVANCED_FILTER=$(cat <<EOF
[0:a:0]channelsplit=channel_layout=5.1[fl][fr][fc][lfe][sl][sr];
[fl]adelay=delays=${FRONT_LEFT_DELAY}:all=1,volume=${SURROUND_VOL}[fl_proc];
[fr]adelay=delays=${FRONT_RIGHT_DELAY}:all=1,volume=${SURROUND_VOL}[fr_proc];
[sl]adelay=delays=${SURROUND_LEFT_DELAY}:all=1,volume=${SURROUND_VOL}[sl_proc];
[sr]adelay=delays=${SURROUND_RIGHT_DELAY}:all=1,volume=${SURROUND_VOL}[sr_proc];
[fc]highpass=f=120,speechnorm=e=1.8:r=0.004,\
    equalizer=f=250:t=q:w=1.2:g=-0.3,\
    equalizer=f=500:t=q:w=1.3:g=0.5,\
    equalizer=f=2000:t=q:w=1:g=0.7,\
    equalizer=f=2500:t=q:w=1.0:g=-0.8,\
    equalizer=f=4000:t=q:w=0.8:g=-1,\
    volume=${VOICE_VOL},\
    alimiter=limit=0.9:attack=3:release=20[fc_proc];
[lfe]lowpass=f=20:t=h,\
    equalizer=f=75:t=q:w=1:g=-8,\
    equalizer=f=65:t=q:w=1:g=-14,\
    equalizer=f=40:t=q:w=1:g=-11,\
    acompressor=threshold=-30dB:ratio=4:attack=3:release=150:knee=5dB,\
    alimiter=limit=${LFE_LIMIT}:attack=3:release=30,\
    volume=${LFE_VOL}[lfe_proc];
[fl_proc]equalizer=f=12000:t=q:w=1:g=-2,\
    equalizer=f=2000:t=q:w=1:g=1.5[fl_proc_adj];
[fr_proc]equalizer=f=12000:t=q:w=1:g=-2,\
    equalizer=f=2000:t=q:w=1:g=1.5[fr_proc_adj];
[sl_proc]equalizer=f=12000:t=q:w=1:g=-2,\
    equalizer=f=2000:t=q:w=1:g=1.5[sl_proc_adj];
[sr_proc]equalizer=f=12000:t=q:w=1:g=-2,\
    equalizer=f=2000:t=q:w=1:g=1.5[sr_proc_adj];
[fl_proc_adj][fr_proc_adj][fc_proc][lfe_proc][sl_proc_adj][sr_proc_adj]join=inputs=6:channel_layout=5.1[out]
EOF
)

# -------------------------------------------------------------------
# IMPOSTAZIONI DI OUTPUT AUDIO BASATE SUL CODEC
# -------------------------------------------------------------------
if [[ "$AUDIO_CODEC" == "dts" ]]; then
    AUDIO_CODEC_OUT="dts"
    EXTRA_AUDIO_FLAGS="-ar 48000 -strict -2"
else
    AUDIO_CODEC_OUT="eac3"
    EXTRA_AUDIO_FLAGS=""
fi

# Assegna un titolo alla nuova traccia audio in base al codec usato
if [[ "$AUDIO_CODEC" == "dts" ]]; then
    AUDIO_TRACK_TITLE="DTS Clearvoice 5.1"
else
    AUDIO_TRACK_TITLE="EAC3 Clearvoice 5.1"
fi

# -------------------------------------------------------------------
# FUNZIONE DI ELABORAZIONE FILE
# -------------------------------------------------------------------
process_file() {
    local input="$1"
    local filename="${input%.*}"
    local output="${filename}_clearvoice0.${EXT}"

    echo "Elaborazione: $input -> $output"

    if [ -f "$output" ]; then
        read -r -p "Il file '$output' esiste già. Sovrascriverlo? (y/n): " ans
        if [[ ! "$ans" =~ ^[Yy]$ ]]; then
            echo "File non sovrascritto. Saltato."
            return 1
        fi
        rm -f "$output"
    fi

    if [[ ! -f "$input" ]]; then
        echo "Errore: file '$input' non trovato!" >&2
        return 1
    fi

    MAP_OPTIONS="-map 0:v? -map [out]"
    if [[ "$KEEP_ORIGINAL_AUDIO" == true ]]; then
        MAP_OPTIONS+=" -map 0:a?"
    fi
    MAP_OPTIONS+=" -map 0:s? -map 0:t?"

    # Non più ridichiarare EXTRA_AUDIO_FLAGS qui: usiamo quello già impostato in base al codec

    if ! ffmpeg -hwaccel cuda -threads 0 -filter_threads 0 -hide_banner \
      -i "$input" -filter_complex "$ADVANCED_FILTER" \
      $MAP_OPTIONS \
      -metadata:s:a:0 title="$AUDIO_TRACK_TITLE" \
      -c:a $AUDIO_CODEC_OUT $EXTRA_AUDIO_FLAGS -b:a "$TARGET_BITRATE" \
      -c:v copy -c:s copy -f matroska "$output"
    then
        echo "Errore nell'elaborazione di '$input'" >&2
        return 1
    fi

    echo "Completato: $output"
}

# -------------------------------------------------------------------
# SELEZIONE E PROCESSAMENTO DEI FILE: Singolo file o tutti i .mkv
# -------------------------------------------------------------------
if [ -n "$FILE_ARG" ]; then
    process_file "$FILE_ARG"
else
    for file in *.mkv; do
        [ -f "$file" ] && process_file "$file"
    done
fi

echo "Elaborazione completata!"