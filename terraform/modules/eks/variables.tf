variable "project_name" {
  type        = string
  description = "Project identifier"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "k8s_version" {
  type        = string
  default     = "1.30"
  description = "Kubernetes control plane version"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for worker nodes"
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Worker node EC2 instance types"
}

variable "desired_nodes" {
  type        = number
  default     = 2
}

variable "min_nodes" {
  type        = number
  default     = 1
}

variable "max_nodes" {
  type        = number
  default     = 5
}

variable "tags" {
  type        = map(string)
  default     = {}
}
