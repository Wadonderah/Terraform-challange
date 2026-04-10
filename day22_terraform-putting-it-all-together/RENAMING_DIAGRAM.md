# Visual Renaming Architecture

## Directory Structure Transformation

```mermaid
graph TD
    subgraph "BEFORE: Current Structure"
        A1[modules/services/hello-world-app/]
        A2[live/dev/services/hello-world-app/]
        A3[live/stage/services/hello-world-app/]
        A4[live/prod/services/hello-world-app/]
        A5[tests/integration/hello_world_app_test.go]
        
        A2 -->|source path| A1
        A3 -->|source path| A1
        A4 -->|source path| A1
        A5 -->|test target| A2
    end
    
    subgraph "AFTER: New Structure"
        B1[modules/services/hello-wadondera-app/]
        B2[live/dev/services/hello-wadondera-app/]
        B3[live/stage/services/hello-wadondera-app/]
        B4[live/prod/services/hello-wadondera-app/]
        B5[tests/integration/hello_wadondera_app_test.go]
        
        B2 -->|source path| B1
        B3 -->|source path| B1
        B4 -->|source path| B1
        B5 -->|test target| B2
    end
    
    A1 -.->|rename| B1
    A2 -.->|rename| B2
    A3 -.->|rename| B3
    A4 -.->|rename| B4
    A5 -.->|rename| B5
```

## Module Reference Flow

```mermaid
flowchart LR
    subgraph "Live Environments"
        DEV[Dev Environment<br/>hello-wadondera-app]
        STAGE[Stage Environment<br/>hello-wadondera-app]
        PROD[Prod Environment<br/>hello-wadondera-app]
    end
    
    subgraph "Shared Module"
        MODULE[Module<br/>hello-wadondera-app<br/>Composition Layer]
    end
    
    subgraph "Infrastructure Components"
        VPC[VPC Module]
        ALB[ALB Module]
        ASG[ASG Module]
        RDS[MySQL Module]
    end
    
    DEV -->|source: ../../../../modules/services/hello-wadondera-app| MODULE
    STAGE -->|source: ../../../../modules/services/hello-wadondera-app| MODULE
    PROD -->|source: ../../../../modules/services/hello-wadondera-app| MODULE
    
    MODULE --> VPC
    MODULE --> ALB
    MODULE --> ASG
    MODULE --> RDS
```

## Backend State Key Mapping

```mermaid
graph TB
    subgraph "S3 Backend: wadoh-terraform-state-us-east-2-123456789012"
        S3[S3 Bucket]
        
        subgraph "State Files"
            DEV_STATE[dev/services/hello-wadondera-app/terraform.tfstate]
            STAGE_STATE[stage/services/hello-wadondera-app/terraform.tfstate]
            PROD_STATE[prod/services/hello-wadondera-app/terraform.tfstate]
        end
    end
    
    subgraph "DynamoDB Locks: wadoh-terraform-locks-us-east-2"
        LOCK[State Lock Table]
    end
    
    S3 --> DEV_STATE
    S3 --> STAGE_STATE
    S3 --> PROD_STATE
    
    DEV_STATE -.->|locked by| LOCK
    STAGE_STATE -.->|locked by| LOCK
    PROD_STATE -.->|locked by| LOCK
```

## File Content Changes Summary

```mermaid
mindmap
    root((Renaming<br/>Operation))
        Terraform Files
            main.tf files
                Comments
                Backend keys
                Module names
                Source paths
            variables.tf files
                Comments
                Default values
            outputs.tf files
                Comments
        Test Files
            hello_world_app_test.go
                File name
                Comments
                Directory paths
        Scripts
            plan-all.sh
                Environment paths
            destroy-all.sh
                Environment paths
        Documentation
            README.md
                Directory references
                File references
            bootstrap/terraform.tfvars
                Comment references
```

## Execution Phases

```mermaid
gantt
    title Renaming Execution Timeline
    dateFormat X
    axisFormat %s
    
    section Phase 1: Content Updates
    Terraform configs     :a1, 0, 5
    Test files           :a2, 5, 2
    Shell scripts        :a3, 7, 2
    Documentation        :a4, 9, 2
    
    section Phase 2: Directory Renaming
    Module directory     :b1, 11, 1
    Dev directory        :b2, 12, 1
    Stage directory      :b3, 13, 1
    Prod directory       :b4, 14, 1
    Test file            :b5, 15, 1
    
    section Phase 3: Verification
    Path validation      :c1, 16, 2
    Cross-ref check      :c2, 18, 2
    Final review         :c3, 20, 1
```

## Impact Analysis

### Files Modified: 15
- Terraform configuration files: 10
- Test files: 1
- Shell scripts: 2
- Documentation: 2

### Directories Renamed: 4
- Module directory: 1
- Live environment directories: 3

### Files Renamed: 1
- Test file: 1

### References Updated: 23+
- Module source paths: 3
- Backend state keys: 3
- Module names: 3
- Directory paths in scripts: 6
- Documentation references: 6+
- Comments and headers: 15+

## Risk Assessment

```mermaid
pie title Change Risk Distribution
    "Low Risk - Comments" : 40
    "Medium Risk - Paths" : 35
    "High Risk - State Keys" : 15
    "Critical - Module Sources" : 10
```

### Mitigation Strategy
1. **Comments (Low Risk)**: Cosmetic changes, no functional impact
2. **Paths (Medium Risk)**: Validated through verification phase
3. **State Keys (High Risk)**: Carefully updated to match new structure
4. **Module Sources (Critical)**: Triple-checked for correct relative paths

## Success Criteria

✓ All 23 todo items completed
✓ Zero broken references
✓ All module paths resolve correctly
✓ Backend configurations intact
✓ Infrastructure remains deployable
✓ Documentation reflects new structure