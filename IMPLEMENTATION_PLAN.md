# Mood Tracker — Implementation Plan

A phased plan for building the Flutter web "mood tracker" single-screen app, deploying it, and submitting it.

## Phase 0 — Setup & Repo Hygiene
- `git init` in the project directory; add a `.gitignore` appropriate for Flutter (build outputs, `.dart_tool`, IDE files).
- Create a fresh GitHub repo and push the initial scaffold as commit #1 ("Initial Flutter scaffold").
- Confirm `flutter doctor` is happy for web; ensure `web/` is configured.
- Add `shared_preferences` to `pubspec.yaml` for client-side persistence (so entries survive reload — important UX for a mood tracker even on web).
- Decision points to lock in here:
  - **Mood set**: 3 distinct moods (happy, neutral, sad) as the minimum, or expand to 5 (very happy, happy, neutral, sad, very sad)? Recommend 5 — gives a richer timeline and still meets the "at least three" requirement.
  - **Deploy target**: Firebase Hosting or Vercel. Recommend **Firebase Hosting** — Flutter web has the most boring/well-documented path (`firebase init hosting` → `flutter build web` → `firebase deploy`).

## Phase 1 — Data Model & Persistence
- Define `MoodEntry { id, moodKind enum, timestamp }`.
- Define `MoodKind` enum with the chosen N values; each has an associated accent color (e.g., happy = green, neutral = amber, sad = blue).
- Build a thin `MoodRepository` wrapping `SharedPreferences`:
  - `Future<List<MoodEntry>> loadEntries()`
  - `Future<void> addEntry(MoodEntry)`
  - JSON-encode the list under a single key.
- Unit test: round-trip serialization in `test/`.
- Commit: "Add MoodEntry model + SharedPreferences repository".

## Phase 2 — `MoodFacePainter` (CustomPainter)
- Single `CustomPainter` taking a `MoodKind` + size + optional color.
- Use only `drawCircle` (head, eyes), `drawArc` (mouth), `drawPath`/`drawLine` (eyebrows), `drawOval`.
- Mood differentiation rules:
  - **Happy** — mouth: upward arc (sweep angle ~π, starting below center); eyebrows: slight upward angle; eyes: round.
  - **Neutral** — mouth: straight line (`drawLine` or near-zero-arc); eyebrows: flat; eyes: round.
  - **Sad** — mouth: downward arc (inverted sweep); eyebrows: angled inward/down; eyes: smaller or with a drop.
  - (If 5 moods: very-happy adds open-mouth grin via `drawPath` + rosy cheek dots; very-sad adds a teardrop path.)
- `shouldRepaint` returns true only when mood/size/color changes.
- Smoke test by mounting the painter in a sandbox route or `flutter run -d chrome` and visually confirming each mood.
- Commit: "Add MoodFacePainter with N distinct expressions".

## Phase 3 — Single-Screen UI Skeleton
- `MoodHomeScreen` stateful widget. Layout (top to bottom):
  1. App title / today's date.
  2. **Logger row** — N tappable `MoodFace` buttons. Tap → adds an entry with `DateTime.now()` and that mood, persists, shows a brief snackbar/toast confirmation.
  3. **Timeline** section — horizontal `ListView.separated` showing the last 7 entries (newest first).
- Responsive: constrain content to ~720px max width and center for desktop web.
- Commit: "Scaffold single-screen layout with logger row".

## Phase 4 — Timeline Cards
- `TimelineEntryCard` widget showing:
  - The drawn face (uses the same `MoodFacePainter`).
  - Date label (e.g., "May 14" or "Today" / "Yesterday").
  - Accent color (background tint or left bar matching `MoodKind` color).
- Wire to repository: load on `initState`, refresh after logging.
- Slice list to `take(7)` after sorting by timestamp desc.
- Commit: "Render last 7 entries in horizontal timeline".

## Phase 5 — Tap-to-Animate Past Entry
- Tap on a `TimelineEntryCard` triggers a brief animation. Options (pick one and commit to it):
  - **A.** Scale + bounce on the face itself (~600ms `AnimationController` with `Curves.elasticOut`).
  - **B.** Mouth re-draw animation via an `AnimatedBuilder` driving an extra `progress` parameter on the painter (mouth arc grows from 0 → full sweep).
- Recommend **B** — it showcases the `CustomPainter` work and feels mood-tracker-y. Keep the controller per-card or use a single controller keyed by selected entry id.
- Commit: "Animate face when a timeline entry is tapped".

## Phase 6 — Polish
- Empty state when there are no entries ("Tap a face to log your first mood").
- Hover/press states on web (cursor: pointer, subtle scale on hover).
- Color theming: `ColorScheme.fromSeed`; ensure accent colors are accessible against backgrounds.
- App title in `web/index.html` and favicon.
- Manual QA checklist: log each mood; reload page; scroll the timeline; tap each entry to animate; resize window.
- Commit: "Polish: empty state, hover, theming".

## Phase 7 — Build & Deploy
- `flutter build web --release`.
- Firebase path: `firebase init hosting` (point at `build/web`, single-page rewrite to `/index.html`), then `firebase deploy`.
  - Vercel alternative: a tiny `vercel.json` with build command `flutter build web --release` and output `build/web`; deploy via `vercel --prod`.
- Verify the live URL works in a fresh browser (no localStorage). Test logging + reload.
- Commit: "Add hosting config".

## Phase 8 — Commit History Cleanup & Submission
- Review `git log` — the per-phase commits above already give a natural progression. If anything was squashed mid-development, leave it; don't fabricate history.
- Update `README.md` with: short description, screenshot/gif, "Run locally" steps, live URL.
- Push to GitHub.
- Submit: live URL + GitHub repo URL.

---

## Risks / Things to Watch
- `shared_preferences` on web uses `localStorage` — fine, but private/incognito sessions won't persist; mention in README.
- CustomPainter coordinates: anchor everything off `size.width`/`size.height` so faces scale cleanly for both the large logger buttons and the smaller timeline cards.
- Make sure `MoodFacePainter` is *one* painter parameterized by mood, not three painters — that's where the "distinct shapes from drawing primitives" criterion is judged.
