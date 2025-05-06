# Clearvoice 5.1 – SP7 Edition

> _"Per chi non vuole solo sentire, ma ascoltare. Dialoghi chiari, bassi intelligenti, soundstage cinematografico."_  
> Ottimizzato per **soundbar LG SP7 5.1.2** – ma amato anche dai vicini di casa.

---

## 📦 Cos'è

`clearvoice043.sh` è uno script **Bash + FFmpeg** che elabora tracce **audio 5.1** all’interno di file `.mkv`, riscrivendole in una versione ottimizzata per la chiarezza dei dialoghi, l’equilibrio del subwoofer e un palco sonoro realistico.

- 🎙️ Boost selettivo sui dialoghi (Center)
- 🔉 Surround ampio ma controllato
- 🧠 Subwoofer ripulito e compresso
- 🧪 Codec AC3, EAC3 o DTS a scelta
- ⚙️ Nessuna ricodifica video

---

## ⚙️ Requisiti

| Componente  | Versione consigliata | Note |
|-------------|----------------------|------|
| `bash`      | >= 4.x               | Presente su Linux/macOS. Su Windows: WSL o Git Bash |
| `ffmpeg`    | >= 6.x               | Deve includere `channelsplit`, `compand`, `equalizer`, `adelay`, `alimiter`, ecc. |
| GPU (opz.)  | NVIDIA CUDA          | Per usare `-hwaccel cuda` (opzionale) |

---

## 🚀 Uso rapido

```bash
./clearvoice043.sh [dts|eac3|ac3] 384k "Film.mkv"
./clearvoice043.sh --no-keep-old dts 768k
```

- Se non indichi alcun file, elabora **tutti i `.mkv`** presenti.
- Flag `--no-keep-old` rimuove le tracce audio originali.

---

## 🎛️ Audio: Trattamento per Frequenze & Canali

### 🎤 Canale Centrale (Dialoghi)

- **Volume**: +12.6 dB (`VOICE_VOL=4.25`)
- **High-pass**: 100 Hz – rimuove i rimbombi
- **Compand**: solleva i passaggi deboli (curve -35/-20dB)
- **Compressore**: 4:1, soglia -22dB, attack 6ms
- **Limiter**: -0.8 dBFS (`limit=0.92`)
- **Equalizzazioni vocali**:
  - 6 kHz: –3 dB (sibilanti)
  - 4 kHz: –0.8 dB
  - 2 kHz: +0.8 dB
  - 1.5 kHz: +1.2 dB
  - 300 Hz: +0.1 dB
  - 250 Hz: +0.8 dB

> 🎯 Risultato: voce calda ma nitida, mai tagliente.

---

### 🔊 Subwoofer (LFE)

- **Volume**: –4.7 dB (`LFE_VOL=0.58`)
- **High-pass**: 28 Hz – taglia l’infrabasso spurio
- **Equalizzazioni**:
  - 40 Hz: –5 dB (anti-rimbombo)
  - 60 Hz: +1.5 dB (mid-bass caldo)
  - 80 Hz: +1.0 dB (punch)
- **Low-pass**: 100 Hz
- **Shelf**: +2 dB @75 Hz
- **Limiter**: `limit=0.75`, attack 3ms, release 200ms

> 🧠 Basso presente ma mai invadente, anche con subwoofer potenti.

---

### 🔈 Frontali e Surround

- **Front L/R**:
  - Volume: +1 dB (`FRONT_VOL=1.12`)
  - Delay: FL 8 ms, FR 4 ms
- **Surround L/R**:
  - Volume: +6 dB (`SURROUND_VOL=2.24`)
  - Delay: SL 4 ms, SR 2 ms

> 🎧 Delay asimmetrici ampliano il palco, enfatizzano il fronte centrale e il retro avvolgente.

---

## 🔁 Codec supportati

| Codec | Bitrate default | Note |
|-------|------------------|------|
| EAC3  | `384k`           | Standard, compatibile con 5.1 |
| AC3   | `448k`           | Compatibile con sistemi legacy |
| DTS   | `768k`           | Alta fedeltà, ma richiede supporto dedicato |

---

## 🔧 Parametri interni modificabili

Apri lo script e modifica a piacere:

```bash
KEEP_OLD=true         # conserva le tracce audio originali
VOICE_VOL=4.25        # gain voce
LFE_VOL=0.58          # gain subwoofer
LFE_LIMIT=0.75        # limitazione LFE
FRONT_VOL=1.12        # frontali
SURROUND_VOL=2.24     # surround
FL_DELAY=8            # front-left delay (ms)
FR_DELAY=4
SL_DELAY=4            # surround-left delay (ms)
SR_DELAY=2
```

---

## 🛠️ Output

Ogni file elaborato verrà salvato come:

```
Nomefile_clearvoice0.mkv
```

Con codec e bitrate selezionati, audio taggato `ita`, video **non ricodificato**.

---

## 🧪 Roadmap

- [ ] Auto-normalizzazione con loudnorm
- [ ] Output HEVC con tag audio dinamici
- [ ] Versione GUI in Electron

---

## 📜 Licenza

MIT. Usalo, adattalo, remixalo. Se il tuo sub si ribella… è una feature, non un bug.

---

## ❤️ Contribuisci

Hai idee, miglioramenti o preset per altri modelli di soundbar?  
Fai una pull request o apri una issue. Il suono perfetto è un lavoro di squadra.
