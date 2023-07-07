variable "availability_zone" {
    type = string
    default = "us-east-2b"
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

variable "pub_cidr_block" {
    type = string
    default = "10.123.1.0/24"
}

variable "pri_cidr_block" {
    type = string
    default = "10.123.1.0/24"
}

// This is set as an environment variable on my localhost: TF_VAR_my_internet_ip
variable "my_internet_ip" {
    type = string
}