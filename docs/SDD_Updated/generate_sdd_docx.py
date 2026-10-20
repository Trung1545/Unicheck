import os
import re
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def set_table_borders(table, color="CBD5E1", sz="4"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'<w:top w:val="single" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:bottom w:val="single" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:left w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'<w:insideH w:val="single" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:insideV w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def build_docx_from_markdown(md_path, docx_path):
    doc = Document()
    
    # Thiết lập lề trang chuẩn đồ án: Lề trái 3cm (1.18 in), Trên/Dưới/Phải 2.5cm (1 in)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.2)
        section.right_margin = Inches(1.0)
        section.different_first_page_header_footer = True
        
        # Header trang
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("Báo Cáo Đặc Tả Thiết Kế Hệ Thống UniCheck (SDD v2.1)")
        hrun.font.name = "Times New Roman"
        hrun.font.size = Pt(9)
        hrun.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
        
        # Footer trang
        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        frun = fp.add_run("Tài liệu báo cáo đồ án / nghiệm thu kỹ thuật — UniCheck Project 2026")
        frun.font.name = "Times New Roman"
        frun.font.size = Pt(9)
        frun.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)

    # -------------------------------------------------------------
    # 1. TRANG BÌA CHUẨN ĐỒ ÁN ĐẠI HỌC
    # -------------------------------------------------------------
    p_univ = doc.add_paragraph()
    p_univ.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_univ.paragraph_format.space_before = Pt(20)
    p_univ.paragraph_format.space_after = Pt(4)
    run_univ = p_univ.add_run("TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN\nKHOA KỸ THUẬT PHẦN MỀM")
    run_univ.font.name = "Times New Roman"
    run_univ.font.size = Pt(13)
    run_univ.bold = True
    run_univ.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)

    p_line = doc.add_paragraph()
    p_line.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_line.paragraph_format.space_before = Pt(0)
    p_line.paragraph_format.space_after = Pt(36)
    run_line = p_line.add_run("----------***----------")
    run_line.font.name = "Times New Roman"
    run_line.font.size = Pt(11)
    run_line.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(24)
    p_title.paragraph_format.space_after = Pt(12)
    run_t = p_title.add_run("BÁO CÁO ĐỒ ÁN CHUYÊN NGÀNH\nĐẶC TẢ THIẾT KẾ KIẾN TRÚC VÀ HỆ THỐNG PHẦN MỀM\n(SOFTWARE DESIGN DOCUMENT - SDD)")
    run_t.font.name = "Times New Roman"
    run_t.font.size = Pt(17)
    run_t.bold = True
    run_t.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)

    p_proj = doc.add_paragraph()
    p_proj.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_proj.paragraph_format.space_before = Pt(10)
    p_proj.paragraph_format.space_after = Pt(36)
    run_p = p_proj.add_run("ĐỀ TÀI: HỆ THỐNG ĐIỂM DANH TỰ GIÁC THÔNG QUA NHẬN DIỆN KHUÔN MẶT ĐA NỀN TẢNG (UNICHECK)")
    run_p.font.name = "Times New Roman"
    run_p.font.size = Pt(13.5)
    run_p.bold = True
    run_p.font.color.rgb = RGBColor(0x1B, 0x36, 0x5D)

    # Bảng thông tin người thực hiện trên bìa
    info_table = doc.add_table(rows=6, cols=2)
    info_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    info_table.autofit = False
    info_table.columns[0].width = Inches(2.2)
    info_table.columns[1].width = Inches(4.3)
    set_table_borders(info_table, color="E2E8F0", sz="4")
    
    meta_info = [
        ("Học phần / Môn học:", "Đồ án Chuyên ngành Kỹ thuật Phần mềm"),
        ("Đơn vị thực hiện:", "Nhóm Kỹ sư Phát triển Dự án UniCheck"),
        ("Hội đồng nghiệm thu:", "Hội đồng Chuyên môn Khoa Kỹ thuật Phần mềm"),
        ("Phiên bản thiết kế:", "Phiên bản 2.1 — Chuẩn hóa theo mã nguồn thực tế"),
        ("Kiểm thử tự động:", "281 / 281 Automated Tests Passed (100%)"),
        ("Thời gian thực hiện:", "Tháng 10 / 2026"),
    ]
    for row_idx, (k, v) in enumerate(meta_info):
        r = info_table.rows[row_idx]
        c0, c1 = r.cells[0], r.cells[1]
        set_cell_background(c0, "F8FAFC")
        set_cell_background(c1, "FFFFFF")
        set_cell_margins(c0, 60, 60, 100, 100)
        set_cell_margins(c1, 60, 60, 100, 100)
        
        p0 = c0.paragraphs[0]
        r0 = p0.add_run(k)
        r0.font.name = "Times New Roman"
        r0.font.size = Pt(11)
        r0.bold = True
        r0.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
        
        p1 = c1.paragraphs[0]
        r1 = p1.add_run(v)
        r1.font.name = "Times New Roman"
        r1.font.size = Pt(11)
        r1.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        if "281 / 281" in v:
            r1.bold = True
            r1.font.color.rgb = RGBColor(0x16, 0x65, 0x34)

    p_bottom = doc.add_paragraph()
    p_bottom.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_bottom.paragraph_format.space_before = Pt(60)
    r_bot = p_bottom.add_run("TP. HỒ CHÍ MINH, NĂM 2026")
    r_bot.font.name = "Times New Roman"
    r_bot.font.size = Pt(12)
    r_bot.bold = True
    r_bot.font.color.rgb = RGBColor(0x47, 0x55, 0x69)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 2. ĐỌC VÀ CHUYỂN ĐỔI NỘI DUNG MARKDOWN
    # -------------------------------------------------------------
    with open(md_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    in_code_block = False
    code_lines = []
    
    in_table = False
    table_rows = []

    def flush_table(rows):
        if not rows:
            return
        parsed_rows = []
        for r in rows:
            cleaned = r.strip()
            if cleaned.startswith("|"):
                cleaned = cleaned[1:]
            if cleaned.endswith("|"):
                cleaned = cleaned[:-1]
            cols = [c.strip() for c in cleaned.split("|")]
            if all(re.match(r'^:?-+:?$', c) for c in cols):
                continue
            parsed_rows.append(cols)
        
        if not parsed_rows:
            return

        num_cols = max(len(r) for r in parsed_rows)
        for r in parsed_rows:
            while len(r) < num_cols:
                r.append("")

        tbl = doc.add_table(rows=len(parsed_rows), cols=num_cols)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        tbl.autofit = True
        set_table_borders(tbl, color="CBD5E1", sz="4")

        for r_idx, row_data in enumerate(parsed_rows):
            row_elem = tbl.rows[r_idx]
            is_header = (r_idx == 0)
            for c_idx, cell_text in enumerate(row_data):
                cell = row_elem.cells[c_idx]
                set_cell_margins(cell, 70, 70, 100, 100)
                if is_header:
                    set_cell_background(cell, "F1F5F9")
                else:
                    set_cell_background(cell, "FAFAFA" if r_idx % 2 == 1 else "FFFFFF")

                p = cell.paragraphs[0]
                p.paragraph_format.space_before = Pt(2)
                p.paragraph_format.space_after = Pt(2)
                p.paragraph_format.line_spacing = 1.2
                
                clean_text = cell_text.replace("<br>", "\n").replace("**", "").replace("`", "")
                run = p.add_run(clean_text)
                run.font.name = "Times New Roman"
                run.font.size = Pt(10 if num_cols <= 4 else 9)
                if is_header:
                    run.bold = True
                    run.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
                else:
                    run.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
                    if "IMPLEMENTED" in clean_text or "ĐẠT" in clean_text or "ACTIVE" in clean_text:
                        run.bold = True
                        run.font.color.rgb = RGBColor(0x16, 0x65, 0x34)
                    elif "PARTIAL" in clean_text or "PLANNED" in clean_text:
                        run.bold = True
                        run.font.color.rgb = RGBColor(0x9A, 0x34, 0x12)

        doc.add_paragraph()

    def flush_code(lines):
        if not lines:
            return
        code_text = "".join(lines).strip()
        tbl = doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        tbl.autofit = False
        tbl.columns[0].width = Inches(6.5)
        set_table_borders(tbl, color="E2E8F0", sz="4")
        
        c = tbl.cell(0, 0)
        set_cell_background(c, "F8FAFC")
        set_cell_margins(c, 90, 90, 120, 120)
        
        p = c.paragraphs[0]
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        run = p.add_run(code_text)
        run.font.name = "Consolas"
        run.font.size = Pt(8.5)
        run.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
        doc.add_paragraph()

    start_processing = False

    for line in lines:
        stripped = line.strip()

        if "## MỤC LỤC TỔNG THỂ" in line or "# CHƯƠNG 1." in line:
            start_processing = True

        if not start_processing:
            continue

        # Code block
        if stripped.startswith("```"):
            if in_code_block:
                in_code_block = False
                flush_code(code_lines)
                code_lines = []
            else:
                if in_table:
                    in_table = False
                    flush_table(table_rows)
                    table_rows = []
                in_code_block = True
            continue

        if in_code_block:
            code_lines.append(line)
            continue

        # Table
        if stripped.startswith("|") and stripped.endswith("|"):
            in_table = True
            table_rows.append(stripped)
            continue
        else:
            if in_table:
                in_table = False
                flush_table(table_rows)
                table_rows = []

        if not stripped:
            continue

        # Horizontal rule
        if stripped == "---":
            continue

        # Headings
        if stripped.startswith("# "):
            h = doc.add_heading(level=1)
            h.paragraph_format.space_before = Pt(22)
            h.paragraph_format.space_after = Pt(8)
            h.paragraph_format.keep_with_next = True
            r = h.add_run(stripped[2:])
            r.font.name = "Times New Roman"
            r.font.size = Pt(15)
            r.bold = True
            r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        elif stripped.startswith("## "):
            h = doc.add_heading(level=2)
            h.paragraph_format.space_before = Pt(16)
            h.paragraph_format.space_after = Pt(6)
            h.paragraph_format.keep_with_next = True
            r = h.add_run(stripped[3:])
            r.font.name = "Times New Roman"
            r.font.size = Pt(13)
            r.bold = True
            r.font.color.rgb = RGBColor(0x1B, 0x36, 0x5D)
        elif stripped.startswith("### "):
            h = doc.add_heading(level=3)
            h.paragraph_format.space_before = Pt(12)
            h.paragraph_format.space_after = Pt(4)
            h.paragraph_format.keep_with_next = True
            r = h.add_run(stripped[4:])
            r.font.name = "Times New Roman"
            r.font.size = Pt(12)
            r.bold = True
            r.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
        elif stripped.startswith("* ") or stripped.startswith("- "):
            p = doc.add_paragraph(style='List Bullet')
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.25
            
            clean_item = stripped[2:].replace("`", "")
            parts = re.split(r'(\*\*.*?\*\*)', clean_item)
            for part in parts:
                if part.startswith("**") and part.endswith("**"):
                    r = p.add_run(part[2:-2])
                    r.bold = True
                else:
                    r = p.add_run(part)
                r.font.name = "Times New Roman"
                r.font.size = Pt(11.5)
                r.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
        elif re.match(r'^\d+\.\s', stripped):
            p = doc.add_paragraph(style='List Number')
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.25
            
            match = re.match(r'^\d+\.\s+(.*)$', stripped)
            text_content = (match.group(1) if match else stripped).replace("`", "")
            parts = re.split(r'(\*\*.*?\*\*)', text_content)
            for part in parts:
                if part.startswith("**") and part.endswith("**"):
                    r = p.add_run(part[2:-2])
                    r.bold = True
                else:
                    r = p.add_run(part)
                r.font.name = "Times New Roman"
                r.font.size = Pt(11.5)
                r.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
        else:
            # Paragraph thông thường
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(3)
            p.paragraph_format.space_after = Pt(4)
            p.paragraph_format.line_spacing = 1.3
            p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
            
            clean_p = stripped.replace("`", "")
            parts = re.split(r'(\*\*.*?\*\*)', clean_p)
            for part in parts:
                if part.startswith("**") and part.endswith("**"):
                    r = p.add_run(part[2:-2])
                    r.bold = True
                else:
                    r = p.add_run(part)
                r.font.name = "Times New Roman"
                r.font.size = Pt(12)
                r.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)

    if in_table:
        flush_table(table_rows)

    doc.save(docx_path)
    print(f"DOCX successfully generated at: {docx_path}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    md_file = os.path.join(base_dir, "UniCheck_SDD_Final.md")
    docx_file = os.path.join(base_dir, "UniCheck_SDD_Final.docx")
    build_docx_from_markdown(md_file, docx_file)
