variable "ami_ids" {
  type = map
}
variable "atlantic" {
  default = "atlantic"
  type    = string
}

variable "cidr_block" {
  type = map
}

variable "configure_nginx" {
  type = map
}

variable "nginx_instance" {
  type = map
}

variable "ssh_public_key" {
  type = string
}