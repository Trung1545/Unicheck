import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
RAW_DIR = DATA_DIR / "raw"
NORMALIZED_DIR = DATA_DIR / "normalized"
SEEDS_DIR = DATA_DIR / "seeds"

# URL sources
FPTU_BASE_URL = "https://daihoc.fpt.edu.vn"
FPTU_CURRICULUM_URL = "https://daihoc.fpt.edu.vn/chuong-trinh-dao-tao/"
FPTU_SE_URL = "https://daihoc.fpt.edu.vn/chuyen-nganh/ky-thuat-phan-mem/"
FPTU_AI_URL = "https://daihoc.fpt.edu.vn/chuyen-nganh/tri-tue-nhan-tao/"
FPTU_IA_URL = "https://daihoc.fpt.edu.vn/chuyen-nganh/an-toan-thong-tin/"
FPTU_IS_URL = "https://daihoc.fpt.edu.vn/chuyen-nganh/he-thong-thong-tin/"
FPTU_BA_URL = "https://daihoc.fpt.edu.vn/chuyen-nganh/quan-tri-kinh-doanh/"

# Scraping settings
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 (UniCheck Audit Bot/1.0)"
REQUEST_TIMEOUT = 12
REQUEST_DELAY_SECONDS = 2.0
MAX_RETRIES = 2

# Safety & Testing Domains (Never impersonate real @fpt.edu.vn)
SYNTHETIC_EMAIL_DOMAIN = "test.unicheck.edu.vn"
DEFAULT_TEST_PASSWORD = "Password@123"
DEFAULT_SEMESTER_CODE = "FALL2026"
