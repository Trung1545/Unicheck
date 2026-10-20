// ==============================================================================
// UniCheck - Timetable Date & Week Navigation Unit Tests (TASK-02D)
// Verifying Week Rules, Month/Year Rollovers, and Asia/Ho_Chi_Minh Timezone
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import {
  formatLocalDateToYMD,
  formatLocalDateToDMY,
  parseYMDToLocalDate,
  getMondayOfWeek,
  getSundayOfWeek,
  getNextWeekMonday,
  getPrevWeekMonday,
  getWeekDays,
  calculateSemesterWeekNumber,
  isWeekWithinSemester,
} from '../utils/timetable-date.utils.ts';

test('1. Monday Start & Sunday End: Given 18/10/2026 (Sunday), returns week 12/10/2026 - 18/10/2026', () => {
  // 18/10/2026 is Sunday
  const sundayDate = parseYMDToLocalDate('2026-10-18');
  const monday = getMondayOfWeek(sundayDate);
  const sunday = getSundayOfWeek(monday);

  assert.equal(formatLocalDateToYMD(monday), '2026-10-12', 'Monday should be 2026-10-12');
  assert.equal(formatLocalDateToDMY(monday), '12/10/2026', 'Monday formatted should be 12/10/2026');
  assert.equal(formatLocalDateToYMD(sunday), '2026-10-18', 'Sunday should be 2026-10-18');
  assert.equal(formatLocalDateToDMY(sunday), '18/10/2026', 'Sunday formatted should be 18/10/2026');
});

test('2. Forward Navigation: Week 12/10-18/10 -> Week 19/10-25/10/2026', () => {
  const w1Monday = parseYMDToLocalDate('2026-10-12');
  const w2Monday = getNextWeekMonday(w1Monday);
  const w2Sunday = getSundayOfWeek(w2Monday);

  assert.equal(formatLocalDateToYMD(w2Monday), '2026-10-19');
  assert.equal(formatLocalDateToDMY(w2Monday), '19/10/2026');
  assert.equal(formatLocalDateToYMD(w2Sunday), '2026-10-25');
  assert.equal(formatLocalDateToDMY(w2Sunday), '25/10/2026');
});

test('3. Month Boundary Crossing: Week 19/10-25/10 -> Week 26/10-01/11/2026', () => {
  const w2Monday = parseYMDToLocalDate('2026-10-19');
  const w3Monday = getNextWeekMonday(w2Monday);
  const w3Sunday = getSundayOfWeek(w3Monday);

  assert.equal(formatLocalDateToYMD(w3Monday), '2026-10-26');
  assert.equal(formatLocalDateToDMY(w3Monday), '26/10/2026');
  // October has 31 days, Sunday rolls over into November 1st
  assert.equal(formatLocalDateToYMD(w3Sunday), '2026-11-01');
  assert.equal(formatLocalDateToDMY(w3Sunday), '01/11/2026');
});

test('4. Backward Navigation: Week 26/10-01/11 -> Week 19/10-25/10 -> Week 12/10-18/10', () => {
  const w3Monday = parseYMDToLocalDate('2026-10-26');
  const w2Monday = getPrevWeekMonday(w3Monday);
  const w1Monday = getPrevWeekMonday(w2Monday);

  assert.equal(formatLocalDateToYMD(w2Monday), '2026-10-19');
  assert.equal(formatLocalDateToYMD(w1Monday), '2026-10-12');
});

test('5. Year Boundary Crossing: Week containing New Year 2027 (28/12/2026 - 03/01/2027)', () => {
  const nyMonday = parseYMDToLocalDate('2026-12-28');
  const nySunday = getSundayOfWeek(nyMonday);

  assert.equal(formatLocalDateToYMD(nyMonday), '2026-12-28');
  assert.equal(formatLocalDateToDMY(nyMonday), '28/12/2026');
  assert.equal(formatLocalDateToYMD(nySunday), '2027-01-03');
  assert.equal(formatLocalDateToDMY(nySunday), '03/01/2027');

  // Next week in 2027
  const nextYearMonday = getNextWeekMonday(nyMonday);
  const nextYearSunday = getSundayOfWeek(nextYearMonday);
  assert.equal(formatLocalDateToYMD(nextYearMonday), '2027-01-04');
  assert.equal(formatLocalDateToYMD(nextYearSunday), '2027-01-10');

  // Roll back from 2027 into 2026
  const rollBackMonday = getPrevWeekMonday(nextYearMonday);
  assert.equal(formatLocalDateToYMD(rollBackMonday), '2026-12-28');
});

test('6. Strict 7 Days Generation: Monday (Thứ Hai) to Sunday (Chủ Nhật)', () => {
  const monday = parseYMDToLocalDate('2026-10-12');
  const weekDays = getWeekDays(monday);

  assert.equal(weekDays.length, 7, 'Week must contain exactly 7 days');
  assert.equal(weekDays[0].label, 'Thứ Hai');
  assert.equal(weekDays[0].dayIndex, 1);
  assert.equal(weekDays[0].isoDate, '2026-10-12');

  assert.equal(weekDays[5].label, 'Thứ Bảy');
  assert.equal(weekDays[5].dayIndex, 6);
  assert.equal(weekDays[5].isoDate, '2026-10-17');

  assert.equal(weekDays[6].label, 'Chủ Nhật');
  assert.equal(weekDays[6].dayIndex, 7);
  assert.equal(weekDays[6].isoDate, '2026-10-18');
});

test('7. Zero UTC Off-By-One Bug: Local calendar methods never subtract 1 day', () => {
  // Testing boundary midnight local time
  const localDate = new Date(2026, 9, 18, 0, 0, 0); // 18/10/2026 00:00:00 local
  const ymd = formatLocalDateToYMD(localDate);
  const dmy = formatLocalDateToDMY(localDate);

  assert.equal(ymd, '2026-10-18', 'Must retain 2026-10-18 regardless of UTC offset');
  assert.equal(dmy, '18/10/2026', 'Must retain 18/10/2026 regardless of UTC offset');
});

test('8. Semester Week Number Calculation (FALL2026 started 2026-10-18)', () => {
  const semesterStart = '2026-10-18'; // Fall 2026 starts week of Oct 12-18
  const w1Monday = parseYMDToLocalDate('2026-10-12');
  const w2Monday = parseYMDToLocalDate('2026-10-19');
  const w3Monday = parseYMDToLocalDate('2026-10-26');

  assert.equal(calculateSemesterWeekNumber(w1Monday, semesterStart), 1, 'Oct 12-18 is Week 1');
  assert.equal(calculateSemesterWeekNumber(w2Monday, semesterStart), 2, 'Oct 19-25 is Week 2');
  assert.equal(calculateSemesterWeekNumber(w3Monday, semesterStart), 3, 'Oct 26-Nov 01 is Week 3');
});

test('9. Semester Window Bounds Check', () => {
  const semStart = '2026-10-18';
  const semEnd = '2027-01-15';

  const w1Monday = parseYMDToLocalDate('2026-10-12');
  const w1Sunday = getSundayOfWeek(w1Monday);
  assert.equal(isWeekWithinSemester(w1Monday, w1Sunday, semStart, semEnd), true);

  const pastMonday = parseYMDToLocalDate('2027-02-01');
  const pastSunday = getSundayOfWeek(pastMonday);
  assert.equal(isWeekWithinSemester(pastMonday, pastSunday, semStart, semEnd), false);
});
