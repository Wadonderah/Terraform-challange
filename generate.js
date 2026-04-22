const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageBreak, Header, Footer, PageNumber
} = require('docx');
const fs = require('fs');

const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const thickBorder = { style: BorderStyle.SINGLE, size: 4, color: "1A6B3A" };
const thickBorders = { top: thickBorder, bottom: thickBorder, left: thickBorder, right: thickBorder };

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    children: [new TextRun({ text, bold: true, size: 32, font: "Arial", color: "1A6B3A" })],
    spacing: { before: 360, after: 120 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "1A6B3A", space: 1 } }
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    children: [new TextRun({ text, bold: true, size: 26, font: "Arial", color: "2D6A4F" })],
    spacing: { before: 280, after: 80 }
  });
}

function h3(text) {
  return new Paragraph({
    children: [new TextRun({ text, bold: true, size: 22, font: "Arial", color: "1B4332" })],
    spacing: { before: 200, after: 60 }
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    children: [new TextRun({ text, size: 22, font: "Arial", ...opts })],
    spacing: { before: 60, after: 60 }
  });
}

function bullet(text, opts = {}) {
  return new Paragraph({
    numbering: { reference: "bullets", level: 0 },
    children: [new TextRun({ text, size: 22, font: "Arial", ...opts })],
    spacing: { before: 40, after: 40 }
  });
}

function codeBlock(lines) {
  return lines.map(line =>
    new Paragraph({
      children: [new TextRun({ text: line, size: 18, font: "Courier New", color: "D6E4FF" })],
      spacing: { before: 0, after: 0 },
      shading: { fill: "1E293B", type: ShadingType.CLEAR },
      indent: { left: 360, right: 360 }
    })
  );
}

function spacer() {
  return new Paragraph({ children: [new TextRun("")], spacing: { before: 80, after: 80 } });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

// Score summary table
function scoreTable() {
  const headerCell = (text, w = 2340) => new TableCell({
    borders: thickBorders,
    width: { size: w, type: WidthType.DXA },
    shading: { fill: "1A6B3A", type: ShadingType.CLEAR },
    margins: { top: 100, bottom: 100, left: 150, right: 150 },
    children: [new Paragraph({ children: [new TextRun({ text, bold: true, color: "FFFFFF", size: 20, font: "Arial" })] })]
  });
  const dataCell = (text, fill = "F0FFF4", w = 2340) => new TableCell({
    borders,
    width: { size: w, type: WidthType.DXA },
    shading: { fill, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 150, right: 150 },
    children: [new Paragraph({ children: [new TextRun({ text, size: 20, font: "Arial" })] })]
  });

  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [2340, 2340, 2340, 2340],
    rows: [
      new TableRow({ children: [headerCell("Exam"), headerCell("Score"), headerCell("Percentage"), headerCell("Result")] }),
      new TableRow({ children: [dataCell("Practice Exam 1"), dataCell("42/57"), dataCell("73.7%"), dataCell("PASS", "E6FFED")] }),
      new TableRow({ children: [dataCell("Practice Exam 2"), dataCell("45/57"), dataCell("78.9%"), dataCell("PASS", "E6FFED")] }),
    ]
  });
}

// Domain accuracy table
function domainTable() {
  const hc = (text, w) => new TableCell({
    borders: thickBorders,
    width: { size: w, type: WidthType.DXA },
    shading: { fill: "2D6A4F", type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [new Paragraph({ children: [new TextRun({ text, bold: true, color: "FFFFFF", size: 18, font: "Arial" })] })]
  });
  const dc = (text, flag = false, w = 1560) => new TableCell({
    borders,
    width: { size: w, type: WidthType.DXA },
    shading: { fill: flag ? "FFF3CD" : "F9FFFE", type: ShadingType.CLEAR },
    margins: { top: 60, bottom: 60, left: 120, right: 120 },
    children: [new Paragraph({ children: [new TextRun({ text, size: 18, font: "Arial", color: flag ? "856404" : "000000", bold: flag })] })]
  });

  const domains = [
    ["IaC Concepts", "8", "6", "75%", false],
    ["Terraform Purpose", "6", "5", "83%", false],
    ["Terraform Basics", "10", "8", "80%", false],
    ["Terraform CLI", "12", "9", "75%", false],
    ["Terraform Modules", "8", "5", "63%", true],
    ["Core Workflow", "6", "5", "83%", false],
    ["State Management", "10", "6", "60%", true],
    ["Configuration", "8", "6", "75%", false],
    ["Terraform Cloud", "5", "3", "60%", true],
    ["TOTAL", "73", "53", "72.6%", false],
  ];

  const rows = [
    new TableRow({ children: [hc("Domain", 3120), hc("Attempted", 1560), hc("Correct", 1560), hc("Accuracy", 1560), hc("Status", 1560)] }),
    ...domains.map(([domain, att, cor, acc, flag]) =>
      new TableRow({ children: [dc(domain, false, 3120), dc(att, false), dc(cor, false), dc(acc, flag), dc(flag ? "NEEDS WORK" : "On Track", flag)] })
    )
  ];

  return new Table({ width: { size: 9360, type: WidthType.DXA }, columnWidths: [3120, 1560, 1560, 1560, 1560], rows });
}

// Wrong answer analysis
function wrongAnswerCard(q, wrong, correct, why, ref, fix) {
  const cells = [
    ["Question Topic", q, "EBF5FB"],
    ["My Wrong Answer", wrong, "FDEDEC"],
    ["Correct Answer", correct, "EAFAF1"],
    ["Why I Was Wrong", why, "FEF9E7"],
    ["Doc Reference", ref, "F0F3FF"],
    ["Hands-On Fix", fix, "F5F5F5"],
  ];
  return cells.map(([label, val, fill]) =>
    new Table({
      width: { size: 9360, type: WidthType.DXA },
      columnWidths: [2500, 6860],
      rows: [new TableRow({
        children: [
          new TableCell({
            borders, width: { size: 2500, type: WidthType.DXA },
            shading: { fill: "2D6A4F", type: ShadingType.CLEAR },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            children: [new Paragraph({ children: [new TextRun({ text: label, bold: true, color: "FFFFFF", size: 18, font: "Arial" })] })]
          }),
          new TableCell({
            borders, width: { size: 6860, type: WidthType.DXA },
            shading: { fill, type: ShadingType.CLEAR },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            children: [new Paragraph({ children: [new TextRun({ text: val, size: 18, font: "Arial" })] })]
          }),
        ]
      })]
    })
  );
}

const wrongAnswers = [
  {
    q: "Q4 Topic 1 - Immutable Infrastructure Advantage",
    wrong: "C - Quicker infrastructure upgrades",
    correct: "D - Less complex infrastructure upgrades",
    why: "I confused speed with simplicity. I assumed immutability means faster deploys because you replace rather than patch. The real benefit is reduced complexity: you eliminate configuration drift, partial upgrade states, and dependency conflicts. Quicker is a sometimes-true side effect, not the core advantage.",
    ref: "https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code",
    fix: "terraform destroy && terraform apply  # Simulating immutable replacement instead of in-place change"
  },
  {
    q: "Q: terraform state rm - What it does to real infrastructure",
    wrong: "Thought terraform state rm destroys the actual cloud resource",
    correct: "terraform state rm removes the resource from state only. The real infrastructure keeps running unmanaged.",
    why: "I conflated state management with resource lifecycle. terraform destroy actually deletes infrastructure. terraform state rm just removes Terraform's knowledge of it - the resource becomes orphaned.",
    ref: "https://developer.hashicorp.com/terraform/cli/commands/state/rm",
    fix: "terraform state rm aws_instance.example\nterraform state list  # confirm it's gone from state but instance still exists in AWS"
  },
  {
    q: "Q: Terraform Cloud - Remote State vs Full Remote Operations",
    wrong: "Assumed remote state backend in Terraform Cloud always runs plans remotely",
    correct: "The 'remote' backend can be configured for remote operations OR just remote state. Plan/apply can still run locally.",
    why: "I did not distinguish between the backend type and the execution mode. You can use Terraform Cloud for state storage while still running CLI operations locally.",
    ref: "https://developer.hashicorp.com/terraform/cloud-docs/run/remote-operations",
    fix: "# Test local execution with remote state:\nterraform init  # with cloud backend configured\nterraform plan  # observe whether it runs locally or triggers a Cloud run"
  },
  {
    q: "Q: Module source types - Which support versioning constraints",
    wrong: "Said all module sources support version constraints",
    correct: "Only registry sources (Terraform Registry and private registries) support the version argument. Local paths and Git sources do not.",
    why: "I overgeneralised. The version argument is specific to registry modules. For Git sources you use ref= in the URL. Local paths have no versioning.",
    ref: "https://developer.hashicorp.com/terraform/language/modules/sources",
    fix: "# Test registry source with version:\nmodule \"vpc\" { source = \"terraform-aws-modules/vpc/aws\"; version = \"5.0.0\" }"
  },
  {
    q: "Q: terraform refresh - Behaviour and when to use it",
    wrong: "Thought terraform refresh updates the configuration files",
    correct: "terraform refresh reconciles state with real-world infrastructure. It updates the state file only - never the .tf configuration files.",
    why: "I confused the direction of update. terraform refresh reads actual infrastructure and updates state to match. Configuration files are only changed by the operator.",
    ref: "https://developer.hashicorp.com/terraform/cli/commands/refresh",
    fix: "terraform refresh\nterraform show  # observe state now reflects real infra, not .tf changes"
  },
  {
    q: "Q: Sensitive values in Terraform output",
    wrong: "Said sensitive = true fully encrypts the value in state",
    correct: "sensitive = true suppresses the value in CLI output only. The value is still stored in plaintext in the state file.",
    why: "I assumed sensitive flag provided security at the state level. It is only a display control. Actual state security requires encrypted backends (S3+KMS, Terraform Cloud, etc.).",
    ref: "https://developer.hashicorp.com/terraform/language/values/outputs#sensitive-suppressing-values-in-cli-output",
    fix: "# Add sensitive output then inspect state directly:\nterraform output -json  # shows value despite sensitive flag\ncat terraform.tfstate | grep -A2 'sensitive_output'"
  },
];

// Hands-on commands
const handsOnSections = [
  {
    title: "State Management Exercises",
    commands: [
      "# 1. List all resources in state",
      "terraform state list",
      "",
      "# 2. Show detail of a specific resource",
      "terraform state show aws_instance.web",
      "",
      "# 3. Move resource to new address (e.g. after module refactor)",
      "terraform state mv aws_instance.web module.compute.aws_instance.web",
      "",
      "# 4. Remove resource from state WITHOUT destroying it",
      "terraform state rm aws_instance.web",
      "",
      "# 5. Pull raw state JSON",
      "terraform state pull | jq '.resources[] | {type, name, instances: .instances | length}'",
      "",
      "# 6. Import existing resource into state",
      "terraform import aws_instance.web i-0abc123def456",
    ]
  },
  {
    title: "Module Versioning Exercises",
    commands: [
      "# 1. Call a versioned registry module",
      "module \"vpc\" {",
      "  source  = \"terraform-aws-modules/vpc/aws\"",
      "  version = \"~> 5.0\"",
      "  cidr    = \"10.0.0.0/16\"",
      "}",
      "",
      "# 2. Call a local module (no version support)",
      "module \"compute\" {",
      "  source = \"./modules/compute\"",
      "}",
      "",
      "# 3. Initialise and see module download",
      "terraform init",
      "ls .terraform/modules/",
    ]
  },
  {
    title: "Terraform Cloud Remote Execution",
    commands: [
      "# Configure cloud backend",
      "terraform {",
      "  cloud {",
      "    organization = \"my-org\"",
      "    workspaces {",
      "      name = \"my-workspace\"",
      "    }",
      "  }",
      "}",
      "",
      "# Authenticate",
      "terraform login",
      "",
      "# Init with cloud backend",
      "terraform init",
      "",
      "# Trigger a remote plan",
      "terraform plan  # runs in Terraform Cloud if execution_mode = remote",
    ]
  }
];

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial" },
        paragraph: { spacing: { before: 360, after: 120 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Arial" },
        paragraph: { spacing: { before: 280, after: 80 }, outlineLevel: 1 } },
    ]
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [{
    properties: {
      page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } }
    },
    headers: {
      default: new Header({
        children: [
          new Paragraph({
            children: [
              new TextRun({ text: "Day 28 | Terraform