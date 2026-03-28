output "domain_id" {
  description = "SageMaker Unified Studio Domain ID"
  value       = aws_datazone_domain.demo_domain.id
}

output "domain_portal_url" {
  description = "Domain portal URL"
  value       = aws_datazone_domain.demo_domain.portal_url
}

output "vpc_a_id" {
  description = "VPC-A ID (original VPC)"
  value       = aws_vpc.vpc_a.id
}

output "vpc_b_id" {
  description = "VPC-B ID (updated VPC)"
  value       = var.enable_vpc_b ? aws_vpc.vpc_b[0].id : "Not created yet"
}

output "project_1_id" {
  description = "Project-1 ID (stays in VPC-A)"
  value       = aws_datazone_project.project_1.id
}

output "project_1_glue_connection_vpc" {
  description = "Project-1 Glue Connection VPC"
  value       = aws_vpc.vpc_a.id
}

output "project_1_emr_vpc" {
  description = "Project-1 EMR Cluster VPC"
  value       = aws_vpc.vpc_a.id
}

output "project_2_id" {
  description = "Project-2 ID (uses VPC-B)"
  value       = var.enable_vpc_b ? aws_datazone_project.project_2[0].id : "Not created yet"
}

output "project_2_glue_connection_vpc" {
  description = "Project-2 Glue Connection VPC"
  value       = var.enable_vpc_b ? aws_vpc.vpc_b[0].id : "Not created yet"
}

output "project_2_emr_vpc" {
  description = "Project-2 EMR Cluster VPC"
  value       = var.enable_vpc_b ? aws_vpc.vpc_b[0].id : "Not created yet"
}

output "demo_summary" {
  description = "Demo summary showing VPC assignments"
  value       = var.enable_vpc_b ? <<-EOT
========================================
SMUS NETWORKING DEMO - AFTER UPDATE
========================================

Domain Tooling Blueprint: NOW USES VPC-B (${aws_vpc.vpc_b[0].id})

Project-1 Resources (UNCHANGED):
  - Glue Connection: VPC-A (${aws_vpc.vpc_a.id})
  - EMR Cluster: VPC-A (${aws_vpc.vpc_a.id})

Project-2 Resources (NEW):
  - Glue Connection: VPC-B (${aws_vpc.vpc_b[0].id})
  - EMR Cluster: VPC-B (${aws_vpc.vpc_b[0].id})

KEY INSIGHT: Project-1 resources stayed in VPC-A!
Only new Project-2 inherited VPC-B settings.
========================================
EOT
  : <<-EOT
========================================
SMUS NETWORKING DEMO - INITIAL STATE
========================================

Domain Tooling Blueprint: VPC-A (${aws_vpc.vpc_a.id})

Project-1 Resources:
  - Glue Connection: VPC-A (${aws_vpc.vpc_a.id})
  - EMR Cluster: VPC-A (${aws_vpc.vpc_a.id})

Next: Set enable_vpc_b = true to demonstrate
that Project-1 stays in VPC-A while new
Project-2 uses VPC-B.
========================================
EOT
}
