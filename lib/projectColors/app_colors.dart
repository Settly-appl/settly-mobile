import 'package:flutter/material.dart';

class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // SCAFFOLD
  // ═══════════════════════════════════════════════════════════════════════════

  static const _scaffoldLight = Color(0xFFF5F7FA);
  static const _scaffoldDark = Color(0xFF0D1B2A);

  static Color scaffold(bool isDark) => isDark ? _scaffoldDark : _scaffoldLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOPBAR
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Avatar ─────────────────────────────────────────────────────────────────
  static const _avatarBgLight = Color(0xFFE8F1FC); // tło kółka z inicjałami
  static const _avatarBgDark = Color(0xFF1A2D45);
  static const _avatarFgLight = Color(0xFF1E6FD9); // litery "MD"
  static const _avatarFgDark = Color(0xFF60B8F5);

  static Color avatarBg(bool isDark) => isDark ? _avatarBgDark : _avatarBgLight;
  static Color avatarFg(bool isDark) => isDark ? _avatarFgDark : _avatarFgLight;

  // ── Tekst powitania ────────────────────────────────────────────────────────
  static const _greetingLight = Color(0xFF6B7A8D); // "Dzień dobry,"
  static const _greetingDark = Color(0xFF7A9AB5);
  static const _usernameLight = Color(0xFF0D1B2A); // "Mateusz"
  static const _usernameDark = Color(0xFFF0F4F8);

  static Color greeting(bool isDark) => isDark ? _greetingDark : _greetingLight;
  static Color username(bool isDark) => isDark ? _usernameDark : _usernameLight;

  // ── Dzwonek ────────────────────────────────────────────────────────────────
  static const _bellBgLight = Color(0x124A5568); // tło kółka dzwonka
  static const _bellBgDark = Color(0xFF1A2D45);
  static const _bellIconLight = Color(0xFF4A5568); // ikona dzwonka
  static const _bellIconDark = Color(0xFF7A9AB5);

  static Color bellBg(bool isDark) => isDark ? _bellBgDark : _bellBgLight;
  static Color bellIcon(bool isDark) => isDark ? _bellIconDark : _bellIconLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // KARTA PODSUMOWANIA
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Gradient (identyczny light/dark) ───────────────────────────────────────
  static const summaryGradientLeft = Color(0xFF1569CC); // lewa strona gradientu
  static const summaryGradientRight = Color(
    0xFF00B386,
  ); // prawa strona gradientu

  // ── Teksty i kafelki (identyczne light/dark — gradient w tle) ──────────────
  static const summaryTitle = Color(
    0xBFFFFFFF,
  ); // "Podsumowanie — marzec 2026" (75% white)
  static const summaryTileBg = Color(0x2DFFFFFF); // tło kafelka (18% white)
  static const summaryTileLabel = Color(
    0xB3FFFFFF,
  ); // "Należności" / "Zobowiązania" (70% white)
  static const summaryTileValue = Color(0xFFFFFFFF); // "210 zł" / "85 zł"
  static const summaryTileSub = Color(
    0x99FFFFFF,
  ); // "inni Tobie" / "Ty innym" (60% white)

  // ═══════════════════════════════════════════════════════════════════════════
  // NAGŁÓWKI SEKCJI
  // ═══════════════════════════════════════════════════════════════════════════

  static const _sectionTitleLight = Color(
    0xFF4A5568,
  ); // "Szybkie akcje" / "Przypięte" / "Ostatnie"
  static const _sectionTitleDark = Color(0xFF7A9AB5);
  static const _sectionActionLight = Color(
    0xFF1E6FD9,
  ); // "Edytuj" / "Zobacz wszystkie"
  static const _sectionActionDark = Color(0xFF60B8F5);

  static Color sectionTitle(bool isDark) =>
      isDark ? _sectionTitleDark : _sectionTitleLight;
  static Color sectionAction(bool isDark) =>
      isDark ? _sectionActionDark : _sectionActionLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRZYCISKI SZYBKICH AKCJI
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Wspólne tło i obramowanie ──────────────────────────────────────────────
  static const _actionBtnBgLight = Color(0xFFFFFFFF); // tło przycisku
  static const _actionBtnBgDark = Color(0xFF1A2D45);
  static const _actionBtnBorderLight = Color(
    0xFFE8EDF3,
  ); // obramowanie przycisku
  static const _actionBtnBorderDark = Color(0xFF243D5A);
  static const _actionBtnLabelLight = Color(
    0xFF0D1B2A,
  ); // tekst etykiety pod ikoną
  static const _actionBtnLabelDark = Color(0xFFF0F4F8);

  static Color actionBtnBg(bool isDark) =>
      isDark ? _actionBtnBgDark : _actionBtnBgLight;
  static Color actionBtnBorder(bool isDark) =>
      isDark ? _actionBtnBorderDark : _actionBtnBorderLight;
  static Color actionBtnLabel(bool isDark) =>
      isDark ? _actionBtnLabelDark : _actionBtnLabelLight;

  // ── Dodaj ──────────────────────────────────────────────────────────────────
  static const _actionAddIconBgLight = Color(0xFFE8F1FC); // tło ikony "+"
  static const _actionAddIconBgDark = Color(0xFF1A3A5C);
  static const _actionAddIconLight = Color(0xFF1E6FD9); // ikona "+"
  static const _actionAddIconDark = Color(0xFF60B8F5);

  static Color actionAddIconBg(bool isDark) =>
      isDark ? _actionAddIconBgDark : _actionAddIconBgLight;
  static Color actionAddIcon(bool isDark) =>
      isDark ? _actionAddIconDark : _actionAddIconLight;

  // ── Skanuj ─────────────────────────────────────────────────────────────────
  static const _actionScanIconBgLight = Color(0xFFE0FAF4); // tło ikony aparatu
  static const _actionScanIconBgDark = Color(0xFF0D3028);
  static const _actionScanIconLight = Color(0xFF00B386); // ikona aparatu
  static const _actionScanIconDark = Color(0xFF00C896);

  static Color actionScanIconBg(bool isDark) =>
      isDark ? _actionScanIconBgDark : _actionScanIconBgLight;
  static Color actionScanIcon(bool isDark) =>
      isDark ? _actionScanIconDark : _actionScanIconLight;

  // ── Projekt ────────────────────────────────────────────────────────────────
  static const _actionProjectIconBgLight = Color(0xFFEEF2FF); // tło ikony grupy
  static const _actionProjectIconBgDark = Color(0xFF1E1A3A);
  static const _actionProjectIconLight = Color(0xFF6366F1); // ikona grupy ludzi
  static const _actionProjectIconDark = Color(0xFF818CF8);

  static Color actionProjectIconBg(bool isDark) =>
      isDark ? _actionProjectIconBgDark : _actionProjectIconBgLight;
  static Color actionProjectIcon(bool isDark) =>
      isDark ? _actionProjectIconDark : _actionProjectIconLight;

  // ── Rozlicz ────────────────────────────────────────────────────────────────
  static const _actionSettleIconBgLight = Color(
    0xFFFEF3E2,
  ); // tło ikony checkboxa
  static const _actionSettleIconBgDark = Color(0xFF2D2010);
  static const _actionSettleIcon = Color(
    0xFFF59E0B,
  ); // ikona checkboxa (taki sam light/dark)

  static Color actionSettleIconBg(bool isDark) =>
      isDark ? _actionSettleIconBgDark : _actionSettleIconBgLight;
  static Color actionSettleIcon(bool isDark) =>
      _actionSettleIcon; // zawsze taki sam

  // ═══════════════════════════════════════════════════════════════════════════
  // KARTY — wspólne (karty przypięte + lista ostatnich)
  // ═══════════════════════════════════════════════════════════════════════════

  static const _cardBgLight = Color(0xFFFFFFFF); // tło karty
  static const _cardBgDark = Color(0xFF1A2D45);
  static const _cardBorderLight = Color(0xFFE8EDF3); // obramowanie karty
  static const _cardBorderDark = Color(0xFF243D5A);
  static const _cardTitleLight = Color(0xFF0D1B2A); // nazwa główna na karcie
  static const _cardTitleDark = Color(0xFFF0F4F8);
  static const _cardSubtitleLight = Color(0xFF6B7A8D); // podpis / data / osoby
  static const _cardSubtitleDark = Color(0xFF7A9AB5);
  static const _cardAmountLight = Color(0xFF0D1B2A); // kwota neutralna
  static const _cardAmountDark = Color(0xFFF0F4F8);

  static Color cardBg(bool isDark) => isDark ? _cardBgDark : _cardBgLight;
  static Color cardBorder(bool isDark) =>
      isDark ? _cardBorderDark : _cardBorderLight;
  static Color cardTitle(bool isDark) =>
      isDark ? _cardTitleDark : _cardTitleLight;
  static Color cardSubtitle(bool isDark) =>
      isDark ? _cardSubtitleDark : _cardSubtitleLight;
  static Color cardAmount(bool isDark) =>
      isDark ? _cardAmountDark : _cardAmountLight;

  // ── Kwoty semantyczne (identyczne light/dark) ──────────────────────────────
  static const amountPositive = Color(0xFF00C896); // "+85 zł" należność
  static const amountNegative = Color(0xFFE05252); // "-34 zł" zobowiązanie

  // ═══════════════════════════════════════════════════════════════════════════
  // BADGE — typ "Projekt"
  // ═══════════════════════════════════════════════════════════════════════════

  static const _badgeProjectBgLight = Color(0xFFE8F1FC); // tło badge "Projekt"
  static const _badgeProjectBgDark = Color(0xFF1A3A5C);
  static const _badgeProjectFgLight = Color(
    0xFF1E6FD9,
  ); // tekst badge "Projekt"
  static const _badgeProjectFgDark = Color(0xFF60B8F5);

  static Color badgeProjectBg(bool isDark) =>
      isDark ? _badgeProjectBgDark : _badgeProjectBgLight;
  static Color badgeProjectFg(bool isDark) =>
      isDark ? _badgeProjectFgDark : _badgeProjectFgLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // BADGE — typ "Wydatek"
  // ═══════════════════════════════════════════════════════════════════════════

  static const _badgeExpenseBgLight = Color(0xFFE0FAF4); // tło badge "Wydatek"
  static const _badgeExpenseBgDark = Color(0xFF0D3028);
  static const _badgeExpenseFgLight = Color(
    0xFF00A87A,
  ); // tekst badge "Wydatek"
  static const _badgeExpenseFgDark = Color(0xFF00C896);

  static Color badgeExpenseBg(bool isDark) =>
      isDark ? _badgeExpenseBgDark : _badgeExpenseBgLight;
  static Color badgeExpenseFg(bool isDark) =>
      isDark ? _badgeExpenseFgDark : _badgeExpenseFgLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // IKONA — typ "Projekt" (fioletowa)
  // ═══════════════════════════════════════════════════════════════════════════

  static const _iconProjectBgLight = Color(0xFFEEF2FF); // tło ikony grupy ludzi
  static const _iconProjectBgDark = Color(0xFF1E1A3A);
  static const _iconProjectLight = Color(0xFF6366F1); // ikona grupy ludzi
  static const _iconProjectDark = Color(0xFF818CF8);

  static Color iconProjectBg(bool isDark) =>
      isDark ? _iconProjectBgDark : _iconProjectBgLight;
  static Color iconProject(bool isDark) =>
      isDark ? _iconProjectDark : _iconProjectLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // IKONA — typ "Wydatek" niebieski (np. Biedronka)
  // ═══════════════════════════════════════════════════════════════════════════

  static const _iconExpenseBlueBgLight = Color(0xFFE8F1FC); // tło ikony torby
  static const _iconExpenseBlueBgDark = Color(0xFF1A3A5C);
  static const _iconExpenseBlueLight = Color(
    0xFF1E6FD9,
  ); // ikona torby / zakupów
  static const _iconExpenseBlueDark = Color(0xFF60B8F5);

  static Color iconExpenseBlueBg(bool isDark) =>
      isDark ? _iconExpenseBlueBgDark : _iconExpenseBlueBgLight;
  static Color iconExpenseBlue(bool isDark) =>
      isDark ? _iconExpenseBlueDark : _iconExpenseBlueLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // IKONA — typ "Wydatek" zielony (np. Pizza Roma)
  // ═══════════════════════════════════════════════════════════════════════════

  static const _iconExpenseGreenBgLight = Color(
    0xFFE0FAF4,
  ); // tło ikony strzałki
  static const _iconExpenseGreenBgDark = Color(0xFF0D3028);
  static const _iconExpenseGreenLight = Color(
    0xFF00B386,
  ); // ikona strzałki / send
  static const _iconExpenseGreenDark = Color(0xFF00C896);

  static Color iconExpenseGreenBg(bool isDark) =>
      isDark ? _iconExpenseGreenBgDark : _iconExpenseGreenBgLight;
  static Color iconExpenseGreen(bool isDark) =>
      isDark ? _iconExpenseGreenDark : _iconExpenseGreenLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // KARTA PUSTA "Przypnij" (przerywane obramowanie)
  // ═══════════════════════════════════════════════════════════════════════════

  static const _pinnedEmptyBgLight = Color(0xFFF8FAFC); // tło karty
  static const _pinnedEmptyBgDark = Color(0xFF132233);
  static const _pinnedEmptyBorderLight = Color(
    0xFFC8D5E8,
  ); // przerywane obramowanie
  static const _pinnedEmptyBorderDark = Color(0xFF243D5A);
  static const _pinnedEmptyCircleBgLight = Color(0xFFE8EDF3); // tło kółka z "+"
  static const _pinnedEmptyCircleBgDark = Color(0xFF1A2D45);
  static const _pinnedEmptyIconLight = Color(0xFF9BA8B7); // ikona "+"
  static const _pinnedEmptyIconDark = Color(0xFF4A6A85);
  static const _pinnedEmptyTextLight = Color(
    0xFF9BA8B7,
  ); // "Przypnij projekt lub wydatek"
  static const _pinnedEmptyTextDark = Color(0xFF4A6A85);

  static Color pinnedEmptyBg(bool isDark) =>
      isDark ? _pinnedEmptyBgDark : _pinnedEmptyBgLight;
  static Color pinnedEmptyBorder(bool isDark) =>
      isDark ? _pinnedEmptyBorderDark : _pinnedEmptyBorderLight;
  static Color pinnedEmptyCircleBg(bool isDark) =>
      isDark ? _pinnedEmptyCircleBgDark : _pinnedEmptyCircleBgLight;
  static Color pinnedEmptyIcon(bool isDark) =>
      isDark ? _pinnedEmptyIconDark : _pinnedEmptyIconLight;
  static Color pinnedEmptyText(bool isDark) =>
      isDark ? _pinnedEmptyTextDark : _pinnedEmptyTextLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ═══════════════════════════════════════════════════════════════════════════

  static const _navBgLight = Color(0xFFF5F7FA); // tło paska nawigacji
  static const _navBgDark = Color(0xFF0D1B2A);
  static const _navBorderLight = Color(0xFFE8EDF3); // linia górna paska
  static const _navBorderDark = Color(0xFF1A2D45);
  static const _navActiveLight = Color(
    0xFF1E6FD9,
  ); // aktywna ikona + tekst + kropka
  static const _navActiveDark = Color(0xFF60B8F5);
  static const _navInactiveLight = Color(
    0xFF9BA8B7,
  ); // nieaktywne ikony + tekst
  static const _navInactiveDark = Color(0xFF4A6A85);

  static Color navBg(bool isDark) => isDark ? _navBgDark : _navBgLight;
  static Color navBorder(bool isDark) =>
      isDark ? _navBorderDark : _navBorderLight;
  static Color navActive(bool isDark) =>
      isDark ? _navActiveDark : _navActiveLight;
  static Color navInactive(bool isDark) =>
      isDark ? _navInactiveDark : _navInactiveLight;
}
