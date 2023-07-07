variable "availability_zones" {
    type = list(string)
    default = ["us-east-2a","us-east-2b","us-east-2c"]
}

variable "s3_service_name" {
    type = string
    default = "com.amazonaws.us-east-2.s3"
}

variable "vpc_prefix" {
    type = string
    default = "dev"
}

variable "vpc_cidr_block" {
    type = string
    default = "10.123.0.0/16"
}

variable "pub_cidr_blocks" {
  type    = list(string)
  default = ["10.0.2.0/24", "10.0.4.0/24", "10.0.6.0/24"]
}

variable "pri_cidr_blocks" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
}

// This is set as an environment variable on my localhost: TF_VAR_my_internet_ip
//   export TF_VAR_my_internet_ip=<YOUR PUBLIC IP/32"
variable "my_internet_ip" {
    type = string
}