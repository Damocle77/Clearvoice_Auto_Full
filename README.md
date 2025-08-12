# 🎙️ ClearVoice Auto Full – "Tuffati nel Suono" – v3.0

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


ClearVoice Auto Full è uno script Bash che trasforma la traccia audio dei tuoi video in un’esperienza immersiva e professionale, pensato per chi vuole risultati da studio senza complicazioni. **Dalla versione 3.0 la logica è completamente adattiva anche a livello spettrale multi-banda, con controllo LFE evoluto e logging dettagliato:**


- **Analisi spettrale multi-banda:** analisi RMS su bassi (30-120Hz), medio-bassi (120-300Hz), sibilanti (3-8kHz) per filtri ancora più intelligenti.
- **Controllo LFE adattivo con isteresi:** la frequenza del filtro passa-alto e la riduzione LFE sono regolate dinamicamente in base ai valori RMS reali, con neutral zone/isteresi per evitare flip-flop tra tagli simili.
- **Logging dettagliato:** ogni scelta sui filtri LFE viene loggata con motivazione e valori RMS di riferimento.
- **Fallback di sicurezza:** se l'analisi spettrale non è disponibile, vengono applicati valori di default sicuri per evitare errori.
- **Nessun notch filter:** solo passa-alto e attenuazione, per massima compatibilità DSP.
- **Voice boost, makeup gain, limiter, surround e frontali:** tutti i parametri sono adattivi e modulati in base all'analisi LUFS/LRA e spettrale.
- **Diagnostica dettagliata:** Prima e dopo l'elaborazione vengono mostrati tutti i parametri applicati e i valori di analisi.
- **Esperienza utente migliorata:** Messaggi chiari, nessun file di log temporaneo, e feedback statico durante le fasi lunghe.

### Analisi Spettrale & Logica Adattiva

ClearVoice Auto Full effettua una **analisi spettrale avanzata** del file audio tramite FFmpeg, misurando parametri come Loudness Integrato (LUFS), True Peak, Range Dinamico (LRA) e RMS su bande di frequenza chiave. Questi dati vengono utilizzati per applicare una logica completamente auto-adattiva, senza preset fissi e senza necessità di intervento manuale:

- Tutti i parametri chiave vengono regolati in tempo reale in base ai valori di LRA, LUFS, True Peak e presenza di bassi/medio-bassi/sibilanti (RMS multi-banda).
- Il filtro vocale (canale centrale) adatta automaticamente la frequenza del passa-alto, la presenza di un lowshelf anti-boomy e la morbidezza del limiter in base alla dinamica del mix.
- Il boost surround si adatta: più discreto nei mix compressi (serie/musical), più avvolgente nei film dinamici, bilanciato negli altri casi.
- La riduzione dei canali frontali e il makeup gain sono anch'essi micro-adattivi, per mantenere sempre chiarezza e impatto.
- **La riduzione dei bassi (LFE) è ora completamente adattiva, con isteresi e neutral zone:**
	- Se i bassi sono molto presenti, il passa-alto LFE sale a 50Hz e la riduzione è più forte.
	- Se i medio-bassi sono pronunciati, il passa-alto LFE si pone a 45Hz con riduzione moderata.
	- Se i valori sono borderline, viene mantenuto il taglio precedente per evitare flip-flop.
	- Se l'analisi fallisce, viene applicato un fallback sicuro (40Hz/0.72x).
- Tutto avviene in modo automatico: lo script "legge" la natura del file e si regola da solo, come un fonico Jedi.
- Viene sempre mostrata una diagnostica dettagliata dei parametri audio prima e dopo l'elaborazione, inclusa la logica LFE.
- Nessun file di log temporaneo viene creato: tutto è trasparente a schermo.
- Durante le fasi lunghe, viene mostrato un messaggio statico rassicurante invece di uno spinner grafico.

#### Estratto logico LFE adattivo (v3.0)
```bash
# --- LFE CONTROL ADATTIVO SPETTRALE (No Notch) ---
LFE_REDUCTION=0.74
LFE_HP_FREQ=35  # Default HPF Sub
LAST_LFE_HP_FREQ=${LAST_LFE_HP_FREQ:-0}
if [ -n "$BASS_RMS" ] && [ "$(awk "BEGIN {print ($BASS_RMS > -18)}")" -eq 1 ]; then
	echo "[SPECTRAL] Bassi molto presenti! HPF Sub più alto e riduzione extra."
	LFE_HP_FREQ=50
	LFE_REDUCTION=0.65
elif [ -n "$MIDBASS_RMS" ] && [ "$(awk "BEGIN {print ($MIDBASS_RMS > -11)}")" -eq 1 ]; then
	echo "[SPECTRAL] Medio-bassi pronunciati. HPF intermedio e riduzione moderata."
	LFE_HP_FREQ=45
	LFE_REDUCTION=0.68
else
	echo "[SPECTRAL] LFE in range normale, nessuna attenuazione extra."
fi
if [ -z "$BASS_RMS" ]; then
	LFE_HP_FREQ=40
	LFE_REDUCTION=0.72
	echo "[LFE_LOGIC] BASS_RMS non disponibile, fallback HPF=40Hz Riduzione=0.72x"
fi
if [ "$LAST_LFE_HP_FREQ" -ne 0 ]; then
	if [ $((LAST_LFE_HP_FREQ - LFE_HP_FREQ)) -lt 3 ] && [ $((LAST_LFE_HP_FREQ - LFE_HP_FREQ)) -gt -3 ]; then
		echo "[LFE_LOGIC] Isteresi attiva: mantengo HPF precedente ${LAST_LFE_HP_FREQ}Hz per stabilità."
		LFE_HP_FREQ=$LAST_LFE_HP_FREQ
	fi
fi
LAST_LFE_HP_FREQ=$LFE_HP_FREQ
echo "[LFE_LOGIC] Scelti HPF=${LFE_HP_FREQ}Hz | Riduzione=${LFE_REDUCTION}x per BASS_RMS=${BASS_RMS} | MIDBASS_RMS=${MIDBASS_RMS}"
LFE_FILTER="highpass=f=${LFE_HP_FREQ},poles=2,volume=${LFE_REDUCTION}"
```


#### Esempio di output diagnostico

```text
LOUDNESS INTEGRATO (EBU R128):
Input Integrated: -21.5 LUFS
TRUE PEAK ANALYSIS:
Input True Peak: -2.1 dBTP
DINAMICA E CARATTERISTICHE FILMICHE:
Loudness Range: 13.2 LU
VOICE_BOOST: 3.2
LFE_REDUCTION: 0.73
FRONT_REDUCTION: 0.85
SURROUND_BOOST: 2.7
MAKEUP_GAIN: 1.3
HIGHPASS_FREQ: 110
LIMITER_ATTACK: 5
LOWSHELF_ON: 0
```


La logica adattiva consente allo script di ottimizzare automaticamente il risultato finale in base alle caratteristiche reali del file, senza necessità di intervento manuale. Il risultato è un audio sempre bilanciato, pronto per lo streaming, la proiezione o l'ascolto in cuffia.

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
- **🎵 Qualità audio HD:** Equalizzazione avanzata, processing professionale e compatibilità con home theater, TV, cuffie e streaming.
- **🚀 Elaborazione batch:** Perfetto per stagioni intere, archivi, backup e conversioni massive.
- **🌍 Compatibilità universale:** Output EAC3 robusto, pronto per ogni player e piattaforma.

- **🧠 Zero pensieri:** Logica adattiva e analisi automatica, nessun parametro da settare manualmente.
- **🛡️ Sicurezza:** Protezione anti-clipping e diagnostica dettagliata per risultati sempre affidabili.
- **💡 Esperienza utente migliorata:** Nessun file di log temporaneo, messaggi rassicuranti durante le fasi lunghe, output sempre chiaro.

---

> "Per riportare equilibrio nella Forza ti servono solo un terminale bash e ClearVoice Batch Auto Full. Questa è la via!"
