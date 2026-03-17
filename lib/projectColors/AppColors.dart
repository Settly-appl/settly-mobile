import 'package:flutter/animation.dart';

class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // SCAFFOLD
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const scaffoldLight = Color(0xFFF5F7FA);
  // Dark
  static const scaffoldDark = Color(0xFF0D1B2A);

  // ═══════════════════════════════════════════════════════════════════════════
  // TOPBAR
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Avatar ─────────────────────────────────────────────────────────────────
  // Light
  static const avatarBgLight = Color(0xFFE8F1FC); // tło kółka z inicjałami
  static const avatarFgLight = Color(0xFF1E6FD9); // litery "MD"
  // Dark
  static const avatarBgDark = Color(0xFF1A2D45); // tło kółka z inicjałami
  static const avatarFgDark = Color(0xFF60B8F5); // litery "MD"

  // ── Tekst powitania ────────────────────────────────────────────────────────
  // Light
  static const greetingLight = Color(0xFF6B7A8D); // "Dzień dobry,"
  static const usernameLight = Color(0xFF0D1B2A); // "Mateusz"
  // Dark
  static const greetingDark = Color(0xFF7A9AB5); // "Dzień dobry,"
  static const usernameDark = Color(0xFFF0F4F8); // "Mateusz"

  // ── Dzwonek ────────────────────────────────────────────────────────────────
  // Light
  static const bellBgLight = Color(0x124a5568); // tło kółka dzwonka
  static const bellIconLight = Color(0xFF4A5568); // ikona dzwonka
  // Dark
  static const bellBgDark = Color(0xFF1A2D45); // tło kółka dzwonka
  static const bellIconDark = Color(0xFF7A9AB5); // ikona dzwonka

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
  static const summaryTileBg = Color(
    0x2DFFFFFF,
  ); // tło kafelka Należności / Zobowiązania (18% white)
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

  // Light
  static const sectionTitleLight = Color(
    0xFF4A5568,
  ); // "Szybkie akcje" / "Przypięte" / "Ostatnie"
  static const sectionActionLight = Color(
    0xFF1E6FD9,
  ); // "Edytuj" / "Zobacz wszystkie"
  // Dark
  static const sectionTitleDark = Color(
    0xFF7A9AB5,
  ); // "Szybkie akcje" / "Przypięte" / "Ostatnie"
  static const sectionActionDark = Color(
    0xFF60B8F5,
  ); // "Edytuj" / "Zobacz wszystkie"

  // ═══════════════════════════════════════════════════════════════════════════
  // PRZYCISKI SZYBKICH AKCJI
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Wspólne tło i obramowanie ──────────────────────────────────────────────
  // Light
  static const actionBtnBgLight = Color(0xFFFFFFFF); // tło przycisku
  static const actionBtnBorderLight = Color(
    0xFFE8EDF3,
  ); // obramowanie przycisku
  static const actionBtnLabelLight = Color(
    0xFF0D1B2A,
  ); // tekst etykiety pod ikoną
  // Dark
  static const actionBtnBgDark = Color(0xFF1A2D45); // tło przycisku
  static const actionBtnBorderDark = Color(0xFF243D5A); // obramowanie przycisku
  static const actionBtnLabelDark = Color(
    0xFFF0F4F8,
  ); // tekst etykiety pod ikoną

  // ── Dodaj ──────────────────────────────────────────────────────────────────
  // Light
  static const actionAddIconBgLight = Color(0xFFE8F1FC); // tło ikony "+"
  static const actionAddIconLight = Color(0xFF1E6FD9); // ikona "+"
  // Dark
  static const actionAddIconBgDark = Color(0xFF1A3A5C); // tło ikony "+"
  static const actionAddIconDark = Color(0xFF60B8F5); // ikona "+"

  // ── Skanuj ─────────────────────────────────────────────────────────────────
  // Light
  static const actionScanIconBgLight = Color(0xFFE0FAF4); // tło ikony aparatu
  static const actionScanIconLight = Color(0xFF00B386); // ikona aparatu
  // Dark
  static const actionScanIconBgDark = Color(0xFF0D3028); // tło ikony aparatu
  static const actionScanIconDark = Color(0xFF00C896); // ikona aparatu

  // ── Projekt ────────────────────────────────────────────────────────────────
  // Light
  static const actionProjectIconBgLight = Color(0xFFEEF2FF); // tło ikony grupy
  static const actionProjectIconLight = Color(0xFF6366F1); // ikona grupy ludzi
  // Dark
  static const actionProjectIconBgDark = Color(0xFF1E1A3A); // tło ikony grupy
  static const actionProjectIconDark = Color(0xFF818CF8); // ikona grupy ludzi

  // ── Rozlicz ────────────────────────────────────────────────────────────────
  // Light
  static const actionSettleIconBgLight = Color(
    0xFFFEF3E2,
  ); // tło ikony checkboxa
  static const actionSettleIconLight = Color(0xFFF59E0B); // ikona checkboxa
  // Dark
  static const actionSettleIconBgDark = Color(
    0xFF2D2010,
  ); // tło ikony checkboxa
  static const actionSettleIconDark = Color(
    0xFFF59E0B,
  ); // ikona checkboxa (taki sam jak light)

  // ═══════════════════════════════════════════════════════════════════════════
  // KARTY — wspólne (karty przypięte + lista ostatnich)
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const cardBgLight = Color(0xFFFFFFFF); // tło karty
  static const cardBorderLight = Color(0xFFE8EDF3); // obramowanie karty
  static const cardTitleLight = Color(0xFF0D1B2A); // nazwa główna na karcie
  static const cardSubtitleLight = Color(0xFF6B7A8D); // podpis / data / osoby
  static const cardAmountLight = Color(0xFF0D1B2A); // kwota neutralna
  // Dark
  static const cardBgDark = Color(0xFF1A2D45); // tło karty
  static const cardBorderDark = Color(0xFF243D5A); // obramowanie karty
  static const cardTitleDark = Color(0xFFF0F4F8); // nazwa główna na karcie
  static const cardSubtitleDark = Color(0xFF7A9AB5); // podpis / data / osoby
  static const cardAmountDark = Color(0xFFF0F4F8); // kwota neutralna

  // ── Kwoty semantyczne (identyczne light/dark) ──────────────────────────────
  static const amountPositive = Color(0xFF00C896); // "+85 zł" należność
  static const amountNegative = Color(0xFFE05252); // "-34 zł" zobowiązanie

  // ═══════════════════════════════════════════════════════════════════════════
  // BADGE — typ "Projekt"
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const badgeProjectBgLight = Color(0xFFE8F1FC); // tło badge "Projekt"
  static const badgeProjectFgLight = Color(0xFF1E6FD9); // tekst badge "Projekt"
  // Dark
  static const badgeProjectBgDark = Color(0xFF1A3A5C); // tło badge "Projekt"
  static const badgeProjectFgDark = Color(0xFF60B8F5); // tekst badge "Projekt"

  // ═══════════════════════════════════════════════════════════════════════════
  // BADGE — typ "Wydatek"
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const badgeExpenseBgLight = Color(0xFFE0FAF4); // tło badge "Wydatek"
  static const badgeExpenseFgLight = Color(0xFF00A87A); // tekst badge "Wydatek"
  // Dark
  static const badgeExpenseBgDark = Color(0xFF0D3028); // tło badge "Wydatek"
  static const badgeExpenseFgDark = Color(0xFF00C896); // tekst badge "Wydatek"

  // ═══════════════════════════════════════════════════════════════════════════
  // IKONA — typ "Projekt" (fioletowa)
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const iconProjectBgLight = Color(0xFFEEF2FF); // tło ikony grupy ludzi
  static const iconProjectLight = Color(0xFF6366F1); // ikona grupy ludzi
  // Dark
  static const iconProjectBgDark = Color(0xFF1E1A3A); // tło ikony grupy ludzi
  static const iconProjectDark = Color(0xFF818CF8); // ikona grupy ludzi

  // ═══════════════════════════════════════════════════════════════════════════
  // IKONA — typ "Wydatek" niebieski (np. Biedronka)
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const iconExpenseBlueBgLight = Color(0xFFE8F1FC); // tło ikony torby
  static const iconExpenseBlueLight = Color(
    0xFF1E6FD9,
  ); // ikona torby / zakupów
  // Dark
  static const iconExpenseBlueBgDark = Color(0xFF1A3A5C); // tło ikony torby
  static const iconExpenseBlueDark = Color(0xFF60B8F5); // ikona torby / zakupów

  // ═══════════════════════════════════════════════════════════════════════════
  // IKONA — typ "Wydatek" zielony (np. Pizza Roma)
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const iconExpenseGreenBgLight = Color(
    0xFFE0FAF4,
  ); // tło ikony strzałki
  static const iconExpenseGreenLight = Color(
    0xFF00B386,
  ); // ikona strzałki / send
  // Dark
  static const iconExpenseGreenBgDark = Color(0xFF0D3028); // tło ikony strzałki
  static const iconExpenseGreenDark = Color(
    0xFF00C896,
  ); // ikona strzałki / send

  // ═══════════════════════════════════════════════════════════════════════════
  // KARTA PUSTA "Przypnij" (przerywane obramowanie)
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const pinnedEmptyBgLight = Color(0xFFF8FAFC); // tło karty
  static const pinnedEmptyBorderLight = Color(
    0xFFC8D5E8,
  ); // przerywane obramowanie
  static const pinnedEmptyCircleBgLight = Color(0xFFE8EDF3); // tło kółka z "+"
  static const pinnedEmptyIconLight = Color(0xFF9BA8B7); // ikona "+"
  static const pinnedEmptyTextLight = Color(
    0xFF9BA8B7,
  ); // "Przypnij projekt lub wydatek"
  // Dark
  static const pinnedEmptyBgDark = Color(0xFF132233); // tło karty
  static const pinnedEmptyBorderDark = Color(
    0xFF243D5A,
  ); // przerywane obramowanie
  static const pinnedEmptyCircleBgDark = Color(0xFF1A2D45); // tło kółka z "+"
  static const pinnedEmptyIconDark = Color(0xFF4A6A85); // ikona "+"
  static const pinnedEmptyTextDark = Color(
    0xFF4A6A85,
  ); // "Przypnij projekt lub wydatek"

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ═══════════════════════════════════════════════════════════════════════════

  // Light
  static const navBgLight = Color(0xFFF5F7FA); // tło paska nawigacji
  static const navBorderLight = Color(0xFFE8EDF3); // linia górna paska
  static const navActiveLight = Color(
    0xFF1E6FD9,
  ); // aktywna ikona + tekst + kropka
  static const navInactiveLight = Color(0xFF9BA8B7); // nieaktywne ikony + tekst
  // Dark
  static const navBgDark = Color(0xFF0D1B2A); // tło paska nawigacji
  static const navBorderDark = Color(0xFF1A2D45); // linia górna paska
  static const navActiveDark = Color(
    0xFF60B8F5,
  ); // aktywna ikona + tekst + kropka
  static const navInactiveDark = Color(0xFF4A6A85); // nieaktywne ikony + tekst
}
