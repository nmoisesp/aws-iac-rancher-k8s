variable "rancher_instance_name" {
  description = "Instance Name for EC2"
  type        = string
}

variable "rancher_instance_type" {
  description = "Instance Type for EC2"
  type        = string
  default     = "t2.micro"
}

variable "kubernates_instance_name" {
  description = "Instance Name for K8s instances"
  type        = string
}

variable "kubernates_instance_type" {
  description = "Instance Type for K8s instances"
  type        = string
  default     = "t2.micro"
}

variable "ubuntu_ami_name" {
  description = "Ubuntu AMI name"
  type        = string
}

variable "ubuntu_ami_architecture" {
  description = "Ubuntu AMI architecture"
  type        = string
}

variable "ubuntu_ami_owner" {
  description = "Ubuntu AMI owner"
  type        = string
}