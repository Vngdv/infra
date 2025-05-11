# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
  sensitive = true
}

variable "cluster_master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "cluster_master_server_type" {
  description = "Server type for master nodes"
  type        = string
  default     = "cx22"
}

variable "ssh_keys" {
  description = "SSH keys to be added to the server"
  type        = list(string)
  default     = []
}

variable "personal_ip" {
  description = "Your personal IP address"
  // Lets hope this keeps my ip from showing up in logs
  sensitive = true
  type        = string
  default     = ""
}

variable "cluster_location" {
  description = "Datacenter for the cluster"
  type        = string
  default     = "fsn1"
}