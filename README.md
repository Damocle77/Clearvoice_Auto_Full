# 🎙️ ClearVoice V8 - Final Edition

Pipeline audio avanzata per ottimizzare i dialoghi in contenuti 5.1, con tecnologia anti-vibrazione e oversampling 2× per eliminare micro-artefatti nei passaggi sussurrati. Boost vocale calibrato per profilo specifico con parametri ottimizzati e compressione RMS per un audio cinematografico naturale.

![Version](https://img.shields.io/badge/Versione-8.0-blue) ![Audio](https://img.shields.io/badge/Audio-5.1-green) ![FFmpeg](https://img.shields.io/badge/FFmpeg-Required-orange) ![SELECT name AS 'Sandro Sabbioni', handle AS 'D@mocle77' FROM developers](https://img.shields.io/badge/SELECT%20name%20AS%20'Sandro%20Sabbioni'%2C%20handle%20AS%20'D%40mocle77'%20FROM%20developers-blue)

---

## Indice

- [Caratteristiche principali](#caratteristiche-principali)
- [Tecnologia Anti-Vibrazione](#tecnologia-anti-vibrazione)
- [Profili Audio](#profili-audio)
- [Requisiti](#requisiti)
- [Installazione](#installazione)
- [Utilizzo](#utilizzo)
- [Guida Bitrate](#guida-bitrate---la-regola-doro)
- [Parametri di Elaborazione](#parametri-di-elaborazione)
- [Perché ClearVoice](#perché-clearvoice)

---


## Caratteristiche principali

ClearVoice Anti-Vibration è uno script bash avanzato che eleva l'esperienza audio a nuovi livelli:

- **🔊 Pipeline audio di nuova generazione**: Elaborazione 48kHz → 96kHz → Processing → 48kHz con SoXR 28-bit
- **🧠 Sistema anti-vibrazione avanzato**: Elimina il "buzz da droidi" nei sussurri e le micro-vibrazioni
- **🎯 Boost vocale calibrato per profilo**: Parametri ottimizzati specifici (2.28-2.33) senza artefatti
- **🎛️ Profili audio adattivi**: Riconoscimento automatico tra Action, Serie TV, Cartoon e Blockbuster
- **🎚️ Equalizzazione frequenziale calibrata**: EQ e parametri dinamici specifici per ogni contenuto
- **📊 Analisi multi-segmento**: Analisi LUFS/LRA/TruePeak intelligente su segmenti rappresentativi
- **👑 Oversampling professionale**: Elaborazione a 96kHz (2× standard) con resampler SoXR di alta precisione
- **🔧 Front L/R dinamici**: Bilanciamento stereo ottimizzato (0.98-1.00) per ogni profilo
- **📱 Ottimizzato per ogni piattaforma**: Perfetto per binge watching e cinema domestico

## Tecnologia Anti-Vibrazione

La tecnologia anti-vibrazione elimina i fastidiosi artefatti nei passaggi sussurrati:

| Componente | Tecnologia Anti-Vibrazione | Beneficio |
|------------|---------------------------|-----------|
| **Gate vocale** | Threshold ultra-basso (0.001), ratio soft (1.2:1), detection RMS | Sussurri fluidi e naturali, zero effetto "droide" |
| **Knee processing** | 4-5dB knee su compressori e gate | Transizioni morbide tra parlato e silenzio |
| **Auto-level** | Disattivato (level=disabled) con ASC attivo | Elimina micro-pumping e vibrazione artificiale |
| **Oversampling** | Pipeline 48kHz → 96kHz → 48kHz con SoXR 28-bit | Audio ultra-clean senza aliasing o artefatti digitali |
| **Attack/Release** | Ottimizzati per transizioni naturali (attack 7ms, release 100-350ms) | Conserva l'espressività vocale naturale |

## Requisiti

- **FFmpeg** >= 7.0 (con supporto filtergraph avanzato e codec E-AC3)
- **Bash** (Linux, macOS, WSL2 o Windows con Git Bash)
- **ffprobe**
- **awk**


## Profili Audio

Lo script analizza automaticamente LUFS, LRA e TruePeak per selezionare e adattare il profilo ottimale:

| Profilo                        | Condizione                        | Tipo di Contenuto           | Parametri Calibrati                    |
|-------------------------------|-----------------------------------|-----------------------------|----------------------------------------|
| **Blockbuster/Alta Dinamica** | Fallback o alta dinamica         | Film epici, disaster, IMAX | Front 0.98 \| FC 100Hz/2.33 \| LFE 45Hz/0.24/0.62 \| Surr 2.10 |
| **Action/Horror/Sci-Fi**      | LUFS < -18.5, LRA > 12           | Film d'azione, horror       | Front 0.99 \| FC 100Hz/2.30 \| LFE 45Hz/0.26/0.62 \| Surr 2.15 |
| **Serie TV Standard**         | LUFS -18.5 a -15.5, LRA 8-12     | Netflix/Amazon standard     | Front 1.00 \| FC 105Hz/2.30 \| LFE 45Hz/0.26/0.63 \| Surr 2.05 |
| **Serie TV Alta Dinamica**    | Serie TV + (LRA ≥ 10 o TP ≥ -1.0) | Netflix premium, HBO        | Front 0.99 \| FC 105Hz/2.32 \| LFE 45Hz/0.24/0.62 \| Surr 2.10 |
| **Cartoon/Disney/Musical**    | LUFS > -18.5, LRA < 8            | Animazione, film family     | Front 1.00 \| FC 105Hz/2.28 \| LFE 45Hz/0.28/0.66 \| Surr 2.00 |

### Legenda Parametri:
- **Front**: Volume canali frontali L/R
- **FC**: Highpass/Volume canale centrale (voce)
- **LFE**: Highpass/Volume/Limiter subwoofer
- **Surr**: Volume canali surround

Lo script effettua automaticamente il rilevamento "Stranger Things Effect" per Serie TV ad alta dinamica, attivando protezione LFE avanzata e parametri ottimizzati per content premium con picchi improvvisi.

---

## Installazione

```bash
# Windows (Git Bash)
winget install ffmpeg -e
winget install Git.Git -e

# Debian/Ubuntu
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Clona il progetto
git clone https://github.com/Damocle77/ClearVoice_Auto_Full.git
cd ClearVoice_Auto_Full
chmod +x *.sh
```
Assicurati che ffmpeg sia nel tuo PATH.

---

## Utilizzo

### Script principale

```bash
./clearvoice_simple.sh "<file_input>" [bitrate] [originale] [codec]
```

Parametri:
- `<file_input>`: File video di input con audio 5.1 (obbligatorio, es. `film.mkv`)
- `bitrate`: Bitrate audio di output (opzionale, default: 768k)
- `originale`: si/no (includi traccia originale, default: si)
- `codec`: eac3/ac3 (default: eac3)

Esempi:
```bash
./clearvoice_simple.sh "film.mkv"
./clearvoice_simple.sh "film.mkv" 640k no ac3
./clearvoice_simple.sh "alienearth.mkv" 768k si eac3
```

Lo script si adatta automaticamente al contenuto, ottimizzando dialoghi, subwoofer e surround per ogni scenario, inclusi i casi in cui le Serie TV si trasformano in veri Blockbuster. Nessuna configurazione manuale necessaria: il tuning è sempre ottimale, anche per sessioni prolungate e mix dinamici.

---

## Calibrazione Parametri Avanzata

### Novità V8: Parametri Dinamici per Profilo

Ogni profilo ora utilizza parametri specificamente calibrati per ottimizzare l'esperienza audio:

#### **Front L/R (0.98-1.00)**
- **Blockbuster**: 0.98 - Riduzione leggera per enfatizzare dialoghi centrali
- **Action/Series High**: 0.99 - Bilanciamento ottimale per contenuti dinamici  
- **Series/Cartoon**: 1.00 - Mantenimento naturale per contenuti TV

#### **FC (Canale Centrale) - Highpass/Volume**
- **100Hz**: Action e Blockbuster - Preserva corpo vocale in mix complessi
- **105Hz**: Serie TV e Cartoon - Maggiore pulizia per dialoghi TV

#### **LFE (Subwoofer) - Highpass/Volume/Limiter**
- **Tutti i profili**: Highpass a 45Hz per controllo preciso bassi
- **Volume**: 0.24-0.28 calibrato per intensità contenuto
- **Limiter**: 0.62-0.66 adattivo per protezione dinamica

#### **Surround (2.00-2.15)**
- **Cartoon**: 2.00 - Bilanciato per contenuti family
- **Series Standard**: 2.05 - Ottimizzato per binge watching
- **Action/Blockbuster**: 2.10-2.15 - Immersione cinematografica

---

## Guida Bitrate - La Regola d'Oro

Per risultati ottimali, segui la regola aurea del bitrate ClearVoice:

### E-AC-3 (raccomandato): Originale +192k
- 256k → 448k
- 384k → 576k
- 640k+ → 768k (cap)

### AC-3 (compatibilità): Originale +256k
- 256k → 512k
- 384k → 640k (cap)
- 640k+ → 640k (limite massimo)

### Regola rapida
- Input basso (≤256k): raddoppia il bitrate
- Input medio (384-512k): +50% del bitrate
- Input alto (≥640k): usa il cap del codec

> Perché +192k/+256k? Compensa perdite da reprocessing, artefatti lossy-to-lossy, headroom per transitori vocali e spazio per dettagli EQ recuperati.

## Parametri di Elaborazione

Per ogni profilo, lo script applica parametri calibrati specifici e anti-vibrazione:

### Calibrazione Dinamica per Profilo:
- **Blockbuster/Alta Dinamica**: Front 0.98 | FC 100Hz/2.33 | LFE 45Hz/0.24/0.62 | Surr 2.10
- **Action/Horror/Sci-Fi**: Front 0.99 | FC 100Hz/2.30 | LFE 45Hz/0.26/0.62 | Surr 2.15  
- **Serie TV Standard**: Front 1.00 | FC 105Hz/2.30 | LFE 45Hz/0.26/0.63 | Surr 2.05
- **Serie TV Alta Dinamica**: Front 0.99 | FC 105Hz/2.32 | LFE 45Hz/0.24/0.62 | Surr 2.10
- **Cartoon/Disney**: Front 1.00 | FC 105Hz/2.28 | LFE 45Hz/0.28/0.66 | Surr 2.00

### Tecnologia Anti-Vibrazione:
- **Compressori RMS**: knee=4, detection=rms, link=average (ottimizzati per profilo)
- **Limiter anti-vibrazione**: attack=8-14, release=120-210, level=disabled, asc=1
- **Oversampling**: processing a 96kHz con precisione SoXR 28-bit
- **Highpass ottimizzato**: 100-105Hz adattivo per preservare corpo vocale
- **Front L/R dinamici**: Bilanciamento stereo ottimizzato (0.98-1.00) per ogni scenario

Lo script mostra a schermo i parametri attivi e segnala con un alert quando viene attivata la protezione LFE avanzata per contenuti ad alta dinamica:

```
[Info] Rilevato "Stranger Things Effect" - Attivata protezione LFE avanzata!
```

## Perché ClearVoice

- **🎭 Dialoghi sempre perfetti**: Zero vibrazione nei sussurri, perfetta intelligibilità anche a volume basso
- **🚀 Tecnologia avanzata**: Oversampling 2× e processing SoXR 28-bit di livello professionale
- **🧠 Zero pensieri**: Selezione profilo automatica, parametri calibrati, tutto senza configurazione
- **⚡ Compatibilità universale**: Output compatibile con ogni sistema, dalle soundbar premium ai sistemi hi-end
- **🎬 Ottimizzato per contenuti critici**: Calibrato per film problematici e content streaming moderni
- **🔧 Parametri dinamici**: Front L/R, FC, LFE e Surround calibrati specificamente per ogni scenario
- **🛠️ Facile da usare**: Una semplice riga di comando per un audio cinematografico perfetto

> "Per riportare equilibrio nella forza audio basta un terminale bash...questa è la via"

---

*Developed by Sandro Sabbioni (Audio Processing Engineer)*
