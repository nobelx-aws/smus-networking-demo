variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "SageMaker Unified Studio domain name"
  type        = string
  default     = "smus-networking-demo"
}

variable "enable_vpc_b" {
  description = "Enable VPC-B and Project-2 (set to true for second deployment)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "SMUS-Networking-Demo"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
