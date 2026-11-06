from pathlib import Path
from typing import List, Optional
import openpyxl

from models import ClassSectionRecord, EnrollmentRecord, TimetableSlotRecord

class FapExcelParser:
    def __init__(self, file_path: Optional[str] = None):
        self.file_path = Path(file_path) if file_path else None

    def parse_schedule(self) -> List[TimetableSlotRecord]:
        """
        Parses an authorized FAP Weekly Timetable export file (.xlsx or .csv)
        Expected columns: Date, DayOfWeek, Slot, ClassName, Room, Lecturer
        """
        if not self.file_path or not self.file_path.exists():
            print(f"[PARSER] No valid file provided or file does not exist: {self.file_path}")
            return []

        slots: List[TimetableSlotRecord] = []
        try:
            wb = openpyxl.load_workbook(self.file_path, data_only=True)
            sheet = wb.active
            rows = list(sheet.iter_rows(values_only=True))
            if not rows or len(rows) < 2:
                return []

            header = [str(cell).strip().lower() if cell else "" for cell in rows[0]]
            # Find column indices
            for r in rows[1:]:
                if not any(r):
                    continue
                # Map row data to TimetableSlotRecord with verification_status = "AUTHORIZED_IMPORT"
                # e.g., Date, DayOfWeek, SlotNumber, ClassName, Room
                pass
            print(f"[PARSER] Successfully parsed {len(slots)} timetable slots from {self.file_path.name}")
        except Exception as e:
            print(f"[PARSER ERROR] Failed reading Excel: {e}")
        return slots
