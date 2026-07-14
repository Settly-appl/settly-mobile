import 'package:flutter/widgets.dart';

class AppTexts {
  final Locale locale;

  const AppTexts._(this.locale);

  factory AppTexts.of(BuildContext context) {
    return AppTexts._(Localizations.localeOf(context));
  }

  bool get _isEnglish => locale.languageCode == 'en';

  String get profileTitle => _isEnglish ? 'Profile' : 'Profil';
  String get projectsTitle => _isEnglish ? 'Projects' : 'Projekty';
  String get settlementsTitle => _isEnglish ? 'Settlements' : 'Rozliczenia';
  String get friendsTitle => _isEnglish ? 'Friends' : 'Znajomi';
  String get homeGreeting => _isEnglish ? 'Hello,' : 'Dzień dobry,';
  String get homeTab => _isEnglish ? 'Home' : 'Główna';
  String get expensesTab => _isEnglish ? 'Expenses' : 'Wydatki';
  String get groupsTab => _isEnglish ? 'Projects' : 'Projekty';
  String get friendsTab => _isEnglish ? 'Friends' : 'Znajomi';
  String get analysisTab => _isEnglish ? 'Analytics' : 'Analiza';
  String get quickActionsSection =>
      _isEnglish ? 'Quick actions' : 'Szybkie akcje';
  String get pinnedSection => _isEnglish ? 'Pinned' : 'Przypięte';
  String get editAction => _isEnglish ? 'Edit' : 'Edytuj';
  String get recentSection => _isEnglish ? 'Recent' : 'Ostatnie';
  String get seeAllAction => _isEnglish ? 'See all' : 'Zobacz wszystkie';
  String get comingSoon => _isEnglish ? 'Coming soon' : 'Wkrótce dostępne';
  String get notificationsTitle =>
      _isEnglish ? 'Notifications' : 'Powiadomienia';
  String get clearAction => _isEnglish ? 'Clear' : 'Wyczyść';
  String get noNotifications =>
      _isEnglish ? 'No notifications' : 'Brak powiadomień';
  String get changeThemeTooltip =>
      _isEnglish ? 'Change app theme' : 'Zmień motyw aplikacji';
  String get loginSubtitle =>
      _isEnglish ? 'Manage expenses together' : 'Zarządzaj wydatkami razem';
  String get loginButton => _isEnglish ? 'Sign in' : 'Zaloguj się';
  String get adminBroadcastButton => _isEnglish
      ? 'Send notification to everyone'
      : 'Wyślij powiadomienie do wszystkich';
  String get logoutButton => _isEnglish ? 'Log out' : 'Wyloguj się';
  String get languageSectionTitle =>
      _isEnglish ? 'App language' : 'Język aplikacji';
  String get switchLanguageLabel => _isEnglish ? 'Polish' : 'English';

  String get retryAction => _isEnglish ? 'Try again' : 'Spróbuj ponownie';
  String get cancelAction => _isEnglish ? 'Cancel' : 'Anuluj';
  String get saveAction => _isEnglish ? 'Save' : 'Zapisz';
  String get deleteAction => _isEnglish ? 'Delete' : 'Usuń';
  String get createAction => _isEnglish ? 'Create' : 'Utwórz';
  String get addAction => _isEnglish ? 'Add' : 'Dodaj';
  String get settledLabel => _isEnglish ? 'Settled' : 'Rozliczony';
  String get noProjects => _isEnglish ? 'No projects' : 'Brak projektów';
  String get noFriends => _isEnglish ? 'No friends' : 'Brak znajomych';
  String get noResults => _isEnglish ? 'No results' : 'Brak wyników';

  String get loading => _isEnglish ? 'Loading…' : 'Ładowanie…';

  String get networkError =>
      _isEnglish ? 'Connection error.' : 'Błąd połączenia.';
  String get searchFriend => _isEnglish ? 'Search friend' : 'Szukaj znajomego';
  String get friendsTabTitle => _isEnglish ? 'Friends' : 'Znajomi';
  String get requestsTabTitle => _isEnglish ? 'Requests' : 'Zaproszenia';
  String get incomingTitle => _isEnglish ? 'Incoming' : 'Przychodzące';
  String get outgoingTitle => _isEnglish ? 'Outgoing' : 'Wychodzące';
  String get acceptAction => _isEnglish ? 'Accept' : 'Akceptuj';
  String get declineAction => _isEnglish ? 'Decline' : 'Odrzuć';
  String get approveAction => _isEnglish ? 'Approve' : 'Akceptuj';

  String get projectsRetryError => _isEnglish
      ? 'Failed to load projects. Try again.'
      : 'Nie udało się pobrać projektów. Spróbuj ponownie.';
  String get projectRetryError => _isEnglish
      ? 'Failed to load project. Try again.'
      : 'Nie udało się pobrać projektu. Spróbuj ponownie.';
  String get balancesRetryError => _isEnglish
      ? 'Failed to load balances. Try again.'
      : 'Nie udało się pobrać sald. Spróbuj ponownie.';
  String get historyRetryError => _isEnglish
      ? 'Failed to load history. Try again.'
      : 'Nie udało się pobrać historii. Spróbuj ponownie.';
  String get settleFailedError => _isEnglish
      ? 'Failed to settle. Try again.'
      : 'Nie udało się rozliczyć. Spróbuj ponownie.';
  String get projectCreateFailedError => _isEnglish
      ? 'Failed to create project.'
      : 'Nie udało się utworzyć projektu.';
  String get projectMembersFailedError => _isEnglish
      ? 'Failed to load members.'
      : 'Nie udało się pobrać uczestników.';
  String get projectAddMemberFailedError =>
      _isEnglish ? 'Failed to add member.' : 'Nie udało się dodać uczestnika.';
  String get projectRemoveMemberFailedError => _isEnglish
      ? 'Failed to remove member.'
      : 'Nie udało się usunąć uczestnika.';
  String get projectLeaveFailedError => _isEnglish
      ? 'Failed to leave project.'
      : 'Nie udało się opuścić projektu.';
  String get projectDeleteFailedError => _isEnglish
      ? 'Failed to delete project.'
      : 'Nie udało się usunąć projektu.';
  String get projectRenameFailedError =>
      _isEnglish ? 'Failed to rename project.' : 'Nie udało się zmienić nazwy.';
  String get projectStatusFailedError => _isEnglish
      ? 'Failed to change status.'
      : 'Nie udało się zmienić statusu.';
  String get projectNoMembers =>
      _isEnglish ? 'No members yet' : 'Brak uczestników';
  String get projectSettled => _isEnglish ? 'Settled' : 'Rozliczony';
  String get projectNotFound =>
      _isEnglish ? 'Project not found' : 'Nie znaleziono projektu';
  String get projectNoBalances => _isEnglish
      ? 'No unsettled balances in this project.'
      : 'Brak nierozliczonych sald w tym projekcie.';
  String get projectNoFriendsInProject => _isEnglish
      ? 'All friends are already in the project.'
      : 'Wszyscy znajomi są już w projekcie.';
  String get projectAddMemberTitle =>
      _isEnglish ? 'Add member' : 'Dodaj uczestnika';
  String get projectMembersHeader => _isEnglish ? 'Members' : 'Uczestnicy';
  String get projectOwner => _isEnglish ? 'Owner' : 'Właściciel';
  String get projectAddExpense => _isEnglish ? 'Add expense' : 'Dodaj wydatek';
  String get projectRenameTitle => _isEnglish ? 'Rename' : 'Zmień nazwę';
  String get projectDeleteTitle =>
      _isEnglish ? 'Delete project?' : 'Usunąć projekt?';
  String get projectLeaveTitle =>
      _isEnglish ? 'Leave project?' : 'Opuścić projekt?';
  String get projectDeleteConfirm => _isEnglish ? 'Delete' : 'Usuń';
  String get projectLeaveConfirm => _isEnglish ? 'Leave' : 'Opuść';
  String get confirmAction => _isEnglish ? 'Confirm' : 'Potwierdź';
  String get receiptTitle => _isEnglish ? 'Receipt' : 'Paragon';

  // Shared screens / tabs
  String get homeTabLabel => _isEnglish ? 'Home' : 'Główna';
  String get allTabLabel => _isEnglish ? 'All' : 'Wszystkie';
  String get todayLabel => _isEnglish ? 'Today' : 'Dziś';
  String get yesterdayLabel => _isEnglish ? 'Yesterday' : 'Wczoraj';
  String get thisWeekLabel => _isEnglish ? 'This week' : 'W tym tygodniu';
  String get lastTwoWeeksLabel =>
      _isEnglish ? 'Last 2 weeks' : 'Ostatnie 2 tygodnie';
  String get thisMonthLabel => _isEnglish ? 'This month' : 'W tym miesiącu';
  String get categoryAllLabel => _isEnglish ? 'All' : 'Wszystkie';
  String get categoryFoodLabel => _isEnglish ? 'Food' : 'Jedzenie';
  String get categoryTransportLabel => _isEnglish ? 'Transport' : 'Transport';
  String get categoryShoppingLabel => _isEnglish ? 'Shopping' : 'Zakupy';
  String get categoryOtherLabel => _isEnglish ? 'Other' : 'Inne';
  String get searchExpenseHint =>
      _isEnglish ? 'Search expense…' : 'Szukaj wydatku…';
  String get noExpenses => _isEnglish ? 'No expenses' : 'Brak wydatków';
  String get noExpensesForQuery =>
      _isEnglish ? 'No results for “{query}"' : 'Brak wyników dla „{query}"';
  String get noExpensesInCategory => _isEnglish
      ? 'There are no expenses in this category yet.'
      : 'W tej kategorii nie ma jeszcze wydatków.';
  String get monthLabel => _isEnglish ? 'March 2026' : 'Marzec 2026';
  String get totalTransactionsLabel =>
      _isEnglish ? '23 transactions' : '23 transakcje';
  String get daysInMonthLabel => _isEnglish ? 'of 30 days' : 'z 30 dni';

  // ── Localized month names & counted nouns ──────────────────────────────────
  static const List<String> _enMonths = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  // Polish nominative — used for standalone headers ("Marzec 2026").
  static const List<String> _plMonthsNominative = [
    '', 'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
    'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień',
  ];
  // Polish genitive — used after a day number ("5 marca").
  static const List<String> _plMonthsGenitive = [
    '', 'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
    'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia',
  ];

  /// Month name for a standalone header, e.g. "March" / "Marzec".
  String monthNominative(int month) =>
      _isEnglish ? _enMonths[month] : _plMonthsNominative[month];

  /// Month name following a day number, e.g. "5 March" / "5 marca".
  String monthGenitive(int month) =>
      _isEnglish ? _enMonths[month] : _plMonthsGenitive[month];

  /// "March 2026" / "Marzec 2026".
  String monthYear(int month, int year) =>
      '${monthNominative(month)} $year';

  /// "12 transactions" / "12 transakcji" (with Polish plural rules).
  String transactionsCount(int n) {
    if (_isEnglish) return '$n ${n == 1 ? 'transaction' : 'transactions'}';
    final mod10 = n % 10;
    final mod100 = n % 100;
    final String word;
    if (n == 1) {
      word = 'transakcja';
    } else if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
      word = 'transakcje';
    } else {
      word = 'transakcji';
    }
    return '$n $word';
  }

  /// "of 30 days" / "z 30 dni".
  String daysInMonthCount(int n) => _isEnglish ? 'of $n days' : 'z $n dni';

  // Balances / settlements
  String get balancesTitle => _isEnglish ? 'Settlements' : 'Rozliczenia';
  String get balancesHistoryTooltip =>
      _isEnglish ? 'Settlement history' : 'Historia rozliczeń';
  String get balancesRetryMessage => _isEnglish
      ? 'Failed to load balances. Try again.'
      : 'Nie udało się pobrać sald. Spróbuj ponownie.';
  String get settleSuccessPrefix => _isEnglish ? 'Settled' : 'Rozliczono';
  String get settleAction => _isEnglish ? 'Settle' : 'Rozlicz';
  String get allSettledTitle =>
      _isEnglish ? 'Everything settled!' : 'Wszystko rozliczone!';
  String get allSettledSubtitle => _isEnglish
      ? 'You have no unsettled balances with friends.'
      : 'Nie masz żadnych nierozliczonych sald ze znajomymi.';
  String get balancesOwedToYou => _isEnglish ? 'Owed to you' : 'Należności';
  String get balancesYouOwe => _isEnglish ? 'You owe' : 'Zobowiązania';
  String get balancesOtherOwes => _isEnglish ? 'owes you' : 'inni Tobie';
  String get balancesYouOweOthers => _isEnglish ? 'you owe others' : 'Ty innym';
  String get settlesAsReceived =>
      _isEnglish ? 'Mark as received' : 'Oznacz jako zapłacone';
  String get settleConfirmTitle =>
      _isEnglish ? 'Mark as settled?' : 'Oznaczyć jako rozliczone?';
  String settleConfirmBody(String label, String amount) => _isEnglish
      ? 'You confirm that $label paid you $amount zł. All unsettled '
            'shares of this person toward you will be closed.'
      : 'Potwierdzasz, że $label zapłacił(a) Ci $amount zł. Wszystkie '
            'nierozliczone udziały tej osoby wobec Ciebie zostaną zamknięte.';
  String get settleConfirmAction => _isEnglish ? 'Yes, settle' : 'Tak, rozlicz';
  String get settleWaitConfirmation => _isEnglish
      ? 'Wait until your friend confirms receiving the payment.'
      : 'Poczekaj, aż znajomy potwierdzi otrzymanie płatności.';

  // Projects
  String get projectNewProject => _isEnglish ? 'New project' : 'Nowy projekt';
  String get projectNameLabel => _isEnglish ? 'Name' : 'Nazwa';
  String get projectDescriptionLabel =>
      _isEnglish ? 'Description (optional)' : 'Opis (opcjonalnie)';
  String get projectNameExample =>
      _isEnglish ? 'e.g. Mountain trip' : 'np. Wyjazd w góry';
  String get projectNoProjectsHint => _isEnglish
      ? 'Create a project to track expenses and balances together with friends.'
      : 'Utwórz projekt, aby wspólnie ze znajomymi śledzić wydatki i salda.';
  String get projectMembersCountSuffixSingular =>
      _isEnglish ? 'member' : 'uczestnik';
  String get projectMembersCountSuffixPlural =>
      _isEnglish ? 'members' : 'uczestników';
  String get projectSettledStatus => _isEnglish ? 'Settled' : 'Rozliczony';
  String get projectRenameMenu => _isEnglish ? 'Rename' : 'Zmień nazwę';
  String get projectDeleteMenu =>
      _isEnglish ? 'Delete project' : 'Usuń projekt';
  String get projectLeaveMenu => _isEnglish ? 'Leave project' : 'Opuść projekt';
  String get projectToggleActive =>
      _isEnglish ? 'Mark as active' : 'Oznacz jako aktywny';
  String get projectToggleSettled =>
      _isEnglish ? 'Mark as settled' : 'Oznacz jako rozliczony';
  String get projectBalanceSection =>
      _isEnglish ? 'Project balances' : 'Salda w projekcie';
  String get projectMembersSection => _isEnglish ? 'Members' : 'Uczestnicy';
  String get projectAddExpenseButton =>
      _isEnglish ? 'Add expense' : 'Dodaj wydatek';
  String get projectAddMemberButton => _isEnglish ? 'Add' : 'Dodaj';
  String get projectOwnerLabel => _isEnglish ? 'Owner' : 'Właściciel';
  String get projectNoBalancesLabel => _isEnglish
      ? 'No unsettled balances in this project.'
      : 'Brak nierozliczonych sald w tym projekcie.';
  String get projectNoFound =>
      _isEnglish ? 'Project not found' : 'Nie znaleziono projektu';
  String get projectMembersMissing => _isEnglish
      ? 'Failed to load members.'
      : 'Nie udało się pobrać uczestników.';
  String get projectAddMemberFailed =>
      _isEnglish ? 'Failed to add member.' : 'Nie udało się dodać uczestnika.';
  String get projectRemoveMemberFailed => _isEnglish
      ? 'Failed to remove member.'
      : 'Nie udało się usunąć uczestnika.';
  String get projectLeaveFailed => _isEnglish
      ? 'Failed to leave project.'
      : 'Nie udało się opuścić projektu.';
  String get projectDeleteFailed => _isEnglish
      ? 'Failed to delete project.'
      : 'Nie udało się usunąć projektu.';
  String get projectRenameFailed =>
      _isEnglish ? 'Failed to rename project.' : 'Nie udało się zmienić nazwy.';
  String get projectStatusFailed => _isEnglish
      ? 'Failed to change status.'
      : 'Nie udało się zmienić statusu.';
  String get projectNoMembersInProject =>
      _isEnglish ? 'No members yet' : 'Brak uczestników';
  String get projectAllFriendsAlready => _isEnglish
      ? 'All friends are already in the project.'
      : 'Wszyscy znajomi są już w projekcie.';

  // Friends
  String get friendsSearchHint =>
      _isEnglish ? 'Search friend' : 'Szukaj znajomego';
  String get friendsNoFriendsTitle =>
      _isEnglish ? 'No friends' : 'Brak znajomych';
  String get friendsNoFriendsSubtitle => _isEnglish
      ? 'Add your first friend using the button below.'
      : 'Dodaj pierwszego znajomego przyciskiem poniżej.';
  String get friendsNoResultsTitle =>
      _isEnglish ? 'No results' : 'Brak wyników';
  String get friendsNoRequestsTitle =>
      _isEnglish ? 'No requests' : 'Brak zaproszeń';
  String get friendsNoRequestsSubtitle => _isEnglish
      ? 'You have no pending requests.'
      : 'Nie masz żadnych oczekujących zaproszeń.';
  String get friendsIncomingLabel => _isEnglish ? 'Incoming' : 'Przychodzące';
  String get friendsOutgoingLabel => _isEnglish ? 'Outgoing' : 'Wychodzące';
  String get friendsAccept => _isEnglish ? 'Accept' : 'Akceptuj';
  String get friendsDecline => _isEnglish ? 'Decline' : 'Odrzuć';
  String get friendsCancel => _isEnglish ? 'Cancel' : 'Anuluj';
  String get friendsDeleteFriend =>
      _isEnglish ? 'Delete friend' : 'Usuń znajomego';
  String get friendsDeleteFriendTitle =>
      _isEnglish ? 'Delete friend?' : 'Usunąć znajomego?';
  String get friendsDeleteFriendSubtitle => _isEnglish
      ? 'will be removed from your friends list.'
      : 'zostanie usunięty z listy znajomych.';
  String get friendsSearchFailed => _isEnglish
      ? 'Failed to update the request.'
      : 'Nie udało się zaktualizować zaproszenia.';
  String get friendsOperationFailed =>
      _isEnglish ? 'Operation failed.' : 'Nie udało się wykonać operacji.';
  String get friendAddTitle => _isEnglish ? 'Add friend' : 'Dodaj znajomego';
  String get friendEmailLabel => _isEnglish ? 'Email' : 'Email';
  String get friendEmailHint =>
      _isEnglish ? 'address@domain.com' : 'adres@domena.pl';
  String get friendSearchButton => _isEnglish ? 'Search' : 'Szukaj';
  String get friendRequestCancelled =>
      _isEnglish ? 'Friend request cancelled.' : 'Anulowano zaproszenie.';

  // Expenses / quick actions / forms
  String get quickAddTitle =>
      _isEnglish ? 'What would you like to add?' : 'Co chcesz dodać?';
  String get quickAddSubtitle => _isEnglish
      ? 'Choose the type you want to create'
      : 'Wybierz typ, który chcesz utworzyć';
  String get quickScanTitle => _isEnglish ? 'Scan a receipt' : 'Skanuj paragon';
  String get quickScanSubtitle => _isEnglish
      ? 'Choose the expense type to scan'
      : 'Wybierz typ wydatku do zskanowania';
  String get singleExpenseLabel =>
      _isEnglish ? 'Single expense' : 'Pojedynczy wydatek';
  String get groupExpenseLabel =>
      _isEnglish ? 'Group expense' : 'Wydatek grupowy';
  String get projectExpenseLabel =>
      _isEnglish ? 'Project expense' : 'Wydatek w projekcie';
  String get quickExpenseExamples => _isEnglish
      ? 'Grocery store, restaurant, transport…'
      : 'Sklep, restauracja, transport…';
  String get quickGroupExamples => _isEnglish
      ? 'Trip, party, shared shopping…'
      : 'Wyjazd, impreza, wspólne zakupy…';
  String get quickProjectExamples =>
      _isEnglish ? 'To a project' : 'Do projektu';
  String get cancelActionLabel => _isEnglish ? 'Cancel' : 'Anuluj';
  String get expenseAdded => _isEnglish ? 'Expense added.' : 'Dodano wydatek.';
  String get expenseScanFailed => _isEnglish
      ? 'Scanning failed. Please try again.'
      : 'Błąd podczas skanowania. Spróbuj ponownie.';
  String get loadingFriends =>
      _isEnglish ? 'Loading friends…' : 'Trwa ładowanie znajomych…';
  String get noFriendsYetAddInTab => _isEnglish
      ? 'You do not have any friends yet. Add them in the Friends tab.'
      : 'Nie masz jeszcze znajomych. Dodaj ich w zakładce Znajomi.';
  String get receiptReadError => _isEnglish
      ? 'Error reading receipt data.'
      : 'Błąd podczas odczytu danych z paragonu.';
  String get receiptNoItems => _isEnglish
      ? 'No items were recognized on the receipt.'
      : 'Nie rozpoznano pozycji na paragonie.';
  String get receiptScanError => _isEnglish
      ? 'Could not scan the receipt. Please try again.'
      : 'Nie udało się zskanować paragonu. Spróbuj ponownie.';
  String get receiptScanItemsFailed => _isEnglish
      ? 'Could not scan the receipt. Please try again.'
      : 'Nie udało się zskanować paragonu. Spróbuj ponownie.';
  String get formNewExpense => _isEnglish ? 'New expense' : 'Nowy wydatek';
  String get formEditExpense => _isEnglish ? 'Edit expense' : 'Edytuj wydatek';
  String get formDetailsSection => _isEnglish ? 'DETAILS' : 'SZCZEGÓŁY';
  String get formProjectSection => _isEnglish ? 'PROJECT' : 'PROJEKT';
  String get formSplitSection => _isEnglish ? 'SPLIT' : 'PODZIAŁ';
  String get noProjectExpense =>
      _isEnglish ? 'No project — personal expense' : 'Brak — wydatek osobisty';
  String get projectLabel => _isEnglish ? 'Project' : 'Projekt';
  String get personalExpenseLabel =>
      _isEnglish ? 'Personal expense' : 'Wydatek osobisty';
  String get splitWithPeople =>
      _isEnglish ? 'Split with {count} people' : 'Dzielisz z {count} {people}';
  String get addFriendsToSplit => _isEnglish
      ? 'Add friends to split costs.'
      : 'Dodaj znajomych, aby podzielić koszty.';
  String get fillFromReceipt =>
      _isEnglish ? 'Fill from receipt scan' : 'Wypełnij skanem paragonu';
  String get choosePeople => _isEnglish ? 'Choose people' : 'Wybierz osoby';
  String get selectedCountLabel =>
      _isEnglish ? '{count} selected' : '{count} zaznaczonych';
  String get clearAllItemsDialogTitle =>
      _isEnglish ? 'Delete all items?' : 'Usuń wszystkie pozycje?';
  String get deleteAllItems => _isEnglish ? 'Delete all' : 'Usuń wszystko';
  String get deselectAll => _isEnglish ? 'Deselect' : 'Odznacz';
  String get selectAll => _isEnglish ? 'Select all' : 'Zaznacz wszystkie';
  String get deleteSelected =>
      _isEnglish ? 'Delete selected' : 'Usuń zaznaczone';
  String get doneAction => _isEnglish ? 'Done' : 'Gotowe';
  String get scanReceiptButton =>
      _isEnglish ? 'Scan receipt' : 'Zeskanuj paragon';
  String get addItemButton => _isEnglish ? 'Add item' : 'Dodaj pozycję';
  String get addItemsHint => _isEnglish
      ? 'Add items manually or scan a receipt to fill them automatically.'
      : 'Dodaj pozycje ręcznie albo zeskanuj paragon, aby je wypełnić automatycznie.';
  String get untitledItem => _isEnglish ? 'Untitled' : 'Bez nazwy';
  String get formItemNameHint => _isEnglish ? 'Item name' : 'Nazwa produktu';

  // ── Ceny własne za produkt (nierówny podział jednego produktu) ─────────────
  String get itemSharesEqual =>
      _isEnglish ? 'Split equally — tap to set prices' : 'Po równo — kliknij, by ustawić ceny';
  String get itemSharesCustom =>
      _isEnglish ? 'Custom prices — tap for equal' : 'Ceny własne — kliknij, by po równo';

  /// Ostrzeżenie pod polami: sumy nie zgadzają się z ceną produktu.
  String get itemSharesMismatchHint => _isEnglish
      ? 'Shares add up to {sum}, item costs {price}'
      : 'Kwoty sumują się do {sum}, produkt kosztuje {price}';

  String get errorItemSharesMismatch => _isEnglish
      ? 'Shares for "{name}" add up to {sum} but it costs {price}.'
      : 'Kwoty za „{name}" sumują się do {sum}, a produkt kosztuje {price}.';
  String get noProjectsYet => _isEnglish
      ? 'You do not have any projects yet.'
      : 'Nie masz jeszcze projektów.';
  String get noProjectPersonal =>
      _isEnglish ? 'Personal expense' : 'Wydatek osobisty';

  // History / details / admin
  String get historyTitle =>
      _isEnglish ? 'Settlement history' : 'Historia rozliczeń';
  String get historyRetryButton =>
      _isEnglish ? 'Try again' : 'Spróbuj ponownie';
  String get historyNoItems =>
      _isEnglish ? 'No settlement history' : 'Brak historii rozliczeń';
  String get historySubtitle => _isEnglish
      ? 'Your closed settlements will appear here.'
      : 'Tu pojawią się Twoje zamknięte rozliczenia.';
  String get historyReceivedPayment =>
      _isEnglish ? 'Payment received' : 'Otrzymano wpłatę';
  String get historySentPayment =>
      _isEnglish ? 'Payment sent' : 'Wysłano wpłatę';
  String get balancePaidOut => _isEnglish
      ? 'Settled {amount} with {name}'
      : 'Rozliczono {amount} z {name}';
  String get loadingLabel => _isEnglish ? 'Loading…' : 'Ładowanie…';
  String get detailsTitle => _isEnglish ? 'Details' : 'Szczegóły';
  String get categoryLabel => _isEnglish ? 'Category' : 'Kategoria';
  String get dateLabel => _isEnglish ? 'Date' : 'Data';
  String get noteLabel => _isEnglish ? 'Note' : 'Notatka';
  String get byItemNoData => _isEnglish
      ? 'No product data for this split type.'
      : 'Brak danych o produktach dla tego podzialu.';
  String get divisionLabel => _isEnglish ? 'SPLIT: ' : 'PODZIAŁ: ';
  String get adminBroadcastTitle =>
      _isEnglish ? 'Broadcast notification' : 'Powiadomienie do wszystkich';
  String get adminBroadcastFieldTitle => _isEnglish ? 'Title' : 'Tytuł';
  String get adminBroadcastFieldBody => _isEnglish ? 'Body' : 'Treść';
  String get adminBroadcastSend =>
      _isEnglish ? 'Send to everyone' : 'Wyślij do wszystkich';
  String get adminBroadcastSending => _isEnglish ? 'Sending…' : 'Wysyłanie…';
  String get adminBroadcastMissing =>
      _isEnglish ? 'Enter a title and body' : 'Podaj tytuł i treść';
  String get adminBroadcastSent =>
      _isEnglish ? 'Notification sent' : 'Wysłano powiadomienie';
  String get adminBroadcastFailedPrefix =>
      _isEnglish ? 'Failed to send' : 'Nie udało się wysłać';
  String get noConnection => _isEnglish ? 'no connection' : 'brak połączenia';

  // Expense details
  String get expenseDetailsTitle => _isEnglish ? 'Details' : 'Szczegóły';
  String get expenseDetailsCategory => _isEnglish ? 'Category' : 'Kategoria';
  String get expenseDetailsDate => _isEnglish ? 'Date' : 'Data';
  String get expenseDetailsNote => _isEnglish ? 'Note' : 'Notatka';
  String get expenseDetailsProject => _isEnglish ? 'Project' : 'Projekt';
  String get expenseDetailsSplitLabel => _isEnglish ? 'SPLIT' : 'PODZIAŁ';
  String get expenseDetailsNoData => _isEnglish
      ? 'No product data for this split.'
      : 'Brak danych o produktach dla tego podzialu.';
  String get expenseDetailsSettled => _isEnglish ? 'Settled' : 'Rozliczone';

  // ── Rozliczanie wydatków (swipe / oznaczenia) ──────────────────────────────
  // `settleAction` ("Rozlicz") jest już zdefiniowane wyżej — używamy go tutaj.
  String get unsettleAction => _isEnglish ? 'Unsettle' : 'Cofnij';
  String get expenseSettledBadge => _isEnglish ? 'Settled' : 'Rozliczone';
  String get expenseSettleFailed => _isEnglish
      ? "Couldn't update the settlement."
      : 'Nie udało się zmienić rozliczenia.';

  /// Udział rozliczony zbiorczo — pieniądze naprawdę wpłynęły, więc nie można
  /// cofnąć pojedynczego wydatku. Trzeba cofnąć całe rozliczenie.
  String get settleLockedBySettleUp => _isEnglish
      ? 'This was settled as part of a settle-up. Undo that settlement in Balances.'
      : 'To zostało rozliczone zbiorczo. Cofnij całe rozliczenie w „Rozliczeniach”.';

  // ── Zgłoszenie zapłaty ─────────────────────────────────────────────────────
  // Uczestnik nie rozlicza już sam siebie: może jedynie ZGŁOSIĆ, że zapłacił.
  // To sugestia dla właściciela wydatku (ma sprawdzić i potwierdzić), nie fakt.
  String get declarePaidAction => _isEnglish ? 'Declare paid' : 'Zgłoś zapłatę';
  String get retractDeclareAction => _isEnglish ? 'Retract' : 'Wycofaj';

  /// Dłuższa wersja do menu kontekstowego (na swipe nie ma miejsca).
  String get retractDeclareLong => _isEnglish
      ? 'Retract payment declaration'
      : 'Wycofaj zgłoszenie zapłaty';

  /// Plakietka na własnym udziale: zgłoszono, czeka na potwierdzenie właściciela.
  String get expenseDeclaredBadge =>
      _isEnglish ? 'Payment declared' : 'Zgłoszono zapłatę';

  /// Chip na cudzym udziale widziany przez właściciela: ta osoba twierdzi,
  /// że zapłaciła.
  String get expenseDetailsDeclaresPaid =>
      _isEnglish ? 'Declares paid' : 'Zgłasza zapłatę';

  /// Chip na własnym udziale uczestnika po zgłoszeniu.
  String get expenseDetailsDeclared => _isEnglish ? 'Declared' : 'Zgłoszono';

  /// np. „2 zgłoszenia" na kafelku właściciela — ilu uczestników twierdzi,
  /// że już zapłaciło. Polskie formy: 1 zgłoszenie / 2-4 zgłoszenia /
  /// 5+ zgłoszeń (z wyjątkiem 12-14).
  String declaredCountBadge(int count) {
    if (_isEnglish) {
      return count == 1 ? '1 declared' : '$count declared';
    }
    if (count == 1) return '1 zgłoszenie';
    final lastTwo = count % 100;
    final last = count % 10;
    if (last >= 2 && last <= 4 && !(lastTwo >= 12 && lastTwo <= 14)) {
      return '$count zgłoszenia';
    }
    return '$count zgłoszeń';
  }

  /// Utworzenie nowego wydatku na wzór istniejącego (powtarzające się wydatki).
  String get repeatAction => _isEnglish ? 'Repeat' : 'Powtórz';

  String get undoSettlementAction =>
      _isEnglish ? 'Undo settlement' : 'Cofnij rozliczenie';
  String get undoSettlementTitle =>
      _isEnglish ? 'Undo this settlement?' : 'Cofnąć to rozliczenie?';
  String get undoSettlementBody => _isEnglish
      ? 'Every expense it covered goes back to unsettled, and the payment is removed from the history.'
      : 'Wszystkie objęte nim wydatki wrócą do nierozliczonych, a wpłata zniknie z historii.';
  String get undoSettlementFailed => _isEnglish
      ? "Couldn't undo the settlement."
      : 'Nie udało się cofnąć rozliczenia.';

  // ── Projekty: wydatki, podsumowanie, filtr ─────────────────────────────────
  String get projectExpensesSection => _isEnglish ? 'Expenses' : 'Wydatki';
  String get projectNoExpensesLabel => _isEnglish
      ? 'No expenses in this project yet. Add the first one.'
      : 'Brak wydatków w tym projekcie. Dodaj pierwszy.';
  String get projectTotalSpent => _isEnglish ? 'Total spent' : 'Wydano łącznie';

  /// np. „3 uczestników" — po liczbie idzie dopełniacz, więc mnoga to zawsze
  /// „uczestników"; odmienia się tylko liczba pojedyncza.
  String projectMembersCount(int count) {
    if (_isEnglish) {
      return count == 1 ? '1 member' : '$count members';
    }
    return count == 1 ? '1 uczestnik' : '$count uczestników';
  }

  /// Filtr projektu na liście wydatków.
  String get expensesAllProjects =>
      _isEnglish ? 'All projects' : 'Wszystkie projekty';
  String get expensesNoProject => _isEnglish ? 'No project' : 'Bez projektu';

  // ── Włączanie powiadomień (gdy push nie działa) ────────────────────────────
  String get notifEnableButton =>
      _isEnglish ? 'Enable notifications' : 'Włącz powiadomienia';
  String get notifDisabledHint => _isEnglish
      ? "Notifications are off — you won't hear about new expenses."
      : 'Powiadomienia są wyłączone — nie dowiesz się o nowych wydatkach.';
  String get notifEnabledOk =>
      _isEnglish ? 'Notifications enabled.' : 'Powiadomienia włączone.';
  String get notifEnableFailed => _isEnglish
      ? "Couldn't enable notifications."
      : 'Nie udało się włączyć powiadomień.';

  String get notifBlockedTitle =>
      _isEnglish ? 'Notifications are blocked' : 'Powiadomienia są zablokowane';
  String get notifBlockedBody => _isEnglish
      ? 'You blocked notifications for this site, so the app cannot ask again. '
            'Allow them in your browser: tap the padlock next to the address → '
            'Notifications → Allow, then reload.'
      : 'Powiadomienia dla tej strony zostały zablokowane, więc aplikacja nie '
            'może zapytać ponownie. Zezwól na nie w przeglądarce: kłódka obok '
            'adresu → Powiadomienia → Zezwalaj, a potem odśwież stronę.';

  /// Zgoda jest, ale przeglądarka nie rejestruje tokenu. Najczęstszy winowajca:
  /// Brave z domyślnie wyłączonym Google push messaging.
  String get notifNoPushServiceTitle => _isEnglish
      ? "Your browser isn't delivering push"
      : 'Przeglądarka nie dostarcza powiadomień';
  String get notifNoPushServiceBody => _isEnglish
      ? 'Notifications are allowed, but the browser will not register for push.\n\n'
            '• Brave: open brave://settings/privacy, turn on "Use Google services '
            'for push messaging", then RESTART the browser. Allowing the site is '
            'not enough — Brave has this off by default.\n\n'
            '• iPhone: install Settly to the Home Screen first (Share → Add to '
            'Home Screen). Safari only delivers push to an installed app.'
      : 'Zgoda jest udzielona, ale przeglądarka nie rejestruje się po '
            'powiadomienia.\n\n'
            '• Brave: wejdź w brave://settings/privacy, włącz „Use Google services '
            'for push messaging" i ZRESTARTUJ przeglądarkę. Sama zgoda dla strony '
            'nie wystarczy — Brave ma to domyślnie wyłączone.\n\n'
            '• iPhone: najpierw zainstaluj Settly na ekranie głównym (Udostępnij → '
            'Do ekranu początkowego). Safari dostarcza powiadomienia tylko do '
            'zainstalowanej aplikacji.';

  String get notifUnsupportedBody => _isEnglish
      ? 'This browser does not support push notifications.'
      : 'Ta przeglądarka nie obsługuje powiadomień push.';

  // ── Admin: ręczne wywołanie przypomnienia o rozliczeniach ──────────────────
  String get adminSettlementReminderButton => _isEnglish
      ? 'Send settle-up reminders'
      : 'Wyślij przypomnienia o rozliczeniach';
  String get adminSettlementReminderFailed => _isEnglish
      ? "Couldn't send the reminders."
      : 'Nie udało się wysłać przypomnień.';

  /// Ile osób dostało przypomnienie (0 = nikt nic nie jest winien).
  String adminSettlementReminderSent(int count) {
    if (count == 0) {
      return _isEnglish
          ? 'Nobody has anything to settle.'
          : 'Nikt nie ma nic do rozliczenia.';
    }
    if (_isEnglish) {
      return count == 1
          ? 'Reminder sent to 1 person.'
          : 'Reminders sent to $count people.';
    }
    // Po „do" idzie dopełniacz, więc liczba mnoga to zawsze „osób"
    // („do 2 osób", „do 5 osób") — odmienia się tylko liczba pojedyncza.
    return count == 1
        ? 'Wysłano przypomnienie do 1 osoby.'
        : 'Wysłano przypomnienia do $count osób.';
  }
  String get balancesAction => _isEnglish ? 'Balances' : 'Rozliczenia';

  /// np. "2/3 rozliczone" — gdy część uczestników już zapłaciła.
  String settledOfCount(int settled, int total) => _isEnglish
      ? '$settled/$total settled'
      : '$settled/$total rozliczone';
  String get expenseDetailsToPay => _isEnglish ? 'To pay' : 'Do zapłaty';
  String get expenseDeleteTitle =>
      _isEnglish ? 'Delete expense?' : 'Usunąć wydatek?';
  String get expenseDeleteBody => _isEnglish
      ? 'This permanently removes the expense and its split.'
      : 'To trwale usunie wydatek i jego podział.';
  String get expenseDeleteFailed => _isEnglish
      ? 'Could not delete the expense.'
      : 'Nie udało się usunąć wydatku.';

  // Quick scan / source picker
  String get chooseImageSourceTitle =>
      _isEnglish ? 'Choose image source' : 'Wybierz źródło zdjęcia';
  String get cameraLabel => _isEnglish ? 'Camera' : 'Aparat';
  String get cameraSubtitle =>
      _isEnglish ? 'Take a photo of the receipt' : 'Zrób zdjęcie paragonu';
  String get galleryLabel => _isEnglish ? 'Gallery' : 'Galeria';
  String get gallerySubtitle =>
      _isEnglish ? 'Choose a photo from gallery' : 'Wybierz zdjęcie z galerii';
  String get expenseScanFailedTitle => _isEnglish
      ? 'Could not scan the receipt. Please try again.'
      : 'Nie udało się zskanować paragonu. Spróbuj ponownie.';
  String get expenseScanReadError => _isEnglish
      ? 'Error reading receipt data.'
      : 'Błąd podczas odczytu danych z paragonu.';
  String get expenseScanNoItems => _isEnglish
      ? 'No items were recognized on the receipt.'
      : 'Nie rozpoznano pozycji na paragonie.';
  String get expenseScanLoadingFriends =>
      _isEnglish ? 'Loading friends…' : 'Trwa ładowanie znajomych…';
  String get expenseScanNoFriends => _isEnglish
      ? 'You do not have any friends yet. Add them in the Friends tab.'
      : 'Nie masz jeszcze znajomych. Dodaj ich w zakładce Znajomi.';
  String get expenseScanCouldNotOpenPhoto => _isEnglish
      ? 'Could not open the photo source.'
      : 'Nie udało się otworzyć źródła zdjęcia.';
  String get expenseScanNoReceipt => _isEnglish
      ? 'No receipt items found.'
      : 'Nie udało się zskanować paragonu. Spróbuj ponownie.';

  // Expenses list / filters
  String get expensesTitle => _isEnglish ? 'Expenses' : 'Wydatki';
  String get expensesLabelAll => _isEnglish ? 'All' : 'Wszystkie';
  String get expensesLabelFood => _isEnglish ? 'Food' : 'Jedzenie';
  String get expensesLabelTransport => _isEnglish ? 'Transport' : 'Transport';
  String get expensesLabelShopping => _isEnglish ? 'Shopping' : 'Zakupy';
  String get expensesLabelOther => _isEnglish ? 'Other' : 'Inne';
  String get expensesSummarySpent => _isEnglish ? 'Spent' : 'Wydano';
  String get expensesSummaryAverage =>
      _isEnglish ? 'Avg / day' : 'Średnio / dzień';
  String get expensesSearchHint =>
      _isEnglish ? 'Search expense…' : 'Szukaj wydatku…';
  String get expensesNoExpenses => _isEnglish ? 'No expenses' : 'Brak wydatków';
  String get expensesNoResults =>
      _isEnglish ? 'No results for "{query}"' : 'Brak wyników dla „{query}"';
  String get expensesNoCategory => _isEnglish
      ? 'There are no expenses in this category yet.'
      : 'W tej kategorii nie ma jeszcze wydatków.';
  // Expense form
  String get formShopLabel => _isEnglish ? 'Shop / place' : 'Sklep / miejsce';
  String get formShopHint => _isEnglish ? 'e.g. Tesco' : 'np. Biedronka';
  String get formDateLabel => _isEnglish ? 'Date' : 'Data';
  String get formCategoryLabel => _isEnglish ? 'Category' : 'Kategoria';
  String get formCategoryHint => _isEnglish ? 'Choose' : 'Wybierz';
  String get formNoteLabel => _isEnglish ? 'Note' : 'Notatka';
  String get formNoteHint => _isEnglish ? 'Optional' : 'Opcjonalnie';
  String get formAmountLocked =>
      _isEnglish ? 'AMOUNT (from items)' : 'KWOTA (z pozycji)';
  String get formAmountLabel => _isEnglish ? 'AMOUNT' : 'KWOTA';
  String get formAmountLockedHint => _isEnglish
      ? 'Total updates automatically from added items.'
      : 'Suma aktualizuje się automatycznie z dodanych pozycji.';
  String get formAmountZeroWarning => _isEnglish
      ? 'Amount must be greater than 0'
      : 'Kwota musi być większa od 0';
  String get splitModeEqual => _isEnglish ? 'Equal' : 'Równo';
  String get splitModeCustom => _isEnglish ? 'Amounts' : 'Kwoty';
  String get splitModeByItem => _isEnglish ? 'Per item' : 'Per produkt';
  String get splitEqualHint =>
      _isEnglish ? 'Enter amount above' : 'Wprowadź kwotę powyżej';
  String get splitEqualPerPerson => _isEnglish
      ? 'About {amount} {currency} per person'
      : 'Po ok. {amount} {currency} na osobę';
  String get splitCustomYouRest => _isEnglish ? 'You (rest)' : 'Ty (reszta)';
  String get splitCustomOverflow => _isEnglish
      ? 'Shares must add up to the total.'
      : 'Udziały muszą sumować się do całości.';
  String get splitCustomHint => _isEnglish
      ? 'Edit top to bottom — the rest splits equally among those below. Drag to reorder.'
      : 'Edytuj od góry — reszta dzieli się równo między osoby poniżej. Przeciągnij, aby zmienić kolejność.';
  String get splitCustomDistribute =>
      _isEnglish ? 'Distribute equally' : 'Rozdziel równo';
  String get itemsCount => _isEnglish ? '{count} {noun}' : '{count} {noun}';
  String get itemNounSingular => _isEnglish ? 'item' : 'pozycja';
  String get itemNounPlural => _isEnglish ? 'items' : 'pozycje';
  String get saveExpenseButton =>
      _isEnglish ? 'Save expense' : 'Zapisz wydatek';

  // Validation / snack errors
  String get errorNoAccount => _isEnglish
      ? 'Could not load your account. Please sign in again.'
      : 'Nie można pobrać Twojego konta. Zaloguj się ponownie.';
  String get errorAmountZero => _isEnglish
      ? 'Enter an amount greater than 0.'
      : 'Wprowadź kwotę większą niż 0.';
  String get errorNoCategory =>
      _isEnglish ? 'Choose an expense category.' : 'Wybierz kategorię wydatku.';
  String get errorFriendsExceedTotal => _isEnglish
      ? 'Shares must add up to the total.'
      : 'Udziały muszą sumować się do całości.';
  String get errorNegativeAmounts =>
      _isEnglish ? 'Amounts cannot be negative.' : 'Kwoty nie mogą być ujemne.';
  String get errorNoItems => _isEnglish
      ? 'Add at least one item.'
      : 'Dodaj przynajmniej jedną pozycję.';
  String get errorItemNoName => _isEnglish
      ? 'Every item must have a name.'
      : 'Każda pozycja musi mieć nazwę.';
  String get errorItemNoPrice => _isEnglish
      ? 'Every item must have a price greater than 0.'
      : 'Każda pozycja musi mieć cenę większą niż 0.';
  String get errorItemNoAssignee => _isEnglish
      ? 'Item "{name}" must have at least one person assigned.'
      : 'Pozycja "{name}" musi mieć przynajmniej jedną osobę.';
  String get errorFriendNotAssigned => _isEnglish
      ? 'Assign items to: {name} (or remove them from the split).'
      : 'Przypisz pozycje dla: {name} (lub usuń osobę z podziału).';
  String get errorNoConnection => _isEnglish
      ? 'No connection. Please try again.'
      : 'Brak połączenia. Spróbuj ponownie.';
  String get errorCreateExpense => _isEnglish
      ? 'Could not create expense'
      : 'Nie udało się utworzyć wydatku';
  String get errorSaveItem => _isEnglish
      ? 'Could not save item "{name}"'
      : 'Nie udało się zapisać pozycji "{name}"';
  String get errorSaveSplit =>
      _isEnglish ? 'Could not save split' : 'Nie udało się zapisać podziału';
  String get snackReceiptItems => _isEnglish
      ? 'Added {count} items from receipt.'
      : 'Dodano {count} pozycji z paragonu.';
  String get snackReceiptNoItems => _isEnglish
      ? 'No items recognised on the receipt.'
      : 'Nie rozpoznano pozycji na paragonie.';
  String get snackReceiptError => _isEnglish
      ? 'An error occurred while analysing the receipt.'
      : 'Wystąpił błąd podczas analizy paragonu.';
  String get snackReceiptScanFailed => _isEnglish
      ? 'Could not scan the receipt.'
      : 'Nie udało się zeskanować paragonu.';
  String get snackSingleExpenseFilled => _isEnglish
      ? 'Filled from receipt scan.'
      : 'Uzupełniono wydatkiem ze skanu paragonu.';
  String get snackProcessingError => _isEnglish
      ? 'An error occurred while processing the items.'
      : 'Wystąpił błąd podczas przetwarzania pozycji.';
  String get snackPhotoSourceError => _isEnglish
      ? 'Could not open the photo source.'
      : 'Nie udało się otworzyć źródła zdjęcia.';
  String get clearAllItemsDialogContent => _isEnglish
      ? 'This will remove all products from the list. You cannot undo this action.'
      : 'Ta akcja usunie wszystkie produkty z listy. Nie da się jej cofnąć.';
  String get categoryEntertainmentLabel =>
      _isEnglish ? 'Entertainment' : 'Rozrywka';
  String get categoryHealthLabel => _isEnglish ? 'Health' : 'Zdrowie';
  String get categorySubscriptionsLabel =>
      _isEnglish ? 'Subscriptions' : 'Subskrypcje';
  String get friendsSentRequest =>
      _isEnglish ? 'Friend request sent.' : 'Wysłano zaproszenie.';
  String get friendsReceivedPrefix => _isEnglish ? 'Received' : 'Otrzymano';
  String get friendsSentPrefix => _isEnglish ? 'Sent' : 'Wysłano';
  String get friendsSendRequestButton =>
      _isEnglish ? 'Send request' : 'Wyślij zaproszenie';
  String get friendsSearchNotFound => _isEnglish
      ? 'No user found with this email.'
      : 'Nie znaleziono użytkownika z tym adresem email.';
  String friendsSearchError(int code) =>
      _isEnglish ? 'Search error ($code).' : 'Błąd wyszukiwania ($code).';
  String friendsSendRequestFailed(int code) => _isEnglish
      ? 'Failed to send request ($code).'
      : 'Nie udało się wysłać zaproszenia ($code).';
  String get relativeTimeJustNow => _isEnglish ? 'just now' : 'przed chwilą';
  String get relativeTimeMinutes => _isEnglish ? 'min ago' : 'min temu';
  String get relativeTimeHours => _isEnglish ? 'h ago' : 'godz. temu';
  String get relativeTimeYesterday => _isEnglish ? 'yesterday' : 'wczoraj';
  String get relativeTimeDays => _isEnglish ? 'days ago' : 'dni temu';
  String get pinPickerTitle =>
      _isEnglish ? 'What do you want to pin?' : 'Co chcesz przypiąć?';
  String get pinPickerSubtitle => _isEnglish
      ? 'Choose an expense or project for the Pinned section.'
      : 'Wybierz wydatek lub projekt do sekcji Przypiętych';
  String get pinnedPrefix => _isEnglish ? 'Pinned' : 'Przypięto';
  String pinnedLimitReached(int max) => _isEnglish
      ? 'Pinned items limit reached (max. $max)'
      : 'Osiągnięto limit przypiętych elementów (maks. $max)';
  String get pinTileAction => _isEnglish ? 'Pin' : 'Przypnij';
  String get pinTileSubtitle =>
      _isEnglish ? 'expense / project' : 'wydatek / projekt';
  String get pinTypeProjLabel => _isEnglish ? 'Proj.' : 'Proj.';
  String get pinTypeExpLabel => _isEnglish ? 'Exp.' : 'Wyd.';
  String get quickScanLabel => _isEnglish ? 'Scan' : 'Skanuj';
  String get recentExpensesEmptySubtitle => _isEnglish
      ? 'Your recent transactions will appear here.'
      : 'Twoje ostatnie transakcje pojawią się tutaj.';
  String get summaryCardTitle => _isEnglish ? 'Summary' : 'Podsumowanie';

  // PWA install
  String get pwaInstallBanner => _isEnglish
      ? 'Install Settly on your device for quick access.'
      : 'Zainstaluj Settly na urządzeniu, aby mieć szybki dostęp.';
  String get pwaInstallAction => _isEnglish ? 'Install' : 'Zainstaluj';
  String get pwaInstallNotNow => _isEnglish ? 'Not now' : 'Nie teraz';
  String get pwaInstallProfileOption =>
      _isEnglish ? 'Install app' : 'Zainstaluj aplikację';
  String get pwaInstallIosHint => _isEnglish
      ? 'In your browser, use the share menu → “Add to Home Screen”.'
      : 'W przeglądarce użyj menu udostępniania → „Do ekranu głównego”.';
  String get pwaInstalledAlready =>
      _isEnglish ? 'App is already installed.' : 'Aplikacja jest już zainstalowana.';
}
