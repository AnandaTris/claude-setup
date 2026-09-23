# Consumer app first-session research

Compiled 22 September 2026. What the evidence says about how a new user meets an
app, why most leave before they reach anything useful, and what the apps that
keep people do differently. Numbers are labelled by source quality: **primary**
(the company's own data or a peer-reviewed study), **survey** (aggregated
platform data such as RevenueCat, Lenny's, Adjust), or **vendor** (an onboarding
or analytics vendor's blog; treat as directional, not citable).

---

## 1. The first session decides almost everything

- Median consumer app retention is roughly **25% on day 1, 8-13% on day 7,
  4-6% on day 30** (survey: Business of Apps, Pushwoosh 2025, UXCam 2026). Most
  of the loss happens before the user has done anything the app is for.
- RevenueCat's State of Subscription Apps 2026 (survey, 115k apps): **about half
  of all paid conversions and over 75% of trial starts happen on day 0**. 55% of
  3-day-trial cancellations also happen on day 0. The subscription is won or
  lost in the first sitting.
- Lose It! (primary, quoted by RevenueCat): a user who has not converted within
  30 days almost never does, and only if still active.
- Vendor claims worth knowing but not quoting as fact: "38% drop after the first
  screen", "84% abandon a blank state within the first session", "75% churn in
  week one from poor onboarding". They all point the same direction and none
  has a traceable primary.

**Implication.** Everything before the user's first real success is a cost paid
up front with no trust in the bank. Count screens, taps and seconds to that
success and treat each as churn.

## 2. Three activation moments, not one

Reforge's framing (Brian Balfour et al.) splits activation into:

| Moment | Definition | Typical failure |
|---|---|---|
| **Setup** | The minimum the user must do to be *able* to get value | Teams stop here: account, profile, permissions, and call it onboarding |
| **Aha** | The user has *felt* the core value once. Describable in one sentence or it is not defined | Buried behind setup; not instrumented |
| **Habit** | The trigger fires and they return without deciding to | Never designed; retention left to notifications |

Lenny Rachitsky's survey of 500+ products: an activation milestone should be
**predictive** (users who hit it retain at least 2x better) and **actionable**.
Average activation rate 34%, median 25%; B2C freemium and subscription apps
sit highest because their milestone is low-friction (start one meditation),
marketplaces lowest (first transaction).

## 3. Time to value: what the good ones do

- **Duolingo** (primary, Gina Gotthilf, growth VP): a full lesson before any
  signup. Delayed signup with two soft walls ("Later" allowed) then one hard
  wall lifted DAU by **20%**. Its aha is "I answered something in a new
  language" and the whole flow is tuned to reach it in minutes.
- **Headspace** (Growth.Design teardown): jobs-to-be-done quiz ("why are you
  here?"), a progress bar, affirmations on loading screens, then a meditation
  matched to the stated job. The quiz is short and every answer visibly changes
  what comes next.
- **Apple HIG, Onboarding and Launching** (primary): "Help people accomplish
  something as soon as they start your app... let them be successful before you
  request additional information." Teach through interactivity, prefer
  context-specific tips to a single up-front flow, make tutorials optional and
  skippable, postpone non-essential setup with sensible defaults, delay ratings
  and purchase prompts until people are engaged, never make them wait on a
  large download at first launch.
- Practitioner consensus (vendor-heavy but consistent): value visible within
  the first **60 seconds**, first core action in **3 screens or fewer**, total
  guided onboarding for subscription apps clustering at **90-180 seconds**.

## 4. Signup: defer it, then make it one tap

- App Store Review Guideline **5.1.1(v)** (primary), quoted: "If your app
  doesn't include significant account-based features, let people use it
  without a login." Apps also may not require personal information to function
  unless it is core to the functionality, and any app that offers account
  creation must offer in-app account deletion. The rule is conditional: a
  messaging, banking or sync-first app may require login at launch. Guest-first
  is a product argument for those apps, not an App Store requirement.
- Soft wall then hard wall (Duolingo above) beats a signup gate at launch.
- Auth friction data (platform): Google reports passkey sign-ins about **4x
  more likely to succeed** than passwords (63.8% vs 13.8% in its own data);
  TikTok reports 97% passkey success. Aggregator figures such as "93% vs 63%"
  circulate without a stated denominator; do not quote them.
  Apple's iOS 26 Passkey Account Creation API creates the account and the
  credential in one native sheet. Social login vendors report 20-60% signup
  lifts. Offer Sign in with Apple and Google first, email as fallback.
- Ask for nothing at signup that the app does not need in the next five
  minutes. Profile details can be collected when a feature first needs them.

## 5. Personalization quizzes: when they help

- Lenny's Subscription Value Loop (Phil Carter): quizzes tailor the experience
  and give segmentation data; ideal length is shorter on mobile than web, longer
  for high-intent categories (health, finance), shorter for freemium where the
  product can speak for itself.
- Practitioner sweet spot: **3-5 questions**, each of which visibly changes the
  outcome. Fewer feels unpersonalized, more feels like data collection.
- RevenueCat's counter-case: some health and fitness apps run 45-50 screen,
  7-10 minute onboardings and see *higher* trial starts, because the perceived
  personalization and "science" framing builds belief. Their own caveats: it
  can lower realized LTV, it only works where users need help seeing the
  value, and it must be A/B tested. Default to short; earn length.
- Every question needs a one-line reason ("so we can size your first
  workout"), and the answer must be used somewhere the user can see.

## 6. Navigation and information architecture

- NN/g mobile navigation primer (primary): tab bars are efficient and always
  visible but cap at about five items; hamburger menus hold many items but
  "out of sight is out of mind": discoverability drops and users forget the
  menu exists during a session. Labelled "Menu" outperforms the bare icon.
- Thumb zone: about 60% of people hold the phone one-handed; the bottom ~40%
  of the screen is reachable. Primary destinations and the primary action
  belong there.
- Hick's law: decision time grows with the number and complexity of options.
  Three to five top-level destinations; overflow lives inside a destination,
  not in a global drawer.
- Every feature should be reachable in two taps from the home tab, and the
  route back should be the platform's own (swipe-back on iOS, system back on
  Android). Custom back behaviour is a defect.

## 7. Progressive disclosure, tips vs tours

- Nielsen's progressive disclosure (primary): show only what the user needs
  for the current step; secondary options on request. Improves learnability,
  efficiency and error rate.
- Product tours and coach marks: vendors report **70-80% of users skip
  tours**; tooltips triggered by a user action get ~2.4x the engagement of
  time- or page-load-triggered ones, and the window is 2-5 seconds after the
  relevant action. Single-spot coach marks on one interaction work; five-step
  overlays explaining the whole UI do not.
- Apple's guidance says the same: a collection of context-specific tips, not
  one up-front flow.

## 8. Empty states and the cold start

- NN/g on empty states (primary): a precise title, one line of why it is
  empty, and one action that changes the state. Keep navigation and filters
  visible. Illustration only when it supports the message.
- Practitioner pattern: first-use empty state teaches the core object and
  creates the first one; the first saved object replaces the empty message;
  the returning view makes it easy to resume.
- Andrew Chen on cold start for social products (primary essay): give
  **single-user utility** first (Pinterest as personal collecting, LinkedIn as
  a hosted resume), let people publish into networks they already have
  (Instagram to Facebook), design for a small critical mass (pairs, small
  groups), and saturate dense local networks rather than scattering users.
  Network density beats user count.
- Recommender cold start: a 3-5 item preference pick or follow-suggestion
  step, seeded with strong defaults, so the first feed is never blank.

## 9. Permissions and notifications

- iOS up-front push opt-in runs **40-54%**; Android much higher. Pre-permission
  priming (an in-app explainer before the system sheet) lifts opt-in by
  **2-3x** in vendor data, and the system prompt can only be shown once, so a
  denied prompt is expensive.
- Ask after a value moment (first save, first result, first order), never at
  launch. Explain what the notification will contain and how often.
- Reframing the ask around the user's own goal, rather than the app's,
  materially lifts opt-in (vendor teardowns such as Growth.Design's LinkedIn
  case; directional only).
- Same rule for location, camera, contacts and photos: request at the moment
  the feature is tapped, with the purpose string saying what the user gets.

## 10. Speed, real and perceived

- Apple WWDC19 "Optimizing App Launch" (primary): the whole cold launch
  fits in **400 ms** so the app is interactive when the system animation ends;
  roughly 100 ms of that is system work. iOS-specific. Android 12+ draws the
  SplashScreen API icon and Play vitals flags cold starts over 5 s; the web
  has no cold launch, so measure first contentful paint and time to
  interactive instead. Cold launch is the one that forms the first impression.
- Nielsen's response-time limits (primary): 0.1 s feels instant, 1 s keeps
  flow, 10 s loses attention. Doherty threshold (IBM, 1982): 400 ms to keep
  the user's train of thought.
- Skeleton screens read as faster than spinners at identical load time
  (directional, one unreviewed practitioner study by Bill Chung). NN/g found
  spinners slightly better for a first-time find task. Use skeletons for
  known layouts, spinners for genuinely unknown ones.
- Optimistic UI (show the result, reconcile later) for likes, saves, sends,
  toggles. State restoration on relaunch so the user lands where they left.
- Vendor abandonment stats (directional): >20% abandon an app that takes 3 s
  to open, >50% at 5 s.

## 11. Motivation, habit and where it turns manipulative

- Endowed progress (Nunes & Drèze 2006, primary): a 10-stamp card with 2
  pre-filled completes at nearly twice the rate of an 8-stamp blank card.
  Applying it to onboarding progress bars and setup checklists is an
  inference from a loyalty-card study, not a tested finding. The honest form:
  the pre-filled step is something the user actually did (installed, chose a
  goal); a bar that starts above zero for nothing done is a small lie.
- Zeigarnik effect: unfinished tasks pull people back. A visible "1 of 3
  done" beats a finished setup screen.
- Hook model (Nir Eyal): trigger, action, variable reward, investment. Useful
  as a design checklist for the habit moment; criticised for having no ethical
  guardrails and for explaining the recipe without the psychology.
- Streaks and daily rewards convert voluntary use into perceived obligation
  (loss aversion). They are legitimate when the user's goal and the streak
  point the same way (Duolingo: practice daily to learn) and manipulative
  when the streak is the only reason to open the app.
- Dark patterns to refuse: confirm-shaming on decline, hidden opt-outs,
  fake urgency and scarcity, pre-checked upsells, cancellation mazes,
  notification asks that reappear after denial, guilt copy. Trust lost here
  compounds through the retention curve.

## 12. Paywalls

- Soft paywall (some free use, dismissible) vs hard paywall (subscribe to
  enter). Adapty 2026: soft converts ~50% better per paywall view (4.85% vs
  3.34%). RevenueCat: hard converts 10.7% of downloads within 35 days vs 2.1%
  for soft, with 20-33% higher spend per payer, because hard walls filter out
  casual installs. Neither is universally right.
- Category rule of thumb (Airbridge, RevenueCat): acute, immediate problems
  (fitness plan, productivity, professional tools) tolerate hard walls;
  habit-driven categories (news, entertainment, education) need a soft ramp.
- Placement default: after the aha, in the same session. A hard paywall
  before the aha is refused. A *dismissible* paywall before the aha is an
  experiment, never a default: Rootd reports a 5x revenue lift from one at the
  front of onboarding and Headspace a double-digit lift going fully locked
  (vendor case studies). Run it as an A/B test scored on realized LTV, not
  trial starts.
- Day-1 paywall view rate of **80%+** is a figure from Superwall's CEO on
  Lenny's podcast (vendor, subscription apps only): a description of what
  high performers do, useful as a comparison point, not a design target for
  free or one-time-purchase apps. Show the price, the trial timeline (when it
  charges), and a plan comparison; make dismissal obvious.
- Trial length: 17-32 day trials convert at a 42.5% median vs 25.5% for under
  four days (RevenueCat 2026), yet apps keep shortening trials for faster
  revenue signal.

## 13. What to instrument from day one

| Metric | Why |
|---|---|
| Activation event (the aha, one named event) | Everything else is relative to it |
| Time to value (install to aha, seconds) | The number to drive down |
| Screen-by-screen onboarding funnel | Finds the exact step that leaks |
| Signup completion and method mix | Tells you if the wall is too early |
| Permission prompt shown / accepted, per trigger | Guards the one-shot system prompt |
| Day-1 paywall view rate, paywall view to trial, trial to paid | Subscription health |
| D1 / D7 / D30 retention by acquisition cohort | The only score that matters |
| Empty-state exposure rate | How many users see nothing on first open |

## 14. Platform specifics the contract depends on

**Android back.** Material distinguishes *Back* (chronological, system gesture or
button) from *Up* (hierarchical, the toolbar arrow). Back on the start
destination exits the app; Back from a non-start tab returns to the start tab
first (Material 3 navigation bar). Each tab keeps its own back stack across
re-selection (Navigation multiple back stacks). A deep link or notification tap
must synthesize the parent stack so Back lands inside the app, not on the
launcher (Navigation deep links and `TaskStackBuilder` do this). Predictive
back is the default for apps targeting Android 15 and later; handlers that
intercept the raw key event break it, so back logic goes through
`OnBackPressedCallback` or Compose `BackHandler`.

**Adaptive navigation.** The bottom tab bar is compact-width guidance. Material 3
maps medium widths to a navigation rail and expanded widths (tablets, foldables,
desktop mode) to a rail or drawer; iPadOS uses a sidebar with
`UISplitViewController` or the tab-bar-to-sidebar mode. A drawer at expanded
width is correct, not a defect.

**Launch screens.** iOS: the launch storyboard is a static placeholder that
should match the first screen's layout and carry no text or interactive
elements (HIG). Android 12+: the SplashScreen API draws the app icon on a plain
background and the app cannot substitute a layout; the correct move is to keep
it short and render the skeleton on the first real frame.

**App Tracking Transparency** is not an ordinary permission. Apple forbids gating
functionality on consent, offering incentives, and pre-prompts that imply the
app degrades on decline. Generic push-style priming copy applied to ATT is a
rejection.

**Deferred deep links.** A paid install's first launch should land on what the
ad promised. That needs a deferred deep link through the install referrer or an
attribution SDK (Branch, AppsFlyer, Adjust), resolved before the first screen
renders. Without it every paid user gets generic onboarding.

## 15. Consumer web and PWA differences

- No install step and no cold launch. The first-visit budget is first
  contentful paint and time to interactive (Core Web Vitals), and the "launch
  screen" is server-rendered or streamed above-the-fold content.
- Back is browser history. Every screen the user can be on is a URL; modals and
  wizard steps that swallow the back button are the web's custom-back defect.
- A shareable URL is the deep link. It must land on the content for a signed-out
  visitor, with the signup ask rendered around it, not in front of it.
- Permissions (push, geolocation, camera) may only be requested after a user
  gesture; Chrome and Firefox demote gesture-less prompts to a quiet UI. A
  dismissed prompt can be re-asked later; a blocked one cannot be from the page.
- PWA install: capture `beforeinstallprompt` and offer install after a value
  moment, not on first paint; iOS has no prompt at all and needs an in-app
  explainer for Add to Home Screen.

## 16. Accessibility in the first session

First-run flows are custom-built and fail accessibility more often than the
rest of the app. The checks that catch it: every onboarding screen, including
Skip and paywall Dismiss, is reachable and labelled under VoiceOver and
TalkBack; focus order follows reading order and carousels do not trap focus;
quiz progress is announced, not only drawn; targets meet Apple's 44 pt and
Material's 48 dp minimum (WCAG 2.2 AA floor is 24 by 24 CSS px); layouts
survive the largest accessibility Dynamic Type size and 200% font scale on
Android without clipping the primary action; motion-heavy transitions honour
Reduce Motion; colour is never the only carrier of the selected state.

## 17. Audiences under 18

- COPPA (US, under 13): verifiable parental consent before collecting personal
  data, which includes persistent identifiers used by third-party analytics
  and ad SDKs. "Instrument from day one" is constrained to first-party,
  consent-compliant analytics for these apps.
- App Store Kids Category (guideline 1.3): no third-party analytics or
  advertising SDKs that collect or transmit identifiable data; a parental gate
  before commerce, external links and account creation. Google Play Families
  policy has parallel ad and data rules and its own self-certified SDK list.
- Paywalls and purchase prompts sit behind a parental gate. Streaks, loot-style
  variable rewards and social comparison are treated as manipulative by the UK
  Age Appropriate Design Code and similar regimes; leave them out.
- Age assurance is moving to platform APIs (Apple's Declared Age Range API,
  Google Play's Age Signals API) and to state app-store age laws in the US.
  Ask for the age band once, at the earliest point it changes what is shown,
  and design the under-18 path as its own first session.

## 18. Returning users and re-onboarding

- A returning session should relaunch to the last screen; a cold return after
  weeks should refresh the session silently (refresh token, passkey) rather
  than present a login wall that reads as a new signup gate. Long-idle users
  get a summary, not a backlog: "here is what changed" beats 400 unread.
- After a major update, show a what's-new screen only when something the user
  can see moved; otherwise use the same action-triggered tips as first run. A
  re-organised tab bar needs a one-time pointer from the old location to the
  new one.
- Android 11+ auto-revokes permissions on apps unused for months. Re-request
  with the same priming rules as the first ask, at the moment of need.
- Localisation: tab labels that fit in English wrap in German and Finnish;
  RTL locales mirror tab order, back chevrons and swipe-back direction. Test
  the first session in the longest supported language and one RTL locale.

## 19. Games

Games invert most of the contract. The tutorial-as-first-level is correct,
there is no tab bar, the aha is a play loop measured over a session, and
monetisation is IAP or rewarded ads rather than a subscription paywall. This
skill's screen budget, tab rules and paywall items do not apply; its ethics
list, permission timing and instrumentation do.

## 20. Source list

Primary and survey sources:
- Apple Human Interface Guidelines, Onboarding and Launching. https://developer.apple.com/design/human-interface-guidelines/onboarding and /launching
- App Store Review Guidelines 5.1.1. https://developer.apple.com/app-store/review/guidelines/
- Apple WWDC19 423, Optimizing App Launch. https://developer.apple.com/videos/play/wwdc2019/423/
- Nielsen Norman Group, Basic Patterns for Mobile Navigation. https://www.nngroup.com/articles/mobile-navigation-patterns/
- Nielsen Norman Group, Designing Empty States. https://www.nngroup.com/articles/empty-state-interface-design/
- Nielsen Norman Group, Response Times: 3 Important Limits. https://www.nngroup.com/articles/response-times-3-important-limits/
- Nielsen Norman Group, Progressive Disclosure. https://www.nngroup.com/videos/progressive-disclosure/
- Reforge, Define your setup moment. https://www.reforge.com/guides/define-your-setup-moment
- Lenny Rachitsky, What is a good activation rate. https://www.lennysnewsletter.com/p/what-is-a-good-activation-rate
- Phil Carter in Lenny's Newsletter, The Subscription Value Loop. https://www.lennysnewsletter.com/p/the-subscription-value-loop-a-framework
- RevenueCat, State of Subscription Apps 2026. https://www.revenuecat.com/state-of-subscription-apps
- RevenueCat, Hard paywall vs soft paywall. https://www.revenuecat.com/blog/growth/hard-paywall-vs-soft-paywall
- RevenueCat, Why your onboarding might be too short. https://www.revenuecat.com/blog/growth/why-your-onboarding-experience-might-be-too-short
- First Round Review, The Tenets of A/B Testing from Duolingo's Master Growth Hacker (Gina Gotthilf). https://review.firstround.com/the-tenets-of-a-b-testing-from-duolingos-master-growth-hacker/
- Andrew Chen, How to solve the cold-start problem for social products. https://andrewchen.com/how-to-solve-the-cold-start-problem-for-social-products/
- Nunes & Drèze, The Endowed Progress Effect (2006). https://papers.ssrn.com/sol3/papers.cfm?abstract_id=991962
- Adapty, What does a high-performing paywall look like in 2026. https://adapty.io/blog/high-performing-paywall-2026/
- Airbridge, Hard vs soft paywall vs freemium. https://www.airbridge.io/en/blog/hard-vs-soft-paywalls
- Laws of UX, Doherty Threshold. https://lawsofux.com/doherty-threshold/
- Corbado, Passkey Account Creation API on iOS 26. https://www.corbado.com/blog/passkey-account-creation-api
- Google, Passkeys: 4x sign-in success (Google Security Blog / Android Developers). https://security.googleblog.com/
- Material 3, Navigation bar, Navigation rail, Adaptive layouts. https://m3.material.io/components/navigation-bar/guidelines
- Android Developers, Principles of navigation, Predictive back, Multiple back stacks. https://developer.android.com/guide/navigation/principles
- Android Developers, Splash screens (Android 12+). https://developer.android.com/develop/ui/views/launch/splash-screen
- Apple, App Tracking Transparency (User Privacy and Data Use). https://developer.apple.com/app-store/user-privacy-and-data-use/
- Apple, App Store Review Guidelines 1.3 Kids Category. https://developer.apple.com/app-store/review/guidelines/#kids-category
- FTC, COPPA Rule. https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa
- Google Play, Families policy. https://support.google.com/googleplay/android-developer/answer/9893335
- ICO, Age Appropriate Design Code. https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/
- Apple HIG, Accessibility; WCAG 2.2 Target Size (Minimum). https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- web.dev, Permissions UX and `beforeinstallprompt`. https://web.dev/articles/permissions-best-practices

Vendor sources used for directional claims only:
- Growth.Design case studies (Headspace, LinkedIn notifications, Duolingo retention), https://growth.design/case-studies; Superwall (Jake Mor on Lenny's Podcast) for the 80% day-1 paywall view rate;
- UXCam retention benchmarks 2026; Pushwoosh benchmarks 2025; Userpilot mobile retention; Appcues onboarding examples; OneSignal and Batch push opt-in guides; Plotline opt-in strategies; Userguiding feature discovery; Setgreet and Dreambit drop-off posts; Eleken and VWO onboarding guides; LogRocket skeleton screens.
