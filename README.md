# Clearvoice 5.1 – SP7 Edition (v0.43)

> _"Per chi non vuole solo sentire, ma ascoltare. Dialoghi chiari, bassi intelligenti, soundstage cinematografico."_  
> Ottimizzato su **soundbar Meridian SP7 5.1.2** – ma amato anche dai vicini di casa.

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
./clearvoice043.sh [dts|eac3|ac3] 640k "Film.mkv"
./clearvoice043.sh --no-keep-old dts 384k
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

> 🎯 Risultato: voce calda, nitida, mai tagliente, intellegibile anche a basso volume.

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

> 🧠 Basso presente, mai invadente con un "briciolo" di vibrazione (anche su subwoofer potenti).

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

## 🔬 Pipeline FFmpeg

Lo script utilizza una pipeline FFmpeg composta da più filtri audio applicati **per canale** tramite `channelsplit`, `pan`, `filter_complex` e `amerge`, in questo ordine generale:

1. **Split e routing dei canali**:
   - Il flusso 5.1 viene separato in: FL, FR, C, LFE, SL, SR

2. **Elaborazione canale centrale (voce)**:
   ```bash
   [c] highpass=100Hz → equalizer x5 → compand → compand → compressor → limiter
   ```

3. **Elaborazione subwoofer (LFE)**:
   ```bash
   [lfe] highpass=28Hz → equalizer x3 → lowpass=100Hz → bass shelf → limiter
   ```

4. **Frontali (FL/FR)**:
   ```bash
   [fl/fr] volume=1.12 → adelay=8ms/4ms
   ```

5. **Surround (SL/SR)**:
   ```bash
   [sl/sr] volume=2.24 → adelay=4ms/2ms
   ```

6. **Ricostruzione 5.1**:
   - I canali trattati vengono rimessi insieme tramite `amerge` e `pan=5.1`.

7. **Limiter finale (master)**:
   - L'intera traccia viene infine passata in un `alimiter=limit=0.92`

> Il tutto avviene senza alterare il video, né gli altri stream (sottotitoli, capitoli, ecc).


## 🧬 Frequenze della voce umana (e perché ci interessano)

La voce umana si sviluppa su un **range di frequenze** ben preciso. Per migliorare la chiarezza dei dialoghi nei film, è fondamentale sapere **dove agire** con equalizzazione e compressione:

| Banda di frequenza | Contenuto | Trattamento |
|--------------------|-----------|-------------|
| **60–100 Hz**      | Voce maschile profonda, rimbombi | Di solito attenuata (high-pass) |
| **150–300 Hz**     | Corposità vocale, tono base | Leggero boost per "calore" |
| **500–1000 Hz**    | Intellegibilità, formanti vocali | Stabilizzata |
| **1–2 kHz**        | Chiarezza e presenza | Leggero aumento |
| **3–5 kHz**        | Nitidezza consonanti | Equalizzazioni mirate, evitare l’asprezza |
| **6–8 kHz**        | Sibili, "S" e "F" | Spesso attenuata per evitare fastidio |
| **10 kHz+**        | Aria e brillantezza | Non sempre utile nei dialoghi |

🎙️ La zona più importante per **capire cosa viene detto** è quella tra **1 kHz e 4 kHz**, ma serve un bilanciamento fine: troppa presenza rende la voce metallica, troppo poco la rende ovattata.

Lo script Clearvoice applica equalizzazioni specifiche proprio in questi punti critici, migliorando la **presenza vocale senza stridori**.

> 🎧 Sì, è un po’ come l’equalizzatore dell’autoradio… ma con il cervello (e FFmpeg).
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
