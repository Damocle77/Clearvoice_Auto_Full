# 🎙️ ClearVoice V8 - Smart Profile Edition

Pipeline avanzata per chiarezza voci e bassi LFE in audio 5.1 mkv/mp4. Analisi loudness multi-segmento (LUFS/LRA/TruePeak), selezione profili intelligente a punteggio, equalizzazione adattiva e compressione anti-vibrazione. LFE chirurgico, bassi definiti, voci cristalline e transizioni naturali.

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

ClearVoice Smart Profile Edition è uno script bash avanzato che eleva l'esperienza audio a nuovi livelli:

- **🧠 Sistema a punteggio intelligente**: Selezione profili automatica basata su analisi audio
- **📊 Analisi multi-segmento**: Fallback robusti e gestione errori avanzata  
- **✅ Validazione completa**: Parametri input (codec, bitrate, file) con messaggi dettagliati
- **🔊 Anti-vibrazione voce**: Compressore ratio 2.0, knee 7, attack 20–22ms, release 200ms
- **� LFE chirurgico**: Boost selettivo su 80Hz con controllo dinamico per ogni profilo
- **⚡ SoXR 28-bit + oversampling 2×**: Massima precisione, zero aliasing, definizione HD
- **🌍 Compatibilità cross-platform**: Linux, macOS, BSD con gestione errori robusta
- **🎯 Equalizzazione voce multi-banda**: Highpass adattivo, EQ chirurgico 500Hz-4800Hz
- **� Parametri dinamici per profilo**: Front L/R, FC, LFE e Surround calibrati specificamente

## Tecnologia Anti-Vibrazione

La tecnologia anti-vibrazione con sistema intelligente elimina i fastidiosi artefatti vocali:

| Componente | Tecnologia Anti-Vibrazione | Beneficio |
|------------|---------------------------|-----------|
| **Compressore voce** | Ratio 2.0, knee 7, attack 20-22ms, release 200ms | Sussurri fluidi e naturali, zero effetto "droide" |
| **EQ multi-banda** | 500Hz(-0.3dB), 1350Hz(+1.8/+2.0dB), 2900Hz(+1.0dB), 4800Hz(+0.1dB) | Intelligibilità cristallina senza sibilanza |
| **Highpass adattivo** | 88-95Hz per profilo dinamico | Rimozione mud/rumble preservando corpo vocale |
| **Oversampling** | Pipeline 48kHz → 96kHz → 48kHz con SoXR 28-bit | Audio ultra-clean senza aliasing o artefatti digitali |
| **LFE chirurgico** | EQ 3-bande: 55Hz(-3.5dB), 75Hz(-1.0dB), 80Hz(+3.6dB) | Bassi definiti e controllati con Q-factor ottimizzato |

## Requisiti

- **FFmpeg** >= 7.0 (con supporto filtergraph avanzato e codec E-AC3)
- **Bash** (Linux, macOS, WSL2 o Windows con Git Bash)
- **ffprobe**
- **awk**


## Profili Audio

Lo script analizza automaticamente LUFS, LRA e TruePeak con sistema a punteggio intelligente per selezionare il profilo ottimale:

| Profilo                        | Algoritmo di Selezione                        | Tipo di Contenuto           | Parametri Calibrati                    |
|-------------------------------|----------------------------------------------|-----------------------------|-----------------------------------------|
| **Blockbuster/Disaster/Marvel/DC** | LRA > 10.0, TruePeak > -2.5, LUFS ≤ -17.5 | Film epici, alta dinamica cinematografica | Front 0.98 \| FC 90Hz/2.35/2.0dB@1350 \| LFE 55+75+80Hz/0.24/3.6dB \| Surr 2.00 |
| **Action/Horror/Sci-Fi/Musical**      | LRA 8.0-10.0, TruePeak -3.5/-2.5, LUFS -18.5/-15.5 | Dinamica equilibrata       | Front 0.99 \| FC 88Hz/2.33/1.9dB@1350 \| LFE 55+75+80Hz/0.26/3.6dB \| Surr 2.05 |
| **Cartoon/Disney/Musical/Drammedy**         | LRA < 7.5, TruePeak ≤ -2.5, LUFS > -16.5     | Compresso, voci brillanti     | Front 1.00 \| FC 92Hz/2.32/1.9dB@1350 \| LFE 55+75+80Hz/0.26/3.6dB \| Surr 1.90 |
| **Serie TV (Bassa Dinamica)** | LRA 6.5-8.0, TruePeak -4.5/-2.0, LUFS -20.0/-16.5     | Standard broadcast     | Front 1.00 \| FC 95Hz/2.33/1.8dB@1350 \| LFE 55+75+80Hz/0.26/3.6dB \| Surr 1.95 |
| **Serie TV (Alta Dinamica)**    | Serie TV + LRA ≥ 7.5, TruePeak > -2.5, LUFS ≤ -17.5 | Netflix/Amazon premium        | Front 0.98 \| FC 92Hz/2.35/1.8dB@1350 \| LFE 55+75+80Hz/0.24/3.6dB \| Surr 2.00 |

### Legenda Parametri:
- **Front**: Volume canali frontali L/R (0.98-1.00)
- **FC**: Highpass/Volume/EQ canale centrale (88-95Hz adattivo, 1350Hz core boost)
- **LFE**: EQ 3-bande chirurgico (55Hz cut, 75Hz cut, 80Hz boost Q-factor ottimizzato)
- **Surr**: Volume canali surround (1.90-2.05)

Lo script effettua automaticamente il rilevamento intelligente per Serie TV ad alta dinamica, attivando protezione LFE avanzata e parametri ottimizzati per content premium con range dinamico estremo.

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

### Parametri Dinamici per Profilo V8

Ogni profilo utilizza parametri specificamente calibrati dal sistema intelligente a punteggio:

### Calibrazione Dinamica per Profilo

- **Blockbuster**: Front 0.98 | FC 90Hz/2.35/2.0dB@1350 | LFE 55+75+80Hz/0.24/3.6dB | Surr 2.00 | Comp 2.0/22/200/K7
- **Action**: Front 0.99 | FC 88Hz/2.33/1.9dB@1350 | LFE 55+75+80Hz/0.26/3.6dB | Surr 2.05 | Comp 2.0/22/200/K7  
- **Serie TV (BD)**: Front 1.00 | FC 95Hz/2.33/1.8dB@1350 | LFE 55+75+80Hz/0.26/3.6dB | Surr 1.95 | Comp 2.0/20/200/K7 
- **Serie TV (AD)**: Front 0.98 | FC 92Hz/2.35/1.8dB@1350 | LFE 55+75+80Hz/0.24/3.6dB | Surr 2.00 | Comp 2.0/22/200/K7  
- **Cartoon**: Front 1.00 | FC 92Hz/2.32/1.9dB@1350 | LFE 55+75+80Hz/0.26/3.6dB | Surr 1.90 | Comp 2.0/20/200/K7

### Tecnologia Anti-Vibrazione

- **Compressore voce**: ratio 2.0, knee 7, attack 20-22ms, release 200ms (ottimizzati per profilo)
- **EQ multi-banda voce**: 500Hz(-0.3dB), 1350Hz(+1.8/+2.0dB), 2900Hz(+1.0dB), 4800Hz(+0.1dB)
- **Highpass adattivo**: 88-95Hz per rimozione mud/rumble preservando corpo vocale
- **LFE chirurgico**: EQ 3-bande con Q-factor ottimizzato (55Hz, 75Hz, 80Hz)
- **Oversampling**: processing a 96kHz con precisione SoXR 28-bit per audio ultra-clean
- **Limiter dinamico**: attack/release adattivi per profilo, level=disabled, asc=1

---

## Guida Bitrate - La Regola d'Oro

Per risultati ottimali, segui la guida bitrate ClearVoice basata sui codec supportati:

### E-AC-3 (raccomandato): Originale +192k

- 256k → 448k | 384k → 576k | 512k → 704k | 640k+ → 768k (optimal)

### AC-3 (compatibilità): Originale +256k

- 256k → 512k | 384k → 576k | 512k+ → 640k (limite hardware standard)

> Perché +192k/+256k? Compensa perdite da reprocessing, artefatti lossy-to-lossy, headroom per transitori vocali e spazio per dettagli EQ recuperati.

## Parametri di Elaborazione

Per ogni profilo, lo script applica parametri calibrati specifici con sistema intelligente a punteggio:

Lo script mostra a schermo i parametri attivi e segnala quando viene attivata la protezione LFE avanzata per contenuti ad alta dinamica:

```bash
[Info] Rilevato "Alta Dinamica" - Attivata protezione LFE avanzata!
```

## Perché ClearVoice

- **🎭 Dialoghi sempre perfetti**: Sistema a punteggio intelligente per parametri ottimali automatici
- **🚀 Tecnologia avanzata**: EQ multi-banda voce, LFE chirurgico 3-bande, oversampling SoXR 28-bit  
- **🧠 Zero pensieri**: Selezione profilo automatica, parametri calibrati, tutto senza configurazione
- **⚡ Compatibilità universale**: Output compatibile con ogni sistema, dalle soundbar ai sistemi hi-end
- **🎬 Ottimizzato per contenuti moderni**: Calibrato per streaming Netflix/Amazon e film problematici
- **🔧 Parametri dinamici**: Front L/R, FC, LFE e Surround calibrati specificamente per ogni scenario
- **🛠️ Facile da usare**: Una semplice riga di comando per un audio cinematografico perfetto

> "Sistema intelligente a punteggio per audio perfetto...questa è la via"

---

**Developed by Sandro Sabbioni (Audio Processing Engineer)**
