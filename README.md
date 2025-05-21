# ClearVoice 5.1 Pipeline 0.70

**Ottimizzazione audio 5.1.2 con focus sulla chiarezza dei dialoghi e bilanciamento surround**

Una soluzione semplice ma potente per conferire voce chiara a film, serie TV, cartoni animati, musical, ecc.<br>
Pensata per sistemi soundbar multicanale LG Meridian e compatibili, ma estendibile a qualsiasi altro AVR.

---

## 🚀 Caratteristiche principali

* **Preset dedicati**: film, serie TV e cartoni animati
* **Pilota LFE** e volumi bilanciati per ogni canale
* **Compressione e soft-clipping** per evitare distorsioni
* **Accelerazione hardware (opzionale)** abilitata di default
* **Supporto multi-file e directory** con globbing `.mkv`
* **Salvataggio dei metadati** (titoli, lingua ita, tracciati secondari, sottotitoli)

---

## 📋 Requisiti

* **FFmpeg** (con supporto `libfdk_aac`, `nvenc` o simili)
* **sotto Windows 11: winget install ffmpeg**
* **bash** (versione 4+ consigliata) *Gitbash sotto Windows
* **Hardware**: GPU NVIDIA per CUDA (opzionale ma consigliata)

---

## 🔧 Installazione

Clona questo repository o copia lo script direttamente nella tua cartella di lavoro:

```bash
git clone https://github.com/tuo-utohandle/clearvoice.git
cd clearvoice
chmod +x clearvoice070_preset.sh
```

---

## 💡 Uso base

```bash
./clearvoice070_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
```

* `PRESET`: `--film`, `--serie`, `--cartoni` (default: `--serie`)
* `CODEC`: `eac3`, `ac3`, `dts` (default `eac3`)
* `BITRATE`: es. `384k`, `448k`, `768k` (default in base al codec)
* `FILES/DIRS`: uno o più file `.mkv` o directory (default: tutti i `.mkv` nel folder corrente)

---

## 🎛️ Preset disponibili

| Preset    | Uso consigliato                          | Parametri voce (center) | LFE  | Surround | Compressione       |
| --------- | ---------------------------------------- | ----------------------- | ---- | -------- | ------------------ |
| `film`    | Film ad alto dinamismo                   | `VOICE_VOL=7.4`         | 0.30 | 3.5      | `0.48:1.15:45:450` |
| `serie`   | Serie TV e documentari                   | `VOICE_VOL=7.3`         | 0.29 | 3.4      | `0.44:1.18:50:400` |
| `cartoni` | Cartoni animati e musical                | `VOICE_VOL=6.5`         | 0.31 | 3.6      | `0.47:1.12:40:300` |

*Filtri center*: highpass, lowpass, compressor, softclipper.

---

## 🔊 Codec supportati

* **eac3**: default `768k`, titolazione "EAC3 Clearvoice 5.1"
* **ac3**: default `640k`, titolazione "AC3 Clearvoice 5.1"
* **dts**: default `756k`, titolazione "DTS Clearvoice 5.1" + equalizzatori specifici

---

## 🛠️ Esempi rapidi

```bash
# Serie TV in DD+ 384k\ n./clearvoice070_preset.sh --serie eac3 384k "LaTuaSerie.mkv"

# Tutti i film in DTS 756k nella cartella corrente\ n./clearvoice070_preset.sh --film dts 756k

# Cartoni animati in AC3 640k da directory specifica
./clearvoice070_preset.sh --cartoni ac3 640k /media/cartoni
```

---

## 🚀 Prospettive future

* **Interfaccia Web**: controllo via browser per un workflow ancora più fluido
* **Supporto Audio 3D**: Dolby Atmos / MPEG-H

---

## 🤝 Contribuire

1. Fork del repository
2. Crea un branch: `git checkout -b feature/nome-feature`
3. Commit dei cambiamenti: `git commit -am 'Aggiunta feature XYZ'`
4. Push: `git push origin feature/nome-feature`
5. Apri una Pull Request

---

## 📄 Licenza

MIT License © 2025
