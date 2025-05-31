# Infrastructure Diagram

This diagram visualizes the AWS resources that will be created by the CloudFormation template.

```mermaid
graph TD
    %% Define nodes
    VPC[VPC: 10.0.0.0/16]
    IGW[Internet Gateway]
    PubRT[Public Route Table]
    
    %% Public Subnets
    PubSub1[Public Subnet 1: 10.0.1.0/24]
    PubSub2[Public Subnet 2: 10.0.2.0/24]
    
    %% Private Subnets
    PrivSub1[Private Subnet 1: 10.0.3.0/24]
    PrivSub2[Private Subnet 2: 10.0.4.0/24]
    
    %% Security Groups
    SG[Security Group]
    DBSG[Database Security Group]
    
    %% Resources
    ALB[Application Load Balancer]
    TG[Target Group]
    RDS[RDS MySQL Database]
    DBSubnetGroup[DB Subnet Group]
    
    %% Connections
    VPC --- IGW
    VPC --- PubRT
    PubRT --- PubSub1
    PubRT --- PubSub2
    VPC --- PrivSub1
    VPC --- PrivSub2
    
    PubSub1 --- ALB
    PubSub2 --- ALB
    
    ALB --- TG
    
    PrivSub1 --- DBSubnetGroup
    PrivSub2 --- DBSubnetGroup
    DBSubnetGroup --- RDS
    
    SG --- ALB
    DBSG --- RDS
    
    %% Internet Access
    IGW --- Internet((Internet))
    
    %% Security Group Rules
    SG -.- SGRules1[HTTP/HTTPS/SSH Access]
    DBSG -.- SGRules2[MySQL Access from App SG]
    
    %% Styling
    classDef aws fill:#FF9900,stroke:#232F3E,color:#232F3E
    classDef subnet fill:#4D27AA,stroke:#232F3E,color:white
    classDef security fill:#D86613,stroke:#232F3E,color:white
    classDef internet fill:#3B48CC,stroke:#232F3E,color:white
    
    class VPC,IGW,PubRT,ALB,TG,RDS,DBSubnetGroup aws
    class PubSub1,PubSub2,PrivSub1,PrivSub2 subnet
    class SG,DBSG,SGRules1,SGRules2 security
    class Internet internet
```

## Architecture Overview

This CloudFormation template creates a highly available architecture with the following components:

1. **Networking**:
   - VPC with CIDR block 10.0.0.0/16
   - 2 Public subnets in different Availability Zones
   - 2 Private subnets in different Availability Zones
   - Internet Gateway for public internet access
   - Route tables for network traffic management

2. **Security**:
   - Security group for the application layer (HTTP/HTTPS/SSH access)
   - Security group for the database (MySQL access from application security group)

3. **Application Layer**:
   - Application Load Balancer distributing traffic across availability zones
   - Target Group for the load balancer

4. **Database Layer**:
   - MySQL RDS instance in private subnets
   - DB Subnet Group spanning multiple availability zones for high availability

This architecture follows AWS best practices by separating public-facing components in public subnets and sensitive data in private subnets, while providing high availability through multi-AZ deployment.