variable "aws_region" {
  description = "AWS-region där servern ska skapas"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2-instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Namnet på AWS Key Pair"
  type        = string
  default     = "ec2kp"
}

variable "huggingface_token" {
  description = "Hugging Face API-token"
  type        = string
  sensitive   = true
}
