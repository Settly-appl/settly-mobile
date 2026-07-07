# Settly Mobile — Claude Code guide

Flutter app for **Settly**: shared/personal expense tracking and settling balances
between friends and projects (Splitwise-style). Package name: `settly_mobile`.

## Running / tooling

- **Flutter lives on the Windows host, not inside WSL.** Commands like
  `flutter analyze` / `flutter run` must be run from Windows (PowerShell) or via
  `flutter.bat`. They are not on the WSL `PATH`. If you need the user to run
  something, ask them to run it themselves (e.g. `! flutter analyze` in-session
  won't find the binary from WSL).
- Backend host is configurable at build time:
  `--dart-define=SETTLY_HOST=https://settly.duckdns.org` (defaults to
  `http://localhost`). See `lib/const/api_url.dart`. Auth is via Keycloak.

## Project layout (`lib/`)

- `main.dart` — `MaterialApp`, theme (light/dark via `AppColors`), locale state,
  `AuthWrapper`. Locale persisted in `SharedPreferences` key `app_language`.
- `app_navigator.dart` — bottom-nav shell; tabs communicate via a
  `ValueNotifier<int>` (`tabNotifier`) so pages can refresh when re-selected.
- `pages/` — screens. `main_pages/` are the primary tabs (home, friends, profile,
  login) + `home_page_widgets/`. Notable: `all_expenses_page.dart` (expenses
  list), `expense_form_page.dart` (create/edit), `expense_details_page.dart`,
  `balances_page.dart`, `projects_page.dart`.
- `models/` — data classes. `expenses/single_expense.dart`,
  `expenses/expens_style.dart` (per-category icon/colour), enums under
  `models/enums/`.
- `services/` — API + auth. `api_service/api_service_request.dart` is the core
  HTTP wrapper (`ApiServiceRequest().request(endpoint:, method:)`).
- `repository/` — higher-level data access (e.g. `expense_repository.dart`).
- `const/` — `app_texts.dart` (all UI strings), `api_url.dart`, `http_enum.dart`.
- `projectColors/app_colors.dart` — every colour, keyed by `isDark`.

## Localization — IMPORTANT

- **No `.arb`/gen-l10n.** All translations live in `lib/const/app_texts.dart` as
  a hand-written `AppTexts` class. Get it with `AppTexts.of(context)`, which
  reads `Localizations.localeOf(context)`.
- Supported locales: `pl` (default, `Locale('pl','PL')`) and `en` (`Locale('en')`).
  `AppTexts._isEnglish` = `languageCode == 'en'`.
- **Every user-facing string must go through `AppTexts`.** Do not hardcode
  English or Polish literals in widgets — that is the root cause of mixed-language
  UI bugs. If a string needs a value interpolated, add a method to `AppTexts`
  (see `transactionsCount`, `daysInMonthCount`, `monthYear`).
- Polish grammar matters: month names differ between standalone headers
  (nominative, `monthNominative` → "Marzec") and after a day number (genitive,
  `monthGenitive` → "5 marca"). Counted nouns need plural rules
  (`transactionsCount` implements them).

## Expenses — domain notes

- **Category ids are a fixed string set**, defined by `_kCategories` in
  `expense_form_page.dart` and used everywhere: `shopping`, `food`, `transport`,
  `entertainment`, `health`, `others` (note: **`others`**, plural). Any filter,
  style, or badge that keys off category must use these exact ids. The filter
  enum in `all_expenses_page.dart` (`AllExpensesPage`) and
  `ExpenseStyle.getStyle` must stay in sync with this list.
- The expenses API is **paginated** (Spring `Page`: `content`, `last`, `number`,
  `size`, `totalElements`). It uses **Spring's standard query params**:
  `page`, `size`, and `sort=<field>,<dir>` (e.g. `sort=createdAt,desc`). The
  non-standard `pageNumber`/`pageSize`/`sortBy`/`sortDirection` are silently
  ignored — a request using them just gets page 0 at the default size (10),
  sorted `createdAt` ASC. Home page and pin picker already use the correct
  params. `all_expenses_page.dart` loads **one page at a time on scroll**
  (infinite scroll) — do NOT load all pages up front.
- **`userShare` is N+1 by design**: the list endpoint returns `totalAmount` but
  not the current user's share, so the page calls
  `GET /expenses/{id}/userShare` once per expense (see
  `ExpenseRepository.fetchUserShareForExpense`). This is why eager full-list
  loading is bad — it fires that call for every expense at once. Only fetch
  `userShare` for the page you just loaded. A batch/embedded field on the list
  endpoint would remove the N+1 entirely (future backend work).
- Per-expense `userShare` is fetched one call at a time
  (`ExpenseRepository.fetchUserShareForExpense`) — an N+1 pattern. Fine for now;
  a batch endpoint would be the future optimization.

## Conventions

- Comments in the codebase are frequently in Polish; match the surrounding file.
- Dark mode is threaded manually as a `bool isDark` argument into `AppColors`
  helpers rather than via `Theme.of`.

## Change log

- **2026-07-06** — Fixed the expenses page (`all_expenses_page.dart`,
  `app_texts.dart`, `expens_style.dart`):
  1. **Pagination** — the page was sending Spring's ignored `pageNumber`/
     `pageSize`/`sortBy`/`sortDirection` params, so the API always returned just
     the first 10 expenses (oldest-first). Switched to the standard
     `page`/`size`/`sort=createdAt,desc` with **incremental infinite-scroll**
     (one 20-item page per scroll; `userShare` fetched only for that page).
     Note: an earlier iteration eagerly looped *all* pages up front — reverted,
     because it fired the per-expense `userShare` N+1 for the whole dataset at
     once and defeated the point of pagination.
  2. **Category filters** — enum sent `other` (backend uses `others`) and was
     missing `entertainment`/`health`, so those expenses never showed under a
     filter. Enum now matches the full `_kCategories` id set.
  3. **Mixed language / `MONTH|marca` leak** — date-group headers were rendering
     their internal sort key (`MONTH|marca`, `THISMONTH|...`) verbatim, and the
     summary card (month, "X transactions", "of N days") was hardcoded English.
     Grouping now separates sort key from a fully-translated label; summary uses
     new `AppTexts` helpers.
  4. **Shopping style bug** — `ExpenseStyle.getStyle` had `case 'Shopping'` after
     a `toLowerCase()`, so it never matched; fixed to `'shopping'`. Category
     badges now show a localized label instead of the raw id.
  5. **Add / scan buttons** — the expenses page had no way to add an expense.
     Added two FABs (extended "add expense" + small "scan receipt") that open the
     same `QuickAddMenu` / `QuickScanMenu` bottom sheets the home page uses, with
     `onSaved: _refreshExpenses`.
  6. **Money inputs** — the amount / split / item-price fields accepted junk like
     `5.353` or `5.1000000`. Added `lib/utils/money_input.dart`
     (`MoneyInputFormatter`, max 2 decimals + single separator; `normalizeMoney`)
     and a reusable `_MoneyField` in `expense_form_page.dart` that pads to 2
     decimals on blur (`5` → `5.00`) and strips trailing zeros on focus for easy
     editing (`5.00` → `5`, `5.10` → `5.1`, cursor at end). Backend now enforces
     the same with
     `@Digits(fraction = 2)` on `CreateExpenseRequest.totalAmount`,
     `CreateExpenseItemRequest.price` (and `fraction = 3` on `quantity`), and
     `SplitParticipant.amount` — validation errors surface as 400 via
     `GlobalExceptionHandler`. **The settly-api must be rebuilt/restarted for the
     new annotations to take effect** (it runs from the IDE, not a container).
  7. **Zero-amount warning** — the expense form's amount card shows a subtle red
     inline warning (`formAmountZeroWarning`) when a non-empty amount parses to 0
     (suppressed while the field is empty or the amount is locked/by-items).
  8. **Creator may owe exactly 0 in a CUSTOM split** — previously the owner's
     share had to be > 0 (friends couldn't cover the full total). Now the owner's
     share can be 0 (you bought it entirely for others); only a friends' total
     that *exceeds* the amount is rejected. Backend: `ExpenseSplitService` CUSTOM
     branch `<= 0` → `< 0` (+ new test `should_allow_custom_split_when_owner_owes_zero`).
     Frontend: `_blockingError`/`_customEditor` use `> total` (with float slack)
     instead of `>= total`; messages `errorFriendsExceedTotal` / `splitCustomOverflow`
     reworded. **Needs settly-api rebuild/restart to take effect.**
  9. **CUSTOM split is now a top-down cascade + reorderable** — the owner is just
     one row in an ordered, drag-to-reorder list (`_customOrder`, owner uses
     `_ownerAmountController`, friends use `_customAmountControllers`, accessed
     uniformly via `_ctrlFor`). Editing the row at index *i* freezes rows `0..i`
     and splits the remaining `total − Σ(0..i)` **equally across the rows below**
     (`_cascadeFromIndex`); so you fill your own irregular amount first, then each
     next person, and everyone above stays put. Reorder via
     `ReorderableListView` + `ReorderableDragStartListener` handles
     (`_onReorderParticipants`, values preserved). Total change → the bottom row
     absorbs (`_cascadeBottomAbsorb`). Validation requires all shares to add up to
     the total (`_customParticipantsTotal`); a re-entrancy guard
     (`_recomputingCustom`) prevents feedback loops. Frontend-only: submit still
     sends friend amounts; backend derives owner = `total − Σfriends`. Because a
     rounded share can land on `0.00`, `SplitParticipant.amount` was relaxed from
     `@DecimalMin("0.01")` to `@DecimalMin("0.00")` (still rejects negatives).

- **2026-07-07** — Avatars now show the user's photo when available:
  - New shared `lib/widgets/user_avatar.dart` (`UserAvatar`): renders
    `NetworkImage(avatarUrl)` when a URL is present, else initials. Every avatar
    surface now uses it — profile, home nav, friends list/requests/search,
    balances, project members + add-member picker, quick-scan friend picker, and
    the expense form (friend chips, split rows, item-assignee chips). Own picture
    comes from the ID token `picture` claim; friends' from their `avatarUrl`.
  - **Backend enabler**: `KeycloakAdminService.syncUser` used to hard-code
    `setAvatarUrl(null)`, so friends never had a photo. It now reads the Keycloak
    user attribute `avatar_url` (Google IdP mapper) / `picture`. Only populated on
    first sync — already-synced users won't backfill. **Needs settly-api restart.**
  - Not yet wired: expense **details** split-member avatars — `ExpenseMember` /
    `ExpenseSplitResponse` carry no `avatarUrl`, so those still show initials.

- **2026-07-08** — Web/desktop push (FCM) scaffolding, off by default:
  - The app is already a PWA (`web/manifest.json`, Flutter service worker), so it
    is installable as-is. Web push was fully disabled (`main.dart` skipped Firebase
    on web; `NotificationService` had `if (kIsWeb) return`; no web `FirebaseOptions`;
    no FCM service worker).
  - Added: `lib/firebase_web_config.dart` (web `FirebaseOptions` + VAPID key +
    `kFirebaseWebConfigured` flag) and `web/firebase-messaging-sw.js`. `main.dart`
    now inits Firebase on web **only when `kFirebaseWebConfigured == true`**, wrapped
    in try/catch so it can never break the web build. `NotificationService` sends
    `platform: WEB` (and now correctly `IOS` on iOS) and fetches the token with the
    VAPID key on web.
  - **To turn it on**: register a Web app in Firebase, paste its config + the Web
    Push VAPID key into `lib/firebase_web_config.dart` AND
    `web/firebase-messaging-sw.js`, set `kFirebaseWebConfigured = true`, rebuild.
    Backend: `FIREBASE_ENABLED=true` + FCM service-account JSON on the server.
    Requires HTTPS (already have it). iOS web push works only for an installed PWA.

> When you change behavior, update this file (esp. the localization and category
> notes and this change log).
