# ClearVoice 5.1 🎧

**Script avanzato per ottimizzazione audio 5.1 con chiarezza dialoghi superiore e controllo LFE avanzato**

[![Version](https://img.shields.io/badge/version-0.86-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2011%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#installazione)
[![FFmpeg](https://img.shields.io/badge/ffmpeg-7.0%2B-orange.svg)](#requisiti-tecnici)

> **✨ Calibrato su sistema LG Meridian SP7 5.1.2 ma compatibile su soundbar/AVR analoghe**

---

## 🚀 Quick Start

```bash
# Download e installazione rapida
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice086_preset.sh

# Uso immediato con preset film e codec EAC3
./clearvoice086_preset.sh --film eac3 640k *.mkv
```

---

## ✨ Novità v0.86

* **Adaptive multiband dynamic expander** sulle frequenze critiche per voce più chiara e dinamiche precise
* **Ducking avanzato su LFE** con sidechaincompress calibrato per chiarezza vocale senza sacrificare bassi
* **SoxR audiophile resampling** a 28-bit con noise shaping triangolare per un audio cristallino
* **Gestione robusta tracce audio** con metadati professionali
* **Validazione input avanzata** con analisi dettagliata dei formati audio
* **Logging verboso** e recovery robusto con cleanup sicuro
* **Output dinamico** con validazione bitrate codec-specifici

---

## 🎧 Caratteristiche principali

* **EQ Firequalizer** anti-baritono ottimizzato specificamente per dialoghi italiani
* **Compressione 2-stage** per una resa vocale naturale e non affaticante
* **Processing parallelo e sequenziale ottimizzato** per stabilità ed efficienza
* **Validazione preventiva robusta dello spazio disco** per evitare interruzioni inattese
* **Cleanup automatico** dei file temporanei e gestione intelligente delle interruzioni
* **Output dinamico**: formato MKV o MP4 selezionato automaticamente in base al formato sorgente

---

## 🎛️ Preset Disponibili

* `--film`: Bilanciamento cinematografico ideale per dialoghi naturali e bassi integrati
* `--serie`: Dialoghi prominenti e dinamica controllata perfetta per sessioni prolungate
* `--tv`: Aggressivo nella riduzione del rumore per materiale problematico
* `--cartoni`: Preservazione musicale e dinamica per animazioni e contenuti musicali

---

## 🎵 Codec Supportati

| Codec    | Qualità | Compatibilità | Bitrate raccomandato |
| -------- | ------- | ------------- | -------------------- |
| **EAC3** | ⭐⭐⭐⭐⭐   | Universale    | 768k   	          |
| **AC3**  | ⭐⭐⭐⭐⭐   | Universale    | 768k                 |
| **DTS**  | ⭐⭐⭐⭐⭐   | Audiophile    | 756k/1536k           |


---

## 🛠️ Installazione

**Linux / macOS / Windows**:

```bash
# Clona repository
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice086_preset.sh
```

---

## 📖 Esempi di utilizzo dettagliati

```bash
# Film con DTS audiophile per home cinema
./clearvoice086_preset.sh --film dts 1536k blockbuster_movie.mkv

# Serie TV ottimizzate per binge-watching
./clearvoice086_preset.sh --serie eac3 640k tv_series_episode_*.mkv

# Documentari e materiale problematico con pulizia aggressiva
./clearvoice086_preset.sh --tv eac3 768k noisy_documentary.mkv

# Animazioni con preservazione dinamica e musicale
./clearvoice086_preset.sh --cartoni dts 756k animated_feature.mkv
```

---

## 📋 Requisiti Tecnici

* **FFmpeg 7.0+** con supporto SoxR
* **Bash 4.0+**
* **CPU multi-core raccomandata**
* **RAM minima 4GB, raccomandati 8GB+**

---

## 🤝 Contribuire

Segnala bug o richiedi nuove funzionalità aprendo una [issue](https://github.com/Damocle77/Clearvoice_5.1/issues).

---

## 📄 Licenza

```
MIT License - Copyright (c) 2025 Sandro "D@mocle77" Sabbioni
```

Sentiti libero di usare, modificare e distribuire secondo i termini MIT.

---

## 📞 Links e Supporto

* **Main Repository**: [Clearvoice\_5.1](https://github.com/Damocle77/Clearvoice_5.1)
* **Issue Tracker**: [Issues](https://github.com/Damocle77/Clearvoice_5.1/issues)
* **Releases**: [Releases](https://github.com/Damocle77/Clearvoice_5.1/releases)
