
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageBreak, Header, Footer, PageNumber
} = require('docx');
const fs = require('fs');

const bdr = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const bdrs = { top: bdr, bottom: bdr, left: bdr, right: bdr };
const gbdr = { style: BorderStyle.SINGLE, size: 4, color: "1A6B3A" };
const gbdrs = { top: gbdr, bottom: gbdr, left: gbdr, right: gbdr };

const blank = () => new Paragraph({ children: [new TextRun("")], spacing: { before: 80, after: 80 } });
const pgbrk = () => new Paragraph({ children: [new PageBreak()] });
const sp = (t, bold) => new Paragraph({
  children: [new TextRun({ text: t, size: 22, font: "Arial", bold: bold || false })],
  spacing: { before: 60, after: 60 }
});
const h1 = (t) => new Paragraph({
  heading: HeadingLevel.HEADING_1,
  children: [new TextRun({ text: t, bold: true, size: 32, font: "Arial", color: "1A6B3A" })],
  spacing: { before: 360, after: 120 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "1A6B3A", space: 1 } }
});
const h2 = (t) => new Paragraph({
  heading: HeadingLevel.HEADING_2,
  children: [new TextRun({ text: t, bold: true, size: 26, font: "Arial", color: "2D6A4F" })],
  spacing: { before: 240, after: 80 }
});
const h3 = (t) => new Paragraph({
  children: [new TextRun({ text: t, bold: true, size: 22, font: "Arial", color: "1B4332" })],
  spacing: { before: 180, after: 60 }
});
const bul = (t) => new Paragraph({
  numbering: { reference: "bullets", level: 0 },
  children: [new TextRun({ text: t, size: 22, font: "Arial" })],
  spacing: { before: 40, after: 40 }
});
const codeLine = (t) => new Paragraph({
  children: [new TextRun({ text: t, size: 18, font: "Courier New", color: "E2E8F0" })],
  shading: { fill: "1E293B", type: ShadingType.CLEAR },
  indent: { left: 360 },
  spacing: { before: 0, after: 0 }
});
const hCell = (t, w, fill) => new TableCell({
  borders: gbdrs, width: { size: w, type: WidthType.DXA },
  shading: { fill: fill || "1A6B3A", type: ShadingType.CLEAR },
  margins: { top: 80, bottom: 80, left: 120, right: 120 },
  children: [new Paragraph({ children: [new TextRun({ text: t, bold: true, color: "FFFFFF", size: 18, font: "Arial" })] })]
});
const dCell = (t, w, fill, color, bold) => new TableCell({
  borders: bdrs, width: { size: w, type: WidthType.DXA },
  shading: { fill: fill || "F9FFFE", type: ShadingType.CLEAR },
  margins: { top: 70, bottom: 70, left: 120, right: 120 },
  children: [new Paragraph({ children: [new TextRun({ text: t, size: 18, font: "Arial", color: color || "111111", bold: bold || false })] })]
});

const scoreTable = () => new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: [2340, 2340, 2340, 2340],
  rows: [
    new TableRow({ children: [hCell("Exam",2340), hCell("Score",2340), hCell("Percentage",2340), hCell("Result",2340)] }),
    new TableRow({ children: [dCell("Practice Exam 1",2340), dCell("42/57",2340), dCell("73.7%",2340), dCell("PASS",2340,"D4EDDA","155724",true)] }),
    new TableRow({ children: [dCell("Practice Exam 2",2340), dCell("45/57",2340), dCell("78.9%",2340), dCell("PASS",2340,"D4EDDA","155724",true)] }),
  ]
});

const domainData = [
  ["IaC Concepts","8","6","75%",false],
  ["Terraform Purpose","6","5","83%",false],
  ["Terraform Basics","10","8","80%",false],
  ["Terraform CLI","12","9","75%",false],
  ["Terraform Modules","8","5","63%",true],
  ["Core Workflow","6","5","83%",false],
  ["State Management","10","6","60%",true],
  ["Configuration","8","6","75%",false],
  ["Terraform Cloud","5","3","60%",true],
  ["TOTAL","73","53","72.6%",false],
];

const domainTable = () => new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: [3200,1490,1490,1490,1690],
  rows: [
    new TableRow({ children: [hCell("Domain",3200), hCell("Attempted",1490), hCell("Correct",1490), hCell("Accuracy",1490), hCell("Status",1690)] }),
    ...domainData.map(([d,a,c,acc,flag]) => new TableRow({ children: [
      dCell(d,3200,flag?"FFF3CD":"F9FFFE",flag?"856404":"111111",flag),
      dCell(a,1490), dCell(c,1490),
      dCell(acc,1490,flag?"FFF3CD":"F9FFFE",flag?"856404":"155724",flag),
      dCell(flag?"NEEDS WORK":"On Track",1690,flag?"F8D7DA":"D4EDDA",flag?"721C24":"155724",flag)
    ]}))
  ]
});

const waCard = (q, wrong, correct, why, ref, fix) => {
  const row = (label, val, fill) => new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [2300,7060],
    rows: [new TableRow({ children: [
      new TableCell({
        borders: gbdrs, width:{size:2300,type:WidthType.DXA},
        shading:{fill:"2D6A4F",type:ShadingType.CLEAR},
        margins:{top:80,bottom:80,left:120,right:120},
        children:[new Paragraph({children:[new TextRun({text:label,bold:true,color:"FFFFFF",size:18,font:"Arial"})]})]
      }),
      new TableCell({
        borders: bdrs, width:{size:7060,type:WidthType.DXA},
        shading:{fill,type:ShadingType.CLEAR},
        margins:{top:80,bottom:80,left:120,right:120},
        children:[new Paragraph({children:[new TextRun({text:val,size:18,font:"Arial"})]})]
      })
    ]})]
  });
  return [
    row("Question Topic", q, "EBF5FB"),
    row("My Wrong Answer", wrong, "FDEDEC"),
    row("Correct Answer", correct, "EAFAF1"),
    row("Why I Was Wrong", why, "FEF9E7"),
    row("Doc Reference", ref, "F0F3FF"),
    row("Hands-On Fix", fix, "F5F5F5"),
    blank()
  ];
};

const wrongAnswers = [
  ["Q4 Topic 1 - Advantage of Immutable Infrastructure",
   "C - Quicker infrastructure upgrades",
   "D - Less complex infrastructure upgrades",
   "I confused speed with simplicity. The core advantage of immutability is reduced complexity: you eliminate configuration drift, partial upgrade states, and dependency conflicts. Quicker deploys are a side-effect, not the defining benefit.",
   "https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code",
   "terraform destroy && terraform apply  # Full replacement vs in-place patch to feel the immutability difference"],
  ["terraform state rm - Effect on real infrastructure",
   "Believed terraform state rm destroys the actual cloud resource",
   "terraform state rm removes the resource from Terraform state only. Real infrastructure keeps running, now unmanaged.",
   "I conflated state management with resource lifecycle. terraform destroy deletes infrastructure. terraform state rm removes Terraform awareness of it - the resource becomes orphaned.",
   "https://developer.hashicorp.com/terraform/cli/commands/state/rm",
   "terraform state rm aws_instance.example && terraform state list  # confirm gone from state; instance still exists in AWS console"],
  ["Terraform Cloud - Remote state vs remote operations",
   "Assumed the cloud backend always executes plans remotely",
   "Terraform Cloud backend can be configured for remote operations OR just remote state. Plans can still run locally via CLI.",
   "I did not distinguish between backend type and execution mode. The execution_mode workspace setting controls where plans run, independent of where state is stored.",
   "https://developer.hashicorp.com/terraform/cloud-docs/run/remote-operations",
   "terraform init (cloud backend) + terraform plan; observe whether local or remote based on workspace execution_mode setting"],
  ["Module source types - which support version constraints",
   "Said all module sources support the version argument",
   "Only Terraform Registry sources (public and private) support the version argument. Local paths and Git sources do not.",
   "I overgeneralised. The version argument is a registry-only feature. For Git use ref= in the URL. Local paths have no versioning mechanism.",
   "https://developer.hashicorp.com/terraform/language/modules/sources",
   "module vpc { source = terraform-aws-modules/vpc/aws; version = ~> 5.0 } -- try adding version to a local module and see it fail"],
  ["terraform refresh - What it updates",
   "Thought terraform refresh updates the .tf configuration files to match real infrastructure",
   "terraform refresh updates the state file only. Configuration files (.tf) are never modified by any Terraform command.",
   "I confused the direction of the refresh operation. State is updated to match reality. Configuration files only change when a human edits them. Terraform never writes back to .tf files.",
   "https://developer.hashicorp.com/terraform/cli/commands/refresh",
   "terraform refresh && terraform show  # state reflects actual infra; diff main.tf shows zero changes to config files"],
  ["sensitive = true on output values - Security scope",
   "Assumed sensitive = true encrypts the value in the state file",
   "sensitive = true suppresses the value in CLI output only. The value is stored in plaintext in terraform.tfstate.",
   "I over-attributed security to a display-only flag. The sensitive flag is purely cosmetic in the CLI. Real secret protection at rest requires encrypted backends: S3+KMS, Terraform Cloud, or Vault.",
   "https://developer.hashicorp.com/terraform/language/values/outputs#sensitive-suppressing-values-in-cli-output",
   "terraform output -json  # reveals value despite sensitive flag; cat terraform.tfstate shows plaintext value in state"],
];

const stateLines = [
  "$ terraform state list",
  "aws_instance.web",
  "aws_security_group.allow_http",
  "aws_vpc.main",
  " ",
  "$ terraform state show aws_instance.web",
  "resource aws_instance web {",
  "    ami           = ami-0c55b159cbfafe1f0",
  "    instance_type = t3.micro",
  "}",
  " ",
  "$ terraform state mv aws_instance.web module.compute.aws_instance.web",
  "Successfully moved 1 object(s).",
  " ",
  "$ terraform state rm module.compute.aws_instance.web",
  "Successfully removed 1 resource instance(s).",
  "# EC2 INSTANCE IS STILL RUNNING IN AWS CONSOLE",
  " ",
  "$ terraform import aws_instance.web i-0abc123def456789a",
  "Import successful! Resource added back to state.",
];

const moduleLines = [
  "# modules/compute/main.tf",
  "variable instance_type { default = t3.micro }",
  "variable ami_id {}",
  "resource aws_instance this {",
  "  ami           = var.ami_id",
  "  instance_type = var.instance_type",
  "}",
  "output instance_id { value = aws_instance.this.id }",
  " ",
  "# root/main.tf",
  "module compute {",
  "  source = ./modules/compute",
  "  ami_id = ami-0c55b159cbfafe1f0",
  "}",
  "module vpc {",
  "  source  = terraform-aws-modules/vpc/aws",
  "  version = ~> 5.0",
  "  cidr    = 10.0.0.0/16",
  "}",
  " ",
  "$ terraform init",
  "Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 5.1.2",
  "- compute in ./modules/compute",
];

const cloudLines = [
  "# backend.tf",
  "terraform {",
  "  cloud {",
  "    organization = my-test-org",
  "    workspaces { name = day28-test }",
  "  }",
  "}",
  " ",
  "$ terraform login",
  "Token generated. Saved to ~/.terraform.d/credentials.tfrc.json",
  " ",
  "$ terraform init",
  "Initializing Terraform Cloud...",
  " ",
  "# With workspace execution_mode = remote:",
  "$ terraform plan",
  "Running plan in Terraform Cloud. Output will stream here.",
  " ",
  "# After switching to local execution_mode in TF Cloud UI:",
  "$ terraform plan",
  "# Runs locally. State still stored in Terraform Cloud.",
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
        paragraph: { spacing: { before: 240, after: 80 }, outlineLevel: 1 } },
    ]
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [{
    properties: {
      page: { size: { width: 12240, height: 15840 }, margin: { top: 1080, right: 1080, bottom: 1080, left: 1080 } }
    },
    headers: {
      default: new Header({ children: [
        new Paragraph({
          children: [new TextRun({ text: "Day 28  |  Terraform Associate Exam Prep  |  30-Day Terraform Challenge", size: 18, font: "Arial", color: "2D6A4F" })],
          border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "1A6B3A", space: 1 } }
        })
      ]})
    },
    footers: {
      default: new Footer({ children: [
        new Paragraph({
          children: [
            new TextRun({ text: "AWS AI/ML UserGroup Kenya  |  Meru HashiCorp User Group  |  EveOps    Page ", size: 16, font: "Arial", color: "888888" }),
            new TextRun({ children: [PageNumber.CURRENT], size: 16, font: "Arial", color: "888888" }),
          ],
          alignment: AlignmentType.CENTER,
          border: { top: { style: BorderStyle.SINGLE, size: 4, color: "1A6B3A", space: 1 } }
        })
      ]})
    },
    children: [
      // TITLE
      blank(), blank(),
      new Paragraph({ children: [new TextRun({ text: "DAY 28", bold: true, size: 80, font: "Arial", color: "1A6B3A" })], alignment: AlignmentType.CENTER, spacing: { before: 720, after: 120 } }),
      new Paragraph({ children: [new TextRun({ text: "Practice Exams 1 & 2", bold: true, size: 44, font: "Arial", color: "2D6A4F" })], alignment: AlignmentType.CENTER, spacing: { before: 0, after: 120 } }),
      new Paragraph({ children: [new TextRun({ text: "Terraform Associate Certification Prep", size: 28, font: "Arial", color: "666666" })], alignment: AlignmentType.CENTER, spacing: { before: 0, after: 480 } }),
      new Paragraph({
        children: [new TextRun({ text: "30-Day Terraform Challenge  |  AWS AI/ML UserGroup Kenya  |  EveOps", bold: true, size: 22, font: "Arial", color: "1A6B3A" })],
        alignment: AlignmentType.CENTER,
        border: { top: { style: BorderStyle.SINGLE, size: 4, color: "1A6B3A", space: 6 }, bottom: { style: BorderStyle.SINGLE, size: 4, color: "1A6B3A", space: 6 } },
        spacing: { before: 120, after: 120 }
      }),
      blank(), blank(),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [3120, 3120, 3120],
        rows: [new TableRow({ children: [
          new TableCell({ borders: gbdrs, width:{size:3120,type:WidthType.DXA}, shading:{fill:"1A6B3A",type:ShadingType.CLEAR}, margins:{top:200,bottom:200,left:200,right:200}, children:[
            new Paragraph({alignment:AlignmentType.CENTER,children:[new TextRun({text:"73.7%",bold:true,size:52,font:"Arial",color:"FFFFFF"})]}),
            new Paragraph({alignment:AlignmentType.CENTER,children:[new TextRun({text:"Exam 1 Score",size:20,font:"Arial",color:"CCFFCC"})]})
          ]}),
          new TableCell({ borders: gbdrs, width:{size:3120,type:WidthType.DXA}, shading:{fill:"2D6A4F",type:ShadingType.CLEAR}, margins:{top:200,bottom:200,left:200,right:200}, children:[
            new Paragraph({alignment:AlignmentType.CENTER,children:[new TextRun({text:"78.9%",bold:true,size:52,font:"Arial",color:"FFFFFF"})]}),
            new Paragraph({alignment:AlignmentType.CENTER,children:[new TextRun({text:"Exam 2 Score",size:20,font:"Arial",color:"CCFFCC"})]})
          ]}),
          new TableCell({ borders: gbdrs, width:{size:3120,type:WidthType.DXA}, shading:{fill:"40916C",type:ShadingType.CLEAR}, margins:{top:200,bottom:200,left:200,right:200}, children:[
            new Paragraph({alignment:AlignmentType.CENTER,children:[new TextRun({text:"+5.2%",bold:true,size:52,font:"Arial",color:"FFFFFF"})]}),
            new Paragraph({alignment:AlignmentType.CENTER,children:[new TextRun({text:"Improvement",size:20,font:"Arial",color:"CCFFCC"})]})
          ]}),
        ]})]
      }),
      pgbrk(),

      // SECTION 1 - SCORES
      h1("1. Exam Scores"),
      sp("Both practice exams completed under strict 60-minute timed conditions. No reference material consulted mid-exam."),
      blank(),
      scoreTable(),
      blank(),
      h2("Score Analysis"),
      sp("Exam 2 scored 5.2 percentage points higher. Three factors:"),
      bul("Warm-up effect: pattern recognition for question phrasing sharpened after 57 questions in Exam 1."),
      bul("Different question source: Exam 2 used ExamTopics with more scenario-based questions which suit my strengths."),
      bul("Break review: 15-minute break was used to scan three weakest domains, directly improving Exam 2 accuracy."),
      blank(),
      sp("Key insight: Doing a 20-minute focused review of Modules, State, and Terraform Cloud before the real exam will prime those areas."),
      pgbrk(),

      // SECTION 2 - DOMAIN TABLE
      h1("2. Domain Accuracy Table"),
      sp("Combined results across both exams (114 total questions). Amber domains are below 70% and received targeted hands-on remediation."),
      blank(),
      domainTable(),
      blank(),
      h2("Domains Below 70% Threshold"),
      bul("Terraform Modules (63%) - Version constraints scope and module composition patterns."),
      bul("State Management (60%) - terraform state rm vs terraform destroy; sensitive value storage in state."),
      bul("Terraform Cloud (60%) - Remote operations vs remote state; workspace execution modes."),
      pgbrk(),

      // SECTION 3 - WRONG ANSWERS
      h1("3. Wrong Answer Analysis"),
      sp("Every missed question reviewed using the structured template below. Six high-value entries are documented. Analysis targets the reasoning error, not just the correct answer."),
      blank(),
      h2("Entry 1 of 6"),
      ...waCard(...wrongAnswers[0]),
      h2("Entry 2 of 6"),
      ...waCard(...wrongAnswers[1]),
      h2("Entry 3 of 6"),
      ...waCard(...wrongAnswers[2]),
      pgbrk(),
      h2("Entry 4 of 6"),
      ...waCard(...wrongAnswers[3]),
      h2("Entry 5 of 6"),
      ...waCard(...wrongAnswers[4]),
      h2("Entry 6 of 6"),
      ...waCard(...wrongAnswers[5]),
      pgbrk(),

      // SECTION 4 - HANDS ON
      h1("4. Hands-On Revision for Weak Domains"),
      sp("Every weak domain received at least one hands-on exercise. Commands and observed output documented here. Reading docs tells you what things do. Running commands tells you how they actually behave."),
      blank(),

      h2("4.1 State Management"),
      sp("Ran a full state lifecycle exercise against a test EC2 instance. Key finding: terraform state rm is non-destructive to real infrastructure. The resource continued running after removal from state."),
      blank(),
      ...stateLines.map(l => codeLine(l)),
      blank(),

      h2("4.2 Terraform Modules"),
      sp("Wrote a reusable compute module and called it from root config with both registry (versioned) and local sources. Confirmed version argument is rejected for local sources."),
      blank(),
      ...moduleLines.map(l => codeLine(l)),
      blank(),

      h2("4.3 Terraform Cloud Execution Modes"),
      sp("Configured a workspace with the cloud backend and toggled between remote and local execution modes. Observed plan behaviour change without state location changing."),
      blank(),
      ...cloudLines.map(l => codeLine(l)),
      pgbrk(),

      // SECTION 5 - PATTERNS
      h1("5. Pattern Recognition"),
      sp("Three consistent error patterns identified after reviewing all wrong answers from both exams:"),
      blank(),

      h2("Pattern 1: Scope Confusion"),
      sp("Multiple wrong answers came from applying a behaviour too broadly. Examples: sensitive = true provides state-level encryption (it is display-only); all module sources support version constraints (registry only); terraform refresh updates configuration files (state only). Fix: for every flag or argument, explicitly ask what it affects: CLI output? State? Config? Real infrastructure?"),

      blank(),
      h2("Pattern 2: Conflating Similar Commands"),
      sp("Consistent confusion between pairs that seem related but have completely different effects: terraform state rm vs terraform destroy, terraform refresh vs terraform apply -refresh-only, and terraform taint vs terraform apply -replace. Fix: command comparison table mapping each command to what it reads, what it writes, and whether it touches real infrastructure."),

      blank(),
      h2("Pattern 3: Immutability vs Idempotency"),
      sp("IaC concept questions revealed inconsistent application of immutable infrastructure, idempotency, and declarative provisioning. These concepts overlap in Terraform but are distinct. Fix: write own definitions from scratch and verify against HashiCorp documentation before the exam."),
      pgbrk(),

      // SECTION 6 - PLAN
      h1("6. Plan for Days 29 and 30"),

      h2("Day 29 - Targeted Remediation"),
      sp("Focus exclusively on the three sub-70% domains. No broad review - only deep work on specific gaps."),
      blank(),
      bul("State Management: Build command comparison table. Run terraform state mv on multi-resource config to feel the state file change. Re-read state rm documentation carefully."),
      bul("Modules: Write three modules from scratch: input variables with validation, output values, and count/for_each meta-arguments. Call each from root module."),
      bul("Terraform Cloud: Go through workspace settings in the UI. Map each setting (execution mode, VCS, variable sets) to CLI behaviour it affects."),
      bul("IaC Concepts: Write out definitions of immutable, idempotent, and declarative from memory. Check against docs. Correct gaps."),

      blank(),
      h2("Day 30 - Final Review and Exam"),
      sp("Light review only. Exam is the priority."),
      blank(),
      bul("Morning: 20-minute review of command comparison table and wrong-answer cards from Day 28."),
      bul("Pre-exam: Review three weak domain summaries only. No new material."),
      bul("Exam: 57 questions, 60 minutes. Flag uncertain questions. Complete first pass, then revisit flagged questions."),
      bul("Target: 80%+ (46/57). Based on trajectory from Exam 1 to Exam 2, this is achievable with Day 29 remediation."),
      pgbrk(),

      // SECTION 7 - BLOG
      h1("7. Blog Post"),
      h2("Title: How I Prepared for the Terraform Associate Exam with Practice Questions"),
      blank(),
      sp("Day 28 was the most brutally useful day of this challenge. Two full practice exams back to back, scored honestly, every wrong answer analysed before stopping for the day. Here is what actually happened."),
      blank(),
      h3("The Scores"),
      sp("Exam 1: 42/57 = 73.7%. Exam 2: 45/57 = 78.9%. Both above the 70% threshold. Both reminding me that I am not fully ready yet."),
      blank(),
      h3("What the Domain Table Revealed"),
      sp("Three domains came in below 70%: Modules at 63%, State Management at 60%, and Terraform Cloud at 60%. The State Management score was humbling. I have used Terraform state commands professionally for two years and still got 40% of exam questions wrong. The gap between practical experience and exam knowledge is real. In production you always know the context. An exam strips context away and asks you to know exact command behaviour in isolation."),
      blank(),
      h3("The Wrong Answer That Hurt Most"),
      sp("Question 4, Topic 1: advantage of immutable infrastructure. I picked quicker infrastructure upgrades. Correct answer is less complex infrastructure upgrades. I knew what immutability was. I answered fast and picked what felt right rather than what was precisely accurate. That is an exam discipline problem, not a knowledge problem."),
      blank(),
      h3("What the Hands-On Time Fixed"),
      sp("After the exams I spent 90 minutes at the terminal. I ran terraform state rm on a real resource and watched it keep running in AWS after disappearing from state. That 30-second terminal session will ensure I never miss that question again. Documentation tells you what things do. Running the command tells you what it feels like."),
      blank(),
      sp("Blog URL: [To be published before submission]", false),
      blank(),

      // SECTION 8 - SOCIAL
      h1("8. Social Media Post"),
      blank(),
      new Paragraph({
        shading: { fill: "F0FFF4", type: ShadingType.CLEAR },
        border: { left: { style: BorderStyle.SINGLE, size: 12, color: "1A6B3A", space: 8 } },
        indent: { left: 360 },
        spacing: { before: 120, after: 120 },
        children: [new TextRun({
          text: "Day 28 of the 30-Day Terraform Challenge - two full practice exams done. Scored 73.7% and 78.9%. Analysed every wrong answer, identified three weak domains (Modules, State, Cloud), and ran hands-on exercises to close the gaps. Two days to go. #30DayTerraformChallenge #TerraformChallenge #Terraform #TerraformAssociate #CertificationPrep #AWSUserGroupKenya #EveOps",
          size: 22, font: "Arial", italics: true, color: "1B4332"
        })]
      }),
      blank(),
      sp("Social Media URL: [To be added after publishing]"),
      blank(), blank(),
      new Paragraph({
        children: [new TextRun({ text: "This challenge is brought to you by AWS AI/ML UserGroup Kenya, Meru HashiCorp User Group, and EveOps.", size: 18, font: "Arial", color: "888888", italics: true })],
        alignment: AlignmentType.CENTER
      })
    ]
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync("/mnt/user-data/outputs/Day28_TerraformExamPrep.docx", buf);
  console.log("SUCCESS: Day28_TerraformExamPrep.docx created");
}).catch(err => console.error("ERROR:", err));
