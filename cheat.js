
const {Document,Packer,Paragraph,TextRun,Table,TableRow,TableCell,AlignmentType,BorderStyle,WidthType,ShadingType,LevelFormat,Header,Footer,PageNumber,HeadingLevel,PageBreak} = require("docx");
const fs = require("fs");
const bdr={style:BorderStyle.SINGLE,size:1,color:"CCCCCC"};
const bdrs={top:bdr,bottom:bdr,left:bdr,right:bdr};
const gbdr={style:BorderStyle.SINGLE,size:4,color:"1A6B3A"};
const gbdrs={top:gbdr,bottom:gbdr,left:gbdr,right:gbdr};
const blank=()=>new Paragraph({children:[new TextRun("")],spacing:{before:60,after:60}});
const h1=(t)=>new Paragraph({heading:HeadingLevel.HEADING_1,children:[new TextRun({text:t,bold:true,size:28,font:"Arial",color:"1A6B3A"})],spacing:{before:300,after:100},border:{bottom:{style:BorderStyle.SINGLE,size:6,color:"1A6B3A",space:1}}});
const h2=(t)=>new Paragraph({heading:HeadingLevel.HEADING_2,children:[new TextRun({text:t,bold:true,size:22,font:"Arial",color:"2D6A4F"})],spacing:{before:200,after:60}});
const sp=(t,bold)=>new Paragraph({children:[new TextRun({text:t,size:20,font:"Arial",bold:bold||false})],spacing:{before:40,after:40}});
const codeLine=(t)=>new Paragraph({children:[new TextRun({text:t,size:16,font:"Courier New",color:"E2E8F0"})],shading:{fill:"1E293B",type:ShadingType.CLEAR},indent:{left:200},spacing:{before:0,after:0}});
const hCell=(t,w,fill)=>new TableCell({borders:gbdrs,width:{size:w,type:WidthType.DXA},shading:{fill:fill||"1A6B3A",type:ShadingType.CLEAR},margins:{top:70,bottom:70,left:100,right:100},children:[new Paragraph({children:[new TextRun({text:t,bold:true,color:"FFFFFF",size:16,font:"Arial"})]})]});
const dCell=(t,w,fill,color,bold)=>new TableCell({borders:bdrs,width:{size:w,type:WidthType.DXA},shading:{fill:fill||"FAFAFA",type:ShadingType.CLEAR},margins:{top:60,bottom:60,left:100,right:100},children:[new Paragraph({children:[new TextRun({text:t,size:16,font:"Arial",color:color||"111111",bold:bold||false})]})]});

const commandData=[
  ["terraform state rm","State file only","No change","Resource becomes orphaned, still running"],
  ["terraform destroy","State file","Deletes resource","Destroys real infrastructure"],
  ["terraform refresh","Real infra (read)","State file updated","Config files untouched"],
  ["terraform apply -refresh-only","Real infra (read)","State file updated","Same as refresh, modern syntax"],
  ["terraform taint","State file only","Marks for replacement","Deprecated; use apply -replace"],
  ["terraform apply -replace=X","Real infra","Destroys + recreates resource","Modern replacement for taint"],
  ["terraform state mv","State file only","Renames resource in state","Does not change real infra"],
  ["terraform import","Real infra (read)","Adds resource to state","Does not modify real infra"],
  ["terraform output -json","State file","None","Reveals sensitive values in JSON mode"],
  ["terraform plan","State + real infra","None (dry run)","Shows what apply would do"],
];

const sourceData=[
  ["Registry (public)","terraform-aws-modules/vpc/aws","Yes","Versioned, signed, cached"],
  ["Registry (private)","app.terraform.io/org/module","Yes","Requires auth"],
  ["Local path","./modules/compute","No","No version, no caching"],
  ["GitHub (HTTPS)","github.com/org/repo","No (use ref=)","git::https://github.com/org/repo.git?ref=v1.0"],
  ["Generic Git","git::https://...","No (use ref=)","Append ?ref=branch/tag/sha"],
  ["HTTP URL","https://example.com/mod.zip","No","Downloaded directly"],
];

const doc=new Document({
  styles:{default:{document:{run:{font:"Arial",size:20}}},paragraphStyles:[
    {id:"Heading1",name:"Heading 1",basedOn:"Normal",next:"Normal",quickFormat:true,run:{size:28,bold:true,font:"Arial"},paragraph:{spacing:{before:300,after:100},outlineLevel:0}},
    {id:"Heading2",name:"Heading 2",basedOn:"Normal",next:"Normal",quickFormat:true,run:{size:22,bold:true,font:"Arial"},paragraph:{spacing:{before:200,after:60},outlineLevel:1}},
  ]},
  sections:[{
    properties:{page:{size:{width:15840,height:12240},margin:{top:720,right:720,bottom:720,left:720}}},
    children:[
      new Paragraph({children:[new TextRun({text:"Terraform Associate - Day 28 Cheat Sheet",bold:true,size:36,font:"Arial",color:"1A6B3A"})],alignment:AlignmentType.CENTER,spacing:{before:100,after:60},border:{bottom:{style:BorderStyle.SINGLE,size:6,color:"1A6B3A",space:1}}}),
      new Paragraph({children:[new TextRun({text:"State Commands  |  Module Sources  |  IaC Concepts  |  Terraform Cloud",size:20,font:"Arial",color:"666666"})],alignment:AlignmentType.CENTER,spacing:{before:40,after:200}}),

      h1("State Command Reference"),
      new Table({
        width:{size:13680,type:WidthType.DXA},
        columnWidths:[2600,2600,2600,5880],
        rows:[
          new TableRow({children:[hCell("Command",2600),hCell("Reads",2600),hCell("Writes",2600),hCell("Effect on Real Infrastructure",5880)]}),
          ...commandData.map(([cmd,reads,writes,effect])=>new TableRow({children:[dCell(cmd,2600,"F0FFF4","1B4332",true),dCell(reads,2600),dCell(writes,2600),dCell(effect,5880)]}))
        ]
      }),
      blank(),

      h1("Module Source Types"),
      new Table({
        width:{size:13680,type:WidthType.DXA},
        columnWidths:[2000,3500,1800,6380],
        rows:[
          new TableRow({children:[hCell("Source Type",2000),hCell("Example",3500),hCell("version arg?",1800),hCell("Notes",6380)]}),
          ...sourceData.map(([type,ex,ver,notes])=>new TableRow({children:[dCell(type,2000,"F0FFF4","1B4332",true),dCell(ex,3500,"F8F8F8","444444"),dCell(ver,1800,ver==="Yes"?"D4EDDA":"FFF3CD",ver==="Yes"?"155724":"856404",true),dCell(notes,6380)]}))
        ]
      }),
      blank(),

      h1("Key IaC Concept Distinctions"),
      new Table({
        width:{size:13680,type:WidthType.DXA},
        columnWidths:[2400,5640,5640],
        rows:[
          new TableRow({children:[hCell("Concept",2400),hCell("Definition",5640),hCell("Terraform Implementation",5640)]}),
          new TableRow({children:[dCell("Immutable Infra",2400,"F0FFF4","1B4332",true),dCell("Replace resources instead of modifying in place. No drift.",5640),dCell("terraform destroy + apply or apply -replace. Main advantage: LESS COMPLEX (not necessarily faster)",5640)]}),
          new TableRow({children:[dCell("Idempotent",2400,"F0FFF4","1B4332",true),dCell("Running the same operation multiple times produces same result.",5640),dCell("terraform apply is idempotent: if infra matches config, no changes made.",5640)]}),
          new TableRow({children:[dCell("Declarative",2400,"F0FFF4","1B4332",true),dCell("You describe the desired end state; the tool figures out how to get there.",5640),dCell("HCL config declares desired state. Terraform calculates diff against current state.",5640)]}),
          new TableRow({children:[dCell("sensitive = true",2400,"FFF3CD","856404",true),dCell("Suppresses value in CLI output ONLY. Does NOT encrypt in state.",5640),dCell("Value still plaintext in terraform.tfstate. Use encrypted backend for real security.",5640)]}),
        ]
      }),
      blank(),

      h1("Terraform Cloud: Remote State vs Remote Operations"),
      new Table({
        width:{size:13680,type:WidthType.DXA},
        columnWidths:[2800,5440,5440],
        rows:[
          new TableRow({children:[hCell("Setting",2800),hCell("Remote State Only",5440),hCell("Full Remote Operations",5440)]}),
          new TableRow({children:[dCell("execution_mode",2800,"F0FFF4","1B4332",true),dCell("local",5440),dCell("remote or agent",5440)]}),
          new TableRow({children:[dCell("Where plan runs",2800,"F0FFF4","1B4332",true),dCell("On developer machine",5440),dCell("In Terraform Cloud worker",5440)]}),
          new TableRow({children:[dCell("State storage",2800,"F0FFF4","1B4332",true),dCell("Terraform Cloud (encrypted)",5440),dCell("Terraform Cloud (encrypted)",5440)]}),
          new TableRow({children:[dCell("terraform plan output",2800,"F0FFF4","1B4332",true),dCell("Local terminal",5440),dCell("Streams from Cloud to terminal",5440)]}),
          new TableRow({children:[dCell("Sentinel policies",2800,"F0FFF4","1B4332",true),dCell("NOT applied",5440,"FFF3CD","856404",true),dCell("Applied before apply",5440,"D4EDDA","155724",true)]}),
        ]
      }),
    ]
  }]
});

Packer.toBuffer(doc).then(buf=>{
  fs.writeFileSync("/home/claude/day28/Day28_CheatSheet.docx",buf);
  console.log("Cheatsheet done");
}).catch(e=>console.error(e));
