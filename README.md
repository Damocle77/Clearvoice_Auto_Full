# 🎵 ClearVoice Preset Suite – Versione 0.89

Una suite avanzata di preset audio e script bash progettati attorno a `ffmpeg`, per **esaltare la voce**, domare i subwoofer ribelli e amplificare la tridimensionalità acustica nei sistemi 5.1 e 5.1.2 moderni. Ottimizzato per soundbar LG Meridian SP7, ma universale nei benefici.

---

## 🌟 Highlights v0.89

### 🔊 Voice Boost + Compressione Multi-banda

* La voce è la protagonista: +8dB con compressione soft dedicata.
* Il canale **FC (centrale)** è trattato con EQ intelligente e pulizia mirata.
* Preserva naturalezza nei dialoghi, evitando l'effetto "megafono".

### 🔇 VERO LFE Ducking (Subwoofer sotto controllo)

* Il sub reagisce alla voce in tempo reale (sidechaincompress):

  * Voce presente → LFE si attenua
  * Voce assente → il basso ritorna
* Parametri dinamici ottimizzati per ogni preset (`film`, `serie`, `tv`, `cartoni`).
* Protezione anti-picco con `alimiter` + `asoftclip` adattivo.

### 🎭 Soundstage Cinematografico

* Delay temporali calibrati:

  * **Frontali**: da 5ms a 10ms
  * **Surround**: da 10ms a 20ms
* Effetto Haas realistico: spazialità senza artifici, niente eco.

### ✨ SoXR Resampling (Hi-Fi Engine)

* Uscita a 48kHz con resampling **SoXR** (28-bit precision)
* Maggiore dettaglio, minor aliasing, perfetto per colonna sonora e parlato.

---

## 💡 A Cosa Serve?

ClearVoice è pensato per chi:

* Vuole **capire i dialoghi** senza alzare il volume globale
* È stanco del **subwoofer invadente** nei mix DTS
* Cerca un **surround definito e pulito**, senza confusione
* Ama sentire ogni **battito, parola e effetto** con chiarezza chirurgica

---

## 🧪 Esempi di Utilizzo

```bash
bash clearvoice089_preset.sh --serie *.mkv
bash clearvoice089_preset.sh --film dts 768k *.mkv
```

Opzioni:

* `--preset`: `film`, `serie`, `tv`, `cartoni`
* `codec`: `eac3`, `ac3`, `dts` (default: `eac3`)
* `bitrate`: `384k`, `448k`, `640k`, `768k`

---

## 🛠️ Preset disponibili

| Preset    | Voce          | LFE            | Soundstage         | Note                                 |
| --------- | ------------- | -------------- | ------------------ | ------------------------------------ |
| `film`    | 🎥 Alta       | 💡 Morbido     | 🎭 Cinematografico | Ideale per cinema e impatto dinamico |
| `serie`   | 📺 Molto alta | 🔇 Controllato | 🏋️ Compatto       | Perfetto per dialoghi e serie TV     |
| `tv`      | 📢 Massima    | 🔥 Ridotto     | 📰 Ridotto         | Audio scadente o compresso           |
| `cartoni` | 🎨 Naturale   | 💥 Musicale    | 🌈 Espanso         | Colori sonori ed effetti brillanti   |

---

## 📊 Tecnologie Implementate

* ✅ **LFE Ducking via sidechaincompress** (voce → subwoofer)
* ✨ **SoXR resampling 48kHz** (Hi-Fi audio quality)
* 📀 **Crossover LFE professionale** con filtri passa-basso
* 🛁 **Delay Soundstage** realistico (5ms–20ms)
* 🔊 **Voice Boost + Multiband Compression**
* 🛡️ **Limiter intelligente + soft clipping** (niente distorsioni)

---

## 🔧 Requisiti

* OS: Linux / macOS / WSL
* `ffmpeg` 6.0+ compilato con:

  * `firequalizer`
  * `sidechaincompress`
  * `alimiter`
  * `soxr` (libsoxr)
* Output 5.1 (fisico o virtuale)

---

## 🪜 Installazione & File

* `clearvoice089_preset.sh` → Script principale
* `README.md` → Questo documento

---

## 🚀 Visione Nerd

ClearVoice è per chi crede che **la voce meriti un palco degno**, che il **basso vada domato come un drago**, e che **il suono debba viaggiare nello spazio, non solo uscire da uno speaker**.

* Tutti i filtri sono **modulari e commentati**
* Ogni preset è **calibrato per contenuti e codec diversi**
* Massima trasparenza nel flusso di processing: da 5.1 input a 5.1 Hi-Fi output

---

## 🌐 Roadmap Futuristica

* GUI interattiva (qt/kivy)
* Auto-profilazione codec in base all'input
* Modalità "night-mode" per visione notturna

---

## 👨‍💻 Autore

Creato da **Sandro "D\@mocle77" Sabbioni**

> Ingegnere informatico. Nerd del suono. Devoto all'intelligibilità vocale.

---

## 📄 Licenza

MIT License — Libero uso, modifica, miglioramento e condivisione.

---

"La forza sia con la voce... e con il subwoofer, ma solo quando serve."
