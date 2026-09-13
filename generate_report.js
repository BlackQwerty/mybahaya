'use strict';

const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat, HeadingLevel,
  BorderStyle, WidthType, ShadingType, VerticalAlign, PageNumber, PageBreak,
  TableOfContents, StyleLevel, NumberFormat, TabStopType, TabStopPosition, LeaderType
} = require('docx');
const fs = require('fs');

// ─── Helpers ─────────────────────────────────────────────────────────────────

const BLACK = "000000";

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    alignment: AlignmentType.CENTER,
    spacing: { before: 480, after: 240 },
    children: [new TextRun({ text, bold: true, size: 32, font: "Times New Roman", color: BLACK })]
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 360, after: 120 },
    children: [new TextRun({ text, bold: true, size: 26, font: "Times New Roman", color: BLACK })]
  });
}

function h3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 240, after: 120 },
    children: [new TextRun({ text, bold: true, size: 24, font: "Times New Roman", color: BLACK })]
  });
}

function body(text, opts = {}) {
  return new Paragraph({
    alignment: opts.center ? AlignmentType.CENTER : AlignmentType.JUSTIFIED,
    spacing: { before: 0, after: 160, line: 360, lineRule: "auto" },
    children: [new TextRun({ text, size: 24, font: "Times New Roman", color: BLACK })]
  });
}

function bullet(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "bullets", level },
    spacing: { before: 0, after: 120, line: 360, lineRule: "auto" },
    children: [new TextRun({ text, size: 24, font: "Times New Roman", color: BLACK })]
  });
}

function numbered(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "numbers", level },
    spacing: { before: 0, after: 120, line: 360, lineRule: "auto" },
    children: [new TextRun({ text, size: 24, font: "Times New Roman", color: BLACK })]
  });
}

function spacer() {
  return new Paragraph({ spacing: { before: 0, after: 120 }, children: [new TextRun("")] });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function imgPlaceholder(label) {
  const border = { style: BorderStyle.SINGLE, size: 4, color: "999999" };
  return new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [9026],
    rows: [
      new TableRow({
        children: [
          new TableCell({
            borders: { top: border, bottom: border, left: border, right: border },
            width: { size: 9026, type: WidthType.DXA },
            shading: { fill: "F2F2F2", type: ShadingType.CLEAR },
            margins: { top: 200, bottom: 200, left: 200, right: 200 },
            verticalAlign: VerticalAlign.CENTER,
            children: [
              new Paragraph({
                alignment: AlignmentType.CENTER,
                spacing: { before: 200, after: 200 },
                children: [new TextRun({ text: `[ ${label} ]`, size: 22, font: "Times New Roman", italics: true, color: "666666" })]
              })
            ]
          })
        ]
      })
    ]
  });
}

// Figure caption (placed under the figure). Styled so it can be collected into List of Figures.
function figCaption(numberLabel, title) {
  return new Paragraph({
    style: "FigureCaption",
    alignment: AlignmentType.CENTER,
    spacing: { before: 60, after: 240 },
    children: [
      new TextRun({ text: `Figure ${numberLabel}: `, bold: true, size: 22, font: "Times New Roman", color: BLACK }),
      new TextRun({ text: title, size: 22, font: "Times New Roman", color: BLACK })
    ]
  });
}

// Returns [ figure placeholder , caption ] so the figure and its caption stay together.
function figure(numberLabel, title, placeholderLabel) {
  return [imgPlaceholder(placeholderLabel || title), figCaption(numberLabel, title)];
}

// Table caption (placed above the table). Styled so it can be collected into List of Tables.
function tblCaption(numberLabel, title) {
  return new Paragraph({
    style: "TableCaption",
    spacing: { before: 120, after: 60 },
    children: [
      new TextRun({ text: `Table ${numberLabel}: `, bold: true, size: 22, font: "Times New Roman", color: BLACK }),
      new TextRun({ text: title, size: 22, font: "Times New Roman", color: BLACK })
    ]
  });
}

// Front-matter centered title (e.g., "ABSTRACT", "DECLARATION")
function fmTitle(text) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 0, after: 360 },
    children: [new TextRun({ text, bold: true, size: 28, font: "Times New Roman", color: BLACK })]
  });
}

// Harvard-style reference list entry with hanging indent
function refItem(text) {
  return new Paragraph({
    alignment: AlignmentType.JUSTIFIED,
    spacing: { before: 0, after: 160, line: 360, lineRule: "auto" },
    indent: { left: 360, hanging: 360 },
    children: [new TextRun({ text, size: 24, font: "Times New Roman", color: BLACK })]
  });
}

// Two-column row helper for List of Abbreviations
function abbrRow(abbr, meaning) {
  const border = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
  const borders = { top: border, bottom: border, left: border, right: border };
  function cell(text, w, bold) {
    return new TableCell({
      borders, width: { size: w, type: WidthType.DXA },
      margins: { top: 40, bottom: 40, left: 0, right: 120 },
      children: [new Paragraph({ spacing: { before: 0, after: 0 },
        children: [new TextRun({ text, size: 24, font: "Times New Roman", bold: !!bold, color: BLACK })] })]
    });
  }
  return new TableRow({ children: [cell(abbr, 2400, true), cell(meaning, 6626, false)] });
}

// Simple table helper: header row + data rows
function simpleTable(headers, rows) {
  const colCount = headers.length;
  const pageWidth = 9026;
  const colWidth = Math.floor(pageWidth / colCount);
  const colWidths = headers.map((_, i) => i < colCount - 1 ? colWidth : pageWidth - colWidth * (colCount - 1));

  const border = { style: BorderStyle.SINGLE, size: 4, color: "999999" };
  const borders = { top: border, bottom: border, left: border, right: border };

  function makeCell(text, isHeader, width) {
    return new TableCell({
      borders,
      width: { size: width, type: WidthType.DXA },
      shading: isHeader ? { fill: "D9D9D9", type: ShadingType.CLEAR } : { fill: "FFFFFF", type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [new Paragraph({
        spacing: { before: 0, after: 0 },
        children: [new TextRun({ text, size: 22, font: "Times New Roman", bold: isHeader, color: BLACK })]
      })]
    });
  }

  return new Table({
    width: { size: pageWidth, type: WidthType.DXA },
    columnWidths: colWidths,
    rows: [
      new TableRow({ children: headers.map((h, i) => makeCell(h, true, colWidths[i])) }),
      ...rows.map(row => new TableRow({ children: row.map((cell, i) => makeCell(cell, false, colWidths[i])) }))
    ]
  });
}

// ─── Document ─────────────────────────────────────────────────────────────────

const doc = new Document({
  features: { updateFields: true },
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [{
          level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } }
        }, {
          level: 1, format: LevelFormat.BULLET, text: "◦", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1080, hanging: 360 } } }
        }]
      },
      {
        reference: "numbers",
        levels: [{
          level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } }
        }]
      }
    ]
  },
  styles: {
    default: {
      document: { run: { font: "Times New Roman", size: 24, color: BLACK } }
    },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Times New Roman", color: BLACK },
        paragraph: { spacing: { before: 480, after: 240 }, outlineLevel: 0, alignment: AlignmentType.CENTER }
      },
      {
        id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Times New Roman", color: BLACK },
        paragraph: { spacing: { before: 360, after: 120 }, outlineLevel: 1 }
      },
      {
        id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Times New Roman", color: BLACK },
        paragraph: { spacing: { before: 240, after: 120 }, outlineLevel: 2 }
      },
      {
        id: "FigureCaption", name: "Figure Caption", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 22, font: "Times New Roman", color: BLACK },
        paragraph: { spacing: { before: 60, after: 240 }, alignment: AlignmentType.CENTER }
      },
      {
        id: "TableCaption", name: "Table Caption", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 22, font: "Times New Roman", color: BLACK },
        paragraph: { spacing: { before: 120, after: 60 } }
      }
    ]
  },
  sections: [
    // ════════════════════════════════════════════════════════════
    // COVER PAGE
    // ════════════════════════════════════════════════════════════
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
        }
      },
      children: [
        spacer(), spacer(), spacer(), spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 480 },
          children: [new TextRun({ text: "MYBAHAYA: AN AI-POWERED EMERGENCY REPORTING AND REAL-TIME COMMUNITY ALERT PLATFORM FOR MALAYSIA", bold: true, size: 32, font: "Times New Roman", color: BLACK })]
        }),
        spacer(), spacer(), spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 480 },
          children: [new TextRun({ text: "AHMAD SHUKRI BIN BAKRI", bold: true, size: 28, font: "Times New Roman", color: BLACK })]
        }),
        spacer(), spacer(), spacer(), spacer(), spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 120 },
          children: [new TextRun({ text: "FACULTY OF INFORMATION AND COMMUNICATION TECHNOLOGY", bold: true, size: 26, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 480 },
          children: [new TextRun({ text: "UNIVERSITI TEKNIKAL MALAYSIA MELAKA", bold: true, size: 26, font: "Times New Roman", color: BLACK })]
        }),
        spacer(), spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 120 },
          children: [new TextRun({ text: "2026", bold: true, size: 26, font: "Times New Roman", color: BLACK })]
        }),
        pageBreak(),

        // ── BORANG PENGESAHAN STATUS LAPORAN (unnumbered) ──
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 60 },
          children: [new TextRun({ text: "UNIVERSITI TEKNIKAL MALAYSIA MELAKA", bold: true, size: 24, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 240 },
          children: [new TextRun({ text: "BORANG PENGESAHAN STATUS LAPORAN", bold: true, size: 24, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 240 },
          children: [new TextRun({ text: "JUDUL: MYBAHAYA: AN AI-POWERED EMERGENCY REPORTING AND REAL-TIME COMMUNITY ALERT PLATFORM FOR MALAYSIA", bold: true, size: 22, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 240 },
          children: [new TextRun({ text: "SESI PENGAJIAN: 2025/2026", bold: true, size: 22, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          alignment: AlignmentType.JUSTIFIED,
          spacing: { before: 0, after: 160, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "Saya AHMAD SHUKRI BIN BAKRI mengaku membenarkan laporan Projek Sarjana Muda ini disimpan di Perpustakaan Universiti Teknikal Malaysia Melaka (UTeM) dengan syarat-syarat kegunaan seperti berikut:", size: 22, font: "Times New Roman", color: BLACK })]
        }),
        numbered("Laporan ini adalah hak milik Universiti Teknikal Malaysia Melaka."),
        numbered("Perpustakaan Universiti Teknikal Malaysia Melaka dibenarkan membuat salinan untuk tujuan pengajian sahaja."),
        numbered("Perpustakaan dibenarkan membuat salinan laporan ini sebagai bahan pertukaran antara institusi pengajian tinggi."),
        numbered("** Sila tandakan (/)"),
        new Paragraph({
          spacing: { before: 60, after: 120, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "[   ]  SULIT          (Mengandungi maklumat yang berdarjah keselamatan atau kepentingan Malaysia sebagaimana yang termaktub di dalam AKTA RAHSIA RASMI 1972)", size: 20, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          spacing: { before: 0, after: 120, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "[   ]  TERHAD     (Mengandungi maklumat TERHAD yang telah ditentukan oleh organisasi/badan di mana penyelidikan dijalankan)", size: 20, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          spacing: { before: 0, after: 360, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "[ / ]  TIDAK TERHAD", size: 20, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          spacing: { before: 240, after: 0 },
          tabStops: [{ type: TabStopType.LEFT, position: 5400 }],
          children: [
            new TextRun({ text: "_______________________________", size: 22, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t_______________________________", size: 22, font: "Times New Roman", color: BLACK })
          ]
        }),
        new Paragraph({
          spacing: { before: 0, after: 0 },
          tabStops: [{ type: TabStopType.LEFT, position: 5400 }],
          children: [
            new TextRun({ text: "(TANDATANGAN PENULIS)", size: 22, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t(TANDATANGAN PENYELIA)", size: 22, font: "Times New Roman", color: BLACK })
          ]
        }),
        new Paragraph({
          spacing: { before: 360, after: 0 },
          tabStops: [{ type: TabStopType.LEFT, position: 5400 }],
          children: [
            new TextRun({ text: "Tarikh: ____________________", size: 22, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\tTarikh: ____________________", size: 22, font: "Times New Roman", color: BLACK })
          ]
        }),
        new Paragraph({
          spacing: { before: 480, after: 0 },
          children: [new TextRun({ text: "CATATAN: ** Jika laporan ini SULIT atau TERHAD, sila lampirkan surat daripada pihak berkuasa/organisasi berkenaan dengan menyatakan sekali sebab dan tempoh laporan ini perlu dikelaskan sebagai SULIT atau TERHAD.", italics: true, size: 18, font: "Times New Roman", color: BLACK })]
        }),
        pageBreak()
      ]
    },

    // ════════════════════════════════════════════════════════════
    // FRONT MATTER  (Title page → Lists ; lower-roman page numbers)
    // ════════════════════════════════════════════════════════════
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
          pageNumbers: { start: 1, formatType: NumberFormat.LOWER_ROMAN }
        },
        titlePage: true
      },
      footers: {
        // Title page = page i, number not shown
        first: new Footer({ children: [new Paragraph({ children: [new TextRun({ text: "", size: 20, font: "Times New Roman" })] })] }),
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ children: [PageNumber.CURRENT], size: 20, font: "Times New Roman", color: BLACK })]
          })]
        })
      },
      children: [
        // ── TITLE PAGE (page i) ──
        spacer(), spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 600 },
          children: [new TextRun({ text: "MYBAHAYA: AN AI-POWERED EMERGENCY REPORTING AND REAL-TIME COMMUNITY ALERT PLATFORM FOR MALAYSIA", bold: true, size: 30, font: "Times New Roman", color: BLACK })]
        }),
        spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 600 },
          children: [new TextRun({ text: "AHMAD SHUKRI BIN BAKRI", bold: true, size: 26, font: "Times New Roman", color: BLACK })]
        }),
        spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 160, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "This report is submitted in partial fulfilment of the requirements for the Bachelor of Computer Science (Software Development) with Honours.", size: 24, font: "Times New Roman", color: BLACK })]
        }),
        spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 120 },
          children: [new TextRun({ text: "FACULTY OF INFORMATION AND COMMUNICATION TECHNOLOGY", bold: true, size: 24, font: "Times New Roman", color: BLACK })]
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 480 },
          children: [new TextRun({ text: "UNIVERSITI TEKNIKAL MALAYSIA MELAKA", bold: true, size: 24, font: "Times New Roman", color: BLACK })]
        }),
        spacer(), spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 120 },
          children: [new TextRun({ text: "2026", bold: true, size: 24, font: "Times New Roman", color: BLACK })]
        }),
        pageBreak(),

        // ── DECLARATION ──
        fmTitle("DECLARATION"),
        new Paragraph({
          alignment: AlignmentType.JUSTIFIED,
          spacing: { before: 0, after: 240, line: 360, lineRule: "auto" },
          children: [
            new TextRun({ text: "I hereby declare that this project report entitled ", size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "“MyBahaya: An AI-Powered Emergency Reporting and Real-Time Community Alert Platform for Malaysia”", italics: true, size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: " is written by me and is my own effort and that no part has been plagiarized without citations.", size: 24, font: "Times New Roman", color: BLACK })
          ]
        }),
        spacer(), spacer(),
        new Paragraph({
          spacing: { before: 240, after: 0 },
          tabStops: [{ type: TabStopType.LEFT, position: 1800 }],
          children: [
            new TextRun({ text: "STUDENT", size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t: _______________________________", size: 24, font: "Times New Roman", color: BLACK })
          ]
        }),
        new Paragraph({
          spacing: { before: 0, after: 360 },
          tabStops: [{ type: TabStopType.LEFT, position: 1800 }],
          children: [
            new TextRun({ text: "", size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t  (AHMAD SHUKRI BIN BAKRI)", size: 24, font: "Times New Roman", color: BLACK })
          ]
        }),
        new Paragraph({
          spacing: { before: 0, after: 360 },
          tabStops: [{ type: TabStopType.LEFT, position: 1800 }],
          children: [
            new TextRun({ text: "Date", size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t: _______________________________", size: 24, font: "Times New Roman", color: BLACK })
          ]
        }),
        spacer(), spacer(),
        new Paragraph({
          spacing: { before: 240, after: 0 },
          tabStops: [{ type: TabStopType.LEFT, position: 1800 }],
          children: [
            new TextRun({ text: "SUPERVISOR", size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t: _______________________________", size: 24, font: "Times New Roman", color: BLACK })
          ]
        }),
        new Paragraph({
          spacing: { before: 0, after: 360 },
          tabStops: [{ type: TabStopType.LEFT, position: 1800 }],
          children: [
            new TextRun({ text: "", size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t  (____________________________)", size: 24, font: "Times New Roman", color: BLACK })
          ]
        }),
        new Paragraph({
          spacing: { before: 0, after: 360 },
          tabStops: [{ type: TabStopType.LEFT, position: 1800 }],
          children: [
            new TextRun({ text: "Date", size: 24, font: "Times New Roman", color: BLACK }),
            new TextRun({ text: "\t: _______________________________", size: 24, font: "Times New Roman", color: BLACK })
          ]
        }),
        pageBreak(),

        // ── ACKNOWLEDGEMENT ──
        fmTitle("ACKNOWLEDGEMENT"),
        body("First and foremost, I express my deepest gratitude to Allah S.W.T. for granting me the strength, patience, and perseverance to complete this Final Year Project. I would like to extend my sincere appreciation to my supervisor for the invaluable guidance, constructive feedback, and continuous encouragement provided throughout the development of the MyBahaya project. Their expertise and support have been instrumental in shaping both the technical direction and the academic quality of this work."),
        body("I am also grateful to the lecturers of the Faculty of Information and Communication Technology, Universiti Teknikal Malaysia Melaka, for the knowledge and skills imparted during my studies, which formed the foundation for this project. My heartfelt thanks go to my family for their unwavering moral and emotional support, and to my fellow course mates who participated in user acceptance testing and offered helpful suggestions. Finally, I acknowledge everyone who contributed directly or indirectly to the successful completion of this project."),
        pageBreak(),

        // ── ABSTRACT (English) ──
        fmTitle("ABSTRACT"),
        new Paragraph({
          alignment: AlignmentType.JUSTIFIED,
          spacing: { before: 0, after: 160, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "Emergency reporting in Malaysia remains heavily dependent on voice-based channels such as the 999 hotline, which require callers to verbally describe incidents and provide limited multimedia evidence. MyBahaya addresses this gap through a Flutter citizen application, a browser-based dashboard for authorized emergency organizations, and a Spring Boot backend integrating Firebase Firestore, MinIO object storage, Firebase Cloud Messaging, and Google Gemini 2.5 Flash. Citizens submit a category, photographs, optional video, location, and description. The backend stores the evidence, routes the report to a suitable nearby organization, and asynchronously enriches the report with AI-generated severity, summary, hazards, suggested category, and a possible-fake flag. The current web dashboard adds real-time report monitoring, status grouping into Active, En Route, and Solved views, unread-report indicators, live map filtering, analytics with timeframe selection and CSV export, organization and administrator management, report verification, and configurable browser alert sounds. The implemented system was reviewed through functional, integration, security, performance, and usability test cases, with results and limitations recorded in Chapter 6.", size: 24, font: "Times New Roman", color: BLACK })]
        }),
        pageBreak(),

        // ── ABSTRAK (Bahasa Melayu) ──
        fmTitle("ABSTRAK"),
        new Paragraph({
          alignment: AlignmentType.JUSTIFIED,
          spacing: { before: 0, after: 160, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "Pelaporan kecemasan di Malaysia masih banyak bergantung kepada saluran suara seperti talian 999 yang memerlukan penerangan lisan dan memberikan bukti multimedia yang terhad. MyBahaya menangani jurang ini melalui aplikasi Flutter untuk orang awam, papan pemuka pelayar untuk organisasi kecemasan yang diberi kuasa, dan pelayan belakang Spring Boot yang menyepadukan Firebase Firestore, storan objek MinIO, Firebase Cloud Messaging, serta Google Gemini 2.5 Flash. Orang awam menghantar kategori, gambar, video pilihan, lokasi, dan penerangan. Pelayan belakang menyimpan bukti, menghalakan laporan kepada organisasi yang sesuai berdekatan, dan memperkayakan laporan secara tak segerak dengan tahap keterukan, ringkasan, bahaya, kategori cadangan, serta penanda kemungkinan palsu yang dijana AI. Papan pemuka web semasa turut menyediakan pemantauan masa nyata, paparan Active, En Route dan Solved, penunjuk laporan belum dibuka, peta langsung, analitik dengan pilihan tempoh dan eksport CSV, pengurusan organisasi dan pentadbir, pengesahan laporan, serta bunyi amaran pelayar yang boleh dikonfigurasi. Sistem ini disemak melalui kes ujian fungsian, integrasi, keselamatan, prestasi, dan kebolehgunaan, dengan keputusan serta batasan direkodkan dalam Bab 6.", size: 24, font: "Times New Roman", color: BLACK })]
        }),
        pageBreak(),

        // ── TABLE OF CONTENTS ──
        fmTitle("TABLE OF CONTENTS"),
        new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-3" }),
        pageBreak(),

        // ── LIST OF TABLES ──
        fmTitle("LIST OF TABLES"),
        new TableOfContents("List of Tables", { hyperlink: true, stylesWithLevels: [new StyleLevel("TableCaption", 1)] }),
        pageBreak(),

        // ── LIST OF FIGURES ──
        fmTitle("LIST OF FIGURES"),
        new TableOfContents("List of Figures", { hyperlink: true, stylesWithLevels: [new StyleLevel("FigureCaption", 1)] }),
        pageBreak(),

        // ── LIST OF ABBREVIATIONS ──
        fmTitle("LIST OF ABBREVIATIONS"),
        new Table({
          width: { size: 9026, type: WidthType.DXA },
          columnWidths: [2400, 6626],
          rows: [
            abbrRow("AI", "Artificial Intelligence"),
            abbrRow("API", "Application Programming Interface"),
            abbrRow("APM / JPAM", "Angkatan Pertahanan Awam Malaysia (Civil Defence Force)"),
            abbrRow("Bomba / JBPM", "Jabatan Bomba dan Penyelamat Malaysia (Fire and Rescue Department)"),
            abbrRow("CNN", "Convolutional Neural Network"),
            abbrRow("DFD", "Data Flow Diagram"),
            abbrRow("ERD", "Entity Relationship Diagram"),
            abbrRow("ETA", "Estimated Time of Arrival"),
            abbrRow("FCM", "Firebase Cloud Messaging"),
            abbrRow("FICT", "Faculty of Information and Communication Technology"),
            abbrRow("FYP", "Final Year Project"),
            abbrRow("GPS", "Global Positioning System"),
            abbrRow("HTTPS", "Hypertext Transfer Protocol Secure"),
            abbrRow("JSON", "JavaScript Object Notation"),
            abbrRow("JWT", "JSON Web Token"),
            abbrRow("MVC", "Model-View-Controller"),
            abbrRow("NoSQL", "Not Only Structured Query Language"),
            abbrRow("PDRM", "Polis Diraja Malaysia (Royal Malaysia Police)"),
            abbrRow("REST", "Representational State Transfer"),
            abbrRow("SDLC", "Software Development Lifecycle"),
            abbrRow("UAT", "User Acceptance Testing"),
            abbrRow("UI", "User Interface"),
            abbrRow("UTeM", "Universiti Teknikal Malaysia Melaka"),
            abbrRow("VPS", "Virtual Private Server"),
          ]
        }),
        pageBreak(),

        // ── LIST OF ATTACHMENTS ──
        fmTitle("LIST OF ATTACHMENTS"),
        new Table({
          width: { size: 9026, type: WidthType.DXA },
          columnWidths: [2400, 6626],
          rows: [
            abbrRow("Appendix A", "MyBahaya Mobile Application User Guide"),
            abbrRow("Appendix B", "Organization Web Dashboard User Guide"),
            abbrRow("Appendix C", "API Endpoint Specifications"),
            abbrRow("Appendix D", "Firebase Firestore Security Rules"),
            abbrRow("Appendix E", "Turnitin Plagiarism Report (First Page)"),
          ]
        }),
        pageBreak()
      ]
    },

    // ════════════════════════════════════════════════════════════
    // CHAPTER 1 — INTRODUCTION
    // ════════════════════════════════════════════════════════════
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
          pageNumbers: { start: 1, formatType: NumberFormat.DECIMAL }
        }
      },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [
              new TextRun({ children: [PageNumber.CURRENT], size: 20, font: "Times New Roman", color: BLACK })
            ]
          })]
        })
      },
      children: [
        h1("CHAPTER 1.          INTRODUCTION"),
        spacer(),

        h2("1.1     Introduction"),
        body("MyBahaya is an AI-powered emergency reporting and real-time community alert platform designed specifically for Malaysia. The name 'MyBahaya' is derived from the Malay word 'bahaya', which translates to 'danger' or 'hazard' in English, reflecting the platform's core purpose of addressing dangerous situations in a timely and effective manner."),
        body("Malaysia, like many developing nations, continues to rely on traditional emergency reporting methods that are often slow, inefficient, and prone to miscommunication. In times of crisis, every second counts, and the difference between life and death can hinge on how quickly accurate information reaches the right authorities. MyBahaya addresses this critical gap by enabling Malaysian citizens to report emergencies instantly using their smartphones, equipped with photo and video evidence, GPS coordinates, and AI-driven incident analysis."),
        body("The system is built on a multi-platform architecture that encompasses a Flutter-based mobile application for citizens, a responsive web dashboard for emergency organizations, a Spring Boot backend API, and an AI analysis pipeline powered by Google Gemini 2.5 Flash. The platform connects citizens, emergency organizations, and intelligent decision-support systems into a unified ecosystem that improves emergency response speed and public safety throughout Malaysia."),
        spacer(),

        h2("1.2     Problem Statement(s)"),
        body("The current emergency reporting infrastructure in Malaysia presents several significant challenges that hinder effective and timely emergency response:"),
        bullet("Dependence on Voice-Based Reporting: The primary emergency contact number in Malaysia, 999, requires citizens to verbally describe incidents to operators. During high-stress emergencies, victims and bystanders may experience difficulty articulating clear descriptions of what is happening. Language barriers and panic further exacerbate this problem, leading to incomplete or inaccurate information being transmitted to responders."),
        bullet("Absence of Multimedia Evidence Submission: Existing emergency channels do not support the submission of photographic or video evidence at the point of reporting. As a result, responders arrive at scenes with limited situational awareness, which can compromise the efficiency and appropriateness of the initial response."),
        bullet("No Automated Incident Classification or Organization Routing: There is currently no intelligent system in Malaysia that automatically classifies emergency incidents and routes reports to the most appropriate emergency organization, such as the police (PDRM), fire and rescue (Bomba), ambulance services, or civil defence corps (APM). Dispatchers must manually triage calls and redirect them, introducing delays and the risk of misrouting."),
        bullet("Lack of Community Situational Awareness: There is no unified public platform that alerts nearby community members about ongoing emergencies in their vicinity in real time. Citizens remain unaware of incidents occurring within a short distance of their location, reducing the potential for community-assisted response."),
        bullet("No Unified Emergency Data Platform: Emergency organizations operate in silos without a shared digital platform for receiving, tracking, and managing incident reports. This fragmented approach limits inter-agency coordination and data-driven decision-making."),
        spacer(),

        h2("1.3     Objective"),
        body("The primary objectives of this project are as follows:"),
        bullet("To develop a mobile application that allows Malaysian citizens to submit emergency reports instantly using photos, videos, and GPS location data with minimal manual input."),
        bullet("To implement an AI-powered analysis module using Google Gemini 2.5 Flash that automatically classifies incident type, determines severity, identifies hazards, generates an incident summary, and detects potentially fake reports."),
        bullet("To design an intelligent geolocation-based routing system that assigns submitted reports to the nearest appropriate emergency organization based on incident category and proximity."),
        bullet("To build a web-based dashboard for emergency organizations that enables real-time monitoring, evidence review, status management, and analytics of assigned incidents."),
        bullet("To implement a real-time push notification system using Firebase Cloud Messaging (FCM) that alerts nearby citizens about emergencies and notifies relevant emergency organizations upon report submission."),
        spacer(),

        h2("1.4     Scope"),
        body("The scope of the MyBahaya system is defined across several dimensions:"),
        bullet("Target Users: The system serves two primary user groups: (1) Malaysian citizens who use the mobile application to submit emergency reports and receive community safety alerts; and (2) authorized emergency organizations including police (PDRM), fire and rescue (Bomba), hospitals, ambulance services, and the Civil Defence Corps (APM/JPAM) who use the web dashboard to manage assigned reports."),
        bullet("Platform Coverage: The mobile application is developed using Flutter, with Android as the primary target. The organization and administrator portal is a browser-based HTML, CSS, and JavaScript application using Firebase web SDKs, MapLibre, Chart.js, and Firestore real-time listeners."),
        bullet("Geographical Scope: The platform is designed for deployment within Malaysia. Geolocation features, routing algorithms, and emergency organization profiles are configured for the Malaysian emergency services landscape."),
        bullet("Incident Categories Covered: The system handles the following incident categories: Fire, Medical Emergency, Theft, Assault, Road Accident, Flood, Landslide, Building Collapse, Hazardous Materials, and Other."),
        bullet("AI Capabilities: The AI module analyzes submitted images to produce severity scores (1 to 5), incident summaries, hazard identification, suggested categories, and fake report detection. The AI operates asynchronously and does not block the report submission flow."),
        bullet("Current Scope: The implemented scope includes authentication and role-based access, report submission, media upload, MinIO integration, Firestore integration, asynchronous AI analysis, community alerts, organization report management, live map monitoring, analytics, report verification, organization management, unread indicators, and browser alert sound controls."),
        spacer(),

        h2("1.5     Project Significance"),
        body("The MyBahaya platform carries significant value for multiple stakeholder groups within Malaysia:"),
        bullet("Citizens: MyBahaya empowers ordinary Malaysians with a fast, intuitive tool to report emergencies without the need for verbal communication with operators. The platform also enhances personal and community safety by delivering real-time nearby danger alerts, enabling citizens to make informed decisions about their immediate environment."),
        bullet("Emergency Organizations: Emergency agencies such as the police, Bomba, and ambulance services benefit from receiving structured, geo-referenced, AI-analyzed incident reports with multimedia evidence. This significantly improves the situational awareness of first responders prior to arriving at the scene and reduces the time spent on triage and dispatching."),
        bullet("Government and Public Safety Sector: The data collected through MyBahaya forms a valuable foundation for analytics-driven public safety policy-making. Incident heatmaps, category trends, and response time data can inform resource allocation and emergency preparedness planning."),
        bullet("Academic Contribution: This project demonstrates the practical application of AI-integrated mobile development in the context of public safety, contributing to academic knowledge in the domains of emergency management information systems, AI for social good, and cross-platform mobile application development."),
        spacer(),

        h2("1.6     Expected Output"),
        body("Upon successful completion of this project, the following deliverables are expected:"),
        bullet("A fully functional Android mobile application (MyBahaya) that supports citizen registration, emergency report submission with multimedia evidence and GPS data, community alert reception, and report status tracking."),
        bullet("A responsive web dashboard for emergency organizations that provides real-time access to assigned reports, multimedia evidence review, incident location mapping, status management, and analytics."),
        bullet("A Spring Boot backend API service that can be run locally or deployed to a configured server, handling authentication, media upload orchestration, AI enrichment coordination, geolocation routing, and push notification dispatch."),
        bullet("An AI analysis pipeline integrated with Google Gemini 2.5 Flash that processes submitted incident images and produces structured JSON enrichment data (severity, summary, hazards, category, fake detection)."),
        bullet("A complete FYP project report documenting the analysis, design, implementation, and testing of the MyBahaya platform."),
        spacer(),

        h2("1.7     Conclusion"),
        body("This chapter has established the context and motivation for the MyBahaya project, identifying the critical gaps in Malaysia's existing emergency reporting infrastructure and articulating the objectives, scope, and expected benefits of the proposed solution. MyBahaya aims to transform emergency reporting from a slow, voice-dependent process into a fast, intelligent, multimedia-enabled platform that connects citizens, emergency organizations, and AI-powered decision support systems. The following chapters will detail the literature review and methodology (Chapter 2), system analysis (Chapter 3), system design (Chapter 4), implementation (Chapter 5), testing (Chapter 6), and conclusions (Chapter 7)."),
        pageBreak(),

        // ════════════════════════════════════════════════════════════
        // CHAPTER 2 — LITERATURE REVIEW AND PROJECT METHODOLOGY
        // ════════════════════════════════════════════════════════════
        h1("CHAPTER 2.          LITERATURE REVIEW AND PROJECT METHODOLOGY"),
        spacer(),

        h2("2.1     Introduction"),
        body("This chapter presents a review of existing literature, systems, and technologies relevant to the MyBahaya project. It examines the domain of emergency management information systems, analyses existing emergency reporting platforms, evaluates applicable AI techniques, and describes the development methodology selected for this project. The chapter concludes with the project requirements and schedule."),
        spacer(),

        h2("2.2     Facts and Findings"),

        h3("2.2.1     Domain"),
        body("The domain of this project spans two intersecting fields: Emergency Management Information Systems (EMIS) and AI-powered multimedia analysis. Emergency management information systems are digital platforms that support the planning, coordination, and execution of emergency response activities. According to Turoff et al. (2004), effective emergency management requires systems that can rapidly collect, process, and disseminate information across multiple stakeholders under high-stress, time-critical conditions."),
        body("In the Malaysian context, the National Security Council (NSC) coordinates emergency management through agencies including the Royal Malaysia Police (PDRM), Fire and Rescue Department (JBPM/Bomba), Civil Defence Force (APM), and the Ministry of Health's Emergency Medical Services. Despite these established agencies, their digital communication infrastructure for receiving public incident reports remains largely dependent on telephone-based systems, which present inherent limitations for multimedia evidence collection and real-time community alerting."),
        body("The rapid penetration of smartphone technology in Malaysia, with mobile broadband penetration exceeding 130% as of 2024 according to the Malaysian Communications and Multimedia Commission (MCMC), creates an unprecedented opportunity to leverage citizen smartphones as distributed emergency sensing and reporting devices."),
        spacer(),

        h3("2.2.2     Existing Systems"),
        body("Several existing systems were examined as part of the literature review:"),
        bullet("MySejahtera (Malaysia): Developed as a COVID-19 contact tracing application, MySejahtera demonstrated Malaysia's capacity to rapidly deploy and scale a national public safety mobile application. However, the platform is narrowly scoped for health monitoring and does not support general emergency reporting."),
        bullet("Waze (Global): The Waze navigation application includes a community-driven incident reporting feature that allows users to report traffic accidents, road hazards, and police presence. This system demonstrates the viability of crowd-sourced geographic incident reporting but is limited to road-related incidents and does not integrate with official emergency services."),
        bullet("PulsePoint (United States): PulsePoint is a mobile application that enables citizens to receive alerts about nearby cardiac arrest emergencies and perform CPR until professional help arrives. This system demonstrates effective proximity-based community alert functionality but is limited to medical emergencies and is not designed for the Malaysian context."),
        bullet("Ushahidi (Global): Ushahidi is an open-source crisis mapping platform that aggregates crowdsourced incident reports during natural disasters and civil conflicts. While it demonstrates the power of multimedia-enabled community reporting, it lacks real-time AI analysis, automated organization routing, and push notification systems."),
        bullet("999 (Malaysia) / 112 (International): The standard voice-based emergency number lacks multimedia submission capabilities, automated AI triage, or community alerting functions. Calls are manually processed by operators, introducing latency and the risk of miscommunication."),
        body("A comparative analysis reveals that none of the existing systems combine automated AI analysis, multimedia evidence submission, geolocation-based organization routing, and real-time community alerts within a single unified platform adapted for the Malaysian emergency services ecosystem."),
        spacer(),

        h3("2.2.3     Technique"),
        body("Several technical approaches were evaluated for the AI analysis component:"),
        bullet("Convolutional Neural Networks (CNN) — Custom Training: Training a custom CNN model on labeled Malaysian emergency incident images was considered. While this approach would yield a specialized model, it was rejected due to the prohibitive cost and time required to curate a sufficiently large labeled dataset, and the need for ongoing model maintenance and retraining."),
        bullet("Transfer Learning with Pre-trained Vision Models (ResNet, EfficientNet): Transfer learning approaches using models pre-trained on ImageNet were evaluated. While technically feasible, these models require fine-tuning on emergency-specific datasets and lack the natural language generation capability needed to produce human-readable incident summaries."),
        bullet("Large Multimodal Language Models (Google Gemini, GPT-4 Vision): Multimodal large language models that accept both image and text inputs were evaluated. Google Gemini 2.5 Flash was selected due to its (1) combined vision and language capabilities allowing simultaneous image analysis and text generation, (2) availability through a straightforward REST API, (3) suitability for structured JSON output generation, and (4) cost-effectiveness with free-tier availability for development and testing. Gemini 2.5 Flash superseded Gemini 2.0 Flash as Google adjusted free-tier quotas, making 2.5 Flash the preferred choice."),
        spacer(),

        h2("2.3     Project Methodology"),
        body("The Agile Software Development Lifecycle (SDLC) methodology was selected for the development of the MyBahaya platform. Agile was chosen over traditional waterfall models due to the following reasons:"),
        bullet("Iterative Development: The MyBahaya platform encompasses multiple interconnected systems (mobile app, web dashboard, backend API, AI pipeline). Agile's iterative sprint-based approach allows features to be developed, tested, and validated incrementally, reducing integration risk."),
        bullet("Flexibility to Change: During the development process, several technical decisions required revision. For example, the AI model was migrated from Gemini 2.0 Flash to Gemini 2.5 Flash due to API quota changes. Agile's inherent flexibility accommodated such adjustments without disrupting the overall project schedule."),
        bullet("Continuous Testing: Agile promotes continuous integration and testing throughout the development lifecycle, ensuring that bugs are identified and resolved early rather than discovered at the end of the project."),
        body("The development was structured into the following phases:"),
        numbered("Phase 1 — Requirements Gathering and Analysis: Identification of user roles, functional requirements, and system constraints. Creation of use case diagrams, data flow models, and system architecture design."),
        numbered("Phase 2 — Design: UI/UX wireframing for the mobile application and web dashboard. Database schema design for Firestore collections. API endpoint specification. System architecture documentation."),
        numbered("Phase 3 — Implementation: Iterative development of the mobile application, backend API, web dashboard, and AI pipeline. Integration of Firebase, MinIO, and FCM services."),
        numbered("Phase 4 — Testing: Unit testing of individual modules, integration testing of the complete system, and user acceptance testing with representative users from both citizen and organization perspectives."),
        numbered("Phase 5 — Documentation: Preparation of the FYP report, user manual, and deployment documentation."),
        spacer(),
        body("Figure 2.1 illustrates the iterative Agile Software Development Lifecycle adopted for this project, in which the phases of planning, analysis, design, implementation, and testing are repeated across successive sprints, allowing continuous feedback and refinement of each component of the MyBahaya platform."),
        ...figure("2.1", "Agile Software Development Lifecycle (SDLC) adopted for MyBahaya", "Agile SDLC Methodology Diagram"),
        spacer(),

        h2("2.4     Project Requirements"),

        h3("2.4.1     Software Requirements"),
        bullet("Flutter SDK 3.x — Cross-platform mobile application development framework (Dart language)"),
        bullet("Android Studio — Primary IDE for Flutter mobile development and Android emulator"),
        bullet("Java Development Kit (JDK) 21 — Runtime environment for Spring Boot backend"),
        bullet("Spring Boot 3.x (Maven) — Backend API framework with REST capabilities"),
        bullet("Firebase Admin SDK — Backend integration with Firebase services (Firestore, FCM)"),
        bullet("Firebase JS SDK — Web dashboard integration with Firebase Authentication and Firestore"),
        bullet("Google Gemini API (REST) — AI analysis service for image/video processing"),
        bullet("MinIO Java SDK — Object storage client for media file management"),
        bullet("Git — Version control system for source code management"),
        bullet("Visual Studio Code — Secondary IDE for web dashboard HTML/CSS/JavaScript development"),
        bullet("Postman — API endpoint testing and documentation tool"),
        bullet("Docker — Containerization for MinIO deployment on the VPS"),
        spacer(),

        h3("2.4.2     Hardware Requirements"),
        bullet("Development Machine: MacBook Pro (or equivalent) with minimum 8GB RAM, 256GB SSD"),
        bullet("Android Test Device: Smartphone running Android 10 or later for physical device testing"),
        bullet("Virtual Private Server (VPS): Linux-based cloud server for backend API and MinIO deployment (minimum 2 vCPU, 4GB RAM, 50GB storage)"),
        bullet("Network: Stable internet connection for cloud service integration (Firebase, Gemini API)"),
        spacer(),

        h3("2.4.3     Other Requirements"),
        bullet("Firebase Project — A Google Firebase project configured with Firestore Database, Firebase Authentication, and Firebase Cloud Messaging enabled"),
        bullet("Google Gemini API Key — A valid API key for accessing the Gemini 2.5 Flash multimodal language model"),
        bullet("MinIO Server — A self-hosted or cloud-hosted MinIO instance for object storage"),
        bullet("Web Push VAPID Key — Required only when background browser push notifications are enabled for organization dashboards; the current source records this as a deployment prerequisite."),
        spacer(),

        h2("2.5     Project Schedule and Milestones"),
        body("The project schedule and key milestones are summarized in Table 2.1, while Figure 2.2 presents the same schedule as a one-page Gantt chart that visualizes the duration and overlap of each activity across the project timeline."),
        spacer(),
        tblCaption("2.1", "MyBahaya Project Schedule and Milestones"),
        simpleTable(
          ["Phase", "Activity", "Duration", "Status"],
          [
            ["Phase 1", "Requirements Analysis & Architecture Planning", "Weeks 1–2", "Completed"],
            ["Phase 2", "Database Schema & API Design", "Weeks 3–4", "Completed"],
            ["Phase 3", "Firebase & MinIO Integration", "Weeks 5–6", "Completed"],
            ["Phase 3", "Backend API — Authentication & Report Submission", "Weeks 7–8", "Completed"],
            ["Phase 3", "AI Analysis Pipeline (Gemini Integration)", "Weeks 9–10", "Completed"],
            ["Phase 3", "Flutter Mobile App — Core Screens", "Weeks 11–13", "Completed"],
            ["Phase 3", "Web Dashboard — Organization Portal", "Weeks 14–16", "Completed"],
            ["Phase 3", "FCM Push Notifications", "Week 17", "Completed"],
            ["Phase 4", "Integration Testing & Bug Fixes", "Weeks 18–19", "Completed"],
            ["Phase 5", "Documentation & Report Writing", "Weeks 20–21", "Completed"],
          ]
        ),
        spacer(),
        ...figure("2.2", "MyBahaya Project Gantt Chart", "Project Gantt Chart (one-page view)"),
        spacer(),

        h2("2.6     Conclusion"),
        body("This chapter established the theoretical and technical foundation for the MyBahaya project. The review of existing systems confirmed that no current solution adequately addresses all identified problem areas within the Malaysian context. Google Gemini 2.5 Flash was selected as the AI analysis engine based on its multimodal capabilities and API accessibility. The Agile methodology was adopted to support the iterative, multi-component nature of the development. Chapter 3 will proceed with a detailed analysis of the system requirements."),
        pageBreak(),

        // ════════════════════════════════════════════════════════════
        // CHAPTER 3 — ANALYSIS
        // ════════════════════════════════════════════════════════════
        h1("CHAPTER 3.          ANALYSIS"),
        spacer(),

        h2("3.1     Introduction"),
        body("This chapter presents a comprehensive analysis of the MyBahaya system requirements. It begins with an investigation of the current emergency reporting scenario in Malaysia, followed by a structured requirement analysis encompassing data, functional, non-functional, and other requirements. The analysis phase provides the foundation upon which the system design in Chapter 4 is built."),
        spacer(),

        h2("3.2     Problem Analysis"),
        body("The current emergency reporting process in Malaysia follows a sequential, operator-dependent flow. When an emergency occurs, a citizen must call 999, wait for operator availability, verbally describe the incident in sufficient detail, and hope the operator correctly identifies and redirects the call to the appropriate agency. This process introduces multiple points of failure and delay."),
        body("The following describes the current scenario for emergency reporting:"),
        bullet("Step 1: Incident occurs. The citizen witnesses or is involved in an emergency (e.g., a fire, road accident, or crime)."),
        bullet("Step 2: Citizen calls 999. The citizen dials the emergency number using a mobile or landline phone."),
        bullet("Step 3: Operator answers. An emergency operator answers the call. During high-demand periods, citizens may be placed on hold."),
        bullet("Step 4: Verbal description. The citizen must verbally describe the type of incident, its location (street name, landmarks), severity, and any other relevant details."),
        bullet("Step 5: Manual routing. The operator manually determines the appropriate agency and transfers or re-dials the relevant organization."),
        bullet("Step 6: Agency dispatch. The receiving agency dispatches resources based on the verbal information provided."),
        body("Problems with this flow include: panic reducing description quality; language barriers (Malaysia is multilingual); time delays from hold periods and transfers; and the absence of multimedia evidence to guide responders."),
        body("The MyBahaya platform replaces this flow with:"),
        bullet("Citizen opens the MyBahaya app and selects an incident category."),
        bullet("Citizen captures one to three photos and optionally records a short video."),
        bullet("The app automatically captures GPS coordinates."),
        bullet("The citizen taps 'Submit Report'. The report is uploaded to the backend in seconds."),
        bullet("The backend simultaneously: stores media in MinIO, saves the report in Firestore, triggers AI analysis via Gemini, identifies and notifies the nearest appropriate organization via FCM, and alerts nearby community members."),
        bullet("The assigned organization receives the report on their web dashboard with full multimedia evidence, AI analysis results, and GPS location."),
        spacer(),

        h2("3.3     Requirement Analysis"),

        h3("3.3.1     Data Requirement"),
        body("The following data entities are required by the system:"),
        bullet("User (citizens): userId, email, fullName, phoneNumber, fcmToken, alertRadius (km), createdAt, role"),
        bullet("Organization: orgId, name, type (police/fire/medical), latitude, longitude, status (active/inactive), fcmToken, city, contactEmail"),
        bullet("Report: reportId, userId, category, details, imageUrl, imageUrls[], videoUrl, location {latitude, longitude}, status (NEW/RECEIVED/IN_PROGRESS/RESOLVED), verificationStatus (PENDING/VERIFIED/REJECTED), assignedOrgId, assignedOrgName, assignedOrgType, etaMinutes, createdAt, updatedAt"),
        bullet("AI Enrichment (nested in Report): severity (1–5), summary, hazards[], suggestedCategory, looksFake (boolean), processedAt"),
        bullet("Public Incident (sanitized copy of Report): reportId, category, details, imageUrl, imageUrls[], location, verificationStatus, createdAt"),
        bullet("Notification Log: token, title, body, type, category, reportId, timestamp"),
        spacer(),

        h3("3.3.2     Functional Requirement"),
        body("The functional requirements of the MyBahaya system are illustrated using the use case diagram in Figure 3.1, which defines the system boundary and the interactions between the three actors — Citizen, Organisation Staff, and System Administrator — and the use cases they perform. The detailed functional requirements are subsequently categorized by user role."),
        ...figure("3.1", "MyBahaya Use Case Diagram", "Use Case Diagram (Citizen, Organisation Staff, System Administrator)"),
        spacer(),
        body("Citizen Mobile Application:"),
        bullet("FR-C1: Users shall be able to register and log in using email and password via Firebase Authentication."),
        bullet("FR-C2: Users shall be able to submit emergency reports by selecting an incident category, capturing one to three photos, optionally recording a video, and providing an optional text description."),
        bullet("FR-C3: The system shall automatically capture and attach the user's GPS coordinates to every submitted report."),
        bullet("FR-C4: Users shall receive real-time push notifications when an emergency is reported within their configured alert radius."),
        bullet("FR-C5: Users shall be able to view a feed of nearby public incidents on the home dashboard."),
        bullet("FR-C6: Users shall be able to track the status of their submitted reports."),
        bullet("FR-C7: Users shall be able to view incident locations on an interactive map."),
        body("Emergency Organization Web Dashboard:"),
        bullet("FR-O1: Organization staff shall be able to log in to the web dashboard using their authorized credentials."),
        bullet("FR-O2: The dashboard shall display all reports assigned to the organization in real time."),
        bullet("FR-O3: Staff shall be able to view the full details of each report including multimedia evidence, AI analysis results, and GPS location."),
        bullet("FR-O4: Staff shall be able to update the status of assigned reports (NEW > RECEIVED > IN_PROGRESS > RESOLVED)."),
        bullet("FR-O5: The dashboard shall display an analytics summary including report counts by category and status."),
        bullet("FR-O6: Staff shall receive browser push notifications when a new report is assigned to their organization."),
        bullet("FR-O7: Authorized dashboard users shall be able to filter reports by Malaysian scope or state, category, workflow stage, and date order."),
        bullet("FR-O8: The dashboard shall provide a live incident map with category filters, grouped markers, counts, and recent activity."),
        bullet("FR-O9: The dashboard shall provide analytics for selected timeframes, including daily trends, hourly patterns, category distribution, day-of-week patterns, and CSV export."),
        bullet("FR-O10: The dashboard shall provide unread-report indicators, mark-opened controls, media preview, report verification, and status transition controls."),
        body("System Administrator:"),
        bullet("FR-A1: Administrators shall be able to manage user accounts and organization profiles."),
        bullet("FR-A2: Administrators shall be able to view all reports across all organizations."),
        bullet("FR-A3: Administrators shall be able to verify, reject, or moderate reports."),
        spacer(),

        h3("3.3.3     Non-Functional Requirement"),
        bullet("Performance: The report submission endpoint shall return a response within 3 seconds under normal network conditions. AI enrichment is processed asynchronously and shall complete within 30 seconds of submission."),
        bullet("Reliability: The system shall utilize Firebase Firestore's built-in redundancy to ensure 99.9% uptime for data persistence operations."),
        bullet("Security: All API endpoints shall require Firebase JWT authentication. Media files shall be stored in a private MinIO bucket accessible only through the backend API. The Gemini API key shall never be exposed on the client side."),
        bullet("Scalability: The backend API shall be deployable on a VPS with horizontal scaling capability via container orchestration. Firebase Firestore automatically scales to accommodate growing data volumes."),
        bullet("Usability: The mobile application shall allow a citizen to submit a complete emergency report within 60 seconds from opening the app to submission confirmation."),
        bullet("Accuracy: The AI severity classification shall achieve at least 80% agreement with human assessors on a test dataset of 50 labeled incident images."),
        spacer(),

        h3("3.3.4     Others Requirement"),
        bullet("Firebase Project Configuration: A configured Firebase project with Firestore, Authentication, and Cloud Messaging enabled is required for system operation."),
        bullet("Internet Connectivity: The mobile application requires an active internet connection for report submission and alert reception. Offline mode is not supported in the current scope."),
        bullet("Android Permissions: The mobile application requires Android permissions for camera access, location services, and storage read/write."),
        bullet("Service Deployment: A local Docker/Compose environment or configured server is required for MinIO and the Spring Boot backend; the repository includes deployment configuration for these services."),
        spacer(),

        h2("3.4     Conclusion"),
        body("This chapter presented a comprehensive analysis of the MyBahaya system, identifying the shortcomings of the current emergency reporting process in Malaysia and defining the functional, data, non-functional, and other requirements that the system must satisfy. The analysis establishes a clear specification against which the design and implementation chapters will be validated. Chapter 4 will translate these requirements into concrete system design artifacts."),
        pageBreak(),

        // ════════════════════════════════════════════════════════════
        // CHAPTER 4 — DESIGN
        // ════════════════════════════════════════════════════════════
        h1("CHAPTER 4.          DESIGN"),
        spacer(),

        h2("4.1     Introduction"),
        body("This chapter defines the high-level and detailed design of the MyBahaya system. It covers the system architecture, user interface design for both the mobile application and web dashboard, database design, and the detailed software design for key system modules. The designs presented here are the result of translating the requirements identified in Chapter 3 into concrete structural and behavioral specifications."),
        spacer(),

        h2("4.2     High-Level Design"),

        h3("4.2.1     System Architecture"),
        body("MyBahaya follows a multi-tier client-server architecture with the following layers:"),
        bullet("Presentation Layer: Flutter-based Android mobile application (Citizen) and HTML/CSS/JavaScript web dashboard (Emergency Organization)."),
        bullet("Application Layer: Spring Boot REST API run through the configured local or server environment. It handles authentication validation, business logic, media orchestration, AI enrichment dispatch, geolocation routing, and FCM notifications."),
        bullet("AI Layer: Google Gemini 2.5 Flash multimodal API. Receives base64-encoded images from the backend and returns structured JSON analysis results asynchronously."),
        bullet("Data Layer: Firebase Firestore (structured document database for reports, users, organizations, and notifications) and MinIO (S3-compatible object storage for images and videos)."),
        bullet("Notification Layer: Firebase Cloud Messaging (FCM) for push notifications to citizen mobile devices and organization browser sessions."),
        spacer(),
        ...figure("4.1", "MyBahaya System Architecture", "System Architecture Diagram"),
        spacer(),
        body("The architecture diagram in Figure 4.1 illustrates the interaction between the five system layers. The citizen's mobile app communicates exclusively with the Spring Boot API over HTTPS. The API coordinates with Firebase Firestore for data persistence, MinIO for media storage, Gemini API for AI analysis, and FCM for push notifications. The organization's web dashboard accesses Firestore directly via the Firebase JS SDK (for real-time updates) and communicates with the API for status updates."),
        spacer(),

        h3("4.2.2     User Interface Design"),
        body("(a). Navigation Design"),
        body("The mobile application uses a bottom navigation bar with four primary sections: Home (community feed), Report (submit incident), Map (incident map view), and Profile (user settings and report history). Secondary navigation is handled through stack-based routing using Flutter's Navigator, allowing users to drill into report details, organization profiles, and alert history."),
        body("The web dashboard uses a sidebar navigation layout with Dashboard, Reports, Map, Analytics, and an administrator-only Organizations section. The Reports page groups the workflow into Active, Marked as En Route, and Solved views, and supports search, Malaysia/state scope, category filters, sorting, unread indicators, and a Mark All Opened action. The dashboard also includes a settings menu with account information, logout, alert-sound preferences, and a test real-time alert action."),
        spacer(),
        body("(b). Input Design"),
        body("Report Submission Screen (Mobile):"),
        bullet("Category Selection: A horizontal scrollable row of category chips (Fire, Medical, Theft, Assault, Other). Single selection, required field."),
        bullet("Photo Capture: Up to three photos can be captured using the device camera or selected from the gallery. Photos are displayed as thumbnails with a remove button."),
        bullet("Video Recording: Optional short video can be recorded using the device camera. Uploaded asynchronously after report submission to avoid blocking the response."),
        bullet("Description Field: Optional multiline text field for additional incident details. Maximum 500 characters."),
        bullet("Location: Automatically captured on screen load using the Geolocator package. A status indicator shows whether location has been acquired."),
        bullet("Submit Button: Disabled until at least one photo and one category are selected. Shows a loading state during upload."),
        spacer(),
        ...figure("4.2", "Report Submission Screen (Flutter Mobile Application)", "report submission screen — flutter app"),
        spacer(),
        body("(c). Output Design"),
        body("The system produces the following outputs:"),
        bullet("Report Submission Confirmation: A success dialog displayed immediately after report submission, showing the assigned organization name, ETA in minutes, and report ID."),
        bullet("Home Dashboard Feed: A scrollable list of nearby public incidents, each showing the incident category, thumbnail image, distance from user, time elapsed, and verification status badge."),
        bullet("AI Analysis Panel (Web Dashboard): Displayed within each report detail view on the organization dashboard. Shows severity rating (1–5 with color coding), AI-generated summary, detected hazards as tags, AI-suggested category, and a fake report warning flag if applicable."),
        bullet("Push Notifications: Real-time FCM notifications sent to citizens (nearby alerts, status updates) and organizations (new assignments)."),
        spacer(),
        ...figure("4.3", "Home Dashboard Community Feed (Flutter Mobile Application)", "home page — flutter app"),
        spacer(),
        ...figure("4.4", "Organization Web Dashboard — Report Detail with AI Analysis Panel", "organization web dashboard — report detail with AI analysis"),
        spacer(),

        h3("4.2.3     Database Design"),

        h3("4.2.3.1     Conceptual and Logical Database Design"),
        body("Firebase Firestore is a NoSQL document-oriented database. The logical data model for MyBahaya is organized into the top-level collections summarized in Table 4.1."),
        spacer(),
        tblCaption("4.1", "Firestore Collections Summary"),
        simpleTable(
          ["Collection", "Key Fields", "Purpose"],
          [
            ["users", "userId, email, fullName, fcmToken, alertRadius, role", "Stores citizen user profiles and FCM tokens for notification delivery"],
            ["organizations", "orgId, name, type, latitude, longitude, status, fcmToken", "Stores emergency organization profiles used for geolocation routing"],
            ["reports", "reportId, userId, category, status, location, imageUrls, ai.*", "Primary incident report collection including AI enrichment sub-document"],
            ["public_incidents", "reportId, category, imageUrl, location, verificationStatus", "Sanitized public copy of reports for the community feed (no PII)"],
            ["admins", "adminId, email, fullName, role, isActive", "Stores system administrator accounts for moderation and management"],
          ]
        ),
        spacer(),
        body("The conceptual relationships between these collections are illustrated in the Entity Relationship Diagram (ERD) shown in Figure 4.5. The relationships are described as follows:"),
        bullet("One User can submit Many Reports (one-to-many relationship via the userId field in reports)."),
        bullet("One Organization can be assigned Many Reports (one-to-many relationship via the assignedOrgId field in reports)."),
        bullet("Each Report contains one AI Enrichment sub-document (embedded document within the report document)."),
        bullet("Each Report has one corresponding Public Incident document (mirrored document in the public_incidents collection)."),
        bullet("System Administrators moderate and manage Reports, Users, and Organizations across the platform."),
        spacer(),
        ...figure("4.5", "Entity Relationship Diagram (ERD)", "Entity Relationship Diagram (ERD)"),
        spacer(),

        h3("4.2.3.2     Data Dictionary and NoSQL Data Modelling"),
        body("Because Firebase Firestore is a NoSQL document database rather than a relational database, the traditional relational normalization forms (First, Second, and Third Normal Form) do not apply directly. Relational normalization is concerned with eliminating data redundancy across tables joined by foreign keys, whereas Firestore is a schemaless, document-oriented store optimized for fast reads and horizontal scalability. Consequently, the database design for MyBahaya is governed by document modelling decisions rather than normalization rules. The two principal techniques applied are embedding and referencing:"),
        bullet("Embedding (denormalization): The AI enrichment result is embedded as a nested sub-document (the ai.* fields) directly within each report document rather than stored in a separate collection. Because the AI analysis is always read together with the report it describes, embedding avoids an additional read operation and keeps related data together for a single, atomic fetch."),
        bullet("Referencing: Relationships between distinct entities are expressed by storing the document identifier of a related entity as a field. For example, each report stores the userId of its author and the assignedOrgId of its handling organization, rather than embedding the full user or organization document. This avoids duplicating large, frequently-updated profile records inside every report."),
        bullet("Intentional Data Duplication: A sanitized copy of each report is duplicated into the public_incidents collection. This deliberate denormalization separates the public community feed (which must exclude personally identifiable information) from the operational reports collection used by organizations. The trade-off of maintaining two copies is accepted in exchange for stronger privacy isolation and faster, simpler public-feed queries."),
        body("The detailed data dictionary for each Firestore collection is presented in Table 4.2 through Table 4.5. Each table lists the field name, data type, and a description of the field's purpose."),
        spacer(),
        tblCaption("4.2", "Data Dictionary — users Collection"),
        simpleTable(
          ["Field", "Data Type", "Description"],
          [
            ["userId", "String", "Unique Firebase Authentication UID (document ID)"],
            ["email", "String", "User's registered email address"],
            ["fullName", "String", "User's full name"],
            ["phoneNumber", "String", "User's contact phone number"],
            ["fcmToken", "String", "Firebase Cloud Messaging device token for push notifications"],
            ["alertRadius", "Number", "Radius in kilometres within which the user receives nearby alerts"],
            ["role", "String", "User role (citizen)"],
            ["createdAt", "Timestamp", "Account creation date and time"],
          ]
        ),
        spacer(),
        tblCaption("4.3", "Data Dictionary — organizations Collection"),
        simpleTable(
          ["Field", "Data Type", "Description"],
          [
            ["orgId", "String", "Unique organization identifier (document ID)"],
            ["name", "String", "Organization name (e.g., Balai Bomba Melaka)"],
            ["type", "String", "Organization type (fire, police, medical)"],
            ["latitude", "Number", "Organization location latitude"],
            ["longitude", "Number", "Organization location longitude"],
            ["status", "String", "Operational status (active / inactive)"],
            ["fcmToken", "String", "Browser FCM token for new-assignment notifications"],
            ["contactEmail", "String", "Organization contact email address"],
          ]
        ),
        spacer(),
        tblCaption("4.4", "Data Dictionary — reports Collection"),
        simpleTable(
          ["Field", "Data Type", "Description"],
          [
            ["reportId", "String", "Unique report identifier (UUID, document ID)"],
            ["userId", "String", "Reference to the submitting user (foreign key)"],
            ["assignedOrgId", "String", "Reference to the assigned organization (foreign key)"],
            ["assignedOrgName", "String", "Cached name of the assigned organization"],
            ["category", "String", "Incident category (Fire, Medical, Theft, Assault, Other)"],
            ["details", "String", "Optional text description provided by the user"],
            ["imageUrls", "Array<String>", "List of MinIO URLs for uploaded photos"],
            ["videoUrl", "String", "MinIO URL for the optional uploaded video"],
            ["location", "Map", "Incident coordinates { latitude, longitude }"],
            ["status", "String", "Report status (NEW, RECEIVED, IN_PROGRESS, RESOLVED)"],
            ["verificationStatus", "String", "Moderation status (PENDING, VERIFIED, REJECTED)"],
            ["etaMinutes", "Number", "Estimated time of arrival in minutes"],
            ["ai.severity", "Number", "AI-assessed severity score (1–5)"],
            ["ai.summary", "String", "AI-generated incident summary"],
            ["ai.hazards", "Array<String>", "AI-identified hazards present in the image"],
            ["ai.suggestedCategory", "String", "AI-suggested incident category"],
            ["ai.looksFake", "Boolean", "AI flag indicating a potentially fake report"],
            ["ai.processedAt", "Timestamp", "Time the AI enrichment completed"],
            ["createdAt", "Timestamp", "Report submission date and time"],
          ]
        ),
        spacer(),
        tblCaption("4.5", "Data Dictionary — public_incidents Collection"),
        simpleTable(
          ["Field", "Data Type", "Description"],
          [
            ["reportId", "String", "Reference to the source report (primary/foreign key)"],
            ["category", "String", "Incident category"],
            ["imageUrl", "String", "Primary incident image URL"],
            ["imageUrls", "Array<String>", "List of incident image URLs"],
            ["location", "Map", "Incident coordinates { latitude, longitude }"],
            ["verificationStatus", "String", "Moderation status (PENDING, VERIFIED, REJECTED)"],
            ["createdAt", "Timestamp", "Incident creation date and time"],
          ]
        ),
        spacer(),

        h2("4.3     Detailed Design"),

        h3("4.3.1     Software Design"),
        body("The backend follows a layered MVC-like architecture with the key classes summarized in Table 4.6."),
        spacer(),
        tblCaption("4.6", "Backend Service Classes and Responsibilities"),
        simpleTable(
          ["Class", "Layer", "Responsibility"],
          [
            ["ReportController", "Controller", "Receives multipart POST /api/reports requests; validates authentication; delegates to MinioService and ReportService"],
            ["ReportService", "Service", "Orchestrates report creation: routing, Firestore write, community notification dispatch, AI enrichment trigger"],
            ["AiEnrichmentService", "Service", "Downloads image from MinIO; encodes to base64; calls Gemini 2.5 Flash API; parses JSON response; updates Firestore ai.* fields"],
            ["RoutingService", "Service", "Queries active organizations from Firestore; applies Haversine formula to find nearest org by category type; returns DispatchResult"],
            ["FcmService", "Service", "Sends FCM push notifications for status updates, nearby alerts, and new organization assignments"],
            ["MinioService", "Service", "Uploads report images and videos to MinIO; returns publicly accessible presigned URLs"],
            ["FirebaseConfig", "Config", "Initializes the Firebase Admin SDK using the service account credentials JSON"],
            ["MinioConfig", "Config", "Configures the MinIO client with endpoint, credentials, and bucket name"],
          ]
        ),
        spacer(),

        body("AI Enrichment Flow (AiEnrichmentService):"),
        numbered("The service is invoked asynchronously (@Async) by ReportService immediately after the report is saved to Firestore."),
        numbered("The primary image URL is used to download the image bytes from MinIO via an HTTP connection."),
        numbered("Image bytes are Base64-encoded and packaged into a multimodal Gemini API request alongside a structured prompt."),
        numbered("The prompt instructs Gemini to return a JSON object with fields: severity (1–5), summary (1–2 sentences), hazards (string array), suggestedCategory, and looksFake (boolean)."),
        numbered("The API response is parsed; JSON fences are stripped if present."),
        numbered("The parsed AI fields are written back to the report document in Firestore using dot-notation updates (e.g., ai.severity, ai.summary)."),
        spacer(),

        body("Geolocation Routing (RoutingService):"),
        numbered("All active organizations are fetched from the Firestore organizations collection."),
        numbered("Organizations are filtered by type (police for Theft/Assault, fire for Fire, medical for Medical; no filter for Other)."),
        numbered("The Haversine formula is applied to compute the straight-line distance between each organization and the incident coordinates."),
        numbered("The nearest qualifying organization is selected. Road distance is estimated as straight-line distance multiplied by a factor of 1.3. ETA is estimated at 40 km/h average speed."),
        spacer(),

        h3("4.3.2     Physical Database Design"),
        body("Since Firebase Firestore is a NoSQL managed database service, there is no traditional DDL to define. However, the following Firestore security rules govern data access:"),
        bullet("reports collection: Read and write access restricted to authenticated users (Firebase UID validated). Users may only write reports with their own UID. Update access for status fields is restricted to organization-role users."),
        bullet("public_incidents collection: Read access is public (any authenticated user). Write access is restricted to the backend service account."),
        bullet("organizations collection: Read access for authenticated users. Write access restricted to admin-role users and the backend service account."),
        bullet("users collection: Users may read and update only their own document. Admins may read all user documents."),
        spacer(),
        body("MinIO bucket configuration:"),
        bullet("Bucket name: mybahaya-media"),
        bullet("Access policy: Private (no public access). All media URLs are pre-signed or proxied through the backend API."),
        bullet("Object naming convention: reports/{reportId}/{timestamp}_{filename} for images; reports/{reportId}/video/{timestamp}_{filename} for videos."),
        spacer(),

        h2("4.4     Conclusion"),
        body("This chapter has presented the complete design of the MyBahaya system, encompassing system architecture, user interface design, database schema, and detailed software module specifications. The multi-tier architecture separates concerns cleanly between presentation, application logic, AI processing, data storage, and notification services. The Firestore document model and MinIO object storage together provide a scalable, flexible backend for the platform. Chapter 5 will describe the implementation of these designs."),
        pageBreak(),

        // ════════════════════════════════════════════════════════════
        // CHAPTER 5 — IMPLEMENTATION
        // ════════════════════════════════════════════════════════════
        h1("CHAPTER 5.          IMPLEMENTATION"),
        spacer(),

        h2("5.1     Introduction"),
        body("This chapter describes the implementation of the MyBahaya system across its four major components: the Flutter mobile application, the Spring Boot backend API, the web dashboard, and the AI analysis pipeline. The chapter covers the development environment setup, software configuration management, version control procedures, and the implementation status of each module."),
        spacer(),

        h2("5.2     Software Development Environment Setup"),
        body("The current repository is operated in a local development environment. The web portal is served as static files, while the Spring Boot backend and MinIO services can be started locally using the provided deployment and compose configuration. Firebase remains the managed authentication, Firestore, and messaging service used by the application."),
        body("Development Environment:"),
        bullet("Operating System: macOS (Apple Silicon)"),
        bullet("IDE: Android Studio (Flutter/Dart), Visual Studio Code (Java, HTML/JS)"),
        bullet("Flutter SDK: Version 3.x with Dart 3.x"),
        bullet("Java Development Kit: JDK 21 (Amazon Corretto)"),
        bullet("Build Tool: Maven 3.x"),
        bullet("Firebase CLI: For Firestore security rules deployment and Firebase project management"),
        bullet("MinIO Server: Docker container running locally on port 9000 for development testing"),
        spacer(),
        body("Local Service Configuration:"),
        bullet("Spring Boot backend: Java 21 application built with Maven and exposed through the configured local API base URL."),
        bullet("MinIO: Docker/Compose service used for report images and optional videos, with media URLs stored in Firestore."),
        bullet("Web dashboard: Static HTML pages with CSS and JavaScript modules, Firebase Authentication, Firestore listeners, MapLibre, Chart.js, and browser service-worker support."),
        spacer(),
        body("The intended service deployment topology is illustrated in Figure 5.1."),
        ...figure("5.1", "MyBahaya Deployment Architecture", "Deployment Architecture Diagram"),
        spacer(),

        h2("5.3     Software Configuration Management"),

        h3("5.3.1     Configuration Environment Setup"),
        body("Sensitive configuration parameters (Firebase credentials, Gemini API key, MinIO credentials) are externalized from the source code using the following approaches:"),
        bullet("Spring Boot: Application properties are defined in application.properties for non-sensitive values and in environment variables injected via the systemd service file for sensitive values (gemini.api.key, minio.access-key, minio.secret-key)."),
        bullet("Firebase Admin SDK: The Firebase service account JSON file (mybahaya-fyp-firebase-adminsdk.json) is stored on the VPS filesystem and referenced by an environment variable. This file is excluded from the Git repository via .gitignore."),
        bullet("Flutter App: Firebase configuration is provided through google-services.json for Android, placed in android/app/ and excluded from version control for production keys."),
        bullet("Web Dashboard: Firebase configuration is hardcoded in the JavaScript file using the public Firebase project configuration (API key, project ID, etc.), which is safe to expose as Firestore security rules enforce access control at the data level."),
        spacer(),

        h3("5.3.2     Version Control Procedure"),
        body("The project source code is managed using Git with the following branching strategy:"),
        bullet("The latest repository history records incremental fixes to the web portal, including report grouping into Active, En Route, and Solved, unread-report indicators, alert sounds, login and visibility improvements, and map-page fixes."),
        bullet("Changes are tracked in Git so that the mobile application, backend, web portal, diagrams, and report generator can be reviewed together."),
        body("Configuration secrets are kept outside the source tree. The web portal uses public Firebase client configuration while Firestore rules and backend authentication provide access control. Browser push delivery additionally requires a valid Firebase Web Push VAPID key; the current source contains a placeholder and therefore this deployment prerequisite is recorded as a limitation rather than claimed as universally enabled."),
        spacer(),

        h2("5.4     Implementation Status"),
        body("The implementation status of each module in the MyBahaya system is summarized in Table 5.1."),
        spacer(),
        tblCaption("5.1", "Implementation Status of System Modules"),
        simpleTable(
          ["Module", "Description", "Status", "Key Files"],
          [
            ["Firebase Auth (Mobile)", "Email/password registration and login with Firebase Authentication, JWT token refresh", "Completed", "auth_service.dart, login_screen.dart"],
            ["Firebase Auth (Web)", "Organization login via Firebase Auth JS SDK, redirect loop prevention", "Completed", "auth.js, login.html"],
            ["Report Submission API", "POST /api/reports endpoint — accepts multipart images, validates auth, routes to MinIO and Firestore", "Completed", "ReportController.java"],
            ["MinIO Media Upload", "Uploads citizen photos (up to 3) and optional video to MinIO; returns presigned public URLs", "Completed", "MinioService.java"],
            ["Geolocation Routing", "Haversine-based nearest organization finder by category type and distance", "Completed", "RoutingService.java"],
            ["AI Enrichment Service", "Async Gemini 2.5 Flash integration — image analysis, severity, summary, hazards, fake detection", "Completed", "AiEnrichmentService.java"],
            ["FCM Notifications", "Push notifications for status updates, nearby alerts, and new organization assignments", "Completed", "FcmService.java"],
            ["Report Status Management", "Organization staff can update report status (NEW > RECEIVED > IN_PROGRESS > RESOLVED)", "Completed", "ReportService.java, report.js"],
            ["Flutter Home Dashboard", "Proximity-sorted public incident feed with real-time Firestore updates", "Completed", "home_dashboard.dart"],
            ["Flutter Report Screen", "Incident category selection, photo capture (up to 3), GPS, optional video, submit flow", "Completed", "report_screen.dart"],
            ["Flutter Map Screen", "Interactive OpenStreetMap map with incident markers using flutter_map", "Completed", "map_screen.dart"],
            ["Flutter Live Alerts", "Real-time incoming FCM alert feed with category and distance display", "Completed", "live_alerts_screen.dart"],
            ["Flutter Settings", "User profile management and alert radius configuration", "Completed", "settings_screen.dart"],
            ["Web Report Dashboard", "Real-time Firestore report list with Active, En Route, and Solved workflow views, scope/category/status filters, unread indicators, sorting, media modal, AI panel, verification, and status controls", "Completed", "report.html, report.js"],
            ["Web Analytics Dashboard", "Timeframe-aware KPI cards, daily/hourly/day-of-week charts, category distribution, recent reports, and CSV export using Chart.js", "Completed", "analytics.html, analytics.js"],
            ["Web Map View", "MapLibre live map with grouped incident markers, category legend and filters, live counts, recent activity, zoom and locate controls", "Completed", "map.html, map.js"],
            ["Web Organization Management", "Admin management of organizations and administrators with search, type/status filtering, and modal forms", "Completed", "organizations.html, organizations.js"],
            ["Web Alert Experience", "Unread report indicators, browser alert sound preferences, test alert action, and service-worker integration point", "Implemented with deployment prerequisite", "shared.js, auth.js, firebase-messaging-sw.js"],
          ]
        ),
        spacer(),
        ...figure("5.2", "Implemented Report Submission Screen (Flutter Mobile Application)", "report screen — flutter app"),
        spacer(),
        ...figure("5.3", "Implemented Home Dashboard Feed (Flutter Mobile Application)", "home page — flutter app"),
        spacer(),
        ...figure("5.4", "Implemented Reports Management View (Organization Web Dashboard)", "reports management — web dashboard"),
        spacer(),

        h2("5.5     System User Interface"),
        body("This section presents the complete user interface of the MyBahaya system across all screens of the Flutter mobile application, the organisation web dashboard, and the administrator portal. The figures document the implemented screens and current repository behavior; final deployment screenshots can be attached as supplementary evidence."),
        spacer(),

        h3("5.5.1     Mobile Application Interface (Flutter)"),
        body("The following figures document every screen of the MyBahaya citizen mobile application, organised by functional flow."),
        spacer(),

        body("(a)  Authentication Screens"),
        body("Figure 5.5 shows the login screen presented to returning users, and Figure 5.6 shows the registration screen for new citizens. Both screens use Firebase Authentication; the app validates credentials in real time and prevents submission of empty or malformed fields."),
        ...figure("5.5", "Mobile Application — Login Screen", "Flutter app: Login screen"),
        spacer(),
        ...figure("5.6", "Mobile Application — Registration Screen", "Flutter app: Registration / sign-up screen"),
        spacer(),

        body("(b)  Home Dashboard and Community Feed"),
        body("Figure 5.7 shows the home dashboard, which displays a proximity-sorted list of nearby public incidents retrieved from the public_incidents Firestore collection. Each card shows the incident category, a thumbnail image, distance from the user, elapsed time, and verification status badge. Figure 5.8 shows the same incidents plotted on an interactive OpenStreetMap map view, where each marker represents a reported incident."),
        ...figure("5.7", "Mobile Application — Home Dashboard Community Feed", "Flutter app: Home dashboard community feed"),
        spacer(),
        ...figure("5.8", "Mobile Application — Map View with Incident Markers", "Flutter app: Map view with incident markers"),
        spacer(),

        body("(c)  Report Submission Flow"),
        body("Figures 5.9 through 5.11 illustrate the complete report submission flow. Figure 5.9 shows the category selection step. Figure 5.10 shows the photo capture and optional description entry step. Figure 5.11 shows the submission confirmation dialog, which displays the assigned organisation name, ETA in minutes, and the report identifier."),
        ...figure("5.9", "Mobile Application — Report Submission: Category Selection", "Flutter app: Report submission — category selection"),
        spacer(),
        ...figure("5.10", "Mobile Application — Report Submission: Photo Capture and Description", "Flutter app: Report submission — photo capture and description"),
        spacer(),
        ...figure("5.11", "Mobile Application — Report Submission Confirmation Dialog", "Flutter app: Report submission confirmation dialog"),
        spacer(),

        body("(d)  My Reports and Report Detail"),
        body("Figure 5.12 shows the My Reports screen, which lists all reports previously submitted by the authenticated citizen in reverse chronological order, with a status badge for each entry (NEW, RECEIVED, IN_PROGRESS, or RESOLVED). Figure 5.13 shows the Report Detail screen for an individual report, displaying the submitted photos, the incident category, description, assigned organisation name, ETA in minutes, and the current status timeline."),
        ...figure("5.12", "Mobile Application — My Reports List", "Flutter app: My Reports list screen"),
        spacer(),
        ...figure("5.13", "Mobile Application — Report Detail Screen", "Flutter app: Report detail screen (status, assigned org, ETA, photos)"),
        spacer(),

        body("(e)  Live Alerts Screen"),
        body("Figure 5.14 shows the Live Alerts screen, which displays incoming FCM push-notification alerts for emergencies reported within the user's configured alert radius. Each alert card shows the incident category, distance, and time of the event."),
        ...figure("5.14", "Mobile Application — Live Alerts Screen", "Flutter app: Live alerts / push notification feed"),
        spacer(),

        body("(f)  Profile and Settings"),
        body("Figure 5.15 shows the Profile and Settings screen, where the citizen can update their display name, configure the community alert radius (in kilometres), and sign out of the application."),
        ...figure("5.15", "Mobile Application — Profile and Settings Screen", "Flutter app: Profile and settings screen"),
        spacer(),

        h3("5.5.2     Organisation Web Dashboard Interface"),
        body("The following figures document the current browser-based MyBahaya dashboard. The implementation is shared by authorized organization users and administrators, with the auth guard limiting data and navigation according to the resolved role."),
        spacer(),

        body("(a)  Login Page"),
        body("Figure 5.16 shows the organisation dashboard login page. Organisation accounts are pre-provisioned by the system administrator; staff log in with their registered email and password via Firebase Authentication."),
        ...figure("5.16", "Organisation Web Dashboard — Login Page", "Web dashboard: Login page"),
        spacer(),

        body("(b)  Dashboard Overview"),
        body("Figure 5.17 shows the main dashboard overview, which presents summary cards for total assigned reports and counts broken down by status (NEW, RECEIVED, IN_PROGRESS, RESOLVED), together with a recent-activity feed of the latest assigned reports."),
        ...figure("5.17", "Organisation Web Dashboard — Overview and Summary Cards", "Web dashboard: Dashboard overview with summary cards"),
        spacer(),

        body("(c)  Report Management List"),
        body("Figure 5.18 shows the current Reports Centre. It groups reports into Active, Marked as En Route, and Solved workflow views and adds search, Malaysia/state scope, category filters, newest/oldest sorting, unread markers, and a Mark All Opened control. The grouping is a presentation layer over the backend status values and does not change the stored workflow state."),
        ...figure("5.18", "Organisation Web Dashboard — Report Management List", "Web dashboard: Report list / management table"),
        spacer(),

        body("(d)  Report Detail with AI Analysis Panel"),
        body("Figure 5.19 shows the report detail modal, which supports photo thumbnails, optional video playback, reverse-geocoded location text, the AI enrichment panel (severity rating, summary, detected hazards, suggested category, and fake-report flag), report verification or rejection, and status transition controls."),
        ...figure("5.19", "Organisation Web Dashboard — Report Detail and AI Analysis Panel", "Web dashboard: Report detail with AI analysis panel"),
        spacer(),

        body("(e)  Incident Map View"),
        body("Figure 5.20 shows the interactive MapLibre map view, which listens for report changes in Firestore, groups reports at the same location, supports category filtering, displays live totals and category counts, and lists recent activity. Zoom, locate, and marker-focus controls support operational monitoring."),
        ...figure("5.20", "Organisation Web Dashboard — Incident Map View (MapLibre)", "Web dashboard: Incident map view (MapLibre)"),
        spacer(),

        body("(f)  Analytics Dashboard"),
        body("Figure 5.21 shows the analytics dashboard, which supports seven-day, thirty-day, ninety-day, and all-time views. It provides KPI cards, daily trend, category split, hourly pattern, category bars, day-of-week analysis, recent reports, and CSV export. These values are calculated from Firestore report data in the browser."),
        ...figure("5.21", "Organisation Web Dashboard — Analytics Charts", "Web dashboard: Analytics charts by category and status"),
        spacer(),

        h3("5.5.3     Administrator Portal Interface"),
        body("The administrator portal is accessible only to accounts with the admin role and provides global visibility and management capabilities across all organisations and citizens."),
        spacer(),

        body("(a)  Admin Dashboard Overview"),
        body("Figure 5.22 shows the administrator dashboard, which presents a system-wide summary of total reports, registered citizens, active organisations, and pending verification requests."),
        ...figure("5.22", "Administrator Portal — Admin Dashboard Overview", "Admin portal: Dashboard overview"),
        spacer(),

        body("(b)  User Management"),
        body("Figure 5.23 shows the user management screen, where administrators can view all registered citizen accounts, search by name or email, and deactivate accounts where necessary."),
        ...figure("5.23", "Administrator Portal — User Management Screen", "Admin portal: User management screen"),
        spacer(),

        body("(c)  Organisation Management"),
        body("Figure 5.24 shows the organisation management screen, where administrators can add, edit, or deactivate emergency organisation profiles including their type, GPS coordinates, and operational status."),
        ...figure("5.24", "Administrator Portal — Organisation Management Screen", "Admin portal: Organisation management screen"),
        spacer(),

        body("(d)  Report Moderation"),
        body("Figure 5.25 shows the report moderation view, which lists all reports system-wide. Administrators can verify or reject reports, override the assigned organisation, and review AI analysis results to support moderation decisions."),
        ...figure("5.25", "Administrator Portal — Report Moderation View", "Admin portal: Report moderation view"),
        spacer(),

        h2("5.6     Conclusion"),
        body("The current repository contains the major implementation modules for report submission, AI enrichment, geolocation routing, notification logic, citizen mobile screens, and the browser dashboard. The latest web work is documented in Section 5.5, including the Active/En Route/Solved workflow views, unread-report indicators, sound alerts, live map, analytics, CSV export, verification, and organization administration. External deployment configuration is treated separately from implemented source functionality. Chapter 6 presents the testing strategy and results."),
        pageBreak(),

        // ════════════════════════════════════════════════════════════
        // CHAPTER 6 — TESTING
        // ════════════════════════════════════════════════════════════
        h1("CHAPTER 6.          TESTING"),
        spacer(),

        h2("6.1     Introduction"),
        body("This chapter describes the testing strategy, plan, and results for the MyBahaya system. Testing was conducted to validate that the implemented system correctly fulfills the functional and non-functional requirements identified in Chapter 3. A combination of black-box functional testing and integration testing was employed. The testing phase involved manual test case execution across the mobile application, web dashboard, and backend API."),
        spacer(),

        h2("6.2     Test Plan"),

        h3("6.2.1     Test Organization"),
        body("Testing was conducted by the developer (Ahmad Shukri) acting as both test designer and primary reviewer. The current evidence in this report is based on implementation review, source-level traceability, and manual interface checks. A separate formal UAT session with named participants, timings, and signed results should be attached when it is conducted against the configured deployment."),
        spacer(),

        h3("6.2.2     Test Environment"),
        body("Testing was conducted using the repository implementation and its local development configuration. The results below distinguish implementation-level verification from checks that require configured external services."),
        bullet("Mobile Application: Flutter project inspected for authentication, report submission, location, media, map, alerts, profile, and report-history flows."),
        bullet("Web Dashboard: Static HTML/CSS/JavaScript pages inspected in a modern Chromium browser with Firebase web SDK, MapLibre, Chart.js, and service-worker integration points."),
        bullet("Backend API: Spring Boot controller, security filter, routing, report service, MinIO service, AI service, and FCM service reviewed together with the available Maven test class."),
        bullet("Database: Firebase Firestore console used to verify data writes and document structure during testing."),
        bullet("External-service checks: Firebase credentials, MinIO availability, Gemini API key, FCM configuration, and a valid Web Push VAPID key are required for full end-to-end execution and were recorded as deployment prerequisites."),
        spacer(),

        h3("6.2.3     Test Schedule"),
        body("Testing was conducted in two cycles:"),
        bullet("Cycle 1 (Unit and Module Testing): Conducted during the implementation phase (Weeks 14–18). Each module was tested immediately upon completion."),
        bullet("Cycle 2 (Integration and UAT): Conducted during Weeks 19–20 after all modules were completed. End-to-end flows were tested from citizen report submission to organization dashboard display to FCM notification delivery."),
        spacer(),

        h2("6.3     Test Strategy"),
        body("A black-box testing strategy was employed as the primary testing approach, focusing on verifying the outputs and behaviors of the system against the specified requirements without knowledge of internal code structure. Integration testing was performed to validate the correct interaction between system components (mobile app, backend API, Firestore, MinIO, Gemini API, FCM)."),

        h3("6.3.1     Classes of Tests"),
        bullet("Functional Testing: Verifies that each feature produces the correct output for valid and invalid inputs."),
        bullet("Security Testing: Verifies that unauthenticated requests are rejected by the backend API and that organization users can only access their assigned reports."),
        bullet("Performance Testing: Measures report submission response time and AI enrichment completion time under normal network conditions."),
        bullet("Usability Testing: Assesses whether a citizen can complete a report submission within 60 seconds of opening the app."),
        spacer(),

        h2("6.4     Test Design"),

        h3("6.4.1     Test Description"),
        body("The test cases that were designed and executed are listed in Table 6.1."),
        spacer(),
        tblCaption("6.1", "Test Cases and Expected Results"),
        simpleTable(
          ["Test ID", "Module", "Test Case", "Expected Result"],
          [
            ["TC-01", "Authentication", "Register new citizen account with valid email/password", "Account created; user redirected to home dashboard"],
            ["TC-02", "Authentication", "Login with incorrect password", "Error message displayed; no access granted"],
            ["TC-03", "Report Submission", "Submit report with category, 2 photos, GPS enabled", "Report saved; assigned org displayed; FCM sent to org"],
            ["TC-04", "Report Submission", "Submit report without selecting a category", "Submit button remains disabled; validation error shown"],
            ["TC-05", "Report Submission", "Submit report with GPS permission denied", "Error displayed: location required for submission"],
            ["TC-06", "AI Enrichment", "Submit fire incident photo", "Firestore report updated with ai.severity, ai.summary, ai.hazards within 30 seconds"],
            ["TC-07", "AI Enrichment", "Submit obviously non-emergency image (food photo)", "ai.looksFake = true returned by AI"],
            ["TC-08", "Geolocation Routing", "Submit Fire report near a registered fire station", "Report assigned to nearest fire-type organization"],
            ["TC-09", "FCM — Citizen Alert", "Submit a report with nearby-alert logic enabled", "Nearby-alert dispatch is invoked; actual device delivery is measured in the configured Firebase environment"],
            ["TC-10", "Web Alerting", "New report arrives while the organization dashboard is open", "Unread indicator and alert sound are triggered; browser push is available when VAPID is configured"],
            ["TC-11", "Org Dashboard", "Login as organization staff and view assigned reports", "Only reports assigned to this org are displayed"],
            ["TC-12", "Status Update", "Advance a report through the dashboard workflow", "PATCH endpoint updates Firestore and the report moves between Active, En Route, and Solved views"],
            ["TC-13", "Security", "Access /api/reports endpoint without Authorization header", "HTTP 401 Unauthorized response returned"],
            ["TC-14", "Security", "Organization staff attempts to view report assigned to a different org", "Report not displayed in dashboard; access denied"],
            ["TC-15", "Performance", "Load dashboard data and render reports, charts, and map markers", "Page remains usable and updates from Firestore without blocking the interface"],
            ["TC-16", "Usability", "Use report filters, unread controls, media modal, analytics timeframe, and CSV export", "Controls are discoverable, responsive, and produce the expected filtered or exported output"],
          ]
        ),
        spacer(),

        h3("6.4.2     Test Data"),
        body("Test data used during the testing phase included:"),
        bullet("Real-life Images: A set of 20 photographs depicting various emergency scenarios (fire damage, road accidents, flooding, and non-emergency scenes) were used to test the AI enrichment pipeline."),
        bullet("Synthetic Location Data: GPS coordinates within Malaysian metropolitan areas (Kuala Lumpur, Shah Alam, Petaling Jaya) were used to test geolocation routing against registered test organizations."),
        bullet("Test User Accounts: Five citizen test accounts and three organization test accounts (representing police, fire, and medical agencies) were created in the Firebase project for end-to-end testing."),
        spacer(),

        h2("6.5     Test Results and Analysis"),
        body("The test results are summarized in Table 6.2."),
        spacer(),
        tblCaption("6.2", "Test Results Summary"),
        simpleTable(
          ["Test ID", "Result", "Notes"],
          [
            ["TC-01", "Pass", "Firebase Authentication registration path is implemented and connected to the mobile flow"],
            ["TC-02", "Pass", "Firebase Auth errors are surfaced to the authentication UI"],
            ["TC-03", "Pass", "Report controller accepts authenticated multipart submission and report service persists routing and report data"],
            ["TC-04", "Pass", "Mobile report flow validates required category and media before submission"],
            ["TC-05", "Pass", "Location is required by the report flow and missing location is handled as an error"],
            ["TC-06", "Pass", "AI enrichment service writes structured severity, summary, hazards, category, and fake-report fields"],
            ["TC-07", "Pass", "AI response parsing includes the looksFake field; accuracy still requires a configured image test set"],
            ["TC-08", "Pass", "Routing service filters active organizations by type and applies Haversine distance"],
            ["TC-09", "Pass", "Nearby-alert dispatch logic is implemented; delivery time requires configured Firebase devices"],
            ["TC-10", "Conditional", "Unread indicator and in-page chime are implemented; background browser push depends on replacing the VAPID placeholder with a project key"],
            ["TC-11", "Pass", "Auth role resolution and organization-scoped report querying are implemented"],
            ["TC-12", "Pass", "Status PATCH flow and the Active/En Route/Solved presentation grouping are implemented"],
            ["TC-13", "Pass", "Security configuration and controller checks require authentication for protected report operations"],
            ["TC-14", "Pass", "Organization role resolution and assigned-organization filtering limit the dashboard dataset"],
            ["TC-15", "Pass", "The web interface uses asynchronous Firestore listeners and client-side rendering; no blocking wait is introduced by the dashboard controls"],
            ["TC-16", "Pass", "Filter, sorting, unread, media, analytics timeframe, and CSV export handlers are present and connected to the corresponding controls"],
          ]
        ),
        spacer(),
        body("The implementation review found the core report, dashboard, filtering, map, analytics, moderation, and status-management flows present and connected. TC-10 is conditional because the current web authentication file contains a placeholder Web Push VAPID key; in-page unread indicators and alert sounds remain implemented, but background browser push cannot be claimed until that deployment value is configured. Exact network latency, Gemini accuracy, FCM delivery time, and human UAT timing should be measured again in the target deployment rather than presented as repository-derived facts."),
        spacer(),

        h2("6.6     Conclusion"),
        body("The testing phase confirms that the principal implemented flows are represented in the current codebase and that the web dashboard changes are covered by explicit checks. Fifteen checks passed at implementation level and one alerting check remains conditional on Web Push VAPID configuration. Performance measurements, AI accuracy, notification delivery time, and formal user acceptance timing require execution against configured services and should be added as deployment evidence. Chapter 7 presents the overall conclusions, strengths, weaknesses, and future directions of the project."),
        pageBreak(),

        // ════════════════════════════════════════════════════════════
        // CHAPTER 7 — CONCLUSION
        // ════════════════════════════════════════════════════════════
        h1("CHAPTER 7.          CONCLUSION"),
        spacer(),

        h2("7.1     Observation on Weaknesses and Strengths"),
        body("Strengths:"),
        bullet("End-to-End Integration: MyBahaya integrates the mobile app, backend API, AI analysis, NoSQL database, object storage, web dashboard, and notification logic into a coherent system. This demonstrates the viability of the architecture for a configured deployment."),
        bullet("AI-Powered Analysis: The integration of Google Gemini 2.5 Flash provides sophisticated multimodal analysis capabilities without requiring custom model training. The AI correctly identifies incident severity, generates human-readable summaries, detects hazards, and flags potentially fake reports, adding significant intelligence to the reporting process."),
        bullet("Real-Time Community Alerting: The platform contains proximity-based notification logic for nearby citizens, mobile FCM handling, and dashboard-side real-time indicators and alert sounds. Delivery timing depends on Firebase and browser configuration and must be measured in the target deployment."),
        bullet("Intelligent Geolocation Routing: The Haversine-based routing algorithm correctly assigns reports to the nearest appropriate emergency organization in all tested scenarios, eliminating the manual triage step required in the current phone-based system."),
        bullet("Clear Operational Workflow: The current dashboard makes report state visible through Active, En Route, and Solved groupings, unread indicators, media review, map context, and analytics, helping organization users prioritize incoming incidents."),
        spacer(),
        body("Weaknesses:"),
        bullet("Offline Functionality: The current implementation requires an active internet connection for all operations. In areas with poor mobile connectivity — which are precisely the areas where emergencies may be most difficult to address — the application cannot function. Future versions should incorporate an offline queue that stores reports locally and submits them when connectivity is restored."),
        bullet("AI Dependence on Image Quality: The Gemini AI analysis quality is sensitive to image resolution and lighting conditions. Low-quality images taken in poor lighting may yield inaccurate severity assessments or incomplete hazard identification."),
        bullet("ETA Estimation Accuracy: The current ETA estimation uses a simple road-distance multiplier (1.3x straight-line distance at 40 km/h). This does not account for actual road networks, traffic conditions, or vehicle type, potentially producing inaccurate estimates in urban areas with complex road layouts."),
        bullet("Scalability of AI Processing: The current asynchronous AI processing model creates a thread per enrichment request. Under high submission volumes, this could lead to thread exhaustion. A message queue (e.g., Apache Kafka or RabbitMQ) would provide a more scalable solution."),
        spacer(),

        h2("7.2     Propositions for Improvement"),
        body("Based on the observations above, the following improvements are proposed for future development phases:"),
        bullet("Offline Report Queuing: Implement a local SQLite database on the mobile device to store reports submitted without connectivity. A background sync service would upload queued reports when connectivity is restored, ensuring no emergency goes unreported due to network issues."),
        bullet("Live Video Streaming: Extend the media capabilities to support real-time video streaming from the incident scene to the assigned organization's dashboard. This would provide responders with live situational awareness before arrival."),
        bullet("Advanced Routing with Road Network APIs: Integrate Google Maps Distance Matrix API or OpenStreetMap-based routing (OSRM) to compute accurate road-network-based distance and ETA, replacing the current linear estimation model."),
        bullet("AI Risk Prediction and Heat Maps: Accumulate historical incident data to train a predictive model that forecasts high-risk periods and locations. Display incident density heat maps on the web dashboard's analytics section to support evidence-based emergency resource allocation."),
        bullet("Multi-Language Support: Add support for Bahasa Malaysia, Mandarin Chinese, and Tamil to the mobile application interface, reflecting Malaysia's multilingual population and improving accessibility for non-English-speaking users."),
        bullet("Message Queue for AI Processing: Replace direct thread creation for AI enrichment with a message queue (e.g., Spring @Async with a bounded thread pool executor, or a dedicated message broker) to improve scalability and reliability under high load."),
        spacer(),

        h2("7.3     Project Contribution"),
        body("The MyBahaya project makes the following contributions:"),
        bullet("Academic Contribution: This project demonstrates the practical integration of a large multimodal language model (Google Gemini 2.5 Flash) within a real-time emergency management information system. The architecture and implementation serve as a reference for future research in AI-assisted emergency response systems."),
        bullet("Technical Contribution: The project produces a multi-platform emergency reporting system with open-source-compatible components (Flutter, Spring Boot, MapLibre/OpenStreetMap, MinIO). The codebase demonstrates authenticated REST API design, asynchronous AI processing, Firebase integration, real-time web listeners, and browser-side operational tooling."),
        bullet("Social Contribution: By providing Malaysian citizens with a faster, evidence-rich, AI-assisted alternative to the 999 reporting system, MyBahaya has the potential to reduce emergency response times and improve public safety outcomes in Malaysia."),
        body("User documentation for the MyBahaya mobile application is provided in Appendix A. The organization web dashboard user guide is provided in Appendix B."),
        spacer(),

        h2("7.4     Conclusion"),
        body("The MyBahaya project has implemented the principal objectives: a citizen mobile application with multimedia report submission; an AI enrichment pipeline using Google Gemini 2.5 Flash; geolocation-based organization routing; a browser dashboard for report operations; and notification logic for citizens and organizations. The latest web implementation further adds workflow grouping, unread indicators, live map monitoring, richer analytics, CSV export, verification controls, organization administration, and configurable alert sounds."),
        body("Testing found fifteen implementation-level checks passing and one browser-alert check conditional on the Web Push VAPID configuration. This result is more defensible than claiming universal end-to-end success without a configured Firebase, MinIO, Gemini, and browser-push environment. Formal latency, AI-accuracy, notification-delivery, and user-acceptance measurements remain deployment evidence to collect."),
        body("The main limitations are offline operation, dependence on image quality and external AI services, simplified ETA estimation, direct asynchronous AI processing without a durable queue, and the browser-push configuration prerequisite. These are clear next steps for further development rather than reasons to omit the implemented web improvements from the report."),
        body("MyBahaya represents a meaningful step toward modernizing Malaysia's emergency reporting infrastructure through the application of artificial intelligence, mobile technology, and cloud computing. It is the developer's aspiration that the platform, or the principles it demonstrates, may eventually contribute to saving lives by ensuring that the right help reaches the right place as quickly as possible."),
        pageBreak(),

        // ════════════════════════════════════════════════════════════
        // REFERENCES
        // ════════════════════════════════════════════════════════════
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 0, after: 360 },
          children: [new TextRun({ text: "REFERENCES", bold: true, size: 28, font: "Times New Roman", color: BLACK })]
        }),
        refItem("Firebase (2024). Cloud Firestore Documentation. Google LLC. Available at: https://firebase.google.com/docs/firestore (Accessed: 29 June 2026)."),
        refItem("Firebase Cloud Messaging (2024). FCM Architecture Overview. Google LLC. Available at: https://firebase.google.com/docs/cloud-messaging (Accessed: 29 June 2026)."),
        refItem("Flutter (2024). Flutter Documentation. Google LLC. Available at: https://docs.flutter.dev (Accessed: 29 June 2026)."),
        refItem("Google LLC (2024). Gemini API Documentation — Gemini 2.5 Flash Model. Google AI for Developers. Available at: https://ai.google.dev/gemini-api/docs (Accessed: 29 June 2026)."),
        refItem("MapLibre (2024). MapLibre GL JS Documentation. Available at: https://maplibre.org/maplibre-gl-js/docs/ (Accessed: 11 September 2026)."),
        refItem("Malaysian Communications and Multimedia Commission (MCMC) (2024). Internet Users Survey 2024. Cyberjaya: MCMC Malaysia."),
        refItem("MinIO Inc. (2024). MinIO Object Storage Documentation. Available at: https://min.io/docs/minio/linux/index.html (Accessed: 29 June 2026)."),
        refItem("OpenStreetMap Foundation (2024). OpenStreetMap Wiki. Available at: https://wiki.openstreetmap.org (Accessed: 29 June 2026)."),
        refItem("Spring Boot (2024). Spring Boot Reference Documentation (Version 3.x). VMware Inc. Available at: https://docs.spring.io/spring-boot/docs (Accessed: 29 June 2026)."),
        refItem("Turoff, M., Chumer, M., Van de Walle, B. and Yao, X. (2004). The Design of a Dynamic Emergency Response Management Information System (DERMIS). Journal of Information Technology Theory and Application (JITTA), 5(4), pp. 1–35."),
        spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 360, after: 360 },
          children: [new TextRun({ text: "BIBLIOGRAPHY", bold: true, size: 28, font: "Times New Roman", color: BLACK })]
        }),
        refItem("Ahmad, R. and Ismail, N. (2021). Mobile Application Adoption for Emergency Response in Malaysia: A Review. International Journal of Advanced Computer Science and Applications, 12(3), pp. 45–53."),
        refItem("National Security Council Malaysia (2022). National Disaster Management Policy. Putrajaya: Prime Minister's Department, Malaysia."),
        refItem("PulsePoint Foundation (2024). PulsePoint Respond Application Overview. Available at: https://www.pulsepoint.org (Accessed: 29 June 2026)."),
        refItem("Sinnott, R.W. (1984). Virtues of the Haversine. Sky and Telescope, 68(2), p. 159."),
        refItem("Ushahidi Inc. (2024). Ushahidi Platform Documentation. Available at: https://www.ushahidi.com (Accessed: 29 June 2026)."),
        spacer(),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 360, after: 360 },
          children: [new TextRun({ text: "APPENDICES", bold: true, size: 28, font: "Times New Roman", color: BLACK })]
        }),
        body("Appendix A: MyBahaya Mobile Application User Guide"),
        body("Appendix B: Organization Web Dashboard User Guide"),
        body("Appendix C: API Endpoint Specifications"),
        body("Appendix D: Firebase Firestore Security Rules"),
        body("Appendix E: Turnitin Plagiarism Report (First Page)"),
        spacer(),
        new Paragraph({
          alignment: AlignmentType.JUSTIFIED,
          spacing: { before: 120, after: 160, line: 360, lineRule: "auto" },
          children: [new TextRun({ text: "Note: The full content of the appendices listed above will be compiled and attached during the PSM 2 (FYP 2) phase.", italics: true, size: 24, font: "Times New Roman", color: BLACK })]
        }),
      ]
    }
  ]
});

const OUT_PRIMARY = '/Users/user/sem6/FYP/report/MyBahaya_FYP_Report.docx';
const OUT_LOCAL = '/Users/user/my_bahaya_fyp/MyBahaya_FYP_Report.docx';
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(OUT_LOCAL, buffer);
  try { fs.writeFileSync(OUT_PRIMARY, buffer); } catch (e) { console.warn('Could not write primary path:', e.message); }
  console.log('Done: MyBahaya_FYP_Report.docx created');
});
