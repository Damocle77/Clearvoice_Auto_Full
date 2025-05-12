# Clearvoice 5.1 Dialog Enhancer

**Clearvoice 5.1** è uno script Bash per migliorare l'intelligibilità dei dialoghi in tracce audio 5.1, ottimizzato per ambienti domestici e sistemi LG SP7 (versione 2025). Applicando una serie di filtri FFmpeg, mantiene i dialoghi in primo piano, controlla i bassi e amplia la scena sonora.

## 📋 Prerequisiti

* **FFmpeg** con supporto per i filtri: `dynaudnorm`, `agate`, `acompressor`, `deesser`, `highshelf`, `equalizer`, `aecho`.
* **Bash** (script testato su Linux con `bash` 5.x, compatibile con macOS).
* **(Opzionale)** CUDA-enabled GPU se si desidera accelerazione hardware: script utilizza `-hwaccel cuda`.

## ⚙️ Configurazione dei Parametri

All'inizio dello script `clearvoice050.sh` trovi le variabili di tuning che puoi personalizzare:

```bash
KEEP_OLD=true         # true = conserva la traccia audio originale come seconda traccia
VOICE_VOL=5.9         # Boost center (dialoghi): +12 dB circa
LFE_VOL=0.38          # Attenuazione subwoofer (~-7 dB)
LFE_LIMIT=0.75        # Ceiling limiter per LFE
FRONT_VOL=1.10        # Boost frontali L/R (+0.8 dB)
SURROUND_VOL=3.5      # Boost rear surround (+9 dB)
FL_DELAY=8            # Delay front-left (ms)
FR_DELAY=4            # Delay front-right (ms)
SL_DELAY=4            # Delay surround-left (ms)
SR_DELAY=2            # Delay surround-right (ms)
```

> **Consiglio:** modifica solo queste variabili per cambiare bilanciamento generale.

## 📡 Uso CLI

```bash
./clearvoice050.sh [codec] [bitrate] <file1.mkv> [file2.mkv ...]
```

* `codec`: `eac3` (default), `ac3`, `dts`
* `bitrate`: `384k` (EAC3), `448k` (AC3), `768k` (DTS)
* `--no-keep-old`: rimuove la traccia originale
* Se non specifichi file, processa **tutti i `.mkv`** nella cartella corrente.

**Esempi:**

```bash
# Processa un singolo file in EAC3/384k
./clearvoice050.sh eac3 384k Film.mkv

# Processa tutti i .mkv in AC3/448k, senza traccia originale
./clearvoice050.sh --no-keep-old ac3 448k
```

## 🎛️ Pipeline Filtri Audio (filter\_complex)

Lo script costruisce un filtro complesso (`ADV_FILTER`) suddiviso in tre macro-sezioni:

1. **Pre-Split & Loudness Globale**

   * `dynaudnorm=f=150:m=2:p=0.90`: make-up gain leggero (+2 dB max) su finestra 150 ms
   * `channelmap` + `channelsplit`: normalizza e separa in 6 stream (FL, FR, FC, LFE, SL, SR)

2. **Center (Dialoghi)**

   * `agate`: noise gate per sopprimere frusci sotto –55 dB
   * `acompressor`: compressione soft (1.6:1) per aumentare corpo senza pompare
   * `deesser`: attenua S/Z (bandwidth stretta 0.27:0.015)
   * `highshelf`: shelf +1 dB sopra 9 kHz per brillantezza
   * `volume`: boost dialoghi (`VOICE_VOL`)

3. **LFE (Subwoofer)**

   * Filtri passa-alto/inferiore (38–90 Hz) + piccole boost EQ per armoniche (50–85 Hz)
   * Compressore + limiter per controllo picchi e vibrazioni
   * `volume`: attenuazione sub (`LFE_VOL`)

4. **Front & Surround**

   * Delay microsecondi per creare scena
   * Boost frontale/rear e riverbero leggero (`aecho`) per gli surround

5. **Join & Master**

   * Ricomposizione 5.1
   * Boost finale (`volume=1.2`)
   * Limitazione (`alimiter=0.95`)
   * Reset timestamp con `asetpts`

## 📑 File Output

Il file generato sarà `<nome_input>_clearvoice0.mkv`, contenente:

* Video originale (stream copiato)
* Traccia audio Clearvoice 5.1 (EAC3/AC3/DTS) + traccia originale opzionale
* Sottotitoli (stream copiato)

## 💡 Suggerimenti & Tweak

* **Dialoghi troppo deboli**: aumenta `VOICE_VOL` di 0.2
* **Sub troppo invadente**: riduci `LFE_VOL` a 0.35
* **Voice più calda**: aumenta `highshelf` a +1.5 dB
* **Meno fruscio**: riduci `p` in `dynaudnorm` o abbassa `threshold` in `agate`

---

*Questo progetto è licenziato MIT. Buon editing audio!*
