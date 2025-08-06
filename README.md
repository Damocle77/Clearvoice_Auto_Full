# 🎙️ ClearVoice_Auto_Full – "Tuffati nel Suono" – v3.0

> "Porta la voce in primo piano come un vero Jedi del suono!"  
> "Dialoghi cristallini, bassi controllati e un mix che conquista la galassia."  
> "Perché anche un Sith non resisterebbe a una voce così limpida!"

![SELECT name AS 'Sandro Sabbioni', handle AS 'D@mocle77' FROM developers](https://img.shields.io/badge/SELECT%20name%20AS%20'Sandro%20Sabbioni'%2C%20handle%20AS%20'D%40mocle77'%20FROM%20developers-blue)

---

## Indice

 - [Cosa fa ClearVoice Auto Full](#cosa-fa-clearvoice-auto-full)
 - [Flusso di lavoro tipico](#flusso-di-lavoro-tipico)
 - [Requisiti](#requisiti)
 - [Installazione](#installazione)
 - [Utilizzo](#utilizzo)
 - [Script ausiliario batch](#script-ausiliario-batch)
 - [Perché scegliere ClearVoice](#perché-scegliere-clearvoice)

---

## Cosa fa ClearVoice Auto Full

ClearVoice Auto Full è uno script Bash che trasforma la traccia audio dei tuoi video in un’esperienza immersiva e professionale, pensato per chi vuole ottenere risultati da studio senza complicazioni:

- **Voice Boost intelligente:** Dialoghi sempre chiari e presenti, anche nei mix più complessi.
- **Equalizzazione dinamica:** Suono bilanciato, dettagliato e pronto per ogni dispositivo.
- **Mappatura automatica:** Mantiene tutte le tracce audio, sottotitoli e capitoli originali.
- **Protezione anti-clipping:** Limiter intelligente per evitare distorsioni.


### Analisi Spettrale & Logica Adattiva

ClearVoice Auto Full effettua una **analisi spettrale avanzata** del file audio tramite FFmpeg, misurando parametri come Loudness Integrato (LUFS), True Peak e Range Dinamico (LRA). Questi dati vengono utilizzati per:

- Rilevare automaticamente il tipo di contenuto (film, serie, corto, musical) tramite analisi del nome file e durata.
- Adattare dinamicamente i parametri di processing: il boost della voce, la riduzione dei bassi (LFE), il bilanciamento dei canali frontali e surround, e il makeup gain.
- Applicare filtri audio ottimizzati per ogni scenario, garantendo chiarezza vocale senza sacrificare la profondità e la dinamica del mix.
- Prevenire il clipping e la distorsione grazie a limiti intelligenti e protezioni automatiche.
- Visualizzare una diagnostica dettagliata dei parametri audio prima e dopo l'elaborazione.

#### Esempio di output diagnostico

```text
LOUDNESS INTEGRATO (EBU R128):
Input Integrated: -21.5 LUFS
TRUE PEAK ANALYSIS:
Input True Peak: -2.1 dBTP
DINAMICA E CARATTERISTICHE FILMICHE:
Loudness Range: 13.2 LU
Tipo di contenuto rilevato: film
VOICE_BOOST: 3.5
LFE_REDUCTION: 0.77
FRONT_REDUCTION: 0.77
SURROUND_BOOST: 2.3
MAKEUP_GAIN: 1.3
```

La logica adattiva consente allo script di ottimizzare automaticamente il risultato finale in base alle caratteristiche reali del file, senza necessità di intervento manuale. Il risultato è un audio sempre bilanciato, pronto per lo streaming, la proiezione o l'ascolto in cuffia.

---

## Flusso di lavoro tipico


### Uso base

```bash
# Script principale (ottimizza la voce in un singolo file)
./clearvoice_auto_full.sh "file.mkv" [bitrate] [originale]
```

### Parametri

- **file.mkv**: File video di input (obbligatorio)
- **bitrate**: Bitrate audio di output (opzionale, default: 768k)
- **originale**: yes/no (includi traccia originale, default: yes)

### Consigli pratici

- Per la massima compatibilità, usa bitrate 768k per film e 384k per serie TV.
- Se vuoi solo la traccia ottimizzata, imposta `originale` su `no`.
- Funziona con MKV, MP4, MOV e la maggior parte dei formati video supportati da FFmpeg.

---

## Requisiti

- **Bash** (Linux, macOS, WSL, o Windows con Git Bash)
- **FFmpeg** (>= 7.x con supporto E-AC3, Filtercomplex, Audiograph)

---

## Installazione

```bash
# Windows
winget install ffmpeg -e && winget install Git.Git -e

# Debian/Ubuntu
sudo apt install ffmpeg

# RHEL/CentOS/Fedora
sudo yum install ffmpeg

# macOS
brew install ffmpeg
```

```bash
# Clonazione del progetto
git clone https://github.com/Damocle77/ClearVoice_Batch_Auto_Full.git
cd clearvoice_batch_auto_full
chmod +x *.sh
```

**Nota:** Assicurati che `ffmpeg` sia nel tuo `PATH`.

---




## Utilizzo

| Script                        | Missione                        | Output                        | Tattiche Speciali                        |
|-------------------------------|---------------------------------|-------------------------------|------------------------------------------|
| `clearvoice_auto_full.sh`     | Ottimizzazione automatica voce  | `*_clearvoice_auto.mkv`       | Analisi spettrale, logica adattiva, voice boost, ducking, deesser, enhancer, diagnostica dettagliata |

---

## Script ausiliario batch

Per elaborazioni di massa su intere cartelle di file `.mkv`, usa lo script ausiliario:

```bash
# Elabora tutti i file nella cartella
./clearvoice_batch_auto_full.sh /path/to/files/ [bitrate] [preset_override]
```

- **/path/to/files/**: Cartella contenente i file video da elaborare (obbligatorio)
- **bitrate**: Bitrate audio di output (opzionale, default: 768k)
- **preset_override**: Parametro opzionale per forzare preset specifici

Lo script batch:

- Lancia automaticamente `clearvoice_auto_full.sh` su tutti i file MKV non ancora processati.
- Gestisce errori, interruzioni e log dettagliati.
- Mostra il tempo totale di elaborazione e il numero di file processati.
- Perfetto per stagioni intere, archivi, conversioni massive o backup audio.

### Esempio di output batch

```text
Trovati 12 file da processare. Attivazione protocollo 'doppia Libidine' in corso...
>>> Inizio elaborazione file 1 di 12: episodio1.mkv
>>> Completato: episodio1.mkv
...
MISSIONE COMPIUTA!
Tempo totale: 34m 12s
File processati: 12
File totali: 12
Batch terminato – 'Doppia Libidine con il fiocco!!! 🚀
```

---

## Perché scegliere ClearVoice

- **🔊 Voce sempre in primo piano:** Dialoghi chiari e intelligibili in ogni situazione, anche con effetti e musica.
- **🎵 Alta Qualità audio:** Equalizzazione avanzata e audio processing professionale.
- **🚀 Elaborazione batch:** Perfetto per stagioni intere, archivi, backup e conversioni massive.
- **🌍 Compatibilità universale:** Output EAC3 robusto, pronto per ogni player ed AVR.
- **🧠 Zero pensieri:** Logica adattiva e analisi automatica, nessun parametro da settare manualmente.
- **🛡️ Sicurezza:** Protezione anti-clipping e diagnostica dettagliata per risultati sempre affidabili.

---

> "Per riportare equilibrio nella Forza ti servono solo un terminale bash e ClearVoice Batch Auto Full. Questa è la via!"
