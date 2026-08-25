# Weekly Flutter Apps

One small Flutter app, built end to end, every weekend.

I'm a final-year Computer Science student graduating in 2027. My main projects
are commercial and closed source, so this series is the opposite by design:
**every line of code here is public.** One app per weekend, 48 hours, shipped
or not shipped — no half-finished repos.

---

## The rules I hold myself to

1. **48 hours.** Scope freezes Saturday morning. Whatever isn't done by Sunday
   evening ships as a documented gap, not as an excuse.
2. **One new skill per app.** Each week demonstrates something the previous
   weeks did not. Breadth of capability beats a pile of similar CRUD apps.
3. **No backend.** I consume APIs, I don't write servers. A server doesn't fit
   in a weekend.
4. **Every app carries a decision.** "Why X instead of Y?" — if I can't answer
   that, the app was too easy and I pick a harder one next week.
5. **Not published to Google Play.** These are portfolio pieces, not products.

---

## The apps

| # | App | Skill demonstrated | Case study | Code |
|---|-----|--------------------|------------|------|
| 01 | **Habit Tracker** | Local database (Drift) + hand-written `CustomPainter` heatmap | [Read](part01-aliskanlik-takipcisi/VAKA.md) | [Source](part01-aliskanlik-takipcisi) |

*More apps land here every weekend.*

---

## How this repo is organised

```
weekly-flutter-apps/
├── PLAN_REHBERI.md      # planning template — filled in before any code
├── VAKA_REHBERI.md      # case study template — filled in after the app ships
├── FIKIRLER.md          # the idea backlog I pick each week's app from
└── partNN-<app>/
    ├── PLAN.md          # this app's frozen scope + decisions log
    ├── VAKA.md          # this app's case study
    ├── README.md        # how to run it
    ├── tasarimlar.html  # the design drafts I chose from
    └── lib/ …
```

**The planning documents are public on purpose.** Anyone can see a finished
app; far fewer can see how the scope was frozen, what was deliberately left
out, and which trade-offs were made along the way. `PLAN.md` in each folder
carries a running decisions log written *while* the work happened, not
reconstructed afterwards.

> The planning and case study documents are written in **Turkish**.
> English versions of each case study live on
> [omergunes.vercel.app](https://omergunes.vercel.app).

---

## Stack

`Flutter` · `Dart` · Android first · offline by default · minimal dependencies
(most apps ship with two or three packages)

---

## Elsewhere

- **Portfolio & case studies:** [omergunes.vercel.app](https://omergunes.vercel.app)
- **My other work:** [github.com/MRGNSs11](https://github.com/MRGNSs11)

---

*Ömer Güneş — Karadeniz Technical University, Computer Science*
