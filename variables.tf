
variable "user_id" {
  type = string
  description = "unique id used to create resources"  
  default = "your_id"
}

variable "gcp_region" {
  type = string
  description = "Google Cloud region where to deploy the resources"  
  default = "your_region"
}

variable "gcp_zone" {
  type = string
  description = "Google Cloud availability zone where to deploy resources"  
  default = "your_zone"
}

variable "gcp_project" {
  type = string
  description = "Google Cloud project name where to deploy resources" 
  default = "your_project"
}

variable "networks" {
  description = "list of VPC names and subnets"
  type        = map(any)
  default = {
    web = "10.0.0.0/24"
  }
}

variable "fwl_allowed_tcp_ports" {
  type        = map(any)
  description = "list of firewall ports to open for each VPC"
  default = {
    web = ["22", "80", "443"]
  }
}

variable "ansible_user" {
  type = string
  description = "Ansible user used to connect to the instance"
  default = "your_user"
}

variable "ansible_ssh_key" {
  type = string
  description = "ssh key file to use for ansible_user"
  default = "your_key_path"
}

variable "ansible_python" {
  type = string
  description = "path to python executable"
  default = "/usr/bin/python3"
}
