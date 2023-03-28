import json
import os

## Functions ##
def read_json_value_from_response(response,key1,key2):
    json_value = response[key1][key2]
    return json_value

def read_main_routetable_id_from_response(response):
    routetableid = response['RouteTables'][0]['RouteTableId']
    return routetableid

def run_awscli_command(command,description):
# the right way to do this is with the AWS modules calling the APIs directly, not calling the AWS cli but just learning here
    print(f"{description}")
    print(f"\tNow running: {command}\n")
    response = json.loads(os.popen(command).read())
    return response

def run_awscli_command_no_response(command,description):
    print(f"{description}")
    print(f"\tNow running: {command}")
    os.popen(command).read()
    return "done"

### MAIN ###
os.system('clear')

# Create the new VPC

vpc_name_prefix = ""
vpc_name_prefix = input("Please enter the name of the VPC you wish to create [dev]:\n") or "dev"

# Could add cidr block and region as arguments here... but this is just practice
command = "aws ec2 create-vpc --cidr-block 11.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=" + vpc_name_prefix + "-vpc}]" + "'"
response = run_awscli_command(command,"Creating a new VPC with a prefix of " + vpc_name_prefix + ":")

# Capture the new VPC ID
vpc_id = (read_json_value_from_response(response,'Vpc','VpcId'))


#Get the main route table for the new VPC so we can tag it with a name
command = 'aws ec2 describe-route-tables --filters "Name=association.main,Values=true" "Name=vpc-id,Values=' + vpc_id + '"'
response = run_awscli_command(command,"Describing the main route table to capture it's ID:")

#Capture the main route table ID
main_route_table_id = read_main_routetable_id_from_response(response)

#Add a name tag to the default main route table for the VPC
command = "aws ec2 create-tags --resources " + main_route_table_id + " --tags Key=Name,Value=" + vpc_name_prefix + "-rtb-main"
response = run_awscli_command_no_response(command,"Adding a NAME tag to the main route table:")

# Enable dns-hostnames on the new VPC
myjsonstring = '{"Value":true}'
command ="aws ec2 modify-vpc-attribute --vpc-id " + vpc_id + " --enable-dns-hostnames '" + myjsonstring + "'"
response = run_awscli_command_no_response(command,"Enabling dns-hostnames on the new VPC:")

#Create the S3 Endpoint Gateway
command = "aws ec2 create-vpc-endpoint --vpc-id " + vpc_id + " --service-name com.amazonaws.us-east-2.s3 --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=" + vpc_name_prefix + "-vpce-s3}]'"
response = run_awscli_command(command,"Creating the S3 Endpoint Gateway:")

#Capture the new S3 Endpoint ID
s3_endpoint_id = read_json_value_from_response(response,'VpcEndpoint','VpcEndpointId')

#Public Subnet creation call
command = "aws ec2 create-subnet --vpc-id " + vpc_id + " --cidr-block 11.0.0.0/20 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=" + vpc_name_prefix + "-subnet-public1-us-east-2a}]'"
response = run_awscli_command(command,"Creating the public subnet:")

#Capture the new public subnet ID
pub_subnet_id = read_json_value_from_response(response,'Subnet','SubnetId')

#Private Subnet creation call
command = "aws ec2 create-subnet --vpc-id " + vpc_id + " --cidr-block 11.0.128.0/20 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=" + vpc_name_prefix + "-subnet-private1-us-east-2a}]'"
response = run_awscli_command(command,"Creating the private subnet:")

#Capture the new private subnet ID
private_subnet_id = read_json_value_from_response(response,'Subnet','SubnetId')

#Create the internet gateway
command = "aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=" + vpc_name_prefix + "-igw}]'"
response = run_awscli_command(command,"Creating the internet gateway:")

# Capture the new IGW ID
igw_id = read_json_value_from_response(response,'InternetGateway','InternetGatewayId')

# Attach the internet gateway IGW to the VPC
command = "aws ec2 attach-internet-gateway --internet-gateway-id " + igw_id + " --vpc-id " + vpc_id
response = run_awscli_command_no_response(command,"Attaching the internet gateway to the vpc:")

#Create a route table to be used by the public subnet
command = "aws ec2 create-route-table --vpc-id " + vpc_id + " --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=" + vpc_name_prefix + "-rtb-public}]'"
response = run_awscli_command(command,"Creating the public subnet route table:")

# Capture the new pub route table ID
pub_route_table_id = read_json_value_from_response(response,'RouteTable','RouteTableId')

# Create (add) the route to the route table for all traffic to go to the IGW
command = "aws ec2 create-route --route-table-id " + pub_route_table_id + " --destination-cidr-block 0.0.0.0/0 --gateway-id " + igw_id
response = run_awscli_command(command,"Adding the IGW to the public route table:")

#Associate the route with the public subnet
command = "aws ec2 associate-route-table --route-table-id " + pub_route_table_id + " --subnet-id " + pub_subnet_id
response = run_awscli_command(command,"Associating the route with the public subnet:")

#Create a route table to be used by the private subnet
command = "aws ec2 create-route-table --vpc-id " + vpc_id + " --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=" + vpc_name_prefix + "-rtb-private1-us-east-2a}]'"
response = run_awscli_command(command,"Creating a route table to be used by the private subnet:")

# Capture the new private route table ID
private_route_table_id = read_json_value_from_response(response,'RouteTable','RouteTableId')

#Associate the route with the private subnet
command = "aws ec2 associate-route-table --route-table-id " + private_route_table_id + " --subnet-id " + private_subnet_id
response = run_awscli_command(command,"Associating the route with the private subnet:")

#Associate the S3 Endpoint with the private subnet route table (the reset policy was just in the example so I kept it.)
command = "aws ec2 modify-vpc-endpoint --vpc-endpoint-id " + s3_endpoint_id + " --add-route-table-ids " + private_route_table_id + " --reset-policy"
response = run_awscli_command_no_response(command,"Associating the S3 Endpoint with the private subnet route table:")


# Print the details
print(f"\nVPC ID: {vpc_id}")
print(f"Main Route Table ID: {main_route_table_id}")
print(f"Internet Gateway ID: {igw_id}")
print(f"S3 Endpoint ID: {s3_endpoint_id}")
print(f"Public subnet route table ID: {pub_route_table_id}")
print(f"Private subnet route table ID: {private_route_table_id}")

print(f"All done!")