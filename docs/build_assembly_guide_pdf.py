#!/usr/bin/env python3
"""Generate Professional SageVM Assembly Guide PDF — SVM & SRVM."""

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

PAGE_W, PAGE_H = A4

LEFT    = 2.0 * cm
RIGHT   = 1.5 * cm
TOP     = 2.5 * cm
BOTTOM  = 2.2 * cm
CONTENT_W = PAGE_W - LEFT - RIGHT


# ─── Page Drawing ────────────────────────────────────────────────────────────
def draw_content_page(canvas, doc):
    canvas.saveState()
    # Explicitly clear background to white to fix "blending" issues
    canvas.setFillColor(white)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    
    # ── Header bar ──
    canvas.setFillColor(C_NAVY)
    canvas.rect(0, PAGE_H - TOP + 0.15 * cm, PAGE_W, TOP - 0.15 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H - TOP + 0.12 * cm, PAGE_W, 0.05 * cm, fill=1, stroke=0)
    
    canvas.setFont('Courier-Bold', 7.5)
    canvas.setFillColor(C_CYAN)
    canvas.drawString(LEFT, PAGE_H - TOP + 0.65 * cm, 'SAGEVM ASSEMBLY & ARCHITECTURE GUIDE')
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
    canvas.setFillColor(C_NAVY)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H * 0.42 - 0.08 * cm, PAGE_W, 0.18 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, PAGE_H - 1.5 * cm, 3.5 * cm, 0.06 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_NAVY_MED)
    canvas.rect(0, 0, PAGE_W, 1.8 * cm, fill=1, stroke=0)
    canvas.setFillColor(C_CYAN)
    canvas.rect(0, 1.8 * cm, PAGE_W, 0.04 * cm, fill=1, stroke=0)
    canvas.setFont('Courier', 7.5)
    canvas.setFillColor(HexColor('#5d8aa8'))
    canvas.drawString(LEFT, 0.7 * cm, 'Night-Traders-Dev  ·  github.com/Night-Traders-Dev')
    canvas.drawRightString(PAGE_W - RIGHT, 0.7 * cm, 'SageVM Assembly Guide')
    canvas.restoreState()


# ─── Styles ──────────────────────────────────────────────────────────────────
def make_styles():
    return {
        'cover_title': ParagraphStyle('cover_title', fontName='Courier-Bold', fontSize=44, textColor=white, leading=52, alignment=TA_LEFT),
        'cover_sub': ParagraphStyle('cover_sub', fontName='Courier', fontSize=16, textColor=C_CYAN, spaceAfter=4, alignment=TA_LEFT),
        'cover_meta_k': ParagraphStyle('cover_meta_k', fontName='Courier-Bold', fontSize=8.5, textColor=HexColor('#5d8aa8'), alignment=TA_LEFT),
        'cover_meta_v': ParagraphStyle('cover_meta_v', fontName='Courier', fontSize=8.5, textColor=white, alignment=TA_LEFT),
        'cover_desc': ParagraphStyle('cover_desc', fontName='Helvetica', fontSize=10.5, textColor=HexColor('#a8c8e0'), leading=17, alignment=TA_LEFT),
        'h1': ParagraphStyle('h1', fontName='Courier-Bold', fontSize=15, textColor=C_NAVY, spaceBefore=4, spaceAfter=6, leading=20),
        'h2': ParagraphStyle('h2', fontName='Courier-Bold', fontSize=11, textColor=C_NAVY_MED, spaceBefore=12, spaceAfter=4, leading=15),
        'h3': ParagraphStyle('h3', fontName='Courier-Bold', fontSize=9.5, textColor=C_BODY, spaceBefore=8, spaceAfter=3, leading=13),
        'body': ParagraphStyle('body', fontName='Helvetica', fontSize=9.5, textColor=C_BODY, alignment=TA_JUSTIFY, spaceBefore=3, spaceAfter=3, leading=15),
        'bullet': ParagraphStyle('bullet', fontName='Helvetica', fontSize=9.5, textColor=C_BODY, spaceBefore=2, spaceAfter=2, leading=14, leftIndent=16, firstLineIndent=-10),
        'numbered': ParagraphStyle('numbered', fontName='Helvetica', fontSize=9.5, textColor=C_BODY, spaceBefore=2, spaceAfter=2, leading=14, leftIndent=20, firstLineIndent=-14),
        'code': ParagraphStyle('code', fontName='Courier', fontSize=7.8, textColor=C_CODE_FG, spaceBefore=0, spaceAfter=0, leading=11.5),
        'th': ParagraphStyle('th', fontName='Courier-Bold', fontSize=8, textColor=white, alignment=TA_LEFT),
        'td': ParagraphStyle('td', fontName='Courier', fontSize=8, textColor=C_BODY, alignment=TA_LEFT, leading=12),
        'td_mono': ParagraphStyle('td_mono', fontName='Courier', fontSize=7.8, textColor=C_NAVY_MED, alignment=TA_LEFT, leading=11.5),
        'exec_body': ParagraphStyle('exec_body', fontName='Helvetica', fontSize=10, textColor=HexColor('#0a3d62'), alignment=TA_JUSTIFY, leading=16),
        'end_note': ParagraphStyle('end_note', fontName='Courier', fontSize=8, textColor=C_MUTED, alignment=TA_CENTER),
    }

# ─── Helpers ─────────────────────────────────────────────────────────────────
def h1(text, S): return [Spacer(1, 10), Paragraph(text, S['h1']), HRFlowable(width='100%', thickness=2, color=C_CYAN, spaceAfter=4, spaceBefore=2)]
def h2(text, S): return [Paragraph(text, S['h2'])]
def h3(text, S): return [Paragraph(text, S['h3'])]
def p(text, S): return [Paragraph(text, S['body'])]
def bullet(items, S): return [Paragraph(f'\u2022\u2002{item}', S['bullet']) for item in items]
def numbered(items, S): return [Paragraph(f'<b>{i}.</b>\u2003{item}', S['numbered']) for i, item in enumerate(items, 1)]
def code_block(text, S):
    pre = Preformatted(text.strip('\n'), S['code'])
    tbl = Table([[pre]], colWidths=[CONTENT_W])
    tbl.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, -1), C_CODE_BG), ('LEFTPADDING', (0, 0), (-1, -1), 10), ('RIGHTPADDING', (0, 0), (-1, -1), 10), ('TOPPADDING', (0, 0), (-1, -1), 8), ('BOTTOMPADDING', (0, 0), (-1, -1), 8), ('BOX', (0, 0), (-1, -1), 0.5, HexColor('#30363d')), ('LINEABOVE', (0, 0), (-1, 0), 2, C_CYAN_DIM)]))
    return [Spacer(1, 4), tbl, Spacer(1, 4)]
def exec_box(text, S):
    p = Paragraph(text, S['exec_body'])
    tbl = Table([[p]], colWidths=[CONTENT_W])
    tbl.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, -1), C_EXEC_BG), ('LEFTPADDING', (0, 0), (-1, -1), 14), ('RIGHTPADDING', (0, 0), (-1, -1), 14), ('TOPPADDING', (0, 0), (-1, -1), 12), ('BOTTOMPADDING', (0, 0), (-1, -1), 12), ('LINEBEFORE', (0, 0), (0, -1), 4, C_EXEC_LEFT), ('BOX', (0, 0), (-1, -1), 0.5, C_BORDER)]))
    return [Spacer(1, 4), tbl, Spacer(1, 8)]
def hr(): return [Spacer(1, 8), HRFlowable(width='100%', thickness=0.5, color=C_DIVIDER), Spacer(1, 8)]
def mc(t): return f'<font face="Courier">{t}</font>'
def mb(t): return f'<b>{t}</b>'

# ─── Main Build ───────────────────────────────────────────────────────────────
def build():
    OUTPUT = 'docs/SageVM_Assembly_Guide.pdf'
    doc = BaseDocTemplate(OUTPUT, pagesize=A4, leftMargin=LEFT, rightMargin=RIGHT, topMargin=TOP, bottomMargin=BOTTOM)
    content_frame = Frame(LEFT, BOTTOM, CONTENT_W, PAGE_H - TOP - BOTTOM, id='body')
    doc.addPageTemplates([PageTemplate(id='Cover', frames=[content_frame], onPage=draw_cover_page), PageTemplate(id='Content', frames=[content_frame], onPage=draw_content_page)])
    S = make_styles()
    story = []

    # ── COVER ──
    story.append(NextPageTemplate('Cover'))
    story += [Spacer(1, PAGE_H * 0.12), Paragraph('SAGEVM', S['cover_title']), Paragraph('Assembly & Architecture', S['cover_sub']), Spacer(1, 0.3 * cm), HRFlowable(width='100%', thickness=0.5, color=HexColor('#30607a'), spaceAfter=12)]
    meta = [('Version', 'v0.9.8'), ('Architectures', 'SVM (Stack) & SRVM (Register)'), ('Binary Format', 'SGVM (.sgvm)'), ('Status', 'Active Development')]
    meta_tbl = Table([[Paragraph(k, S['cover_meta_k']), Paragraph(v, S['cover_meta_v'])] for k, v in meta], colWidths=[3.8 * cm, CONTENT_W - 3.8 * cm])
    meta_tbl.setStyle(TableStyle([('LEFTPADDING', (0, 0), (-1, -1), 0), ('TOPPADDING', (0, 0), (-1, -1), 4), ('LINEBELOW', (0, 0), (-1, -2), 0.5, HexColor('#1e3a54'))]))
    story += [meta_tbl, Spacer(1, 1.6 * cm), Paragraph('A comprehensive guide to the low-level mechanics of SageVM. This document covers the dual-architecture model, the SGVM binary format, and provides detailed tutorials for writing and optimizing assembly for both stack and register-based backends.', S['cover_desc']), PageBreak()]

    # ── CONTENT ──
    story.append(NextPageTemplate('Content'))
    
    # Chapter 1
    story += h1('1. Foundations: Virtual Machines & Bytecode', S)
    story += p('At its core, a <b>Virtual Machine (VM)</b> is a software abstraction of a physical computer. It provides a consistent execution environment regardless of the underlying hardware. For SageVM, this abstraction is defined by two primary concepts:', S)
    story += bullet([
        f'{mb("Bytecode:")} The instruction set of the VM. Unlike native machine code (x86_64, ARM), bytecode is portable and designed to be interpreted or JIT-compiled by the VM runtime.',
        f'{mb("Assembly:")} The human-readable textual representation of bytecode. Assembly provides a 1:1 mapping to the VM\'s numeric opcodes, allowing developers to write low-level code without memorizing hex values.'
    ], S)
    story += p('Virtual Machines act as an intermediate layer in the compilation pipeline, decoupling the high-level language features from the complexities of silicon architectures.', S)

    # Chapter 2
    story += h1('2. VM Architectures: Stack vs. Register', S)
    story += p('There are two dominant architectural patterns for virtual machines, both of which are implemented within SageVM to serve different strategic needs.', S)
    
    story += h2('2.1 Stack-based Virtual Machines (SVM)', S)
    story += p('A stack machine uses a <b>Last-In, First-Out (LIFO)</b> operand stack for all computations. To add two numbers, you "push" both onto the stack and then call "add", which pops them, computes the sum, and "pushes" the result back.', S)
    story += bullet([
        f'{mb("Pros:")} Extremely compact bytecode (instructions don\'t need to specify register addresses); easy to generate from ASTs.',
        f'{mb("Cons:")} Often requires more instructions than register machines; harder to optimize for modern CPUs without a sophisticated JIT.'
    ], S)

    story += h2('2.2 Register-based Virtual Machines (SRVM)', S)
    story += p('A register machine operates on a <b>Virtual Register File</b>. Instructions explicitly state the source and destination registers (e.g., "add x10, x11, x12").', S)
    story += bullet([
        f'{mb("Pros:")} Faster execution as it reduces stack traffic; closer mapping to physical hardware (like RISC-V or x86).',
        f'{mb("Cons:")} Larger instruction size (as each instruction must carry register indices).'
    ], S)

    # Chapter 3
    story.append(PageBreak())
    story += h1('3. The SageVM Dual-Architecture Model', S)
    story += exec_box('SageVM is unique because it provides both architectures in a single unified toolchain. This allows developers to choose the best substrate for their specific task.', S)
    
    story += h2('3.1 SVM (Standard Virtual Machine)', S)
    story += p('The SVM is the core execution layer of SageVM. It is optimized for portability and tight integration with the SageLang object system.', S)
    story += bullet([
        'Uses variable-length encoding (1-byte opcodes, 2-byte operands).',
        'Implements capability-based security at the opcode level.',
        'Primary target for initial compilation from SageLang source.'
    ], S)

    story += h2('3.2 SRVM (Register Virtual Machine / RISC-V)', S)
    story += p('The SRVM is a high-performance backend that maps directly to the <b>RISC-V (RV64I)</b> specification. It is the foundation for the SageVM JIT and AOT pipelines.', S)
    story += bullet([
        '32 x 64-bit general-purpose registers (x0 to x31).',
        'Fixed 32-bit instruction width for efficient decoding.',
        'Custom "VMSYS" extension for accessing SageVM-specific features like printing and object manipulation.'
    ], S)

    # Chapter 4
    story += h1('4. Binary Formats: SGVM vs. ELF', S)
    story += p('Understanding the container format is as important as the code inside it. SageVM uses a custom format called <b>SGVM</b>, which differs significantly from standard system formats like <b>ELF</b>.', S)
    
    story += h2('4.1 What is ELF?', S)
    story += p('The <b>Executable and Linkable Format (ELF)</b> is the standard binary format for Linux and most Unix-like systems. It is designed to hold native machine code, symbol tables, and relocation information for physical hardware.', S)

    story += h2('4.2 What is SGVM?', S)
    story += p('The <b>SGVM (.sgvm)</b> format is a portable container designed specifically for the Sage Virtual Machine. It contains:', S)
    story += bullet([
        f'{mb("Constant Pool:")} A centralized table for strings and large numbers, reducing duplication.',
        f'{mb("Code Chunks:")} Modular blocks of bytecode representing functions and scripts.',
        f'{mb("Capability Tags:")} Metadata that restricts what the code is allowed to do (e.g., GPU access, Filesystem access).'
    ], S)

    story += h2('4.3 Why not use ELF?', S)
    story += p('While ELF is powerful, SGVM provides <b>Architectural Neutrality</b>. An SGVM file compiled on an x86_64 machine will run identically on an ARM64 or RISC-V machine without modification. Furthermore, SGVM integrates directly with the SageLang Garbage Collector and Object System, which ELF cannot easily do.', S)

    # Chapter 5
    story.append(PageBreak())
    story += h1('5. Assembly Tutorials & Patterns', S)
    
    story += h2('5.1 Basic Arithmetic & Stack Management (SVM)', S)
    story += code_block(
        '; Compute (5 + 10) * 2\n'
        'CONSTANT 5   ; Push 5\n'
        'CONSTANT 10  ; Push 10\n'
        'ADD          ; Stack now contains 15\n'
        'CONSTANT 2   ; Push 2\n'
        'MUL          ; Stack now contains 30\n'
        'PRINT        ; Output top of stack\n'
        'HALT         ; Terminate VM', S)

    story += h2('5.2 Register-Based Logic (SRVM)', S)
    story += p('SRVM instructions use RISC-V mnemonics. Note the explicit register use.', S)
    story += code_block(
        '; Register-based equivalent\n'
        'ldc x10, 5        ; Load constant index 5 into x10\n'
        'ldc x11, 10       ; Load constant index 10 into x11\n'
        'add x10, x10, x11 ; x10 = x10 + x11\n'
        'li  x11, 2        ; Load immediate 2 into x11\n'
        'mul x10, x10, x11 ; x10 = x10 * x11\n'
        'vmsys x10, 0x09   ; VM_PRINT register x10\n'
        'vmsys x0, 0x01    ; VM_HALT', S)

    story += h2('5.3 Control Flow & Loops', S)
    story += p('Loops in SVM use relative jumps, while SRVM uses labels and branch instructions.', S)
    story += code_block(
        '; SVM Loop: Print 1 to 5\n'
        'CONSTANT 1\n'
        'DEFINE_GLOBAL "i"\n'
        'LOOP:\n'
        '  GET_GLOBAL "i"\n'
        '  CONSTANT 5\n'
        '  LESS_EQUAL\n'
        '  JUMP_IF_FALSE EXIT\n'
        '  GET_GLOBAL "i"\n'
        '  PRINT\n'
        '  GET_GLOBAL "i"\n'
        '  CONSTANT 1\n'
        '  ADD\n'
        '  SET_GLOBAL "i"\n'
        '  JUMP LOOP\n'
        'EXIT:\n'
        '  HALT', S)

    # Chapter 6
    story.append(PageBreak())
    story += h1('6. Advanced System Engineering', S)
    
    story += h2('6.1 Exception Handling Architecture', S)
    story += p('SageVM uses an explicit handler stack. This ensures that even in low-level assembly, memory safety and resource cleanup are guaranteed.', S)
    story += code_block(
        'SETUP_TRY CATCH_BLOCK ; Register a handler at CATCH_BLOCK\n'
        'CONSTANT "Dangerous Operation"\n'
        'RAISE                 ; Trigger exception\n'
        'END_TRY               ; Never reached\n'
        'CATCH_BLOCK:\n'
        '  PRINT               ; Exception value is on stack\n'
        '  HALT', S)

    story += h2('6.2 GPU Interfacing via Assembly', S)
    story += p('SageVM provides 28 dedicated GPU opcodes. These allow you to build Vulkan command buffers directly in assembly.', S)
    story += code_block(
        'OP_GPU_POLL_EVENTS\n'
        'CONSTANT 0; OP_GPU_ACQUIRE_IMG\n'
        'CONSTANT 1; OP_GPU_BEGIN_COMMANDS\n'
        'OP_GPU_CMD_BEGIN_RP\n'
        'OP_GPU_CMD_DRAW\n'
        'OP_GPU_CMD_BIND_GP\n'
        'OP_GPU_CMD_END_RP\n'
        'OP_GPU_END_COMMANDS\n'
        'OP_GPU_PRESENT', S)

    # Final Notes
    story += hr()
    story += [Spacer(1, 8), Paragraph('End of Document  ·  SageVM Assembly & Architecture Guide v0.9.8  ·  Night-Traders-Dev', S['end_note'])]

    doc.build(story)
    print(f'✓  PDF written to {OUTPUT}')

if __name__ == '__main__':
    build()
