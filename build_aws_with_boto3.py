import os
import boto3
from botocore.config import Config
import time
from jsonpath_ng import jsonpath, parse


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
response = client.describe_route_tables(
    Filters=[
        {
            'Name': 'association.main',
            'Values': [
                'true'
            ]
        },
        {
            'Name': 'vpc-id',
            'Values': [
                vpc_id
            ]
        }
    ],
    DryRun=False
)

jsonpath_expression = parse('RouteTables[*].RouteTableId')
for match in jsonpath_expression.find(response):
    routetableid = match.value
print(f"routetableid={routetableid}")
    
#Add a name tag to the default main route table for the VPC
response = client.create_tags(
    DryRun=False,
    Resources=[
        routetableid,
    ],
    Tags=[
        {
            'Key': 'Name',
            'Value': vpc_name_prefix + "-rtb-main"
        },
    ]
)

# Enable dns-hostnames on the new VPC
response = client.modify_vpc_attribute(
    EnableDnsHostnames={
        'Value': True
    },
    VpcId=vpc_id
)

#Create the S3 Endpoint Gateway
response = client.create_vpc_endpoint(
    DryRun=False,
    VpcEndpointType='Gateway',
    VpcId=vpc_id,
    ServiceName='com.amazonaws.us-east-2.s3',
    TagSpecifications=[
        {
            'ResourceType': 'vpc-endpoint',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': vpc_name_prefix + "-vpce-s3"
                }
            ]
        }
    ]
)

#Capture the new S3 Endpoint ID
jsonpath_expression = parse('VpcEndpoint[*].VpcEndpointId')
for match in jsonpath_expression.find(response):
    s3_endpoint_id = match.value
print(f"s3_endpoint_id={s3_endpoint_id}")

#Subnet creation call - this will be my public subnet
response = client.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': vpc_name_prefix + '-subnet-public1-us-east-2a'
                }
            ]
        }
    ],
    CidrBlock='11.0.0.0/20',
    VpcId=vpc_id,
    DryRun=False
)

#Capture the new public subnet ID
jsonpath_expression = parse('Subnet[*].SubnetId')
for match in jsonpath_expression.find(response):
    pub_subnet_id = match.value
print (f"pub_subnet_id={pub_subnet_id}")

#Subnet creation call - this will be my private subnet
response = client.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': vpc_name_prefix + '-subnet-private1-us-east-2a'
                }
            ]
        }
    ],
    CidrBlock='11.0.128.0/20',
    VpcId=vpc_id,
    DryRun=False
)

#Capture the new private subnet ID
jsonpath_expression = parse('Subnet[*].SubnetId')
for match in jsonpath_expression.find(response):
    private_subnet_id = match.value
print (f"private_subnet_id={private_subnet_id}")

#Create the internet gateway
response = client.create_internet_gateway(
    TagSpecifications=[
        {
            'ResourceType': 'internet-gateway',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': vpc_name_prefix + '-igw'
                }
            ]
        }
    ],
    DryRun=False
)

# Capture the new IGW ID
jsonpath_expression = parse('InternetGateway[*].InternetGatewayId')
for match in jsonpath_expression.find(response):
    igw_id = match.value
print (f"igw_id={igw_id}")

# Attach the internet gateway IGW to the VPC
response = client.attach_internet_gateway(
    DryRun=False,
    InternetGatewayId=igw_id,
    VpcId=vpc_id
)

#Create a route table to be used by the public subnet
response = client.create_route_table(
    DryRun=False,
    VpcId=vpc_id,
    TagSpecifications=[
        {
            'ResourceType': 'route-table',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': vpc_name_prefix + '-rtb-public'
                }
            ]
        }
    ]
)

# Capture the new pub route table ID
jsonpath_expression = parse('RouteTable[*].RouteTableId')
for match in jsonpath_expression.find(response):
    pub_route_table_id = match.value
print (f"pub_route_table_id={pub_route_table_id}")


# Create (add) the route to the route table for all traffic to go to the IGW
response = client.create_route(
    DestinationCidrBlock='0.0.0.0/0',
    DryRun=False,
    GatewayId=igw_id,
    RouteTableId=pub_route_table_id
)

#Associate the route with the public subnet
response = client.associate_route_table(
    DryRun=False,
    RouteTableId=pub_route_table_id,
    SubnetId=pub_subnet_id
)

#Create a route table to be used by the private subnet
response = client.create_route_table(
    DryRun=False,
    VpcId=vpc_id,
    TagSpecifications=[
        {
            'ResourceType': 'route-table',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': vpc_name_prefix + '-rtb-private1-us-east-2a'
                }
            ]
        }
    ]
)

# Capture the new pub route table ID
jsonpath_expression = parse('RouteTable[*].RouteTableId')
for match in jsonpath_expression.find(response):
    private_route_table_id = match.value
print (f"private_route_table_id={private_route_table_id}")

#Associate the route with the private subnet
response = client.associate_route_table(
    DryRun=False,
    RouteTableId=private_route_table_id,
    SubnetId=private_subnet_id
)

#Associate the S3 Endpoint with the private subnet route table (the reset policy was just in the example so I kept it.)
response = client.modify_vpc_endpoint(
    DryRun=False,
    VpcEndpointId=s3_endpoint_id,
    ResetPolicy=True,
    AddRouteTableIds=[
        private_route_table_id,
    ]
)