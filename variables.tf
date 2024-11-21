variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-1"
}

variable "hosted_zone" {
  default     = "kisialeu.com"
  description = "Hosted Zone"
}

variable "env" {
  description = "Environment"
  default     = "dev"
}

variable "project" {
  type        = string
  default     = "Ollama"
  description = "Project name for tagging resources"
}

variable "project_prefix" {
  type        = string
  default     = "ai"
  description = "Project prefix for tagging resources"
}

variable "app" {
  description = "Application configuration"
  type = object({
    name          = string
    image         = optional(string)
    port          = number
    desired_count = number
    health_check_path = string
  })
  default = {
    name          = "nginx"
    image         = "latest"
    port          = 80
    desired_count = 1
    health_check_path = "/"
  }
}


variable "vpc" {
  description = "VPC configuration"
  type        = object({
    vpc_cidr             = string
    public_subnets_cidr  = list(string)
    private_subnets_cidr = list(string)
  })
  default = {
    vpc_cidr             = "10.0.0.0/20"
    public_subnets_cidr  = ["10.0.0.0/24", "10.0.4.0/24"]
    private_subnets_cidr = ["10.0.1.0/24", "10.0.5.0/24"]
  }
}

variable "fargate" {
  description = "Fargate configuration for ECS tasks"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "512"
    memory = "1024"
  }
}
