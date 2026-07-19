# RISVEGLIO — Documento di progetto
Ultimo aggiornamento: 19 luglio 2026

## Chi sono
Mi chiamo Fabrizio Giannandrea. Non sono un tecnico informatico — spiegami sempre le cose in modo semplice, passo per passo, in italiano, un'azione alla volta con conferma.
Lavoro su turni (vigile del fuoco, sezione B3). Ho già due app fatte con lo stesso metodo: NutriGest e Patrimonio.

## Cos'è Risveglio
App personale di routine in stile anime **Solo Leveling**: completo "quest" giornaliere (sport, cultura, corsi, meditazione), guadagno XP, salgo di livello. Se salto le quest, perdo XP e posso scendere di livello. Ogni 20 livelli (al PRIMO raggiungimento) si sblocca una foto milestone per confrontarmi esteticamente nel tempo.

- **File principale**: `index.html` (unico file self-contained: HTML + CSS + JS)
- **File di configurazione**: `config.js` — contiene SOLO le chiavi Supabase. Si crea una volta e non si tocca mai più. Quando arriva un `index.html` nuovo, si sostituisce e basta: nessuna chiave da reinserire.
- **Versione**: costante `APP_VERSION` nel codice, mostrata in fondo alla schermata Profilo (serve per verificare che il telefono abbia l'ultima build). Attuale: 2.2
- **GitHub**: `github.com/giannandreafabrizio-dotcom/Risveglio` (attenzione: R maiuscola)
- **URL live**: `https://giannandreafabrizio-dotcom.github.io/Risveglio/`
- **Cartella locale**: `C:\Users\giann\Desktop\Routine`
- **Database**: Supabase, progetto `zxuexfhuxxmsleiqkoaz` (SEPARATO da NutriGest `zrhmspylnlklppvhgplp` — non confonderli!)
- **Autenticazione**: nessuna (app personale, RLS disattivata, accesso con anon key)
- **ID utente fisso**: `00000000-0000-0000-0000-000000000001` (costante `OWNER_ID` nel codice)
- **Dispositivi**: Windows laptop + iPhone 15 Pro Max (installata da Safari → Aggiungi a Home)

## Sistema di gioco
- XP per livello: `140 + livello × 6` (funzione `xpNeeded`)
- XP per quest in base alla difficoltà (10–50), definiti nella tabella `quests`
- Combo +30 XP se completo TUTTE le giornaliere; completa anche la streak
- Bonus settimanale +40 XP al raggiungimento di 3 allenamenti nella settimana (una tantum)
- Quest speciali a ogni soglia 20/40/60/80: 3 sfide a scelta (definitiva), ricompensa XP al completamento reale (vedi sezione dedicata)
- Penalità −70 XP: automatica da v1.6 + bottone demo nel Profilo per simulare manualmente
- Gradi: E (1) · D (10) · C (20) · B (35) · A (55) · S (80) — funzione `rankForLevel`
- Il livello sale E scende; `max_level_reached` invece non scende mai ed è ciò che sblocca le foto milestone (1, 20, 40, 60, 80) — così scendere e risalire non ri-attiva la milestone

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
| profiles | livello, XP, max_level, rank, streak, timezone, last_penalty_check, last_weekly_bonus_week (1 riga, OWNER_ID) | ✅ in uso |
| quests | definizioni quest giornaliere (title, subtitle, category, xp_value, frequency, is_active, sort_order) | ✅ in uso, gestibile dall'app (v1.8) |
| quest_logs | 1 riga per quest completata per data (UNIQUE quest_id+data) | ✅ in uso |
| xp_events | registro append-only di ogni variazione XP; reason: quest, combo, weekly_bonus, penalty, penalty_auto, special | ✅ in uso |
| workout_plans / workout_exercises | schede A-Spinta, B-Tirata, C-Gambe + esercizi | ✅ in uso |
| workout_logs | pesi salvati per esercizio e data ("ultimo: Xkg") | ✅ in uso |
| shift_overrides | eccezioni turnario: ferie / richiamo / libero | ✅ in uso |
| calendar_events | giorni di allenamento segnati (all_day, senza orario) | ✅ in uso |
| books | libreria libri (title, author, status 'reading'/'finished', finished_date, sort_order, created_at) | ✅ in uso (v1.4) |
| progress_photos | foto milestone (user_id, level, path, created_at; UNIQUE user_id+level) | ✅ in uso (v1.5) |
| special_quests | quest speciali scelte (user_id, threshold, challenge_id, title, description, metric, goal, baseline, xp_reward, status, accepted_at, completed_at; UNIQUE user_id+threshold) | ✅ in uso (v1.9) |

## Storage Supabase
- Bucket **`progress-photos`** — PUBBLICO. Foto milestone, path `{OWNER_ID}/lvl-N.jpg`, upload `upsert:true`.
- Policy `risveglio_photos_all` su `storage.objects`: `for all to anon` filtrata per `bucket_id`.
- Nel codice: costante `PHOTO_BUCKET`. Lettura con `getPublicUrl` + `?t=<created_at>` per bustare la cache.

## Struttura di index.html
Un solo file. Ordine interno dello `<script>`:
1. Chiavi Supabase (`SUPABASE_URL`, `SUPABASE_ANON_KEY`)
2. Logica livelli pura (`xpNeeded`, `rankForLevel`, `applyXp`)
3. Categorie `CAT` + catalogo sfide speciali `CHALLENGES` + `METRIC_LABEL`
4. Motore turnario (`shiftFor`, `SHIFT_COLOR`)
5. Stato globale + caricamento (`load`, `loadBooks`, `loadPhotos`, `checkDailyPenalty`, `loadWeeklyTraining`, `checkWeeklyBonus`, `loadSpecial`, `measureMetrics`, `checkSpecialQuests`, `loadWorkout`, `loadCal`)
6. **Audio v2.0** (`initMusic`, `toggleMusic`, `openSpotify`, effetti `tone`/`sfxQuest`/`sfxCombo`/`sfxLevel`/`sfxBad`, `welcomeCheck`, `levelUpModal`)
7. Azioni (`completeQuest`, `skipDay`, `saveWeight`, `setOverride`, `toggleTraining`, `saveBook`, `finishBook`, `delBook`, `uploadPhoto`, `delPhoto`, `refreshWeekly`, `loadAllQuests`, `saveQuestForm`, `toggleQuestActive`, `moveQuest`, `acceptChallenge`, `offerSpecial`)
8. Viste: `viewHome` (con pannello turno + bottoni musica/Spotify) `viewWorkout` `viewCalendar` `viewLibrary` `viewProfile` (con `specialSection`) `viewManageQuests`
9. Modali `#special` (scelta sfida, sfida completata, form quest/libro, foto, penalità, menu calendario, benvenuto, level up) + input file `#photoInput`
10. Avvio in fondo

## Libreria (v1.4) · Foto milestone (v1.5) · Penalità automatica (v1.6) · Quest settimanale (v1.7) · Gestisci Quest (v1.8)
(sezioni invariate — vedi versioni precedenti del documento nella cronologia; riassunto nella tabella tabelle e nella Storia in fondo)

- Libreria: tabella `books`, `viewLibrary` con "In lettura"/"Finiti"; libro in lettura collegato alla quest "Leggi 10 pagine" (regex `/pagin|legg/i`).
- Foto milestone: caselle nel Profilo, upload/sostituisci/elimina su bucket `progress-photos`.
- Penalità automatica: `checkDailyPenalty` in `load()`, colonna `last_penalty_check`, −70 XP se ieri zero quest.
- Quest settimanale: barra verde in Home, `weekTrained` = giorni distinti allenamento (calendario ∪ pesi), bonus +40 XP a 3, colonna `last_weekly_bonus_week`, `refreshWeekly()`.
- Gestisci Quest: Profilo → "⚙ Gestisci Quest" (`tab='manage'`, `viewManageQuests`), aggiungi/modifica/attiva-disattiva/riordina, riusa tabella `quests`.

## Quest speciali (v1.9, 18 lug 2026)
- Tabella `special_quests` (ricreata pulita: prima era solo grafica). Una riga per soglia scelta.
- **Catalogo `CHALLENGES` nel codice** (i testi li ha scritti Claude, a sorpresa per l'utente): soglie 20/40/60/80, ognuna con 3 opzioni (facile/media/difficile) a XP crescente. Nomi evocativi stile Solo Leveling (es. "Il Rituale delle Tre Albe", "L'Opera Magna"). Se in futuro si vogliono cambiare o ampliare le sfide, si modifica SOLO l'oggetto `CHALLENGES`.
- **Metriche cumulative** misurate da `measureMetrics()` (aggiorna il globale `metricNow`): `quests_total` (righe quest_logs), `perfect_days` (xp_events reason='combo'), `trainings` (giorni distinti calendario ∪ pesi), `books` (libri finiti), `active_days` (giorni distinti con quest). Sono tutte cumulative → non regrediscono, quindi il completamento è sempre raggiungibile.
- **Scelta definitiva**: al primo raggiungimento di una soglia, `offerSpecial(threshold)` apre `specialChoiceModal` con le 3 sfide. `acceptChallenge` (con `confirm`) crea la riga: cattura `baseline = metrica attuale`, imposta `goal = baseline + target`, salva title/description/metric/xp_reward, status='active'. `UNIQUE(user_id,threshold)` garantisce che non si possa scegliere due volte.
- **Completamento automatico**: `checkSpecialQuests()` gira in `load()` e dopo `completeQuest`, `finishBook`, `refreshWeekly`. Per ogni sfida attiva, se `metrica_attuale >= goal` → status='completed', `commitXp(xp_reward,'special')`, popup verde `specialCompletedModal`. Nessuna conferma "sulla parola": è il Sistema a misurare.
- **Profilo**: `specialSection()` mostra, per ogni soglia sbloccata (max_level_reached ≥ soglia), lo stato: DISPONIBILE (bottone "SCEGLI" → riapre la scelta se non ancora fatta), IN CORSO (barra progresso `metrica_attuale − baseline` su `goal − baseline`) o COMPLETATA ✓.
- La foto milestone (v1.5) e la quest speciale (v1.9) sono cose distinte ma condividono le stesse soglie 20/40/60/80.

## Personalizzazione "Sistema" · Musica (v2.0–v2.2, 19 lug 2026)
- **Nessuna nuova tabella database**: tutto lato codice/browser (`localStorage` per preferenze, nessun dato sensibile).
- **Effetti visivi** (CSS): scanline leggera su tutto lo sfondo (`body::after`), raggio di scansione animato che scorre dall'alto (`body::before`), effetto "sheen" di luce che attraversa la barra XP (`.bar>i::after`), testo LEVEL UP pulsante (`.lvltxt`). Tutto disattivato se l'utente ha `prefers-reduced-motion`.
- **Effetti sonori originali** (Web Audio, nessun file esterno): `sfxQuest` (bling breve a ogni quest completata), `sfxCombo` (arpeggio a 4 note per combo/sfida completata), `sfxLevel` (fanfara più lunga al level up), `sfxBad` (suono cupo discendente per la penalità demo). Generati con oscillatori (`tone()`), nessun asset da scaricare.
- **Musica di sottofondo facoltativa**: se l'utente mette un file `musica.mp3` nella cartella dell'app, il bottone ♪/🔊 in Home lo riproduce in loop. Preferenza salvata in `localStorage` (`rv_music`); su iPhone la ripartenza automatica ad ogni apertura richiede comunque un tocco (regola Apple), gestita con listener su `pointerdown`. Se il file manca, il bottone avvisa senza errori.
- **Colonna sonora originale via Spotify**: le musiche vere di Solo Leveling sono protette da copyright e non possono essere incluse nel repository (pubblico). Soluzione adottata: bottone verde **♫** in Home (`openSpotify`) che apre direttamente la playlist Spotify personale dell'utente (costante `SPOTIFY_PLAYLIST_ID` nel codice, playlist "Anime"). Su iPhone salta nell'app Spotify; la musica continua in sottofondo tornando su Risveglio.
- **Popup benvenuto del Sistema**: una volta al giorno (`localStorage` chiave `rv_welcome`), mostra il turno di oggi (dal motore turnario) e un messaggio diverso per diurno/notte/smontante/riposo/salto turno.
- **Popup LEVEL UP**: si apre automaticamente quando il livello sale dopo una quest (non in concorrenza con la milestone foto, che ha priorità se scattano insieme).
- **Home rinnovata**: pannello "OGGI" col turno corrente (icona e colore coerenti col Calendario), bottoni ♫ (Spotify) e ♪/🔊 (musica locale) accanto allo streak.
- Per cambiare la playlist Spotify in futuro: modificare solo la costante `SPOTIFY_PLAYLIST_ID` in `index.html`.

## Roadmap
1. ~~Libreria collegata al DB~~ ✅ (v1.4)
2. ~~Foto milestone~~ ✅ (v1.5)
3. ~~Penalità automatica~~ ✅ (v1.6)
4. ~~Quest settimanali reali~~ ✅ (v1.7)
5. ~~Quest speciali dal DB~~ ✅ (v1.9)
6. ~~Modifica quest dall'app~~ ✅ (v1.8)
7. ~~Personalizzazione "Sistema" (audio, popup, effetti)~~ ✅ (v2.0–v2.2)
8. Idee future (aperte): grafico storico carichi per esercizio; storico XP (da `xp_events`); statistiche streak; eventuali nuove sfide nel catalogo `CHALLENGES`; sfide "assolute" basate sulla streak in corso.

## Regole di sviluppo — SEMPRE
1. **Non rompere mai quello che funziona** — prima di modificare una funzione, leggerla tutta
2. Un solo file `index.html` per l'app + `config.js` per le sole chiavi — mai altri file CSS/JS separati
3. Prima di sostituire index.html, tenere copia del precedente (`index_vecchio.html`)
4. **Le chiavi NON si toccano più**: stanno in `config.js`. Sostituire index.html direttamente. Alzare `APP_VERSION` a ogni consegna.
5. Testare in locale (doppio clic) PRIMA del push; warning console "Unsafe attempt to load URL file:" in locale è innocuo.
6. `node --check` sul blocco script prima di consegnare (regola ereditata da NutriGest)
7. URL Supabase: SOLO `https://zxuexfhuxxmsleiqkoaz.supabase.co` — senza barra finale, senza `/rest/v1`
8. Commit: `git add index.html && git commit -m "descrizione" && git push` dalla cartella `C:\Users\giann\Desktop\Routine`
9. GitHub Pages si aggiorna in ~30 secondi. Se l'iPhone mostra la versione vecchia: rimuovere l'icona dalla Home e riaggiungerla da Safari. Verificare `APP_VERSION` nel Profilo.
10. I file `.js` su Windows NON si aprono col doppio clic: tasto destro → Apri con → Blocco note.
11. Nuove tabelle: RLS disattivata + `grant all ... to anon` + `notify pgrst, 'reload schema';`. Avviso "Potential issue detected / creates a table without RLS" → **Run without RLS** (NON "Run and enable RLS"). Storage: bucket pubblico + policy `for all to anon` filtrata per `bucket_id`. Una semplice `alter table ... add column` di solito non fa comparire l'avviso.
12. Aggiornare QUESTO file quando cambia qualcosa di strutturale.
13. Testare penalità/rollover settimanale in locale: cambiare temporaneamente la data del PC o modificare `last_penalty_check`/`last_weekly_bonus_week` da SQL; ripristinare la data dopo.
14. Le quest giornaliere si gestiscono dall'app (Profilo → "⚙ Gestisci Quest"): niente più SQL manuale per aggiungere/modificare/disattivare/riordinare.
15. Le sfide delle quest speciali sono nel catalogo `CHALLENGES` in `index.html`: per cambiarle basta modificare quell'oggetto (non serve toccare il database). Le metriche devono restare tra quelle misurate da `measureMetrics` (o aggiungerne di nuove lì).

## Storia essenziale
- 18 lug 2026: progettazione, mockup, database, app online su GitHub Pages, installata su iPhone. Home + Schede + Calendario turnario collegati. Incidenti risolti: chiave incollata male (SyntaxError riga 139), URL con `/rest/v1` doppio (404).
- 18 lug 2026 (v1.4): **Libreria** collegata al DB (tabella `books`). Roadmap punto 1 chiuso.
- 18 lug 2026 (v1.5): **Foto milestone** (tabella `progress_photos` + bucket `progress-photos`). Roadmap punto 2 chiuso.
- 18 lug 2026 (v1.6): **Penalità automatica** (colonna `last_penalty_check`). Roadmap punto 3 chiuso.
- 18 lug 2026 (v1.7): **Quest settimanale 3 allenamenti** (colonna `last_weekly_bonus_week`, barra in Home, bonus +40 XP). Roadmap punto 4 chiuso.
- 18 lug 2026 (v1.8): **Gestisci Quest dall'app** (riusa `quests`, schermata dal Profilo). Roadmap punto 6 chiuso.
- 18 lug 2026 (v1.9): **Quest speciali dal DB** (tabella `special_quests` ricreata, catalogo `CHALLENGES` nel codice, 3 sfide per soglia a scelta definitiva, ricompensa XP al completamento reale verificato automaticamente). Roadmap punto 5 chiuso. Con questo la roadmap principale (punti 1–6) è COMPLETA.
- 19 lug 2026 (v2.0–v2.2): **Personalizzazione "Sistema"**: effetti visivi (scanline, raggio di scansione, sheen sulla barra XP), effetti sonori generati via Web Audio, popup benvenuto giornaliero e popup LEVEL UP, pannello turno in Home. Musica: supporto `musica.mp3` locale opzionale + bottone Spotify collegato alla playlist personale dell'utente (le musiche originali di Solo Leveling restano escluse per copyright, non distribuibili in un repository pubblico). Roadmap punto 7 chiuso.
