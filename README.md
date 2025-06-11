# ClearVoice 5.1 🎧

**Script professionale per ottimizzazione audio 5.1 con chiarezza dialoghi superiore e ducking LFE avanzato**

[![Version](https://img.shields.io/badge/version-0.87-blue.svg)](https://github.com/Damocle77/Clearvoice_5.1/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2011%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](#installazione)
[![FFmpeg](https://img.shields.io/badge/ffmpeg-6.0%2B-orange.svg)](#requisiti-tecnici)

> **✨ Sistema professionale calibrato per voci italiane con tecnologia SoxR avanzata**

---

## 🚀 Quick Start

```bash
# Download e installazione rapida
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice087_preset.sh

# Uso immediato con preset film e codec EAC3
./clearvoice087_preset.sh --film eac3 640k *.mkv
```

---

## 🎆 Novità Rivoluzionarie v0.87

### 🎯 **Ducking LFE Professionale**
* **Sidechaincompress calibrato** per voci italiane con parametri codec-specifici
* **DTS più marcato** (threshold 0.15, ratio 3.2) per gestire dinamica superiore
* **E-AC3 bilanciato** (threshold 0.28, ratio 2.0) per compatibilità universale
* **Voce non processata** per sidechain naturale e timing perfetto

### 🎚️ **Firequalizer Anti-Baritono**
* **Boost intelligente** 1200-2200Hz per consonanti italiane
* **Attenuazione sibilanti** 5-8kHz per naturalezza
* **Preset differenziati**: TV aggressivo, Film bilanciato, Cartoni musicali

### 🎵 **SoxR Audiophile Grade**
* **DTS**: precision 33-bit, cutoff 0.99, oversampling Chebyshev
* **E-AC3**: precision 28-bit, filter_size 32, bilanciato qualità/performance
* **Noise shaping triangolare** per minima distorsione

### 🔧 **Processing Chain Ottimizzata**
* **De-esser** posizionato dopo firequalizer per riduzione sibilanti naturale
* **Stereotools** sui frontali per imaging spaziale migliorato
* **Compressione 2-stage** dolce per naturalezza vocale
* **Gestione parallela** canali per efficienza massima

---

## 🎧 Caratteristiche Professionali

* **EQ Firequalizer** specificamente calibrato per dialoghi italiani con boost presenza
* **Ducking LFE avanzato** che preserva chiarezza vocale senza sacrificare profondità bassi
* **Processing audio reference-quality** con SoxR audiophile per risultati cristallini
* **Tracce multiple intelligenti**: ClearVoice primaria + originale secondaria
* **Metadati professionali** con language tags e titoli descrittivi
* **Recovery robusto** con cleanup automatico e gestione interruzioni

---

## 🎛️ Preset Intelligenti

| Preset      | Voce (dB) | LFE | Surround | HP/LP (Hz) | Ideale per |
| ----------- | --------- | --- | -------- | ---------- | ---------- |
| `--film`    | 8.2       | 0.23| 4.6      | 120/8800   | Cinema, film d'autore |
| `--serie`   | 8.4       | 0.23| 4.5      | 150/8800   | Binge-watching TV |
| `--tv`      | 7.5       | 0.23| 4.0      | 180/7000   | Materiale problematico |
| `--cartoni` | 8.1       | 0.23| 4.6      | 130/6900   | Animazioni, musical |

---

## 🎵 Codec Reference Quality

| Codec      | Qualità | Compatibilità | Bitrate | SoxR Config |
| ---------- | ------- | ------------- | ------- | ----------- |
| **E-AC3**  | ⭐⭐⭐⭐⭐   | Universale    | 640k/768k | 28-bit, triangular |
| **DTS**    | ⭐⭐⭐⭐⭐   | Audiophile    | 756k/1536k | 33-bit, Chebyshev |

**Parametri Ducking Ottimizzati:**
- **DTS**: Threshold 0.15, Ratio 3.2, Attack 5ms (dinamica superiore)
- **E-AC3**: Threshold 0.28, Ratio 2.0, Attack 12ms (compatibilità)

---

## 🛠️ Installazione

**Linux / macOS / Windows (WSL)**:

```bash
# Clona repository con ultima versione
git clone https://github.com/Damocle77/Clearvoice_5.1.git
cd Clearvoice_5.1
chmod +x clearvoice087_preset.sh

# Verifica installazione FFmpeg con SoxR
ffmpeg -filters | grep soxr
```

---

## 📖 Esempi Professionali

```bash
# Film 4K con DTS reference quality
./clearvoice087_preset.sh --film dts 1536k movie_4k_remux.mkv

# Serie TV per maratone con E-AC3 ottimizzato
./clearvoice087_preset.sh --serie eac3 640k tv_series_s01e*.mkv

# Documentari con cleanup aggressivo
./clearvoice087_preset.sh --tv eac3 768k documentary_low_quality.mkv

# Animazioni Disney/Pixar con preservazione musicale
./clearvoice087_preset.sh --cartoni dts 756k animated_movie.mkv

# Batch processing completo
./clearvoice087_preset.sh --film eac3 640k /media/movies/*.{mkv,mp4}
```

---

## 🔧 Tecnologie Avanzate Implementate

### **Chain Audio Professionale**
1. **Channelsplit 5.1** → Split parallelo per processing ottimizzato
2. **Voice split** → Ducking pulito con voce non processata
3. **Firequalizer** → EQ calibrato per consonanti italiane
4. **De-esser** → Riduzione sibilanti post-EQ
5. **Compressor 2-stage** → Naturalezza con controllo dinamico
6. **Stereotools frontali** → Imaging spaziale migliorato
7. **LFE ducking** → Sidechaincompress codec-specifico
8. **SoxR finale** → Reference quality resampling

### **Ottimizzazioni Performance**
- **Threading adattivo** basato su CPU cores disponibili
- **Filter parallelo** per processing simultaneo canali
- **Memory management** ottimizzato per file grandi
- **Progress tracking** con ETA intelligente

---

## 📋 Requisiti Sistema

* **FFmpeg 6.0+** con supporto completo SoxR e sidechaincompress
* **Bash 4.0+** con supporti array associativi
* **CPU multi-core** raccomandati 8+ threads per performance ottimali
* **RAM 8GB+** per processing 4K e file grandi
* **Storage**: ~2x dimensione file sorgente per processing sicuro

---

## 🎯 Output Garantito

**Sempre prodotto:**
- 🥇 **Track 1**: ClearVoice ottimizzata (primaria, default)
- 🥈 **Track 2+**: Audio originale completo (backup, secondarie)
- 📝 **Metadati**: Language tags, titoli descrittivi, disposizioni corrette
- 📦 **Format**: MKV (default) o MP4 (se input MP4) con faststart

---

## 🤝 Contribuire

1. **Fork** il repository
2. **Crea** feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** le modifiche (`git commit -m 'Add amazing feature'`)
4. **Push** al branch (`git push origin feature/amazing-feature`)
5. **Apri** Pull Request

**Segnala bug** o richiedi funzionalità via [Issues](https://github.com/Damocle77/Clearvoice_5.1/issues).

---

## 📊 Performance Benchmark

| Sistema | CPU | Velocità | File 4K (25GB) |
| ------- | --- | -------- | -------------- |
| AMD 7950X | 16c/32t | 2.8x | ~12 minuti |
| Intel 13900K | 24c/32t | 3.1x | ~11 minuti |
| M2 Ultra | 24c | 2.2x | ~15 minuti |

*Performance reali con preset --film, codec DTS 1536k*

---

## 📄 Licenza

```
MIT License - Copyright (c) 2025 Sandro "D@mocle77" Sabbioni

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software to use, modify, and distribute according to MIT terms.
```

---

## 🌟 Riconoscimenti

- **Audio Engineering Society** per riferimenti su dialog intelligibility
- **Community FFmpeg** per continuous improvement e supporto tecnico
- **Beta testers** per feedback prezioso su voci italiane

---

## 📞 Links e Supporto

* 🏠 **Repository**: [Clearvoice_5.1](https://github.com/Damocle77/Clearvoice_5.1)
* 🐛 **Issues**: [Bug Reports](https://github.com/Damocle77/Clearvoice_5.1/issues)
* 📦 **Releases**: [Download](https://github.com/Damocle77/Clearvoice_5.1/releases)
* 📚 **Wiki**: [Documentation](https://github.com/Damocle77/Clearvoice_5.1/wiki)

---

**⭐ Se ClearVoice ti è utile, lascia una stella su GitHub! ⭐**