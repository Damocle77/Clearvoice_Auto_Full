# ClearVoice 0.75 - Ottimizzazione Audio 5.1

**Script avanzato per ottimizzazione audio 5.1 con focus su chiarezza dialoghi e controllo LFE**  
*Sound engineering by Sandro 'D@mocle77' Sabbioni*

Soluzione professionale testata su sistema LG Meridian SP7 5.1.2 e usabile su soundbar o AVR compatibili.<br>

Ottimizza film, serie TV e cartoni animati (EAC3-DTS) per eliminare "booming" del subwoofer e migliorare l'intelligibilità del parlato.
---

## 🚀 Caratteristiche principali

* **Preset ottimizzati**: parametri specifici per film, serie TV e cartoni
* **Controllo LFE anti-boom**: riduzione 8-20% secondo il preset
* **EQ specifico SP7**: frequenze 2800Hz/3000Hz per presenza vocale
* **Compressione intelligente**: elimina vibrazione voce mantenendo dinamica
* **Gestione layout "unknown"**: supporto robusto per file problematici
* **Accelerazione hardware**: GPU quando disponibile
* **Output professionale**: statistiche dettagliate e suggerimenti

---

## 📋 Requisiti

* **FFmpeg** 6.0+ (con supporti codec moderni)
* **Windows 11**: `winget install ffmpeg`
* **Git Bash** o WSL per ambiente Unix
* **Hardware**: LG Meridian SP7 5.1.2 (testato e ottimizzato)

---

## 🔧 Installazione

```bash
git clone https://github.com/Damocle77/Clearvoice_5.1/
cd clearvoice075
chmod +x clearvoice075_preset.sh
```

---

## 💡 Uso base

```bash
./clearvoice075_preset.sh [PRESET] [CODEC] [BITRATE] [FILES/DIRS]
```

* `PRESET`: `--film`, `--serie`, `--cartoni` (default: `--serie`)
* `CODEC`: `eac3`, `ac3`, `dts` (default: `eac3`)
* `BITRATE`: es. `384k`, `448k`, `768k` (defaults ottimizzati)
* `FILES/DIRS`: file `.mkv` o directory (default: tutti i `.mkv` in cartella)

---

## 🎛️ Preset disponibili (calibrati per SP7)

### **🎬 --film** : Contenuti cinematografici con action e dialoghi
- **Parametri**: `VOICE_VOL=8.5`, `LFE=0.24`, `SURR=3.6`, `COMP=0.35:1.30:40:390`
- **Filtri FC**: Highpass 115Hz, Lowpass 7900Hz, EQ 2800Hz/3000Hz, Compressore, Softclipper
- **Ideale per**: Film d'azione, thriller, drammi con effetti sonori intensi

### **📺 --serie** : Serie TV con dialoghi sussurrati e problematici  
- **Parametri**: `VOICE_VOL=8.6`, `LFE=0.24`, `SURR=3.4`, `COMP=0.32:1.18:50:380`
- **Filtri FC**: Highpass 120Hz, Lowpass 7600Hz, EQ 2800Hz/3000Hz, Compressore delicato
- **Ideale per**: Serie TV, documentari, contenuti con dialoghi difficili

### **🎨 --cartoni** : Animazione con preservazione musicale e dinamica
- **Parametri**: `VOICE_VOL=8.2`, `LFE=0.26`, `SURR=3.5`, `COMP=0.40:1.15:50:330`
- **Filtri FC**: Highpass 110Hz, Lowpass 6900Hz, EQ 2800Hz/3000Hz, Compressione minima
- **Ideale per**: Cartoni animati, anime, contenuti con colonne sonore elaborate

---

## 🔊 Codec supportati

| Codec | Default Bitrate | Descrizione | Uso consigliato |
|-------|----------------|-------------|------------------|
| **eac3** | `384k` | Enhanced AC3 (DD+) | Streaming, serie TV |
| **ac3** | `448k` | Dolby Digital | Compatibilità universale |
| **dts** | `768k` | DTS premium | Film, Blu-ray alta qualità |

**Titolazione automatica**: "EAC3/AC3/DTS Clearvoice 5.1", lingua ITA, traccia predefinita

---

## 🛠️ Esempi pratici

```bash
# Serie TV sussurrate in DD+ 384k
./clearvoice075_preset.sh --serie eac3 384k "Episodio.mkv"

# Film d'azione in DTS alta qualità
./clearvoice075_preset.sh --film dts 768k *.mkv

# Cartoni animati batch processing
./clearvoice075_preset.sh --cartoni ac3 448k

# Auto-processing (preset serie, EAC3 384k)
./clearvoice075_preset.sh
```

---

## 🎯 Risultati LFE ottimizzati per SP7

| Preset    | EAC3/AC3 | DTS   | Riduzione | Caratteristiche          |
|-----------|----------|-------|-----------|--------------------------|
| **Serie** | 0.192    | 0.204 | -20%/-15% | Dialoghi TV cristallini  |
| **Film**  | 0.199    | 0.197 | -17%/-18% | Action bilanciato        |
| **Cartoni** | 0.239  | 0.239 | -8%/-8%   | Musica preservata        |

**Note tecniche:**
- **EQ**: 2800Hz per EAC3/AC3, 3000Hz per DTS (+3dB presenza vocale)
- **Compressione**: Serie TV ottimizzata anti-vibrazione (0.32:1.18:50:380)
- **Range frequenze**: Adattato per ogni tipo di contenuto

---

## 📊 Output dello script

```
═══════════════════════════════════════════════
  CLEARVOICE 0.75 - ELABORAZIONE COMPLETATA
═══════════════════════════════════════════════
Preset utilizzato: serie
Codec output: eac3 (384k)
File processati: 3

📁 File elaborati con successo:
   ✓ SerieTV.S01E01.mkv → SerieTV.S01E01_serie_clearvoice0.mkv
   ✓ SerieTV.S01E02.mkv → SerieTV.S01E02_serie_clearvoice0.mkv
   ✓ SerieTV.S01E03.mkv → SerieTV.S01E03_serie_clearvoice0.mkv

💡 Testa l'audio <Clearvoiced>:
   - Il preset 'serie' è ottimizzato per questo tipo di contenuto
   - Per serie TV o film sussurrati, usa volume TV leggermente più alto
═══════════════════════════════════════════════
```

---

## 🧪 Testing e calibrazione

**Hardware testato:**
- LG Meridian SP7 5.1.2
- Windows 11
- FFmpeg 6.x/7.x

**Metodologia di test:**
- Dialoghi sussurrati (serie TV drama)
- Boom subwoofer (film action)
- Vibrazione voce (compressione ottimizzata)
- Bilanciamento musica/voce (cartoni)

---

## 🚀 Changelog v0.75

* ✅ **LFE ottimizzato**: Riduzione boom subwoofer specifica per SP7
* ✅ **Compressione serie**: Eliminata vibrazione voce (0.32:1.18:50:380)
* ✅ **Layout robusto**: Gestione file audio "unknown" ma 6 canali
* ✅ **EQ calibrato**: 2800Hz EAC3/AC3, 3000Hz DTS per SP7
* ✅ **Output professionale**: Statistiche dettagliate e troubleshooting

---

## 🤝 Contribuire

1. Fork del repository
2. Testa su tuo hardware audio 5.1
3. Documenta risultati con setup specifico
4. Pull Request con miglioramenti

---

## 📄 Licenza

MIT License © 2025 - Sandro 'D@mocle77' Sabbioni

**Testato su**: Soundbar LG Meridian SP7 5.1.2

**Nota**: I parametri sono stati testati per SP7. Per altri sistemi audio, potrebbero essere necessari aggiustamenti.
