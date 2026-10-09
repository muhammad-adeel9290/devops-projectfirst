variable "project_name" {
  type        = string
  description = "Project identifier"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev/staging/prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR list for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR list for private subnets"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}

