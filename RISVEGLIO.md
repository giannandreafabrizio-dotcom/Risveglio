# RISVEGLIO — Documento di progetto
Ultimo aggiornamento: 6 agosto 2026 — versione online: **2.5** (pubblicata, commit `5fdc775`)

> ⚠ NOTA PER CHI LEGGE IL CODICE: da v2.4 `index.html` contiene un'immagine incorporata in base64
> (la faccia della schermata di risveglio, ~90.000 caratteri). È tutto su una riga sola dentro il CSS,
> nella regola `#boot .face`. Non spaventarti e non provare a leggerla: è normale.

## Chi sono
Mi chiamo Fabrizio Giannandrea. Non sono un tecnico informatico — spiegami sempre le cose in modo semplice, passo per passo, in italiano, un'azione alla volta con conferma.
Lavoro su turni (vigile del fuoco, sezione B3). Ho già due app fatte con lo stesso metodo: NutriGest e Patrimonio.

## Cos'è Risveglio
App personale di routine in stile anime **Solo Leveling**: completo "quest" giornaliere (sport, cultura, corsi, meditazione), guadagno XP, salgo di livello. Se salto le quest, perdo XP e posso scendere di livello. Ogni 20 livelli (al PRIMO raggiungimento) si sblocca una foto milestone per confrontarmi esteticamente nel tempo. Da v2.4 esiste anche una progressione parallela di **caratteristiche** (STATUS) alimentata dalle attività reali.

- **File principale**: `index.html` (unico file self-contained: HTML + CSS + JS)
- **File di configurazione**: `config.js` — contiene SOLO le chiavi Supabase. Si crea una volta e non si tocca mai più. Quando arriva un `index.html` nuovo, si sostituisce e basta: nessuna chiave da reinserire.
- **Versione**: costante `APP_VERSION` nel codice, mostrata in fondo alla schermata Profilo (serve per verificare che il telefono abbia l'ultima build). Attuale: 2.5
- **GitHub**: `github.com/giannandreafabrizio-dotcom/Risveglio` (attenzione: R maiuscola)
- **URL live**: `https://giannandreafabrizio-dotcom.github.io/Risveglio/`
- **Cartella locale**: `C:\Users\giann\Desktop\Routine`
- **Database**: Supabase, progetto `zxuexfhuxxmsleiqkoaz` (SEPARATO da NutriGest `zrhmspylnlklppvhgplp` — non confonderli!)
- **Autenticazione**: nessuna (app personale, RLS disattivata, accesso con anon key)
- **ID utente fisso**: `00000000-0000-0000-0000-000000000001` (costante `OWNER_ID` nel codice)
- **Dispositivi**: Windows laptop + iPhone 15 Pro Max (installata da Safari → Aggiungi a Home)
- **Connettore Supabase**: dal 6 agosto 2026 Claude è collegato al database tramite il connettore ufficiale Supabase. Può leggere le tabelle e fare diagnosi da solo, senza chiedere copia-incolla di query.

## Sistema di gioco
- XP per livello: `140 + livello × 6` (funzione `xpNeeded`)
- XP per quest in base alla difficoltà (10–50), definiti nella tabella `quests`
- Combo +30 XP se completo TUTTE le giornaliere; completa anche la streak
- Bonus settimanale +40 XP al raggiungimento di 3 allenamenti nella settimana (una tantum)
- Quest speciali a ogni soglia 20/40/60/80: 3 sfide a scelta (definitiva), ricompensa XP al completamento reale (vedi sezione dedicata)
- Penalità −70 XP: automatica da v1.6 + bottone demo nel Profilo per simulare manualmente
- Gradi: E (1) · D (10) · C (20) · B (35) · A (55) · S (80) — funzione `rankForLevel`
- Titoli (v2.4, funzione `titleForLevel`, basata su `max_level_reached`): Risvegliato (1) · Apprendista del Sistema (10) · Lupo Solitario (20) · Cacciatore d'Elite (35) · Signore della Notte (55) · Sovrano delle Ombre (80)
- Il livello sale E scende; `max_level_reached` invece non scende mai ed è ciò che sblocca le foto milestone (1, 20, 40, 60, 80) — così scendere e risalire non ri-attiva la milestone
- **Le caratteristiche NON danno XP**: l'XP resta legato esclusivamente alle quest, così l'economia dei livelli non cambia. (Scelta di progetto di v2.4, ancora aperta a modifiche — vedi "Punti in sospeso".)
- **Da v2.5 il totale XP non è più un numero "tenuto a memoria"**: si ricalcola sempre rigiocando la tabella `xp_events` (vedi sezione dedicata).

## Turnario (motore di calcolo — NON toccare senza verificare)
I turni NON sono salvati nel database: sono CALCOLATI dalla funzione `shiftFor(dateStr)`.
- Ciclo di 4 giorni: Diurno (8–20, giallo) → Notte (20–8, blu) → Smontante → Riposo
- Ogni ciclo avanza la sezione: B1→B2→…→B8→B1 (ciclo completo 32 giorni)
- Ancoraggio verificato: **1 novembre 2026 = B2 diurno** (costanti `ANCHOR`, `ANCHOR_B`)
- La mia sezione è **B3** (`MY_SECTION=3`): quando il ciclo è B3, salto turno → diurno e notte liberi (verde)
- Eccezioni (ferie/richiami/permessi) nella tabella `shift_overrides`, gestite toccando un giorno nel calendario
- Ferie: 27 giorni/anno, contatore automatico nel calendario

## Database Supabase — tabelle
| Tabella | Uso | Stato |
|---|---|---|
| profiles | livello, XP, max_level, rank, streak, timezone, last_penalty_check, last_weekly_bonus_week (1 riga, OWNER_ID) | ✅ in uso — da v2.5 è solo una **copia** del totale, non la fonte |
| quests | definizioni quest giornaliere (title, subtitle, category, xp_value, frequency, is_active, sort_order) | ✅ in uso, gestibile dall'app (v1.8) |
| quest_logs | 1 riga per quest completata per data (UNIQUE quest_id+data) | ✅ in uso |
| xp_events | registro append-only di ogni variazione XP; reason: quest, combo, weekly_bonus, penalty, penalty_auto, special, manual | ✅ in uso — **fonte di verità del totale XP (v2.5)** |
| workout_plans / workout_exercises | schede A-Spinta, B-Tirata, C-Gambe + esercizi | ✅ in uso |
| workout_logs | pesi salvati per esercizio e data ("ultimo: Xkg") | ✅ in uso |
| shift_overrides | eccezioni turnario: ferie / richiamo / libero | ✅ in uso |
| calendar_events | giorni di allenamento segnati (all_day, senza orario) | ✅ in uso |
| books | libreria libri (title, author, status 'reading'/'finished', finished_date, sort_order, created_at) | ✅ in uso (v1.4) |
| progress_photos | foto milestone (user_id, level, path, created_at; UNIQUE user_id+level) | ✅ in uso (v1.5) |
| special_quests | quest speciali scelte (user_id, threshold, challenge_id, title, description, metric, goal, baseline, xp_reward, status, accepted_at, completed_at; UNIQUE user_id+threshold) | ✅ in uso (v1.9) |
| stat_logs | attività giornaliere per le caratteristiche (user_id, log_date, activity, amount, variant, created_at; UNIQUE user_id+log_date+activity) | ✅ creata e funzionante (v2.4) — **ancora mai usata: 0 righe al 6 ago 2026** |

## Storage Supabase
- Bucket **`progress-photos`** — PUBBLICO. Foto milestone, path `{OWNER_ID}/lvl-N.jpg`, upload `upsert:true`.
- Policy `risveglio_photos_all` su `storage.objects`: `for all to anon` filtrata per `bucket_id`.
- Nel codice: costante `PHOTO_BUCKET`. Lettura con `getPublicUrl` + `?t=<created_at>` per bustare la cache.

## Struttura di index.html
Un solo file. Ordine interno dello `<script>`:
1. Chiavi Supabase (`SUPABASE_URL`, `SUPABASE_ANON_KEY`)
2. Logica livelli pura (`xpNeeded`, `rankForLevel`, `titleForLevel`, `applyXp`, **`milestoneCrossed`**)
3. Categorie `CAT` + caratteristiche `STAT_DEF` / `ACT` / `GRIPS` + catalogo sfide speciali `CHALLENGES` + `METRIC_LABEL`
4. Motore turnario (`shiftFor`, `SHIFT_COLOR`)
5. Stato globale + caricamento (`load`, **`syncXpFromLedger`**, `loadBooks`, `loadPhotos`, `checkDailyPenalty`, `loadWeeklyTraining`, `checkWeeklyBonus`, `loadSpecial`, `measureMetrics`, `loadStats`, `checkSpecialQuests`, `loadWorkout`, `loadCal`)
6. Audio v2.0 (`initMusic`, `toggleMusic`, `openSpotify`, effetti `tone`/`sfxQuest`/`sfxCombo`/`sfxLevel`/`sfxBad`, `welcomeCheck`, `levelUpModal`)
7. Azioni (**`stateFromLedger`**, `commitXp`, `completeQuest`, `skipDay`, `saveWeight`, `setOverride`, `toggleTraining`, `saveBook`, `finishBook`, `delBook`, `uploadPhoto`, `delPhoto`, `refreshWeekly`, `loadAllQuests`, `saveQuestForm`, `toggleQuestActive`, `moveQuest`, `acceptChallenge`, `offerSpecial`, `saveRegistro`)
8. Viste: `viewHome` `viewWorkout` `viewCalendar` `viewLibrary` `viewProfile` `viewManageQuests` `viewStatus` `viewRegistro`
9. Modali `#special` (scelta sfida, sfida completata, form quest/libro, foto, penalità, menu calendario, benvenuto, level up, caratteristica aumentata) + input file `#photoInput`
10. Schermata di risveglio `#boot` (`bootHide`, `initBoot`) + avvio in fondo

## Libreria (v1.4) · Foto milestone (v1.5) · Penalità automatica (v1.6) · Quest settimanale (v1.7) · Gestisci Quest (v1.8)
- Libreria: tabella `books`, `viewLibrary` con "In lettura"/"Finiti"; libro in lettura collegato alla quest "Leggi 10 pagine" (regex `/pagin|legg/i`).
- Foto milestone: caselle nel Profilo, upload/sostituisci/elimina su bucket `progress-photos`.
- Penalità automatica: `checkDailyPenalty` in `load()`, colonna `last_penalty_check`, −70 XP se ieri zero quest.
- Quest settimanale: barra verde in Home, `weekTrained` = giorni distinti allenamento (calendario ∪ pesi), bonus +40 XP a 3, colonna `last_weekly_bonus_week`, `refreshWeekly()`.
- Gestisci Quest: Profilo → "⚙ Gestisci Quest" (`tab='manage'`, `viewManageQuests`), aggiungi/modifica/attiva-disattiva/riordina, riusa tabella `quests`.

## Quest speciali (v1.9, 18 lug 2026)
- Tabella `special_quests`. Una riga per soglia scelta.
- **Catalogo `CHALLENGES` nel codice**: soglie 20/40/60/80, ognuna con 3 opzioni (facile/media/difficile) a XP crescente.
- **Metriche cumulative** misurate da `measureMetrics()` (aggiorna il globale `metricNow`): `quests_total`, `perfect_days`, `trainings`, `books`, `active_days`.
- **Scelta definitiva**: `offerSpecial(threshold)` → `specialChoiceModal`; `acceptChallenge` cattura `baseline` e imposta `goal = baseline + target`.
- **Completamento automatico**: `checkSpecialQuests()` gira in `load()` e dopo `completeQuest`, `finishBook`, `refreshWeekly`.
- **Profilo**: `specialSection()` mostra DISPONIBILE / IN CORSO (barra) / COMPLETATA ✓.
- Da v2.4 `measureMetrics()` viene chiamata SEMPRE in `load()` (serve anche alle caratteristiche), non solo quando c'è una sfida attiva.

## Personalizzazione "Sistema" · Musica (v2.0–v2.2, 19 lug 2026)
- **Nessuna nuova tabella database**: tutto lato codice/browser (`localStorage`).
- **Effetti visivi** (CSS): scanline (`body::after`), raggio di scansione (`body::before`), sheen sulla barra XP (`.bar>i::after`), testo LEVEL UP pulsante (`.lvltxt`). Disattivati con `prefers-reduced-motion`.
- **Effetti sonori originali** (Web Audio, nessun file esterno): `sfxQuest`, `sfxCombo`, `sfxLevel`, `sfxBad`.
- **Musica di sottofondo facoltativa**: file `musica.mp3` nella cartella, bottone ♪/🔊 in Home, preferenza in `localStorage` (`rv_music`).
- **Colonna sonora via Spotify**: bottone ♫ verde (`openSpotify`, costante `SPOTIFY_PLAYLIST_ID`). Le musiche originali di Solo Leveling restano fuori dal repository per copyright.
- **Popup benvenuto** una volta al giorno (`rv_welcome`) e **popup LEVEL UP**.

## Fix layout iPhone (v2.3, 21 lug 2026)
- `padding-top` di `#app` usa `calc(24px + env(safe-area-inset-top))`: l'orologio/barra di stato non copre più "SYSTEM · RISVEGLIO".

## Risveglio del Sistema · STATUS · Registro (v2.4, 3 ago 2026)

### 1. Schermata di apertura "IL SISTEMA SI RISVEGLIA"
- Overlay `#boot` a tutto schermo mostrato a OGNI apertura dell'app, prima della schermata Quest.
- Immagine: la faccia del Monarca fornita dall'utente, **incorporata in base64 nel CSS** (regola `#boot .face`, ~90 KB). Nessun file esterno da caricare su GitHub: l'app resta `index.html` + `config.js`.
- Effetti: zoom lento (`bootzoom`), flash iniziale, scanline, raggio di scansione, vignettatura, scritte "⚠ SISTEMA · CONNESSIONE IN CORSO" e "IL SISTEMA SI RISVEGLIA".
- Si chiude **al tocco** o **dopo 3,6 secondi** (`bootHide`). Viene chiusa anche in caso di errore di avvio o config mancante, per non lasciare l'app bloccata dietro l'immagine.
- Il popup di benvenuto giornaliero resta sotto e compare quando l'overlay sparisce (z-index: `#boot` 100, `#special` 60).
- Per cambiare l'immagine in futuro: sostituire la stringa base64 dentro `url(data:image/jpeg;base64,...)` nella regola `#boot .face`.

### 2. STATUS — le caratteristiche
- Si apre **toccando il pannello Livello/Grado in Home** (o il pannello viola in cima al Profilo) → `tab='status'`, funzione `viewStatus()`.
- Sette caratteristiche (`STAT_DEF`): **FORZA · AGILITÀ · VELOCITÀ · VITALITÀ · INTELLIGENZA · PERCEZIONE · SPIRITO**.
  (SPIRITO è il nome scelto per la meditazione, tra le alternative Sensibilità / Anima / Mente.)
- Ogni caratteristica parte da `STAT_BASE = 10` e sale di +1 ogni `STAT_STEP = 25` punti. Barra di avanzamento verso il punto successivo su ogni scheda.
- Pannello superiore in stile Solo Leveling: livello grande, **CLASSE** (Nessuna sotto il livello 20, poi Cacciatore), **TITOLO** (`titleForLevel`), barre **HP** (`100 + VIT×80 + FOR×10`), **MP** (`50 + INT×10 + SPI×15`) e **FATICA** (percentuale di quest di oggi ancora da fare: 0 = riposato).
- Collegamento attività → caratteristica (oggetto `ACT`, campo `pts` = punti per unità):

| Caratteristica | Attività | Punti |
|---|---|---|
| FORZA | allenamenti in palestra (**automatico**: giorni distinti da `workout_logs` ∪ `calendar_events`) | 10 a sessione |
| AGILITÀ | push-up · squat · trazioni · verticali al muro (HSPU) | 0,2 · 0,15 · 1 · 2 a ripetizione |
| VELOCITÀ | corsa | 4 al km |
| VITALITÀ | passi giornalieri | 0,0025 a passo (2,5 ogni 1000) |
| INTELLIGENZA | libri finiti (**automatico** da `books`) + pagine lette | 30 a libro · 0,1 a pagina |
| PERCEZIONE | lezioni Duolingo + portoghese | 3 a lezione |
| SPIRITO | meditazione | 0,3 al minuto |

- Funzioni: `loadStats()` (carica `stat_logs`, riempie `statRows`, `statTotals`, `regToday`), `statPoints()`, `statValues()`.
- Le attività con `auto:true` in `ACT` (`palestra`, `libri`) NON si registrano a mano: si contano da `metricNow.trainings` e `metricNow.books`.
- ⚠ **La quest "Sessione allenamento" NON alimenta né FORZA né la barra settimanale**: quelle contano solo `calendar_events` e `workout_logs`. Punto aperto, vedi "Punti in sospeso".

### 3. REGISTRO — inserimento della giornata
- Si apre dallo STATUS con "✎ REGISTRA LA GIORNATA" → `tab='reg'`, funzione `viewRegistro()`.
- Una riga per attività, raggruppate per caratteristica: campo numerico + bottoni **−** e **+** con passo diverso per attività (`step`: 1, 10 o 1000).
- Si scrive il **totale della giornata**: il salvataggio fa `upsert` su `stat_logs` con chiave `user_id + log_date + activity`, quindi sostituisce il valore di oggi e non tocca i giorni passati.
- Il salvataggio (`saveRegistro`) scrive solo le righe effettivamente cambiate, poi ricarica le statistiche e, se una caratteristica è salita, apre il popup **CARATTERISTICA AUMENTATA** (`statUpModal`) con suono `sfxCombo`.
- **Trazioni a rotazione automatica**: costante `GRIPS = ['Pull-up · presa prona', 'Chin-up · presa supina', 'Trazioni · presa neutra']`. `gripIndex()` conta i giorni passati in cui sono state registrate trazioni e ruota; `gripToday()` mostra l'impugnatura del giorno e la salva nella colonna `variant`. Se oggi le trazioni sono già state registrate, l'impugnatura resta quella salvata.
- **Verticali al muro** = *Strict Handstand Push-Up*, voce separata dai push-up (piegamenti sulle braccia normali).
- Se la tabella `stat_logs` non esiste ancora o non è leggibile, STATUS e REGISTRO mostrano un avviso giallo invece di rompersi (`statsLoaded=false`).
- ⚠ **Percorso poco evidente**: Home → riquadro Livello/Grado → STATUS → "✎ REGISTRA LA GIORNATA" → compilare → **"SALVA LA GIORNATA"** in fondo. Senza quell'ultimo bottone non parte niente. Al 6 ago 2026 Fabrizio non l'aveva ancora trovato e `stat_logs` era vuota.

## XP a prova di errore (v2.5, 6 ago 2026)

### Cosa era successo
Il 5 agosto 2026 Fabrizio completa 4 quest su 6 (Duolingo +20, Lezione portoghese +25, Sessione allenamento +50, Meditazione +10: 105 XP in totale). Le righe in `quest_logs` e tutti e quattro i movimenti in `xp_events` risultano salvati correttamente, ma il giorno dopo il profilo mostra **35 XP invece di 120**: 85 XP persi.

### La causa
`commitXp` calcolava il nuovo totale partendo dalla **copia in memoria** del profilo (`profile.current_xp`) e scriveva in `profiles` un valore **assoluto**. Se quella copia era vecchia — app iPhone ripresa dal background senza ricaricare, pagina rimasta aperta sul portatile, risposta in cache — il salvataggio sovrascriveva il totale buono con uno calcolato su una base superata. Le quest restavano registrate, gli XP no. Nessun messaggio d'errore, perché l'esito dell'`update` non veniva controllato.

### La soluzione
Il registro `xp_events` è append-only e non si era mai sbagliato: da v2.5 è **l'unica fonte di verità**.
- **`stateFromLedger()`** rilegge tutti gli `xp_events` in ordine di `created_at` e rigioca `applyXp` dal primo all'ultimo, ottenendo livello, XP, livello massimo e grado reali.
- **`syncXpFromLedger()`** viene chiamata in `load()` subito dopo aver letto il profilo: se il valore salvato non coincide, lo corregge nel database. Effetto collaterale voluto: **eventuali danni passati si riparano da soli alla prima apertura** (il 6 ago 2026 il profilo è tornato da 35 a 120 XP da solo).
- **`commitXp()`** ora inserisce prima l'evento nel registro, poi ricalcola il totale dal registro e scrive quello. Il valore in memoria non viene più usato per fare il conto.
- **`milestoneCrossed(prevMax,newMax)`**: nuova funzione per capire se si è superata una soglia da 20, dato che il confronto non passa più da `applyXp` su un singolo delta.
- Se la rete non risponde, `stateFromLedger()` torna `null` e `commitXp` usa il vecchio comportamento come rete di sicurezza: l'app non si blocca e il conto verrà comunque risistemato alla prossima apertura.
- `max_level_reached` non scende mai: si prende sempre il massimo tra il valore ricalcolato e quello già salvato, così le foto milestone non si ri-bloccano.

### Conseguenza pratica
**Per correggere gli XP a mano non si modifica più `profiles`**: qualunque valore scritto lì verrebbe sovrascritto al primo avvio. Si aggiunge invece una riga in `xp_events`:
```sql
insert into xp_events (user_id, delta, reason)
values ('00000000-0000-0000-0000-000000000001', 50, 'manual');
```

## Punti in sospeso (da riprendere alla prossima sessione)
1. **La "terza cosa"**: nel messaggio del 3 agosto Fabrizio ne annunciava tre ma ne ha scritte due (immagine di apertura + STATUS/caratteristiche). La terza non è mai stata detta: chiedergliela.
2. **XP dalle caratteristiche**: oggi registrare attività NON dà XP (scelta per non alterare l'economia dei livelli). Da decidere se aggiungere un piccolo XP anche al registro.
3. **Registro poco raggiungibile**: il bottone "SALVA LA GIORNATA" è in fondo a una schermata che si apre da un pannello non ovvio. Valutare una scorciatoia diretta dalla Home o dalla barra in basso.
4. **Allenamento contato a metà**: completare la quest "Sessione allenamento" non fa salire né FORZA né la barra settimanale 0/3. Valutare se la quest debba creare in automatico anche il `calendar_events` del giorno.
5. **Lista modifiche di agosto 2026**: Fabrizio ha annunciato una serie di modifiche da affrontare una alla volta. Punto 1 (XP persi) chiuso con la v2.5; gli altri sono ancora da farsi dettare.
6. Idee già emerse: grafico storico delle caratteristiche; sfide speciali basate sulle caratteristiche (es. "porta AGILITÀ a 20"); import automatico dei passi dall'app Salute dell'iPhone (richiederebbe una scorciatoia iOS).

## Roadmap
1. ~~Libreria collegata al DB~~ ✅ (v1.4)
2. ~~Foto milestone~~ ✅ (v1.5)
3. ~~Penalità automatica~~ ✅ (v1.6)
4. ~~Quest settimanali reali~~ ✅ (v1.7)
5. ~~Quest speciali dal DB~~ ✅ (v1.9)
6. ~~Modifica quest dall'app~~ ✅ (v1.8)
7. ~~Personalizzazione "Sistema" (audio, popup, effetti)~~ ✅ (v2.0–v2.2)
8. ~~Caratteristiche stile Solo Leveling + registro attività + schermata di risveglio~~ ✅ (v2.4)
9. ~~XP a prova di errore (ricalcolo dal registro)~~ ✅ (v2.5)
10. Idee future (aperte): vedi "Punti in sospeso"; grafico carichi per esercizio; storico XP (da `xp_events`); statistiche streak.

## Regole di sviluppo — SEMPRE
1. **Non rompere mai quello che funziona** — prima di modificare una funzione, leggerla tutta
2. Un solo file `index.html` per l'app + `config.js` per le sole chiavi — mai altri file CSS/JS separati (le immagini vanno incorporate in base64, vedi `#boot .face`)
3. Prima di sostituire index.html, tenere copia del precedente (`index_vecchio.html`). In alternativa vale il commit git della versione precedente, che è già una copia di sicurezza.
4. **Le chiavi NON si toccano più**: stanno in `config.js`. Sostituire index.html direttamente. Alzare `APP_VERSION` a ogni consegna.
5. Testare in locale (doppio clic) PRIMA del push; warning console "Unsafe attempt to load URL file:" in locale è innocuo.
6. `node --check` sul blocco script prima di consegnare (regola ereditata da NutriGest)
7. URL Supabase: SOLO `https://zxuexfhuxxmsleiqkoaz.supabase.co` — senza barra finale, senza `/rest/v1`
8. Commit: `git add index.html && git commit -m "descrizione" && git push`. **Nel Prompt dei comandi bisogna prima spostarsi nella cartella con `cd C:\Users\giann\Desktop\Routine`**: scrivere solo il percorso dà l'errore "non è riconosciuto come comando interno o esterno". L'avviso `LF will be replaced by CRLF` è normale su Windows.
9. GitHub Pages si aggiorna in ~30 secondi. Se l'iPhone mostra la versione vecchia: rimuovere l'icona dalla Home e riaggiungerla da Safari. Verificare `APP_VERSION` nel Profilo.
10. I file `.js` su Windows NON si aprono col doppio clic: tasto destro → Apri con → Blocco note.
11. Nuove tabelle: RLS disattivata + `grant all ... to anon` + `notify pgrst, 'reload schema';`. All'avviso **"Potential issue detected / creates a table without RLS"** premere SEMPRE il bottone **giallo "Run without RLS"**, mai il verde. Il verde ("Run and enable RLS") accende la protezione e l'app, che entra con la chiave `anon` senza login, non riesce più a leggere né scrivere quella tabella. **Rimedio se succede** (capitato il 3 ago 2026 con `stat_logs`): eseguire `alter table public.<tabella> disable row level security;` seguito da `notify pgrst, 'reload schema';` — nessun dato viene perso.
12. Aggiornare QUESTO file quando cambia qualcosa di strutturale.
13. Testare penalità/rollover settimanale in locale: cambiare temporaneamente la data del PC o modificare `last_penalty_check`/`last_weekly_bonus_week` da SQL; ripristinare la data dopo.
14. Le quest giornaliere si gestiscono dall'app (Profilo → "⚙ Gestisci Quest"): niente più SQL manuale.
15. Le sfide speciali sono nel catalogo `CHALLENGES` in `index.html`; le metriche devono restare tra quelle misurate da `measureMetrics`.
16. Le caratteristiche si tarano solo modificando `STAT_DEF`, `ACT`, `STAT_BASE` e `STAT_STEP` in `index.html`: nessuna modifica al database. Cambiare i `pts` non riscrive lo storico, ricalcola tutto al volo dai dati già salvati in `stat_logs`.
17. **Gli XP si correggono SOLO aggiungendo righe a `xp_events`** (reason `manual`), mai scrivendo dentro `profiles`: da v2.5 quel valore viene ricalcolato dal registro a ogni avvio e qualunque modifica manuale verrebbe cancellata.
18. **Prima di dare la colpa all'app, guardare i dati**: `xp_events` racconta ogni variazione con data e ora, `quest_logs` dice cosa è stato completato, `profiles.updated_at` dice quando il profilo è stato toccato l'ultima volta. Con il connettore Supabase questa verifica la fa Claude da solo.

## Storia essenziale
- 18 lug 2026: progettazione, mockup, database, app online su GitHub Pages, installata su iPhone. Home + Schede + Calendario turnario collegati. Incidenti risolti: chiave incollata male (SyntaxError riga 139), URL con `/rest/v1` doppio (404).
- 18 lug 2026 (v1.4): **Libreria** collegata al DB. Roadmap punto 1 chiuso.
- 18 lug 2026 (v1.5): **Foto milestone**. Roadmap punto 2 chiuso.
- 18 lug 2026 (v1.6): **Penalità automatica**. Roadmap punto 3 chiuso.
- 18 lug 2026 (v1.7): **Quest settimanale 3 allenamenti**. Roadmap punto 4 chiuso.
- 18 lug 2026 (v1.8): **Gestisci Quest dall'app**. Roadmap punto 6 chiuso.
- 18 lug 2026 (v1.9): **Quest speciali dal DB**. Roadmap punto 5 chiuso.
- 19 lug 2026 (v2.0–v2.2): **Personalizzazione "Sistema"**: effetti visivi e sonori, popup benvenuto e LEVEL UP, pannello turno in Home, musica locale + playlist Spotify. Roadmap punto 7 chiuso.
- 21 lug 2026 (v2.3): **Fix layout iPhone** con `env(safe-area-inset-top)`.
- 3 ago 2026 (v2.4): **Risveglio del Sistema** (schermata di apertura con la faccia del Monarca in base64), **STATUS** con 7 caratteristiche collegate ad attività reali, **REGISTRO** giornaliero con nuova tabella `stat_logs`, trazioni a rotazione automatica (pull-up → chin-up → presa neutra), verticali al muro (HSPU) e passi giornalieri come nuove attività tracciate. Roadmap punto 8 chiuso. Pubblicata con commit `3eeecd4` e verificata sull'iPhone. Incidente risolto in corsa: premuto per errore "Run and enable RLS" alla creazione di `stat_logs` → sistemato disattivando RLS (vedi regola 11).
- 5 ago 2026: **primo giorno di uso reale**. 4 quest su 6 completate (mancano "Leggi 10 pagine" e "Cultura finanziaria"), quindi niente combo e niente streak. Il Registro delle caratteristiche non viene usato: il bottone "SALVA LA GIORNATA" non era stato trovato.
- 6 ago 2026 (v2.5): **collegato il connettore Supabase a Claude** e fatta la diagnosi direttamente sul database. Scoperti 85 XP persi per il bug della copia in memoria in `commitXp`. Riscritta la gestione XP con `stateFromLedger` / `syncXpFromLedger`: il registro `xp_events` diventa l'unica fonte di verità. Profilo tornato da solo a 120 XP alla prima apertura. Pubblicata con commit `5fdc775`. Roadmap punto 9 chiuso.
