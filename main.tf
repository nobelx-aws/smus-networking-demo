# VPC-A (Initial VPC)
resource "aws_vpc" "vpc_a" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "smus-demo-vpc-a" })
}

resource "aws_subnet" "vpc_a_private_1" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(var.tags, { Name = "smus-demo-vpc-a-private-1" })
}

resource "aws_subnet" "vpc_a_private_2" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = merge(var.tags, { Name = "smus-demo-vpc-a-private-2" })
}

resource "aws_security_group" "vpc_a_default" {
  name        = "smus-demo-vpc-a-sg"
  description = "Default security group for VPC-A"
  vpc_id      = aws_vpc.vpc_a.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = merge(var.tags, { Name = "smus-demo-vpc-a-sg" })
}

# VPC-B (Updated VPC - only created when enable_vpc_b = true)
resource "aws_vpc" "vpc_b" {
  count                = var.enable_vpc_b ? 1 : 0
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "smus-demo-vpc-b" })
}

resource "aws_subnet" "vpc_b_private_1" {
  count             = var.enable_vpc_b ? 1 : 0
  vpc_id            = aws_vpc.vpc_b[0].id
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(var.tags, { Name = "smus-demo-vpc-b-private-1" })
}

resource "aws_subnet" "vpc_b_private_2" {
  count             = var.enable_vpc_b ? 1 : 0
  vpc_id            = aws_vpc.vpc_b[0].id
  cidr_block        = "10.1.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = merge(var.tags, { Name = "smus-demo-vpc-b-private-2" })
}

resource "aws_security_group" "vpc_b_default" {
  count       = var.enable_vpc_b ? 1 : 0
  name        = "smus-demo-vpc-b-sg"
  description = "Default security group for VPC-B"
  vpc_id      = aws_vpc.vpc_b[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = merge(var.tags, { Name = "smus-demo-vpc-b-sg" })
}

# IAM Roles
resource "aws_iam_role" "domain_execution_role" {
  name = "smus-demo-domain-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = ["datazone.amazonaws.com", "glue.amazonaws.com", "elasticmapreduce.amazonaws.com"]
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "domain_datazone" {
  role       = aws_iam_role.domain_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDataZoneFullAccess"
}

resource "aws_iam_role_policy_attachment" "domain_glue" {
  role       = aws_iam_role.domain_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "domain_emr" {
  role       = aws_iam_role.domain_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_instance_profile" "emr_profile" {
  name = "smus-demo-emr-instance-profile"
  role = aws_iam_role.domain_execution_role.name
}

# SageMaker Unified Studio Domain
resource "aws_datazone_domain" "demo_domain" {
  name                  = var.domain_name
  domain_execution_role = aws_iam_role.domain_execution_role.arn
  tags                  = var.tags
}

# Note: Blueprint configuration is managed through console/API after domain creation
# For this demo, we'll use projects directly to demonstrate VPC binding

# Project-1 (Always in VPC-A)
resource "aws_datazone_project" "project_1" {
  domain_identifier = aws_datazone_domain.demo_domain.id
  name              = "project-1-vpc-a"
  description       = "Project created with VPC-A - will NOT migrate to VPC-B"
}

resource "aws_glue_connection" "project_1_connection" {
  name = "project-1-glue-connection"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://dummy-endpoint:3306/demo"
    USERNAME            = "demo_user"
    PASSWORD            = "demo_password"
  }

  physical_connection_requirements {
    availability_zone      = data.aws_availability_zones.available.names[0]
    security_group_id_list = [aws_security_group.vpc_a_default.id]
    subnet_id              = aws_subnet.vpc_a_private_1.id
  }

  tags = merge(var.tags, { Project = "project-1", VPC = "vpc-a" })
}

# EMR removed - Glue connections are sufficient to demonstrate VPC binding

# Project-2 (Only created when enable_vpc_b = true, uses VPC-B)
resource "aws_datazone_project" "project_2" {
  count             = var.enable_vpc_b ? 1 : 0
  domain_identifier = aws_datazone_domain.demo_domain.id
  name              = "project-2-vpc-b"
  description       = "Project created with VPC-B - inherits new network settings"
}

resource "aws_glue_connection" "project_2_connection" {
  count = var.enable_vpc_b ? 1 : 0
  name  = "project-2-glue-connection"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://dummy-endpoint:3306/demo"
    USERNAME            = "demo_user"
    PASSWORD            = "demo_password"
  }

  physical_connection_requirements {
    availability_zone      = data.aws_availability_zones.available.names[0]
    security_group_id_list = [aws_security_group.vpc_b_default[0].id]
    subnet_id              = aws_subnet.vpc_b_private_1[0].id
  }

  tags = merge(var.tags, { Project = "project-2", VPC = "vpc-b" })
}

# EMR removed - Glue connections are sufficient to demonstrate VPC binding

data "aws_availability_zones" "available" {
  state = "available"
}
