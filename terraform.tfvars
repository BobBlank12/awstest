//
availability_zones = ["us-east-2a"]
#availability_zones = ["us-east-2a","us-east-2b","us-east-2c"]

s3_service_name = "com.amazonaws.us-east-2.s3"
//
vpc_prefix = "dev"
vpc_cidr_block = "10.0.0.0/16"

pub_cidr_blocks = ["10.0.2.0/24"]
#pub_cidr_blocks = ["10.0.2.0/24", "10.0.4.0/24", "10.0.6.0/24"]

pri_cidr_blocks = ["10.0.1.0/24"]
#pri_cidr_blocks = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
