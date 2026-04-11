# Exam-Day Strategy
## Terraform Associate Certification — Specific and Actionable

---

## Before the Exam

- [ ] Get 8 hours of sleep the night before — performance under time pressure degrades significantly with fatigue
- [ ] Eat a real meal 90 minutes before the exam — not immediately before
- [ ] Have water nearby — a 60-minute exam in a quiet room gets dry
- [ ] Close every application except the exam browser tab
- [ ] Disable notifications on all devices
- [ ] Test your webcam, microphone, and ID (if online proctored) 30 minutes early
- [ ] Do a 10-minute flashcard run before sitting down — warm up, do not cram

---

## Time Management (57 Questions / 60 Minutes)

**Rule 1: 1 minute per question is the target pace.**
57 questions × 1 minute = 57 minutes. You have 3 minutes of buffer.

**Rule 2: 90 seconds maximum on any single question before flagging and moving on.**
A difficult question counts the same as an easy one. Spending 4 minutes on Q7 means
you are running out of time on Q55 — where there might be 3 easy questions.

**Rule 3: Flag-and-return is a strategy, not a fallback.**
Use it actively. If you are not 80% confident in 90 seconds, flag it and keep moving.
You will often answer it faster on the return pass because your brain kept working on it.

**Rule 4: Never leave a question blank.**
There is no penalty for wrong answers on the Terraform Associate exam.
If you are out of time, guess systematically — options B and C are statistically
correct more often than A and D, but in a pinch, pick the longest answer.

**Time checkpoints:**
- Q15 by 15 minutes
- Q30 by 30 minutes
- Q45 by 45 minutes
- Q57 by 57 minutes (3 minutes for flagged review)

If you are behind at any checkpoint, speed up on the next section.

---

## Question Reading Strategy

**Step 1: Read the last sentence first.**
The question stem often sets a long scenario and the actual question is the last line.
Know what you are being asked before reading the scenario.

**Step 2: Read ALL four answer choices before selecting.**
The exam uses plausible wrong answers. A quick first read might make A look correct —
but B is more precisely correct. Read all four, then eliminate.

**Step 3: Eliminate first — select last.**
On any uncertain question, eliminate the obviously wrong answers first.
Get it to 2 choices, then apply your knowledge.

**Step 4: Watch for absolute language.**
Answers with "always," "never," "only," and "must" are often wrong —
Terraform (like most systems) has exceptions. Answers with "typically," "usually,"
and "by default" are often correct.

---

## Domain-Specific Strategies

**Domain 4 — CLI (26%, highest weight):**
The three mental columns for every command:
1. What does it do to the STATE FILE?
2. What does it do to REAL INFRASTRUCTURE?
3. Does it require AWS CREDENTIALS?

Know these cold for all 15 commands. Most CLI questions are testing one of these three things.

**Domain 3 — Terraform Basics (24%):**
For version constraint questions: write out `~> X.Y.Z` and ask "which component is rightmost?"
That component is what can change freely; the ones to the left are locked.

For count vs for_each questions: ask "what happens if an item is removed from the middle?"
Count = chaos (index shifts). For_each = only that key is affected.

**Domain 2 — Purpose (20%):**
For state questions: "What is the state file for?" → maps code to real world.
For provider questions: "What does a provider do?" → translates resource blocks into API calls.

---

## Common Trap Defense

Before submitting any answer, run a quick trap check:

**Is this a `state rm` vs `destroy` question?**
→ state rm = nothing happens to real infra. Always.

**Is this a `sensitive = true` question?**
→ sensitive masks terminal output. State still contains the value in plaintext.

**Is this a `prevent_destroy` question?**
→ prevents apply-time destroy only. Removing the resource block defeats it.

**Is this a `ref=main` vs `ref=v1.0.0` question?**
→ branch = mutable. tag = immutable. Production = always tags.

**Is this a `~>` version constraint question?**
→ rightmost component = what can change. Write it out to check.

---

## Multi-Select Question Strategy

"Select TWO" means exactly two — not one, not three.

**Read the question carefully.** "Select TWO" is typically written in caps or bold.
Getting one right and two right are both scored the same: wrong if you do not choose
exactly the right number.

**Strategy:** Find the two that are clearly correct, not the two that are least wrong.
If you cannot find two clearly correct answers, use elimination — find the two that are
clearly NOT wrong.

---

## If You Hit a Confidence Crash

At some point (usually around Q30) many test takers hit a wall — a question they
do not know and it shakes confidence in everything that follows.

**The reset:**
1. Flag the question immediately (do not spiral on it)
2. Take one slow breath
3. Read Q+1 fresh — do not carry the previous question into it
4. Remind yourself: 70% to pass. You can miss 17 questions and still pass.

---

## After Submitting

The exam gives immediate pass/fail. You will not see your exact score until later.

**If you pass:** Great. The challenge continues.
**If you do not pass:** Review the domain breakdown in your score report.
The breakdown tells you which domains you were weakest in — that is your study plan
for the retake. HashiCorp allows retakes — there is no shame in a second attempt with better preparation.

---

## The Single Most Important Exam Insight

**70% to pass. That means you can miss 17 questions.**

You do not need to know everything perfectly. You need to know approximately 80%
of it well enough to select the correct answer under time pressure. The domains you
know cold (IaC concepts, modules, workflow) give you your base. The CLI section
(26%) and Terraform basics (24%) are where preparation pays off most.

Know the state file behaviour of every CLI command. Know what `~>` does to each
version component. Know for_each vs count. Know sentinel tiers.

Those four topics cover a disproportionate percentage of questions that catch people.
