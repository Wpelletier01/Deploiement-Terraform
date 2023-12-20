
variable "ssh-pub-file" {
  type = string
  default = "~/.ssh/tp3.pub"
}

variable "keypair_name" {
  type = string
  default = "tp3"
}

variable "canonical-owner" {
  type = string
  default = "099720109477"
}

variable "DOMAIN" {
  type = string

}

variable "NOIP_USER" {
  type = string
}

variable "NOIP_PASSWD" {
  type = string
}