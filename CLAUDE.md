# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Settly Mobile

Flutter app for **Settly**: shared/personal expense tracking and settling balances
between friends and projects (Splitwise-style). Package name: `settly_mobile`.

## The target is the PWA, not the Android app — IMPORTANT

Despite the repo name, **the Android/APK build is no longer developed.** The app
ships as an installable **PWA** (web), and that is the only platform that gets
tested and deployed. When you make a call, optimise for web:

- "The phone's back button" means the **browser/PWA back gesture**, not Android's
  native back — it is a browser history pop, so a page opened from a notification
  can otherwise *leave the app* (its window has one history entry). See
  `_NotificationRoute` in `services/notification_service.dart`.
- Don't spend effort on Android-only concerns (native notification channels, APK
  icons/mipmaps, platform channels) unless explicitly asked.
- Native code paths still exist and must keep compiling; they're just not the
  thing being shipped.

## The two-repo system — read this first

Settly is **two repos**, and a large share of frontend tasks need a matching
backend change. Assume you may have to touch both.

| | path | stack |
|---|---|---|
| this repo | `settly-mobile` | Flutter (Dart) |
| backend | `/home/mdut/Settly/settly-api` | Spring Boot / JPA / Postgres, Keycloak auth |

Backend packages: `expenses`, `friendships`, `projects`, `debts`, `notifications`,
`auth`, `ai`, `common`. Each feature package is `controller/ service/ repository/
model/ dto/`. When the API "doesn't do what the app needs", the fix usually
belongs in the backend service, not a frontend workaround.

## Commands

**Flutter lives on the Windows host, not inside WSL.** `flutter` is not on the
WSL `PATH` — `flutter analyze` / `flutter run` / `flutter test` must be run by the
user from Windows (PowerShell), or via `flutter.bat`. You generally **cannot
compile-check Dart yourself**; rely on careful reading, and let CI's
`flutter build web` gate the build. Ask the user to run things when it matters.

```bash
# Flutter (run these on the Windows host)
flutter analyze
flutter test                                   # only the default widget_test.dart exists
flutter run --dart-define=SETTLY_HOST=http://localhost
# NOTE: omit SETTLY_HOST to test locally — setting it to prod points at prod Keycloak.

# Backend (runs fine from WSL)
cd /home/mdut/Settly/settly-api
./mvnw -o compile
./mvnw -o test                                 # full suite
./mvnw -o test -Dtest=ExpensesServiceTest      # one class
./mvnw -o test -Dtest='ExpensesServiceTest,ExpensesControllerTest'
```

The backend auto-formats with **spotless on build** — it will rewrite your Java
files, so re-read them before further edits.

Backend host is configurable at build time:
`--dart-define=SETTLY_HOST=https://settly.duckdns.org` (defaults to
`http://localhost`). See `lib/const/api_url.dart`. Auth is via Keycloak.

## Deployment / CI-CD

Both repos deploy on **push to `develop`**. There is **no inbound SSH** — it's
pull-based:

1. GitHub Actions builds a **native arm64** image (`ubuntu-24.04-arm`, no QEMU)
   and pushes to **GHCR**. The backend runs its test suite first (Postgres +
   Redis services); a failing test blocks the deploy.
2. A **self-hosted runner on the server** pulls the image and
   `docker compose -f docker-compose.prod.yml up -d <service>`.
3. The image is **SHA-pinned** into `/opt/settly/.env` (`SETTLY_WEB_IMAGE` /
   `SETTLY_API_IMAGE`) so a later manual `up -d` or a reboot keeps the same
   version rather than drifting to `:latest`.

Server: `ssh ubuntu@130.61.209.179`, app lives in `/opt/settly`.
`SETTLY_HOST` is baked into the **web image at build time**, not read at runtime.

Server-only config (not in git) lives in `/opt/settly/.env` — notably the FCM
credentials below.

## Localization — IMPORTANT

- **No `.arb`/gen-l10n.** All translations live in `lib/const/app_texts.dart` as
  a hand-written `AppTexts` class. Get it with `AppTexts.of(context)`, which
  reads `Localizations.localeOf(context)`.
- Supported locales: `pl` (default, `Locale('pl','PL')`) and `en` (`Locale('en')`).
  `AppTexts._isEnglish` = `languageCode == 'en'`. Persisted in `SharedPreferences`
  key `app_language`.
- **Every user-facing string must go through `AppTexts`.** Do not hardcode
  English or Polish literals in widgets — that is the root cause of mixed-language
  UI bugs. If a string needs a value interpolated, add a method to `AppTexts`
  (see `transactionsCount`, `daysInMonthCount`, `monthYear`).
- Polish grammar matters: month names differ between standalone headers
  (nominative, `monthNominative` → "Marzec") and after a day number (genitive,
  `monthGenitive` → "5 marca"). Counted nouns need plural rules
  (`transactionsCount` implements them).
- **Push-notification text is the exception**: it is built on the *backend*
  (`NotificationEventListener`) and is **hardcoded Polish**, because the backend
  has no per-user language. Real localization would need a `users.language`
  column + a sync endpoint.

## Project layout (`lib/`)

- `main.dart` — `MaterialApp`, theme (light/dark via `AppColors`), locale state,
  `AuthWrapper`. Web Firebase init happens **after `runApp`, non-blocking** — do
  not await it in `main()` or the web build shows a white page.
- `app_navigator.dart` — bottom-nav shell; tabs communicate via a
  `ValueNotifier<int>` (`tabNotifier`) so pages can refresh when re-selected.
- `pages/` — screens. `main_pages/` are the primary tabs (home, friends, profile,
  login) + `home_page_widgets/`. Notable: `all_expenses_page.dart` (list),
  `expense_form_page.dart` (create **and edit**), `expense_details_page.dart`,
  `balances_page.dart`, `projects_page.dart`.
- `models/`, `services/` (API + auth; `api_service/api_service_request.dart` is
  the core HTTP wrapper), `repository/`, `const/`, `projectColors/app_colors.dart`.

Note `HttpMethod` is defined **twice** (`api_service_request.dart` and
`const/http_enum.dart`). Files use the one from `api_service_request.dart`;
importing both causes an ambiguous-import error.

## Expenses — domain notes

- **Category ids are a fixed string set**, defined by `_kCategories` in
  `expense_form_page.dart`: `shopping`, `food`, `transport`, `entertainment`,
  `health`, `subscriptions`, `others` (note: **`others`**, plural). Any filter,
  style, or badge that keys off category must use these exact ids. Keep in sync:
  the filter enum in `all_expenses_page.dart`, `ExpenseStyle.getStyle`,
  `category_label.dart`, and the **backend AI prompts** (`AiGeminiService` lists
  the ids for receipt categorization).
- The expenses API is **paginated** (Spring `Page`) and uses **Spring's standard
  query params**: `page`, `size`, `sort=<field>,<dir>`. The non-standard
  `pageNumber`/`pageSize`/`sortBy`/`sortDirection` are **silently ignored** — a
  request using them just gets page 0 at the default size (10), sorted
  `createdAt` ASC. `all_expenses_page.dart` loads **one page at a time on
  scroll**; do NOT load all pages up front.
- **`userShare` is N+1 by design**: the list endpoint returns `totalAmount` but
  not the current user's share, so the page calls `GET /expenses/{id}/userShare`
  per expense. This is why eager full-list loading is bad. Only fetch `userShare`
  for the page you just loaded. (A batch/embedded field would remove the N+1 —
  future backend work.) It 404s for personal expenses (no split row).
- **Edit** reuses `ExpenseFormPage` via an `editExpense:` param: it PUTs the
  header, then **deletes and recreates** the split/items.
- **Long-press (or right-click on desktop) on a tile** (expenses list + home
  recent) opens a context sheet. The browser's native context menu is disabled
  globally on web (`BrowserContextMenu.disableContextMenu()` in `main()`) —
  Flutter does NOT block it by default, and without this the browser menu
  opens on top of ours. Text fields keep Flutter's own selection toolbar.
  The sheet (`widgets/expense_actions_sheet.dart`) offers the same actions and
  rules as swipe + details: settle/undo for the owner, declare/retract for a
  participant, repeat for everyone, edit/delete owner-only. It takes the same
  `onSetSettled` callback as `SettleSwipe`, so in-place tile updates behave
  identically to the swipe.
- **Repeat** (`repeatExpense:` param, "Powtórz" in the details menu, visible to
  anyone who can see the expense) prefills the form from an existing expense —
  header, split, items — but saves a **new** one: date resets to today, split
  participants / item assignees who aren't the repeater's friends are dropped
  (the backend friendship check would refuse them), and a project the repeater
  isn't a member of is cleared. Custom item shares fall back to an equal split
  when an assignee was dropped (they'd no longer add up). Deleting a split is
  refused by the backend if a participant already **settled** — that case is
  surfaced as an error and the split is left alone.
- Only the **owner** may edit/delete (`SingleExpense.ownerId` vs the current
  user's `sub`).
- **Settled is the owner's word; a participant only *declares*.** The same
  settle gesture means two things: the expense owner really settles a share
  (confirms money arrived), a participant merely sets `declaredPaid` — an
  "I paid" **suggestion** shown to the owner to verify and confirm (chip
  "Zgłasza zapłatę" → tap settles directly). Declarations are optional, do
  not touch balances, are retractable, and a participant cannot un-settle an
  owner-confirmed share. Viewer-relative fields: `ExpenseResponse.declared`
  (my own claim) and `declaredCount` (pending claims, for the owner's badge);
  `ExpenseSplitResponse.declaredPaid` per member. The swipe (`SettleSwipe`)
  needs `isOwner` — pages resolve it from `ownerId` vs the JWT `sub`.
- After edit/delete, `ExpenseDetailsPage` pops with `true`; every screen that
  pushes it must `await` the push and refresh on `true` (list, home recent,
  pinned) — otherwise stale rows linger.

## Projects — domain notes

A project groups expenses (a trip, a party). Any **member** — not just the owner —
may add expenses to it.

- **A project is a shared ledger.** Scoped to a project, a member sees **every**
  expense in it, including expenses between other members they are not party to.
  This is a deliberate exception to the normal visibility rule (you see an expense
  if you created it *or* are in its split). Without it each member saw a different
  subset of "the trip's expenses" and the project total disagreed with the list
  under it. Membership is checked in `ExpenseService.searchExpenses` — it is the
  only thing between a stranger and everyone else's spending, so it must not be
  left to the query. `ExpenseAccessService` has the matching rule, or tapping such
  an expense would 404.
- **`ExpenseResponse.canSettle`** says whether *this viewer* may settle it. A
  member seeing someone else's project expense has no share in it, so the backend
  refuses — the UI must not offer the gesture (`SettleSwipe` honours this).
- Only an expense's **creator** may edit/delete it. The *project* owner has no
  power over other people's expenses; they can only rename/delete the project and
  manage members.
- Filtering by project happens **server-side** (`GET /expenses?projectId=…`). The
  list is paginated, so filtering client-side would only ever cover the page that
  happened to be loaded.
- `ProjectResponse.expenseCount`/`totalAmount` come from **one grouped query** for
  the whole list (`ExpenseRepository.sumByProject`), not a lookup per project.
- **Deleting a project detaches, never deletes.** Expenses and settlements are real
  money and outlive the grouping. This is also load-bearing: `debts.project_id`
  carries a FK, so a project that had ever been settled up could not be deleted at
  all; `expenses.project_id` has **no** FK, so it was silently orphaning rows.

### Open questions (deliberately not built)

- **Project-wide "who owes whom" is missing.** `getBalances(userId, projectId)` and
  the settlement history are both anchored on `:userId`, so a member sees only
  *their own* balances within the trip — never "Anna owes Piotr 50 zł". A member can
  see an expense is `1/3 settled` but not who the outstanding party is unless they
  are personally involved. A project-wide pairwise overview is the natural missing
  piece, but it is a **privacy decision**, not just UI: it exposes every member's
  debts to every other member. Right for a holiday with friends; possibly wrong
  otherwise.
- Should the **project owner** be able to remove/detach expenses from their own
  project? Today they cannot touch an expense they did not create.

## Notifications / PWA (web push)

Non-obvious and easy to break:

- **Enablement**: web push only initialises when `kFirebaseWebConfigured == true`
  (`lib/firebase_web_config.dart`). The backend only *sends* when
  `FIREBASE_ENABLED=true` **and** `FIREBASE_CREDENTIALS` (the **base64** of the
  Firebase service-account JSON) are set in `/opt/settly/.env`. If pushes silently
  never arrive, check these first — `FcmService` logs "FCM not configured".
- **Never call `showNotification` in `onBackgroundMessage`.** The FCM SDK already
  auto-displays messages that carry a `notification` payload; showing it again
  produces a **duplicate** toast. `web/firebase-messaging-sw.js` deliberately has
  no such handler.
- **Never set a colour `badge`** on a web notification: Android renders the badge
  as a monochrome silhouette of the icon's alpha, so an opaque square icon shows
  as a **white box**.
- **Deep-linking** uses the backend's `webpush.fcmOptions.link`
  (`…/?notif_type=…&notif_id=…`); the FCM SDK's built-in click handler opens it,
  and `NotificationService.consumeWebLaunch()` reads those query params on launch.
  Do not add a custom `notificationclick` handler — it fights the SDK's.
- Permission is requested **only when undetermined**; requesting on every launch
  re-prompts forever and leaves the FCM token unregistered.
- **Pages opened from a notification must be pushed via `_pushFromNotification`**
  (`notification_service.dart`), which wraps them in `_NotificationRoute`. Its
  `PopScope` sends the **system/browser back** to the home page instead of letting
  it leave the PWA — a notification opens a window with a single history entry, so
  a plain back would close the app. `PopScope` only intercepts the *system* back
  (`Navigator.maybePop`); an in-app `Navigator.pop()` still works normally and
  still returns its result (e.g. "something changed, refresh the list").
- Notification text is composed on the **backend** and is hardcoded **Polish**
  (`NotificationEventListener`, `SettlementReminderJob`). Polish counted nouns
  need the real plural rules — see `SettlementReminderJob.expensesPlural`
  (1 wydatek / 2-4 wydatki / 5+ wydatków, with the 12-14 exception).
- A daily 18:00 (Europe/Warsaw) job reminds **debtors only** to settle up. The
  scheduler is in-process, so it would fire once per instance if the API is ever
  scaled out.
- **On-screen keyboard**: since Chrome 108, Android browsers *overlay* the
  keyboard instead of resizing the viewport unless the viewport meta contains
  `interactive-widget=resizes-content` — without it Flutter never sees the
  keyboard (`viewInsets.bottom` stays 0), so no amount of Dart-side scroll
  padding can uncover a focused field. The Flutter engine **replaces** any
  static viewport meta at startup, so `web/index.html` patches the property
  onto the engine's tag after injection (MutationObserver +
  `flutter-first-frame`). Don't move it into a static `<meta>` — it would be
  clobbered.
- **Orientation lives in `web/manifest.json`, not in Dart.** `SystemChrome.
  setPreferredOrientations` is the *native* path and does nothing for the shipped
  PWA. The manifest used to say `"orientation": "any"` — that is not a neutral
  default but an assertion that the app may use any orientation, and an installed
  standalone PWA takes it as permission to rotate **even when the device's
  rotation lock is on**. It is now `"portrait"`. A manifest change may only take
  effect after the PWA is reinstalled.
- Icons (`web/icons/*`, `web/favicon.png`) are generated from `settly_icon.png`.
  **Maskable** icons need a generous safe-zone margin or Android's adaptive mask
  clips them. An installed PWA caches its launcher icon at install time — it only
  updates on **uninstall + reinstall**.
- `nginx/web.conf` sends `no-cache` for the service workers so a deploy is picked
  up on the next load.

## Conventions

- Comments in the codebase are frequently in Polish; match the surrounding file.
- Dark mode is threaded manually as a `bool isDark` argument into `AppColors`
  helpers rather than via `Theme.of`.
- Money input: `lib/utils/money_input.dart` (`MoneyInputFormatter`, max 2 decimals;
  `normalizeMoney`). The backend enforces the same with `@Digits(fraction = 2)`.

## Change log

- **2026-07-06** — Expenses page fixes: pagination switched to Spring's real
  `page`/`size`/`sort` params with incremental infinite scroll (an earlier
  iteration eagerly looped all pages and fired the `userShare` N+1 for the whole
  dataset — reverted); category filter enum synced to the backend ids; date-group
  headers no longer leak their sort key (`MONTH|marca`) and the summary is
  localized; `ExpenseStyle` `case 'Shopping'` never matched after `toLowerCase()`;
  add/scan FABs; money inputs capped at 2 decimals; zero-amount warning; a CUSTOM
  split may now leave the creator owing exactly 0; CUSTOM split is a top-down
  cascade with drag-to-reorder participants.
- **2026-07-07** — Avatars use the user's photo when available (shared
  `widgets/user_avatar.dart`). Backend enabler: `KeycloakAdminService.syncUser`
  used to hard-code `setAvatarUrl(null)`; it now reads the Keycloak `avatar_url` /
  `picture` attribute (only on first sync — existing users don't backfill).
  Expense **details** split members still show initials (`ExpenseMember` carries
  no `avatarUrl`).
- **2026-07-08** — Web/desktop push + PWA install (FCM, VAPID, service worker,
  one-time install banner + Profile install button).
- **2026-07-13** — Expense **edit + delete** (owner-only, incl. splits/items);
  backend `updateExpense` was silently dropping `category`/`currency`, and
  `deleteExpense` now cascades to item-splits/splits/items (an FK previously
  blocked deleting any split expense). Notification fixes: duplicate toast,
  white-box badge, permission re-prompt, Polish text, deep-linking to the expense
  / friends page. Real Settly favicon + PWA icons. Pull-to-refresh audited across
  data pages; screens that push expense details now refresh on return.

- **2026-07-14** — Notification **inbox** (backend `notifications` table, V7): a push
  is fire-and-forget, so a dismissed/undelivered one used to vanish. `sendToUser`
  now records it *first and unconditionally* — the inbox, not the push, is the
  source of truth, so a user whose browser refuses push still sees it in the bell.
  Tapping the toast marks that exact entry read (the payload carries the inbox id).
  Foreground pushes get an in-app heads-up bar (the system draws no toast while the
  app is open). "Enable notifications" recovery in Profile + the bell — **Brave
  ships with "Use Google services for push messaging" OFF, so a granted permission
  still yields no token**; that case is reported separately from "blocked".
  **Projects made end-to-end** (see the Projects section): a project's expenses were
  previously invisible — the feature was write-only. On-screen keyboard no longer
  covers focused inputs (custom split prices etc.): `interactive-widget=
  resizes-content` is patched onto the engine's viewport meta (see the PWA
  section) — the Dart-side `viewInsets` padding alone could never work because
  Chrome 108+ overlays the keyboard without telling Flutter.
  **Declared-paid** (backend V8): participants no longer settle their own share;
  they *declare* payment as a suggestion the owner confirms (see the Expenses
  section). Reminder job skips declared shares; owner gets a dedicated push.
  New **`subscriptions`** category (Subskrypcje) across form, filter, styles,
  labels and the AI receipt prompts. **Repeat expense**: "Powtórz" in expense
  details creates a new expense prefilled from an existing one (see the
  Expenses section) — no backend change needed. **Long-press context menu** on
  expense tiles (list + home): settle/declare, repeat, edit, delete.

> When you change behavior, update this file (esp. the localization, expenses,
> projects and notifications notes, and this change log).
