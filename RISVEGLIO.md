# RISVEGLIO — Documento di progetto
Ultimo aggiornamento: 18 luglio 2026

## Chi sono
Mi chiamo Fabrizio Giannandrea. Non sono un tecnico informatico — spiegami sempre le cose in modo semplice, passo per passo, in italiano, un'azione alla volta con conferma.
Lavoro su turni (vigile del fuoco, sezione B3). Ho già due app fatte con lo stesso metodo: NutriGest e Patrimonio.

## Cos'è Risveglio
App personale di routine in stile anime **Solo Leveling**: completo "quest" giornaliere (sport, cultura, corsi, meditazione), guadagno XP, salgo di livello. Se salto le quest, perdo XP e posso scendere di livello. Ogni 20 livelli (al PRIMO raggiungimento) si sblocca una foto milestone per confrontarmi esteticamente nel tempo.

- **File principale**: `index.html` (unico file self-contained: HTML + CSS + JS)
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
- Penalità −70 XP (bottone demo nel Profilo; da automatizzare, vedi roadmap)
- Gradi: E (1) · D (10) · C (20) · B (35) · A (55) · S (80) — funzione `rankForLevel`
- Il livello sale E scende; `max_level_reached` invece non scende mai ed è ciò che sblocca le foto milestone (1, 20, 40, 60, 80) — così scendere e risalire non ri-attiva la milestone
- Quest speciale: popup automatico al primo raggiungimento di un multiplo di 20

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
| profiles | livello, XP, max_level, rank, streak, timezone (1 riga, OWNER_ID) | ✅ in uso |
| quests | definizioni quest giornaliere/settimanali | ✅ in uso (6 giornaliere) |
| quest_logs | 1 riga per quest completata per data (UNIQUE quest_id+data = niente doppioni; il "reset giornaliero" è: nessun log oggi = da fare) | ✅ in uso |
| xp_events | registro append-only di ogni variazione XP (il livello in profiles è solo cache ricalcolabile) | ✅ in uso |
| workout_plans / workout_exercises | schede A-Spinta, B-Tirata, C-Gambe + esercizi | ✅ in uso |
| workout_logs | pesi salvati per esercizio e data ("ultimo: Xkg") | ✅ in uso |
| shift_overrides | eccezioni turnario: ferie / richiamo / libero | ✅ in uso |
| calendar_events | giorni di allenamento segnati (all_day, senza orario) | ✅ in uso |
| books | libreria libri letti | ⬜ tabella pronta, UI statica |
| progress_photos | foto milestone (path nel bucket `progress-photos`) | ⬜ tabella e bucket pronti, UI da fare |
| special_quests | quest speciali a soglie di livello | ⬜ tabella pronta, popup è solo UX |

## Struttura di index.html
Un solo file. Ordine interno dello `<script>`:
1. Chiavi Supabase (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) — in cima, ben marcate
2. Logica livelli pura (`xpNeeded`, `rankForLevel`, `applyXp`)
3. Motore turnario (`shiftFor`, `SHIFT_COLOR`)
4. Stato globale + caricamento (`load`, `loadWorkout`, `loadCal`)
5. Azioni (`completeQuest`, `skipDay`, `saveWeight`, `setOverride`, `toggleTraining`)
6. Viste: `viewHome` `viewWorkout` `viewCalendar` `viewLibrary` `viewProfile` (render via innerHTML + event delegation con `data-action`)
7. Modale `#special` (quest speciali E menu del giorno calendario)
8. Avvio in fondo

Schede: Home ✅ collegata · Schede ✅ collegata · Calendario ✅ collegato · Libreria ⬜ statica · Profilo ✅ collegato (tranne foto)

## Roadmap — prossime modifiche in ordine
1. **Libreria collegata al DB**: lista da `books`, bottone "+ aggiungi libro" (titolo, autore, stato), spostare un libro a "finito" con data. Collegare al libro in lettura il sottotitolo della quest "Leggi 10 pagine".
2. **Foto milestone**: upload dal Profilo nel bucket Storage `progress-photos` (path `{OWNER_ID}/lvl-N.jpg`), riga in `progress_photos`, galleria per confronto estetico. È il pezzo più laborioso.
3. **Penalità automatica**: oggi la penalità è un bottone manuale. Automatizzare: al primo avvio del giorno, controllare se ieri mancano quest_logs e applicare −70 XP una sola volta (serve una colonna tipo `last_penalty_check` in profiles per non duplicare).
4. **Quest settimanali reali**: "3 allenamenti/settimana" contando i calendar_events o i workout_logs della settimana; barra di avanzamento in Home.
5. **Quest speciali dal DB**: leggere/scrivere `special_quests` invece del popup solo estetico; ricompense XP alla conclusione.
6. **Modifica quest dall'app**: aggiungere/modificare/disattivare quest senza passare da SQL.
7. Idee future: grafico storico carichi per esercizio; storico XP (da `xp_events`); statistiche streak.

## Regole di sviluppo — SEMPRE
1. **Non rompere mai quello che funziona** — prima di modificare una funzione, leggerla tutta
2. Un solo file `index.html`, self-contained — mai file CSS/JS separati
3. Prima di sostituire index.html, tenere copia del precedente (`index_vecchio.html`)
4. Le CHIAVI Supabase vanno reinserite ogni volta che Claude consegna un index.html nuovo (Claude non le conosce) — righe marcate `INCOLLA_QUI` in cima allo script
5. Testare in locale (doppio clic) PRIMA del push; il warning console "Unsafe attempt to load URL file:" in locale è innocuo
6. `node --check` sul blocco script prima di consegnare (regola ereditata da NutriGest)
7. Attenzione all'URL Supabase: SOLO `https://zxuexfhuxxmsleiqkoaz.supabase.co` — senza barra finale, senza `/rest/v1` (errore già successo il 18 lug 2026: 404 su tutto)
8. Commit: `git add index.html && git commit -m "descrizione" && git push` dalla cartella `C:\Users\giann\Desktop\Routine`
9. GitHub Pages si aggiorna in ~30 secondi dopo il push
10. Nuove tabelle: RLS disattivata + `grant all ... to anon` + `notify pgrst, 'reload schema';` (senza reload lo schema nuovo non è visibile all'API)
11. Aggiornare QUESTO file nello stesso commit quando cambia qualcosa di strutturale (tabelle nuove, funzioni chiave, voci di roadmap chiuse)

## Storia essenziale
- 18 lug 2026: progettazione, mockup, database, app online su GitHub Pages, installata su iPhone. Home + Schede + Calendario turnario collegati. Incidenti risolti: chiave incollata male (SyntaxError riga 139), URL con `/rest/v1` doppio (404).
