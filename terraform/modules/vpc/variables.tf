variable "environment" {
  description = "The environment (staging or production)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "The availability zones to use"
  type        = list(string)
} 