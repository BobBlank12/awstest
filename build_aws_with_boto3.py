import os
import boto3
from botocore.config import Config
import time
from jsonpath_ng import jsonpath, parse

### Functions ###


### Main ###
os.system("clear")

aws_config = Config()
client = boto3.client('ec2', config=aws_config)

vpc_name_prefix = ""
vpc_name_prefix = input("Please enter the name of the VPC you wish to create [dev]:\n") or "dev"

# Create the new VPC
response = client.create_vpc(
    CidrBlock='11.0.0.0/16',
    AmazonProvidedIpv6CidrBlock=False,
    DryRun=False,
    InstanceTenancy='default',
    TagSpecifications=[
        {
            'ResourceType':'vpc',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': vpc_name_prefix + '-vpc'
                }
            ]
        }
    ]
)

#Read the new vpc ID
jsonpath_expression = parse('Vpc[*].VpcId')
for match in jsonpath_expression.find(response):
    vpc_id = match.value
print (f"The new VPC Id is: {vpc_id}")

#Loop until the new vpc is available, pending|available
vpc_state = "pending"
x = 1

while (vpc_state != "available") and (x < 10): 
    #Describe the new VPC to get the state:
    response = client.describe_vpcs(
        VpcIds=[
            vpc_id
        ]
    )
    jsonpath_expression = parse('Vpcs[*].State')
    for match in jsonpath_expression.find(response):
       vpc_state = match.value
    x = x + 1
    time.sleep(1)

if (x > 10) or (vpc_state != "available"):
    print("VPC is not available after 10 seconds... aborting.")
    print(f"Please check in the AWS console for the status of Vpc Id: {vpc_id}")
    exit(1)
else:
    print(f"Vpc Id: {vpc_id} is available.")

#Describe the main route table of the new VPC so we can get its ID and tag it with a name
#aws ec2 describe-route-tables --filters "Name=association.main,Values=true" "Name=vpc-id,Values=vpc-02645ba38f23e937d"






