# Examples/samples to build AWS VPC's via:

- shell script just calling the AWS CLI
- python script just calling the AWS CLI
- python script using boto3 to make the API calls directly
- Terraform 

**Each version will create:**
- one VPC with a "prefix" like "dev"-vpc
- a public subnet with an internet gateway
- a private subnet with an S3 endpoint

**Some of the examples will also:**
- create public and private subnets in multiple AZs
- security group to limit the traffic from your own IP
- probably other things I have already forgotten

