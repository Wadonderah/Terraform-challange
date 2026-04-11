# Day 24 — Final Exam Review and Certification Focus
## 30-Day Terraform Challenge

---

## What is in this package

```
day24/
├── exam-simulation/
│   └── 57-question-simulation.md      ← Full 57-question timed exam with answers
│
├── flashcards/
│   └── 10-flashcard-answers.md        ← 10 official flash cards with detailed answers
│
├── domain-drills/
│   └── high-weight-domain-drills.md   ← 3 precision facts per high-weight domain
│
├── common-traps/
│   └── exam-traps.md                  ← 11 traps with explanations + example questions
│
├── exam-strategy/
│   └── exam-day-strategy.md           ← Specific actionable strategy for exam day
│
├── blog-post/
│   └── blog-post-day24.md             ← Full blog post with simulation results
│
├── knowledge-check/
│   └── last-minute-reference.md       ← Quick-scan cheat sheet for day before exam
│
└── SUBMISSION.md                      ← Copy-paste ready workspace documentation
```

---

## How to use this for the exam

### Today (Day 24)
1. Set timer for 60 minutes
2. Work through `exam-simulation/57-question-simulation.md` without looking anything up
3. Score yourself — record wrong answers
4. Read `domain-drills/high-weight-domain-drills.md` for your weak domains
5. Read `common-traps/exam-traps.md` — memorise the 11 traps

### Night before exam
1. Read `knowledge-check/last-minute-reference.md` — the entire cheat sheet
2. Run through `flashcards/10-flashcard-answers.md` rapidly
3. Read `exam-strategy/exam-day-strategy.md` once
4. Stop studying. Get 8 hours of sleep.

### Morning of exam
1. 10-minute flashcard pass — warm up, do not cram
2. Review the three-column CLI table from last-minute-reference.md
3. Read your personal exam strategy one more time

---

## The Single Most Important Fact

```
terraform state rm aws_instance.web
```

The EC2 instance keeps running unchanged.
state rm touches ONLY the state file.
Nothing happens to real infrastructure.

This is tested in multiple question formats on the exam.
Know it cold.

---

## Exam Numbers

| Number | Meaning |
|--------|---------|
| 57 | Total questions |
| 60 | Minutes allowed |
| 70% | Passing score |
| 40 | Minimum correct to pass |
| 17 | Questions you can miss and still pass |
| 26% | Weight of Domain 4 (CLI) — highest |
| 24% | Weight of Domain 3 (Basics) — second highest |
| 1 | Resources per terraform import CLI command |
