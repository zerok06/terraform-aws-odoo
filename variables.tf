variable "key_pair_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  sensitive   = true
}

variable "access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "ssh_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}
