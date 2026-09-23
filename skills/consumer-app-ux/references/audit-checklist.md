# First-session audit

Run this as a brand-new user on a clean install (or a cleared account) with the
network throttled to a normal 4G profile. Do not read the code first; the code
tells you what was intended, the walkthrough tells you what happens. Record
every screen in order with the tap count and elapsed seconds.

Before the walkthrough, answer three gates. They change which items apply.

| Gate | Effect |
|---|---|
| Audience includes under-18s? | Section J applies and overrides H (instrumentation) and G4 (paywall) |
| Platform: iOS, Android, web, or several? | Items marked with a platform apply only there; web maps back to browser history and deep links to URLs |
| Does the app monetise in-app? | If not, A5 and G4 are N/A |

Each item scores PASS, FAIL or N/A. Items marked **★** are launch blockers.
Everything else is ranked by how early a user meets it. Report as a table:
item, verdict, evidence (screen name and what you saw), fix.

## A. Reaching value

| # | Check |
|---|---|
| A1 ★ | The aha moment is written down in one sentence and the walkthrough reached it (for delayed-value apps, the named proxy: the first commitment that makes the aha inevitable) |
| A2 ★ | Install to aha took under 60 seconds and at most 3 screens of pre-value content, or the plan names which item-3 requirement forced the overrun and the overrun is that requirement alone |
| A3 ★ | No account was required before the aha (guest or deferred signup), unless the app's core is account-based (messaging, banking, sync-first) and the plan says so |
| A4 ★ | No permission prompt fired before the aha, except a permission the aha cannot happen without (camera, mic, location, motion). That one is preceded by a one-screen explainer and has a working decline path that still shows something |
| A5 ★ | No paywall before the aha, dismissible or not. Two exceptions pass: a lighter paywall after the commitment moment in a delayed-value product, or a running A/B test scored on realized LTV. Dismiss quality is scored under G4 |
| A6 | Launch: iOS launch screen matches the first screen's layout; Android 12+ splash is the themed icon and the skeleton renders on the first frame; web renders above-the-fold content server-side or streamed. Timing is scored in section I |
| A7 | Nothing on first launch waited on a large download, a network round-trip with no skeleton, or a splash animation longer than a second |
| A8 | There is no welcome carousel. A short skippable one is still a FAIL, recorded as a known defect; if one ships under pressure it is 3 screens or fewer, skippable from screen 1, and never used as a permission primer |

## B. Signup and personalization

| # | Check |
|---|---|
| B1 | Sign in with Apple and Google are offered above email. Passkeys are offered on iOS 16+ and Android 14+ builds with a backend that can store a public key; if not, the specific blocker is named |
| B2 ★ | The signup wall is soft first (a "Later" or "Skip" route) and only becomes hard where the feature genuinely needs an account: sync across devices, anything social, a purchase that must be restored on another device |
| B3 | Signup asks for nothing the app does not use within the next five minutes |
| B4 | Personalization quiz, if present, is 3 to 5 questions, each with a one-line reason, and each answer visibly changes what comes next; a longer quiz is a shipped A/B winner evidenced on realized LTV |
| B5 | A progress indicator exists for any flow longer than two steps. If it starts above zero, the pre-filled step is something the user actually did |
| B6 | Account deletion is reachable in-app from settings (App Store 5.1.1(v)) |

## C. Navigation

| # | Check |
|---|---|
| C1 | At compact width, primary navigation is a bottom tab bar with 3 to 5 labelled destinations and no hamburger for primary destinations. At medium and expanded widths a rail, drawer or sidebar is the pass condition |
| C2 | The single most important action sits in the bottom 40% of the screen on the home tab |
| C3 | Every destination the app's own store listing or marketing names is reachable in 2 taps from the home tab |
| C4 | Back works the platform way: iOS swipe-back; Android system and predictive back, with Up and Back distinct, Back on the home tab exiting and on other tabs returning to home first; web browser back through every step, including modals |
| C5 | The current location is always visible (selected tab, screen title) |
| C6 | Deep links, notification taps and, for paid installs, deferred deep links land on the target content with a back stack behind it, not on the home screen |
| C7 | Search exists if the content set is larger than one screen |
| C8 | Tab labels fit without wrapping in the longest supported language; RTL locales mirror tab order and back gestures |

## D. Disclosure and empty states

| # | Check |
|---|---|
| D1 | No multi-step product tour at launch; tips appear on the first relevant action, within 5 seconds, one at a time, and dismiss with one tap |
| D2 | Each empty state names what will appear, why it is empty, and offers one action that fills it |
| D3 | The first-run empty state creates the first core object instead of describing it |
| D4 | The first feed or list is never blank: seeded content, strong defaults, or a preference/follow pick. No seeded number reads as the user's own measurement |
| D7 | If the core action runs unattended, its partial-failure state says what happened, how much was captured and what to change |
| D5 | Advanced settings and secondary options are hidden behind a clear disclosure, not on the main path |
| D6 | Any skipped tutorial or tip is recoverable from Help or Settings |

## E. Feedback and speed (observable)

| # | Check |
|---|---|
| E1 | Every tap shows a pressed state, haptic or navigation before anything else; nothing feels dead. Exact timing is scored in section I |
| E2 | Any visible wait shows a skeleton of the destination layout, not a spinner |
| E3 | Likes, saves, sends and toggles are optimistic; failures roll back with a message |
| E4 | Relaunch restores the previous screen and scroll position |
| E5 | Errors say what happened and what to do next, in the user's words, with a retry |
| E6 | Offline or slow-network first launch still shows something usable |

## F. Permissions and notifications

| # | Check |
|---|---|
| F1 | Every system permission is preceded by an in-app explainer that states the benefit and lets the user decline without penalty |
| F2 | Permissions are requested at the moment the feature is used, after at least one value moment (A4 covers the sole exception) |
| F3 | A declined pre-prompt does not fire the system prompt |
| F4 | Notifications carry content the user asked for; frequency is stated and adjustable in-app |
| F5 | Rating prompts appear only after a completed positive action, never on launch |
| F6 | App Tracking Transparency has no incentive, no gated feature and no copy implying the app degrades on decline |

## G. Habit loop and ethics

| # | Check |
|---|---|
| G1 | The return trigger (what brings the user back on day 2) is named and designed, not left to push |
| G2 | For every streak, badge or reward: the metric it counts appears in the user's own stated goal, and removing it would not remove the reason to open the app |
| G3 ★ | Every decline, skip or "not now" has the same visual weight as the accept. No confirm-shaming, fake urgency, pre-checked upsells, hidden opt-outs, re-asking after a denial, or cancellation mazes |
| G4 | Subscription paywall shows price, trial end and charge date, and plan comparison; dismissal is one obvious tap |

## H. Instrumentation

| # | Check |
|---|---|
| H1 | The aha is one named analytics event |
| H2 | Time to value is measurable from install |
| H3 | Every onboarding screen emits a viewed/completed event so the funnel can be read step by step |
| H4 | Permission prompt shown/accepted, paywall viewed/converted, and signup method are tracked |
| H5 | D1/D7/D30 retention can be cut by acquisition source |

## I. Measured (instrumented, not eyeballed)

Run separately from the walkthrough with the named tool. Record the number.

| # | Check |
|---|---|
| I1 | iOS cold launch completes within 400 ms (Xcode Instruments, App Launch template); Android cold start under 2 s (`adb shell am start -W`, or Play vitals); web first contentful paint under 1.8 s on 4G (Lighthouse) |
| I2 | Tap-to-pressed-state under 100 ms on a 60 fps screen recording (6 frames) for the primary action on each onboarding screen |
| I3 | Any wait over 1 s has a skeleton; any wait over 10 s has progress with an estimate and a way to leave |

## J. Accessibility and audience

| # | Check |
|---|---|
| J1 ★ | Every onboarding screen, including Skip, Later and paywall Dismiss, is reachable and labelled under VoiceOver and TalkBack, in reading order, with no focus trap in carousels |
| J2 | Quiz and setup progress is announced, not only drawn |
| J3 | Skip, Dismiss and the primary action are at least 44 pt (iOS) or 48 dp (Android) and stay on screen at the largest accessibility text size |
| J4 | Transitions honour Reduce Motion; selected tab and chosen answers are not colour-only |
| J5 ★ (under-18) | Third-party analytics and ad SDKs are absent or consent-compliant for the audience (COPPA, Kids Category 1.3, Play Families); the H items are scored against first-party analytics only |
| J6 ★ (under-18) | Purchases, external links and account creation sit behind a parental gate; no streaks, variable rewards or social comparison in the under-18 path |

## Reporting

Lead with the walkthrough itself: the ordered list of screens with taps and
seconds, and where the aha landed (or that it never did). Then the FAIL table,
★ items first, then by the order a user meets them, because fixing screen 2
changes everything after it.
