# Weekly Flutter Apps

One small Flutter app, built end to end, every week.

My main projects are commercial and closed source. This series is the opposite
by design: **every line of code here is public.**

---

## The apps

| # | App | Skill demonstrated | Case study | Code |
|---|-----|--------------------|------------|------|
| 01 | **Habit Tracker** | Local database (Drift) + hand-written `CustomPainter` heatmap | [Read](part01-aliskanlik-takipcisi/VAKA.md) | [Source](part01-aliskanlik-takipcisi) |
| 02 | **Recipe Book** | Turkish-specific text normalization &amp; search + keeping private data out of a public repo | [Read](part02-tarif-defteri/VAKA.md) | [Source](part02-tarif-defteri) |
| 03 | **Movie Search** | REST API layer: debounced search, request cancellation, pagination, explicit loading/error/empty states | [Read](part03-film-arama/VAKA.md) | [Source](part03-film-arama) |

*More apps land here as they ship.*

---

## How each app is built

- **One app per week.** Scope is fixed before any code is written.
- **One new skill per app.** Each app demonstrates something the previous ones
  did not — breadth of capability over a pile of similar CRUD apps.
- **No backend.** These apps consume APIs; they don't ship servers.
- **Every app carries a decision.** Each case study answers one concrete
  "why X instead of Y?" question.
- **Not published to Google Play.** These are portfolio pieces, not products.

Each app folder contains a `VAKA.md` — a short case study covering what was
built, what was deliberately left out, the technical decision behind it, and
how it was verified. Written in Turkish; English versions are on
[omergunes.vercel.app](https://omergunes.vercel.app).

---

## Stack

`Flutter` · `Dart` · Android first · offline by default · minimal dependencies
(most apps ship with two or three packages)

---

## Secret scanning

Every commit is scanned by [gitleaks](https://github.com/gitleaks/gitleaks)
through a pre-commit hook. If you clone this repo:

```bash
git config core.hooksPath .githooks
```

---

## Elsewhere

- **Portfolio & case studies:** [omergunes.vercel.app](https://omergunes.vercel.app)
- **My other work:** [github.com/MRGNSs11](https://github.com/MRGNSs11)

---

*Ömer Güneş — Karadeniz Technical University, Computer Science*
