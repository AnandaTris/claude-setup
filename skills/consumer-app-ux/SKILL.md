---
name: consumer-app-ux
description: Use when work touches a consumer app's first session or its return loop, on mobile or consumer web: first launch and cold start, onboarding order, guest vs signup wall, personalization quiz, tab bar and IA, empty states and cold-start content, permission and push priming, paywall placement, the day-2 trigger. Also for activation, time to value, D1/D7/D30 retention, churn, or "users drop off before they get it". Owns the order and budget of first-run screens; impeccable owns how each screen looks. Not for internal tools, B2B admin, backend-only work, or games.
---

# Consumer app UX

**Core principle:** everything between install and the user's first real success
is a cost paid before any trust exists. Count it in screens, taps and seconds,
and spend it only where it buys belief. About half of all paid conversions and
most trial starts happen within a day of install, so the first sitting is also
where the business is decided.

Evidence and numbers live in `references/research.md`; read it when a decision
needs a source. Visual craft belongs to `impeccable`, component feel and motion
to `emil-design-eng`, Expo tabs and stacks to `expo-router` and `expo-native-ui`,
and `superpowers:brainstorming` when the aha itself is undecided.

## Two modes

**Build mode.** Before any screen is designed, write the first-session contract
below into the plan or spec. Every screen then has to justify its place in it.

**Audit mode.** Walk the app as a new user on a clean install and score it
against `references/audit-checklist.md`. Report the ordered screen list with
taps and seconds first, then failures, launch blockers first.

## The first-session contract

Write these down, in this order, before designing anything.

1. **The aha, in one sentence.** What the user has *felt* once the app has
   worked for them. Not "completed setup". If it takes two sentences it is not
   defined. This is one named analytics event. Every feature the sentence names
   is free in the first session; an aha that is paywalled is not an aha.
2. **The budget to reach it.** Under 60 seconds and 3 screens or fewer of
   pre-value content, no account, no paywall, at most one permission (see item
   6). Exceeding it needs a written reason in the plan naming which item-3
   requirement forces it. Cold launch is interactive within 400 ms on iOS and
   the launch screen matches the first screen's layout (platform variants in
   `references/research.md` §14).
   **Delayed-value products** (sleep, cycle, savings, a week of data): the aha
   waits on real-world time, so the same budget applies to the **commitment
   moment**, the last screen before the user starts the thing that produces
   value (armed, enrolled, tracking). Name that event, then budget the return
   visit where value is collected just as hard; it is a first session too.
   This moves the finish line, never the ceiling.
3. **The setup that is truly required.** List only what the app cannot deliver
   the aha without. Everything else moves after the aha or into the moment a
   feature first needs it.
4. **The quiz, if any.** Default to none: if nothing downstream branches on the
   answers, the quiz is omitted, not shortened. If it does branch: 3 to 5
   questions, each with a one-line reason, each visibly changing what comes
   next. A progress bar may start above zero only when the pre-filled step is
   something the user actually did. Longer quizzes are an A/B test with
   realized LTV as the metric, never a default.
5. **Signup placement.** Guest first. Then a soft wall the user can skip, then a
   hard wall only where the feature genuinely needs an account: cross-device
   sync, social identity, server-held data, a web counterpart. Not purchase:
   StoreKit and Play Billing tie the entitlement to the store account, so a
   guest can trial, buy and subscribe. The soft ask lands at the first moment
   the user owns something they would be sorry to lose, and the copy says so;
   one re-ask at a *new* value moment, never at the same one. Sign in with
   Apple and Google above email; passkeys on iOS 16+ and Android 14+ with a
   backend that can hold a public key, otherwise name the blocker. Account
   deletion in settings. Account-based cores (messaging, banking, sync-first)
   may require login at launch; say so in the plan.
6. **Permission moments.** For each of push, location, camera, mic, contacts,
   photos: the exact user action that triggers it, the in-app explainer shown
   first, and what happens on decline. None fire before the aha, with one
   exception: a sensor permission the aha cannot happen without (camera, mic,
   location, motion). It fires once, never back to back with another prompt,
   and is bought with a **preview** of the value (a canned sample, a real
   result animating) above the ask, not with copy alone. Decline still shows
   something. App Tracking Transparency gets no incentive, no gated feature,
   no degradation copy.
7. **Paywall moment**, if the app monetises in-app. After the aha, in the same
   session. Measure exposure in hours since install, not calendar days;
   subscription apps compare against roughly 80% of users seeing it within 24
   hours (vendor benchmark, not a rule). Delayed-value products may place a
   second, lighter paywall at the commitment moment, after the commitment,
   never before it. A pre-aha paywall, dismissible or not, is a defect unless
   it is a running A/B test scored on realized LTV. Price, trial end date,
   charge date, plan comparison, and a dismiss with the same visual weight as
   the buy button.
8. **The day-2 trigger.** What brings the user back tomorrow without a push
   notification. If the answer is "the streak", the product has no reason to
   return and the streak is manipulation. Also name what a user returning after
   weeks sees: a silent session refresh and a summary, not a login wall and a
   backlog.

## Navigation contract

| Rule | Reason |
|---|---|
| Compact width: bottom tab bar, 3 to 5 labelled destinations. Medium and expanded: rail, drawer or sidebar | Hidden navigation is forgotten within a session; tabs are always visible |
| Pick tabs by ranking destinations on expected share of sessions: top four plus the one that owns creation. "More" is a tab only if it is a content screen | Hick's law: fewer top-level choices, faster decisions |
| Primary action in the bottom 40% of the home tab | Most people hold the phone one-handed; that is the reachable zone |
| Every destination the store listing names within 2 taps of home | Depth is where features go to die |
| Back is the platform's back: iOS swipe-back; Android Up vs Back, home-tab Back exits, other tabs return home first, predictive back honoured; web browser back through every step | Custom back is a defect; `references/research.md` §14 has the Android rules |
| Deep links, notification taps and deferred deep links on paid installs land on the content with a back stack behind them | A tap that lands on home is a broken promise |
| Tab labels fit in the longest supported language; RTL mirrors order and gestures | A wrapped label is an unlabelled tab |

## Disclosure contract

- No multi-step tour at launch. One tip, on the first relevant action, within 5
  seconds of it, dismissed in one tap. Tours are skipped; action-triggered
  tips are read.
- No welcome carousel, and no carousel renamed as a permission primer. A primer
  is one screen, for one permission, at the moment it fires.
- An empty state is a screen with a job: title naming what will be here, one
  line on why it is empty, one action that fills it. The first-run empty state
  creates the first core object instead of describing it.
- The first feed or list is never blank. Seed it, default it, or run a 3-item
  preference or follow pick. Never seed a number the user will read as their
  own measurement (a zero score, a chart at origin); measurement products show
  the action that produces the first real reading and say none exists yet.
- If the core action runs unattended (overnight, background, long upload),
  design its partial-failure state: what happened, how much was captured, what
  to change next time.
- Anything skippable is recoverable from Help or Settings.
- Every onboarding screen, including Skip and Dismiss, works under VoiceOver
  and TalkBack, at the largest text size, and with Reduce Motion on. Targets
  are 44 pt or 48 dp. Section J of the checklist scores it.

## Feedback budget

| Wait | What the user sees |
|---|---|
| under 100 ms | Pressed state, haptic, or the next screen; nothing else |
| 100 ms to 1 s | The action already applied (optimistic), reconciled later |
| over 1 s | Skeleton of the destination layout, not a spinner |
| over 10 s | Progress with an estimate, and a way to leave and come back |

Relaunch restores the previous screen and scroll position. Errors say what
happened and what to do, with a retry.

## Habit loop

Design the return trigger, action, reward and investment deliberately, then
apply two checks to every mechanic: the metric it counts appears in the user's
own stated goal, and removing it would not remove the reason to open the app.
A decline, skip or "not now" is a control of the same visual weight as the
accept; a de-emphasised skip link is a hidden opt-out. Confirm-shaming, fake
urgency, pre-checked upsells, hidden opt-outs, re-asking after a denial, and
cancellation mazes are refused, whatever the metric they would move.

**If the audience includes under-18s:** third-party analytics and ad SDKs are
out unless consent-compliant (COPPA, Kids Category 1.3, Play Families);
purchases, external links and account creation sit behind a parental gate; no
streaks, variable rewards or social comparison on the under-18 path.
`references/research.md` §17.

## Instrument from day one

Instrument the eight events in `references/research.md` §13 before the first
build. A funnel with no D1/D7/D30 cut by acquisition source cannot say whether
the funnel was worth optimising.

## Rationalizations that ship the wrong first session

Seen in a no-skill baseline; each one sounds reasonable in the moment.

| Excuse | Reality |
|---|---|
| "Sign in with Apple is one tap, so asking at launch is frictionless" | Friction is trust, not taps. An identity ask before value costs drop-off at any tap count |
| "Each carousel screen does double duty as a permission primer" | A deck before the product is a carousel whatever it is called. Delete it |
| "Founder wants 5 screens; we shipped 3, mostly refused" | 3 screens of pre-value content is the whole budget spent on nothing. The number to negotiate is zero |
| "The 'Not now' link is there, so the wall is soft" | A tiny decline is a hidden opt-out. Same weight as accept, or it is a hard wall |
| "Screen 2 described the feature, so the permission ask is contextual" | Context is an action the user just took. A description is advertising |
| "Three prompts back to back, ordered by importance" | Ordering a stack does not fix a stack. One sensor permission before the aha, the rest at their trigger |
| "The paywall is dismissible, so showing it before the first result costs nothing" | A dismiss decision placed before the critical action is a tax on that action |
| "Logo splash while the app boots" | The launch screen is the first screen's layout. A logo is a second of nothing |
