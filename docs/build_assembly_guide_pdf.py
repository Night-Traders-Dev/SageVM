#!/usr/bin/env python3
"""Generate SageVM Assembly Guide PDF — SVM & SRVM."""

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame,
    Paragraph, Spacer, PageBreak,
    Table, TableStyle, HRFlowable, Preformatted,
    KeepTogether, NextPageTemplate,
)
from reportlab.lib.colors import HexColor, white

# ─── Palette ─────────────────────────────────────────────────────────────────
C_NAVY       = HexColor('#0b1c2c')
C_NAVY_MED   = HexColor('#1a3553')
C_CYAN       = HexColor('#00bcd4')
C_CYAN_DIM   = HexColor('#006e7f')
C_CODE_BG    = HexColor('#0d1117')
C_CODE_FG    = HexColor('#e6edf3')
C_TH_BG      = HexColor('#1a3553')
C_ALT_ROW    = HexColor('#f0f5fa')
C_BORDER     = HexColor('#c0cdd8')
C_DIVIDER    = HexColor('#dde6ee')
C_BODY       = HexColor('#1a202c')
C_MUTED      = HexColor('#718096')
C_EXEC_BG    = HexColor('#e8f4fd')
C_EXEC_LEFT  = HexColor('#0078c2')
C_ACCENT_BOX = HexColor('#f0fafb')
C_GREEN      = HexColor('#27ae60')
C_RED        = HexColor('#c0392b')

PAGE_W, PAGE_H = A4

LEFT    = 2.0 * cm
RIGHT   = 1.5 * cm
TOP     = 2.5 * cm
BOTTOM  = 2.2 * cm
CONTENT_W = PAGE_W - LEFT - RIGHT  # ~496 pts / ~17.5 cm


# ─── Page Drawing ────────────────────────────────────────────────────────────
def draw_content_page(canvas, doc):
    canvas.saveState()
    # ── Header bar ──
    canvas.setFillColor(C_NAVY)
    canvas.rect(0, PAGE_H - TOP + 0.15 * cm, PAGE_W, TOP - 0.15 * cm, fill=1, stroke=0)
    # Cyan rule under header
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H - TOP + 0.12 * cm, PAGE_W, 0.05 * cm, fill=1, stroke=0)
    # Header text
    canvas.setFont('Courier-Bold', 7.5)
    canvas.setFillColor(C_CYAN)
    canvas.drawString(LEFT, PAGE_H - TOP + 0.65 * cm, 'SAGEVM ASSEMBLY GUIDE')
    canvas.setFont('Courier', 7.5)
    canvas.setFillColor(HexColor('#8bafc4'))
    canvas.drawRightString(PAGE_W - RIGHT, PAGE_H - TOP + 0.65 * cm,
                           'Night-Traders-Dev  ·  v0.9.8')
    # ── Footer ──
    canvas.setFillColor(C_DIVIDER)
    canvas.rect(LEFT, BOTTOM - 0.5 * cm, CONTENT_W, 0.03 * cm, fill=1, stroke=0)
    canvas.setFont('Courier', 7.5)
    canvas.setFillColor(C_MUTED)
    canvas.drawCentredString(PAGE_W / 2, BOTTOM - 0.42 * cm, f'— {doc.page} —')
    canvas.restoreState()


def draw_cover_page(canvas, doc):
    canvas.saveState()
    # Full dark background
    canvas.setFillColor(C_NAVY)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    # Cyan accent stripe
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H * 0.42 - 0.08 * cm, PAGE_W, 0.18 * cm, fill=1, stroke=0)
    # Corner accent
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H - 1.5 * cm, 3.5 * cm, 0.06 * cm, fill=1, stroke=0)
    # Bottom strip
    canvas.setFillColor(C_NAVY_MED)
    canvas.rect(0, 0, PAGE_W, 1.8 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, 1.8 * cm, PAGE_W, 0.04 * cm, fill=1, stroke=0)
    # Footer text
    canvas.setFont('Courier', 7.5)
    canvas.setFillColor(HexColor('#5d8aa8'))
    canvas.drawString(LEFT, 0.7 * cm, 'Night-Traders-Dev  ·  github.com/Night-Traders-Dev')
    canvas.drawRightString(PAGE_W - RIGHT, 0.7 * cm, 'SageVM Assembly Guide')
    canvas.restoreState()


# ─── Styles ──────────────────────────────────────────────────────────────────
def make_styles():
    return {
        # Cover
        'cover_title': ParagraphStyle('cover_title',
            fontName='Courier-Bold', fontSize=44, textColor=white,
            leading=52, spaceAfter=2, alignment=TA_LEFT),
        'cover_sub': ParagraphStyle('cover_sub',
            fontName='Courier', fontSize=16, textColor=C_CYAN,
            spaceAfter=4, alignment=TA_LEFT),
        'cover_meta_k': ParagraphStyle('cover_meta_k',
            fontName='Courier-Bold', fontSize=8.5, textColor=HexColor('#5d8aa8'),
            alignment=TA_LEFT),
        'cover_meta_v': ParagraphStyle('cover_meta_v',
            fontName='Courier', fontSize=8.5, textColor=white, alignment=TA_LEFT),
        'cover_desc': ParagraphStyle('cover_desc',
            fontName='Helvetica', fontSize=10.5, textColor=HexColor('#a8c8e0'),
            leading=17, alignment=TA_LEFT),
        # Headings
        'h1': ParagraphStyle('h1',
            fontName='Courier-Bold', fontSize=15, textColor=C_NAVY,
            spaceBefore=4, spaceAfter=6, leading=20),
        'h2': ParagraphStyle('h2',
            fontName='Courier-Bold', fontSize=11, textColor=C_NAVY_MED,
            spaceBefore=12, spaceAfter=4, leading=15),
        'h3': ParagraphStyle('h3',
            fontName='Courier-Bold', fontSize=9.5, textColor=C_BODY,
            spaceBefore=8, spaceAfter=3, leading=13),
        # Body
        'body': ParagraphStyle('body',
            fontName='Helvetica', fontSize=9.5, textColor=C_BODY,
            alignment=TA_JUSTIFY, spaceBefore=3, spaceAfter=3, leading=15),
        'bullet': ParagraphStyle('bullet',
            fontName='Helvetica', fontSize=9.5, textColor=C_BODY,
            spaceBefore=2, spaceAfter=2, leading=14,
            leftIndent=16, firstLineIndent=-10),
        'numbered': ParagraphStyle('numbered',
            fontName='Helvetica', fontSize=9.5, textColor=C_BODY,
            spaceBefore=2, spaceAfter=2, leading=14,
            leftIndent=20, firstLineIndent=-14),
        # Code
        'code': ParagraphStyle('code',
            fontName='Courier', fontSize=7.8, textColor=C_CODE_FG,
            spaceBefore=0, spaceAfter=0, leading=11.5),
        # Tables
        'th': ParagraphStyle('th',
            fontName='Courier-Bold', fontSize=8, textColor=white, alignment=TA_LEFT),
        'td': ParagraphStyle('td',
            fontName='Courier', fontSize=8, textColor=C_BODY,
            alignment=TA_LEFT, leading=12),
        'td_mono': ParagraphStyle('td_mono',
            fontName='Courier', fontSize=7.8, textColor=C_NAVY_MED,
            alignment=TA_LEFT, leading=11.5),
        # Callout
        'exec_body': ParagraphStyle('exec_body',
            fontName='Helvetica', fontSize=10, textColor=HexColor('#0a3d62'),
            alignment=TA_JUSTIFY, leading=16),
        # Misc
        'caption': ParagraphStyle('caption',
            fontName='Helvetica-Oblique', fontSize=8, textColor=C_MUTED,
            alignment=TA_CENTER, spaceBefore=1, spaceAfter=5),
        'end_note': ParagraphStyle('end_note',
            fontName='Courier', fontSize=8, textColor=C_MUTED, alignment=TA_CENTER),
        'obs': ParagraphStyle('obs',
            fontName='Helvetica', fontSize=9, textColor=C_BODY,
            spaceBefore=2, spaceAfter=2, leading=13.5,
            leftIndent=16, firstLineIndent=-10),
    }


# ─── Helper Flowable Builders ────────────────────────────────────────────────
def h1(text, S):
    p = Paragraph(text, S['h1'])
    rule = HRFlowable(width='100%', thickness=2, color=C_CYAN,
                      spaceAfter=4, spaceBefore=2)
    return [Spacer(1, 10), p, rule]

def h2(text, S):
    return [Paragraph(text, S['h2'])]

def h3(text, S):
    return [Paragraph(text, S['h3'])]

def p(text, S):
    return [Paragraph(text, S['body'])]

def bullet(items, S):
    return [Paragraph(f'\u2022\u2002{item}', S['bullet']) for item in items]

def numbered(items, S):
    return [Paragraph(f'<b>{i}.</b>\u2003{item}', S['numbered'])
            for i, item in enumerate(items, 1)]

def sp(n=6):
    return [Spacer(1, n)]

def hr():
    return [Spacer(1, 8),
            HRFlowable(width='100%', thickness=0.5, color=C_DIVIDER),
            Spacer(1, 8)]

def code_block(text, S):
    lines = text.strip('\n').split('\n')
    # strip uniform leading indent
    nonempty = [l for l in lines if l.strip()]
    if nonempty:
        mi = min(len(l) - len(l.lstrip()) for l in nonempty)
        lines = [l[mi:] for l in lines]
    pre = Preformatted('\n'.join(lines), S['code'])
    tbl = Table([[pre]], colWidths=[CONTENT_W])
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), C_CODE_BG),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('BOX', (0, 0), (-1, -1), 0.5, HexColor('#30363d')),
        ('LINEABOVE', (0, 0), (-1, 0), 2, C_CYAN_DIM),
    ]))
    return [Spacer(1, 4), tbl, Spacer(1, 4)]

def data_table(headers, rows, col_widths, S, mono_cols=None):
    mono_cols = mono_cols or []
    data = [[Paragraph(h, S['th']) for h in headers]]
    for row in rows:
        data.append([
            Paragraph(str(c), S['td_mono'] if i in mono_cols else S['td'])
            for i, c in enumerate(row)
        ])
    cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), C_TH_BG),
        ('GRID', (0, 0), (-1, -1), 0.5, C_BORDER),
        ('LEFTPADDING', (0, 0), (-1, -1), 7),
        ('RIGHTPADDING', (0, 0), (-1, -1), 7),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LINEBELOW', (0, 0), (-1, 0), 1.5, C_CYAN_DIM),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            cmds.append(('BACKGROUND', (0, i), (-1, i), C_ALT_ROW))
    tbl = Table(data, colWidths=col_widths)
    tbl.setStyle(TableStyle(cmds))
    return [Spacer(1, 4), tbl, Spacer(1, 6)]

def exec_box(text, S):
    p = Paragraph(text, S['exec_body'])
    tbl = Table([[p]], colWidths=[CONTENT_W])
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), C_EXEC_BG),
        ('LEFTPADDING', (0, 0), (-1, -1), 14),
        ('RIGHTPADDING', (0, 0), (-1, -1), 14),
        ('TOPPADDING', (0, 0), (-1, -1), 12),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
        ('LINEBEFORE', (0, 0), (0, -1), 4, C_EXEC_LEFT),
        ('BOX', (0, 0), (-1, -1), 0.5, C_BORDER),
    ]))
    return [Spacer(1, 4), tbl, Spacer(1, 8)]

def note_box(text, S, color=None):
    color = color or C_ACCENT_BOX
    p = Paragraph(text, ParagraphStyle('nb', fontName='Helvetica', fontSize=9,
                                        textColor=C_BODY, leading=14))
    tbl = Table([[p]], colWidths=[CONTENT_W])
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), color),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LINEBEFORE', (0, 0), (0, -1), 3, C_CYAN),
        ('BOX', (0, 0), (-1, -1), 0.5, C_BORDER),
    ]))
    return [Spacer(1, 4), tbl, Spacer(1, 4)]

# short tag helpers
def mc(t): return f'<font face="Courier">{t}</font>'
def mb(t): return f'<b>{t}</b>'


# ─── Main Build ───────────────────────────────────────────────────────────────
def build():
    OUTPUT = 'docs/SageVM_Assembly_Guide.pdf'

    doc = BaseDocTemplate(
        OUTPUT,
        pagesize=A4,
        leftMargin=LEFT, rightMargin=RIGHT,
        topMargin=TOP, bottomMargin=BOTTOM,
        title='SageVM Assembly Guide',
        author='Night-Traders-Dev',
        subject='Definitive Guide to SVM & SRVM Assembly — v0.9.8',
        creator='SageLang Documentation Pipeline',
    )

    content_frame = Frame(LEFT, BOTTOM, CONTENT_W, PAGE_H - TOP - BOTTOM, id='body')

    cover_tmpl   = PageTemplate(id='Cover',   frames=[content_frame], onPage=draw_cover_page)
    content_tmpl = PageTemplate(id='Content', frames=[content_frame], onPage=draw_content_page)
    doc.addPageTemplates([cover_tmpl, content_tmpl])

    S = make_styles()
    story = []

    # ════════════════════════════════════════════════════════════════════════
    # COVER PAGE
    # ════════════════════════════════════════════════════════════════════════
    story.append(NextPageTemplate('Cover'))
    story += [
        Spacer(1, PAGE_H * 0.12),
        Paragraph('SAGEVM', S['cover_title']),
        Paragraph('Assembly Guide', S['cover_sub']),
        Spacer(1, 0.3 * cm),
        HRFlowable(width='100%', thickness=0.5, color=HexColor('#30607a'), spaceAfter=12),
    ]

    meta = [
        ('Version',         'v0.9.8'),
        ('Organization',    'Night-Traders-Dev'),
        ('Architectures',   'SVM (Stack) & SRVM (Register/RISC-V)'),
        ('Document Type',   'Technical Guide & Reference'),
        ('Status',          'Draft / Active Development'),
    ]
    meta_tbl = Table(
        [[Paragraph(k, S['cover_meta_k']), Paragraph(v, S['cover_meta_v'])]
         for k, v in meta],
        colWidths=[3.8 * cm, CONTENT_W - 3.8 * cm],
    )
    meta_tbl.setStyle(TableStyle([
        ('LEFTPADDING',   (0, 0), (-1, -1), 0),
        ('RIGHTPADDING',  (0, 0), (-1, -1), 6),
        ('TOPPADDING',    (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LINEBELOW',     (0, 0), (-1, -2), 0.5, HexColor('#1e3a54')),
    ]))
    story.append(meta_tbl)
    story += [
        Spacer(1, 1.6 * cm),
        Paragraph(
            'The Definitive Guide to writing assembly for the Sage General Virtual Machine (SGVM). '
            'This document explores the low-level mechanics of the dual-VM architecture, '
            'providing comprehensive tutorials and examples for both the stack-based SVM '
            'and the RISC-V mapped SRVM. From basic arithmetic to advanced system-level '
            'bootloaders and GPU command streams.',
            S['cover_desc']
        ),
    ]
    story.append(PageBreak())

    # ════════════════════════════════════════════════════════════════════════
    # CONTENT PAGES
    # ════════════════════════════════════════════════════════════════════════
    story.append(NextPageTemplate('Content'))

    # ── Executive Summary ────────────────────────────────────────────────────
    story += h1('1. Introduction: The Dual-Architecture Model', S)
    story += p(
        'SageVM implements a unique dual-VM architecture, allowing high-level Sage code to be '
        'compiled into two distinct execution substrates:', S)
    story += bullet([
        f'{mb("SVM (Stack Virtual Machine):")} Optimized for binary density and portable execution. Uses an implicit operand stack.',
        f'{mb("SRVM (Register Virtual Machine):")} Optimized for speed and JIT friendliness. Maps directly to the RV64I (RISC-V) specification.'
    ], S)

    # ── §2 Mechanics ──────────────────────────────────────────────────────
    story += h1('2. Core Mechanics: How the Machines Move', S)
    
    story += h2('2.1 The SVM Stack Logic', S)
    story += p('In SVM, all operations happen at the top of an implicit LIFO stack.', S)
    story += bullet([
        f'{mb("Pushing:")} {mc("CONSTANT 0")} pushes the first item from the constant pool.',
        f'{mb("Operating:")} {mc("ADD")} pops two values and pushes their sum.',
        f'{mb("Scoping:")} Managed via {mc("PUSH_ENV")} and {mc("POP_ENV")}.'
    ], S)

    story += h2('2.2 The SRVM Register Logic', S)
    story += p('SRVM uses 32 general-purpose 64-bit registers (x0-x31).', S)
    story += bullet([
        f'{mb("x0 (zero):")} Hardwired to 0.',
        f'{mb("x10-x17 (a0-a7):")} Function arguments and return values.',
        f'{mb("VMSYS:")} A special SYSTEM instruction ({mc("0x73")}) for calling VM Services (Print, Halt, etc.).'
    ], S)

    # ── §3 Real-World Examples ──────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('3. Real-World Examples: The Basics', S)

    story += h2('3.1 Basic Math and Output', S)
    story += p('Objective: Compute (10 + 20) * 2 and print the result.', S)
    
    story += h3('Pure Sage Equivalent', S)
    story += code_block('print (10 + 20) * 2', S)

    story += h3('SVM Assembly', S)
    story += code_block(
        'CONSTANT 10\n'
        'CONSTANT 20\n'
        'ADD\n'
        'CONSTANT 2\n'
        'MUL\n'
        'PRINT', S)

    story += h3('SRVM (RISC-V) Assembly', S)
    story += code_block(
        'ldc x10, 10\n'
        'ldc x11, 20\n'
        'add x10, x10, x11\n'
        'ldc x11, 2\n'
        'mul x10, x10, x11\n'
        'vmsys x10, 0x09   # VM_PRINT', S)

    story += h2('3.2 Control Flow (While Loop)', S)
    story += p('Objective: Print numbers from 1 to 5.', S)
    
    story += h3('Pure Sage', S)
    story += code_block('var i = 1\nwhile i <= 5:\n    print i\n    i = i + 1', S)

    story += h3('SVM Assembly', S)
    story += code_block(
        'CONSTANT 1\nDEFINE_GLOBAL "i"\n'
        'LOOP_START:\n'
        '  GET_GLOBAL "i"\n  CONSTANT 5\n  LESS_EQUAL\n'
        '  JUMP_IF_FALSE EXIT\n'
        '  GET_GLOBAL "i"\n  PRINT\n'
        '  GET_GLOBAL "i"\n  CONSTANT 1\n  ADD\n  SET_GLOBAL "i"\n'
        '  JUMP LOOP_START\n'
        'EXIT:\nHALT', S)

    # ── §4 Advanced Examples ────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('4. Advanced Examples: Objects and Exceptions', S)

    story += h2('4.1 Object Orientation', S)
    story += p('SageVM handles classes via method tables and property maps.', S)
    story += code_block(
        'class Point:\n'
        '    proc init(self, x, y):\n'
        '        self.x = x\n'
        '        self.y = y', S)
    story += bullet([
        f'{mb("SVM Implementation:")} Uses {mc("CLASS")}, {mc("METHOD")}, and {mc("SET_PROPERTY")} opcodes.',
        f'{mb("SRVM Implementation:")} Uses {mc("vmsys")} with {mc("OBJ_NEW_CLASS")} and {mc("OBJ_METHOD_BIND")} markers.'
    ], S)

    story += h2('4.2 Exception Handling', S)
    story += p('Exceptions use a dedicated handler stack for unwinding.', S)
    story += h3('SVM Pattern', S)
    story += code_block(
        'SETUP_TRY CATCH_LABEL\n'
        'CONSTANT "Error!"\n'
        'RAISE\n'
        'END_TRY\n'
        'JUMP EXIT\n'
        'CATCH_LABEL:\n'
        '  PRINT\n'
        'EXIT:', S)

    story += h1('5. Advanced System & GPU Interfacing', S)
    
    story += h2('5.1 Advanced SRVM Bootloader', S)
    story += p('Demonstrates low-level machine state initialization in RISC-V.', S)
    story += code_block(
        'ldc x10, 0x01      # Const Index 1: Memory Block\n'
        'mv  x2, x10        # Set Stack Pointer (sp)\n'
        'ldc x3, 0x02       # Const Index 2: Global Env\n'
        'vmsys x0, 0x02     # VMO_PUSH_ENV\n'
        'ldc x10, 0x03      # Index 3: kernel_main\n'
        'vmsys x10, 0x04    # VMO_CALL\n'
        'vmsys x0, 0x01     # VMO_HALT', S)

    story += h2('5.2 Advanced SVM GPU Bridge (Vulkan)', S)
    story += p('Managing a Vulkan render pass via native VM opcodes.', S)
    story += code_block(
        'OP_GPU_POLL_EVENTS\n'
        'CONSTANT 0; OP_GPU_ACQUIRE_IMG\n'
        'CONSTANT 1; OP_GPU_BEGIN_COMMANDS\n'
        '# ... Begin Render Pass ...\n'
        'OP_GPU_CMD_BEGIN_RP\n'
        'CONSTANT 6; OP_GPU_CMD_BIND_GP\n'
        '# ... Draw Call ...\n'
        'OP_GPU_CMD_DRAW\n'
        'OP_GPU_CMD_END_RP\n'
        'OP_GPU_END_COMMANDS\n'
        'OP_GPU_PRESENT', S)

    # ── §6 Reference ──────────────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('6. Technical Reference & Pro Tips', S)
    
    story += h2('6.1 Constant Pool Encoding', S)
    story += data_table(
        ['Type', 'Byte', 'Description'],
        [
            ['Double', '0x01', 'IEEE 754 double-precision (8 bytes)'],
            ['String', '0x02', 'Length-prefixed (2-byte BE) UTF-8 data'],
            ['Int32',  '0x03', '32-bit big-endian integer'],
        ],
        col_widths=[4.0 * cm, 3.0 * cm, 10.0 * cm], S=S, mono_cols=[1]
    )

    story += h2('6.2 Pro Tips', S)
    story += numbered([
        f'{mb("Halt is Mandatory:")} Always end your main chunk with {mc("HALT")} to prevent executing uninitialized memory.',
        f'{mb("Native Bridge:")} Use {mc("OP_CALL")} on global objects like {mc("math")} or {mc("io")} to switch to high-performance C implementations.',
        f'{mb("Debugging:")} Leverage {mc("sagevm hex binary.sgvm")} to inspect the exact byte layout of your binaries.'
    ], S)

    story += hr()
    story += [
        Spacer(1, 8),
        Paragraph(
            'End of Document  ·  SageVM Assembly Guide v0.9.8  ·  Night-Traders-Dev',
            S['end_note']
        ),
    ]

    doc.build(story)
    print(f'✓  PDF written to {OUTPUT}')

if __name__ == '__main__':
    build()
