#!/usr/bin/env python3
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

W, H = 22, 16
fig, ax = plt.subplots(figsize=(W, H))
ax.set_xlim(0, W); ax.set_ylim(0, H); ax.axis("off")
fig.patch.set_facecolor("#F0F4F8")

C = dict(
    orange="#FF9900", vpc_bg="#EAF4FD", vpc_bd="#1565C0",
    pub_bg="#E8F8EE", pub_bd="#2E7D32",
    priv_bg="#FFFDE7", priv_bd="#F57F17",
    alb_bg="#E3F2FD", alb_bd="#1565C0",
    nat_bg="#E0F2F1", nat_bd="#00695C",
    ec2_bg="#FFF3E0", ec2_bd="#E65100",
    asg_bg="#F3E5F5", asg_bd="#6A1B9A",
    igw_bg="#FFEBEE", igw_bd="#C62828",
    cw_bg="#E8F5E9",  cw_bd="#2E7D32",
    sg_bd="#AD1457",
    user_bg="#ECEFF1",user_bd="#37474F",
    tgt_bg="#EDE7F6", tgt_bd="#4527A0",
)

def box(x,y,w,h,fc,ec,lw=1.8,r=0.3,z=3,alpha=1.0):
    ax.add_patch(FancyBboxPatch((x,y),w,h,
        boxstyle=f"round,pad=0,rounding_size={r}",
        fc=fc,ec=ec,lw=lw,zorder=z,alpha=alpha))

def t(x,y,s,fs=8,c="black",bold=False,ha="center",va="center",z=15,italic=False):
    ax.text(x,y,s,fontsize=fs,color=c,
            fontweight="bold" if bold else "normal",
            fontstyle="italic" if italic else "normal",
            ha=ha,va=va,zorder=z,multialignment="center")

def arr(x1,y1,x2,y2,c="#212121",lw=1.8,lbl="",lc="#333",fs=7,rad=0.0,z=12):
    ax.annotate("",xy=(x2,y2),xytext=(x1,y1),
        arrowprops=dict(arrowstyle="->",color=c,lw=lw,
                        connectionstyle=f"arc3,rad={rad}"),zorder=z)
    if lbl:
        mx,my=(x1+x2)/2,(y1+y2)/2
        ax.text(mx,my,lbl,fontsize=fs,color=lc,ha="center",va="center",zorder=z+2,
            bbox=dict(boxstyle="round,pad=0.2",fc="white",ec="none",alpha=0.92))

# ── TITLE
t(11,15.65,"Day 17 — AWS Webserver Cluster Architecture (High Availability)",fs=15,bold=True,c="#1A237E")
t(11,15.25,"Terraform: Up & Running | Chapter 9: Manual Testing | Two-AZ Deployment | us-east-1",fs=9,c="#546E7A",italic=True)

# ── USERS
box(8.6,13.9,4.8,1.0,C["user_bg"],C["user_bd"],lw=2,z=6)
t(11,14.55,"Internet / End Users",fs=10,bold=True,c=C["user_bd"])
t(11,14.18,"curl http://<alb-dns>  |  Browser  (Port 80)",fs=8,c="#546E7A")

# ── AWS REGION
box(0.3,0.3,21.4,13.3,"#FAFAFA",C["orange"],lw=2.5,r=0.5,z=1)
t(1.2,13.38,"AWS Region: us-east-1",fs=9,bold=True,c=C["orange"],ha="left")

# ── VPC
box(0.7,0.55,20.6,12.55,C["vpc_bg"],C["vpc_bd"],lw=2.2,r=0.4,z=2)
t(1.7,12.88,"VPC — 10.0.0.0/16  |  DNS support + DNS hostnames enabled",fs=9,bold=True,c=C["vpc_bd"],ha="left")

# ── IGW
box(8.1,11.72,5.8,0.9,C["igw_bg"],C["igw_bd"],lw=2.2,z=7)
t(11,12.22,"Internet Gateway (IGW)",fs=9,bold=True,c=C["igw_bd"])
t(11,11.9,"Attached to VPC  |  Route Table: 0.0.0.0/0 -> IGW (public subnets only)",fs=7,c="#555")

# ── PUBLIC SUBNETS
for az,cidr,px,nat_cidr in [
    ("us-east-1a","10.0.1.0/24",1.0,"EIP-1"),
    ("us-east-1b","10.0.2.0/24",11.3,"EIP-2"),
]:
    box(px,8.1,9.5,3.35,C["pub_bg"],C["pub_bd"],lw=1.8,r=0.35,z=3)
    t(px+4.75,11.27,f"Public Subnet — {az}",fs=8.5,bold=True,c=C["pub_bd"])
    t(px+4.75,10.97,f"CIDR: {cidr}  |  map_public_ip_on_launch = true",fs=7,c="#444")

    # ALB
    box(px+0.2,8.35,4.4,2.5,C["alb_bg"],C["alb_bd"],lw=2,z=8)
    t(px+2.4,10.72,"Application Load Balancer",fs=8,bold=True,c=C["alb_bd"])
    t(px+2.4,10.42,"internet-facing  |  HTTP Listener :80",fs=7,c="#333")
    t(px+2.4,10.12,"Default action -> forward to TG",fs=7,c="#333")
    t(px+2.4,9.82,"SG: alb-sg",fs=7,bold=True,c=C["sg_bd"])
    t(px+2.4,9.52,"IN: 0.0.0.0/0:80  OUT: inst-sg:8080",fs=6.5,c=C["sg_bd"])
    t(px+2.4,9.2,"Nodes span both public subnets",fs=6.5,c="#777",italic=True)
    t(px+2.4,8.6,"ALB Listener -> Target Group",fs=6.5,c=C["alb_bd"],italic=True)

    # NAT
    box(px+4.85,8.35,4.4,2.5,C["nat_bg"],C["nat_bd"],lw=2,z=8)
    t(px+7.05,10.72,"NAT Gateway",fs=8,bold=True,c=C["nat_bd"])
    t(px+7.05,10.42,"One per AZ (High Availability)",fs=7,c="#333")
    t(px+7.05,10.12,f"Elastic IP: {nat_cidr}",fs=7,c="#333")
    t(px+7.05,9.82,"Outbound internet for",fs=7,c="#333")
    t(px+7.05,9.52,"private instances",fs=7,c="#333")
    t(px+7.05,9.22,"HTTPS :443 only (via SG)",fs=6.5,c="#555")
    t(px+7.05,8.7,"Route: 0.0.0.0/0 -> NAT",fs=6.5,c=C["nat_bd"],italic=True)

# ── PRIVATE SUBNETS
for az,cidr,px in [
    ("us-east-1a","10.0.11.0/24",1.0),
    ("us-east-1b","10.0.12.0/24",11.3),
]:
    box(px,0.6,9.5,7.2,C["priv_bg"],C["priv_bd"],lw=1.8,r=0.35,z=3)
    t(px+4.75,7.62,f"Private Subnet — {az}",fs=8.5,bold=True,c=C["priv_bd"])
    t(px+4.75,7.32,f"CIDR: {cidr}  |  No public IP  |  Egress -> NAT Gateway",fs=7,c="#444")

    # ASG
    box(px+0.2,0.82,9.1,6.25,C["asg_bg"],C["asg_bd"],lw=1.8,r=0.3,z=4,alpha=0.5)
    t(px+4.75,6.92,"Auto Scaling Group (ASG)",fs=8,bold=True,c=C["asg_bd"])
    t(px+4.75,6.62,"min=2  desired=2  max=6  |  health_check=ELB  |  grace_period=120s",fs=6.5,c=C["asg_bd"])
    t(px+4.75,6.35,"Instance Refresh: Rolling  |  min_healthy=50%  |  create_before_destroy",fs=6.5,c=C["asg_bd"])

    # EC2 x2
    for j in range(2):
        ex=px+0.35+j*4.6
        box(ex,1.05,4.3,5.0,C["ec2_bg"],C["ec2_bd"],lw=1.8,r=0.25,z=9)
        t(ex+2.15,5.9,f"EC2 Instance {j+1}",fs=8,bold=True,c=C["ec2_bd"])
        t(ex+2.15,5.6,"Amazon Linux 2023",fs=7,c="#333")
        t(ex+2.15,5.32,"t3.micro (dev) / t3.small (prod)",fs=6.5,c="#333")
        t(ex+2.15,5.04,"Launch Template ($Latest)",fs=6.5,c="#333")
        t(ex+2.15,4.76,"IMDSv2 required | Monitoring ON",fs=6.5,c="#555")
        # web server sub-box
        box(ex+0.2,3.6,3.9,0.85,"#E8F5E9",C["pub_bd"],lw=1.4,r=0.2,z=10)
        t(ex+2.15,4.1,"Python HTTP :8080",fs=7,bold=True,c=C["pub_bd"])
        t(ex+2.15,3.8,'GET /  ->  "Hello World v2"',fs=6.5,c="#333")
        t(ex+2.15,3.4,"SG: instance-sg",fs=7,bold=True,c=C["sg_bd"])
        t(ex+2.15,3.12,"IN: alb-sg:8080  OUT: 0.0.0.0/0:443",fs=6.2,c=C["sg_bd"])
        t(ex+2.15,2.82,"Tags: ManagedBy=terraform",fs=6.2,c="#546E7A")
        t(ex+2.15,2.54,"Environment | Project | Name",fs=6.2,c="#546E7A")
        box(ex+0.35,1.15,3.6,0.65,"#F1F8E9",C["pub_bd"],lw=1.2,r=0.18,z=11)
        t(ex+2.15,1.5,"Health Check: GET /  2/2 threshold",fs=6.5,bold=True,c=C["pub_bd"])

# ── TARGET GROUP (center between AZs)
box(8.5,3.3,5.0,2.5,C["tgt_bg"],C["tgt_bd"],lw=2,z=7)
t(11,5.65,"ALB Target Group",fs=9,bold=True,c=C["tgt_bd"])
t(11,5.35,"Protocol: HTTP  |  Port: 8080",fs=7.5,c="#333")
t(11,5.05,"Deregistration delay: 30s",fs=7,c="#555")
t(11,4.75,"Health: GET /  interval=15s",fs=7,c="#555")
t(11,4.45,"timeout=5s  matcher=HTTP 200",fs=7,c="#555")
t(11,4.15,"Healthy threshold: 2",fs=7,c="#555")
t(11,3.85,"Unhealthy threshold: 2",fs=7,c="#555")
t(11,3.52,"ALB forwards all HTTP :80 traffic here",fs=7,c=C["tgt_bd"],italic=True)

# ── CLOUDWATCH
box(16.4,5.3,5.2,4.7,C["cw_bg"],C["cw_bd"],lw=1.8,z=7)
t(19.0,9.82,"CloudWatch Alarms",fs=9.5,bold=True,c=C["cw_bd"])
t(19.0,9.45,"Scale OUT",fs=8,bold=True,c="#E65100")
t(19.0,9.15,"CPU >= 70%  |  2 x 120s periods",fs=7,c="#333")
t(19.0,8.87,"+1 instance  |  cooldown: 300s",fs=7,c="#555")
t(19.0,8.52,"Scale IN",fs=8,bold=True,c=C["cw_bd"])
t(19.0,8.22,"CPU <= 30%  |  2 x 120s periods",fs=7,c="#333")
t(19.0,7.94,"-1 instance  |  cooldown: 300s",fs=7,c="#555")
t(19.0,7.55,"Namespace: AWS/EC2",fs=7,c="#555")
t(19.0,7.27,"Dim: AutoScalingGroupName",fs=7,c="#555")
t(19.0,6.95,"Metric: CPUUtilization  Stat: Average",fs=7,c="#555")
t(19.0,6.57,"Scaling policies ->",fs=7,c=C["cw_bd"],italic=True)
t(19.0,6.27,"ChangeInCapacity: +1 / -1",fs=7,c=C["cw_bd"],italic=True)
t(19.0,5.75,"ASG auto-replaces failed instances",fs=7,c="#777",italic=True)
t(19.0,5.48,"ELB health check triggers removal",fs=7,c="#777",italic=True)

# ── LEGEND
box(0.75,0.65,5.2,6.0,"white","#BDBDBD",lw=1.2,r=0.25,z=12)
t(3.35,6.45,"LEGEND",fs=9,bold=True,c="#212121")
items=[
    (C["alb_bg"],C["alb_bd"],"Application Load Balancer"),
    (C["ec2_bg"],C["ec2_bd"],"EC2 Instance (in ASG)"),
    (C["nat_bg"],C["nat_bd"],"NAT Gateway"),
    (C["igw_bg"],C["igw_bd"],"Internet Gateway"),
    (C["cw_bg"], C["cw_bd"], "CloudWatch Alarms"),
    (C["asg_bg"],C["asg_bd"],"Auto Scaling Group"),
    (C["tgt_bg"],C["tgt_bd"],"ALB Target Group"),
    ("#FCE4EC",  C["sg_bd"],  "Security Group rule"),
]
for k,(fc,ec,lbl) in enumerate(items):
    ry=5.88-k*0.65
    box(0.95,ry-0.2,0.7,0.42,fc,ec,lw=1.3,r=0.1,z=13)
    t(2.05,ry+0.02,lbl,fs=7.5,c="#212121",ha="left",z=14)

# ── ARROWS
arr(11,13.9,11,12.65,"#1565C0",lw=2.5,lbl="HTTP :80",lc="#1565C0",fs=9)
arr(9.5,11.72,4.5,11.0,"#1565C0",lw=2,lbl="route -> pub-1a",lc="#1565C0",rad=0.1)
arr(12.5,11.72,14.4,11.0,"#1565C0",lw=2,lbl="route -> pub-1b",lc="#1565C0",rad=-0.1)
arr(3.8,8.35,9.2,5.6,"#4527A0",lw=1.8,lbl="forward :8080",lc="#4527A0",rad=0.15)
arr(15.4,8.35,12.8,5.6,"#4527A0",lw=1.8,lbl="forward :8080",lc="#4527A0",rad=-0.15)
arr(9.2,4.5,5.8,5.5,"#E65100",lw=1.8,lbl=":8080",lc="#E65100",rad=0.1)
arr(12.8,4.5,14.5,5.5,"#E65100",lw=1.8,lbl=":8080",lc="#E65100",rad=-0.1)
arr(4.5,4.0,6.2,8.35,"#00695C",lw=1.4,lbl="HTTPS :443\npkg updates",lc="#00695C",rad=-0.2,fs=6.5)
arr(15.4,4.0,15.4,8.35,"#00695C",lw=1.4,lbl="HTTPS :443\npkg updates",lc="#00695C",rad=0.2,fs=6.5)
arr(16.4,7.4,10.9,6.8,"#2E7D32",lw=1.6,lbl="scaling\npolicies",lc="#2E7D32",rad=0.15,fs=7)

# ── FOOTER
t(11,0.18,"Module layout:  root  ->  modules/networking | modules/security | modules/compute     |     "
          "Environments: dev / prod     |     S3 remote backend (commented)     |     "
          "Tags: ManagedBy=terraform, Environment, Project",
  fs=7,c="#78909C",italic=True)

plt.tight_layout(pad=0.1)
plt.savefig("/home/claude/terraform-day17/architecture.png",dpi=160,
            bbox_inches="tight",facecolor=fig.get_facecolor())
print("Done.")
