// ==============================================================================
// UniCheck - Timetable Date & Week Navigation Utilities (TASK-02D)
// Compliant with Asia/Ho_Chi_Minh Timezone & Academic Week Standards
// Pure Local Calendar Math: Strictly Zero UTC Off-By-One Errors
// ==============================================================================

export interface DayOfWeekMeta {
  dayIndex: number; // 1 to 7 (1 = Thứ Hai, ..., 7 = Chủ Nhật)
  label: string; // 'Thứ Hai', ..., 'Chủ Nhật'
  shortLabel: string; // 'T2', ..., 'CN'
  date: Date;
  isoDate: string; // 'YYYY-MM-DD'
  formatted: string; // 'DD/MM'
  fullFormatted: string; // 'DD/MM/YYYY'
}

export const DAYS_OF_WEEK_NAMES = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

export const DAYS_OF_WEEK_SHORT = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/**
 * Formats a Date to 'YYYY-MM-DD' using local calendar parts.
 * Prevents UTC off-by-one errors (where toISOString shifts by -1 day in UTC+7).
 */
export function formatLocalDateToYMD(d: Date): string {
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Formats a Date to 'DD/MM/YYYY' using local calendar parts.
 */
export function formatLocalDateToDMY(d: Date): string {
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
}

/**
 * Parses 'YYYY-MM-DD' string into a local Date set to 12:00:00 (noon).
 * Setting time to noon protects against any daylight or timezone shift bugs.
 */
export function parseYMDToLocalDate(ymd: string): Date {
  const parts = ymd.split('-');
  if (parts.length !== 3) {
    return new Date();
  }
  const year = parseInt(parts[0], 10);
  const month = parseInt(parts[1], 10) - 1;
  const day = parseInt(parts[2], 10);
  return new Date(year, month, day, 12, 0, 0);
}

/**
 * Returns the Monday (start of week) for any given Date at 12:00:00.
 * Follows the ISO / Vietnamese standard where the week starts on Monday (Thứ Hai)
 * and ends on Sunday (Chủ Nhật).
 */
export function getMondayOfWeek(d: Date): Date {
  const date = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 12, 0, 0);
  const day = date.getDay(); // 0 is Sunday, 1 is Monday, ..., 6 is Saturday
  const diff = day === 0 ? -6 : 1 - day;
  date.setDate(date.getDate() + diff);
  return date;
}

/**
 * Returns the Sunday (end of week) for a given Monday date (Monday + 6 days).
 */
export function getSundayOfWeek(monday: Date): Date {
  const date = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate(), 12, 0, 0);
  date.setDate(date.getDate() + 6);
  return date;
}

/**
 * Advances the date by 7 days (next week Monday).
 */
export function getNextWeekMonday(currentMonday: Date): Date {
  const next = new Date(currentMonday.getFullYear(), currentMonday.getMonth(), currentMonday.getDate(), 12, 0, 0);
  next.setDate(next.getDate() + 7);
  return next;
}

/**
 * Decreases the date by 7 days (previous week Monday).
 */
export function getPrevWeekMonday(currentMonday: Date): Date {
  const prev = new Date(currentMonday.getFullYear(), currentMonday.getMonth(), currentMonday.getDate(), 12, 0, 0);
  prev.setDate(prev.getDate() - 7);
  return prev;
}

/**
 * Returns Monday of current week based on current system time.
 */
export function getCurrentWeekMonday(): Date {
  return getMondayOfWeek(new Date());
}

/**
 * Generates metadata for all 7 days of the week starting from Monday.
 */
export function getWeekDays(monday: Date): DayOfWeekMeta[] {
  return Array.from({ length: 7 }).map((_, i) => {
    const d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i, 12, 0, 0);
    return {
      dayIndex: i + 1,
      label: DAYS_OF_WEEK_NAMES[i],
      shortLabel: DAYS_OF_WEEK_SHORT[i],
      date: d,
      isoDate: formatLocalDateToYMD(d),
      formatted: `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`,
      fullFormatted: formatLocalDateToDMY(d),
    };
  });
}

/**
 * Calculates academic week number relative to semester start date.
 * Week 1 is the week of the semester start date.
 */
export function calculateSemesterWeekNumber(
  currentMonday: Date,
  semesterStartDate?: string | null
): number | null {
  if (!semesterStartDate) return null;
  const semDate = parseYMDToLocalDate(semesterStartDate);
  const semMonday = getMondayOfWeek(semDate);

  // Difference in weeks using milliseconds (safe with 12:00:00 noon times)
  const diffMs = currentMonday.getTime() - semMonday.getTime();
  const diffWeeks = Math.round(diffMs / (7 * 24 * 60 * 60 * 1000));
  return diffWeeks + 1; // 1-indexed (Week 1, Week 2, ...)
}

/**
 * Determines whether a date range overlaps with or is within the semester window.
 */
export function isWeekWithinSemester(
  monday: Date,
  sunday: Date,
  semesterStart?: string | null,
  semesterEnd?: string | null
): boolean {
  if (!semesterStart || !semesterEnd) return true;
  const semStart = parseYMDToLocalDate(semesterStart);
  const semEnd = parseYMDToLocalDate(semesterEnd);
  // Week overlaps if monday <= semEnd and sunday >= semStart
  return monday <= semEnd && sunday >= semStart;
}
