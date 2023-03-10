#!/bin/sh

# Create the new VPC
aws ec2 create-vpc --cidr-block 11.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=dev2-vpc}]'

#OUTPUT:
#{
#    "Vpc": {
#        "CidrBlock": "11.0.0.0/16",
#        "DhcpOptionsId": "dopt-04be8fbd8052bbc9c",
#        "State": "pending",
#        "VpcId": "vpc-02645ba38f23e937d",
#        "OwnerId": "980075630834",
#        "InstanceTenancy": "default",
#        "Ipv6CidrBlockAssociationSet": [],
#        "CidrBlockAssociationSet": [
#            {
#                "AssociationId": "vpc-cidr-assoc-0e2bf103991419756",
#                "CidrBlock": "11.0.0.0/16",
#                "CidrBlockState": {
#                    "State": "associated"
#                }
#            }
#        ],
#        "IsDefault": false,
#        "Tags": [
#            {
#                "Key": "Name",
#                "Value": "dev2-vpc"
#            }
#        ]
#    }
#}

# Enable dns-hostnames on the new VPC
aws ec2 modify-vpc-attribute --vpc-id vpc-02645ba38f23e937d --enable-dns-hostnames '{"Value":true}'

#Create the S3 Endpoint Gateway

aws ec2 create-vpc-endpoint --vpc-id vpc-02645ba38f23e937d --service-name com.amazonaws.us-east-2.s3

#{
#    "VpcEndpoint": {
#        "VpcEndpointId": "vpce-0576cb44998524c8e",
#        "VpcEndpointType": "Gateway",
#        "VpcId": "vpc-02645ba38f23e937d",
#        "ServiceName": "com.amazonaws.us-east-2.s3",
#        "State": "available",
#        "PolicyDocument": "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"*\",\"Resource\":\"*\"}]}",
#        "RouteTableIds": [],
#        "SubnetIds": [],
#        "Groups": [],
#        "PrivateDnsEnabled": false,
#        "RequesterManaged": false,
#        "NetworkInterfaceIds": [],
#        "DnsEntries": [],
#        "CreationTimestamp": "2023-03-10T16:53:51+00:00",
#        "OwnerId": "980075630834"
#    }
#}

#Subnet creation call - this will be my public subnet

aws ec2 create-subnet --vpc-id vpc-02645ba38f23e937d --cidr-block 11.0.0.0/20 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev2-subnet-public1-us-east-2a}]'

#{
#    "Subnet": {
#        "AvailabilityZone": "us-east-2a",
#        "AvailabilityZoneId": "use2-az1",
#        "AvailableIpAddressCount": 4091,
#        "CidrBlock": "11.0.0.0/20",
#        "DefaultForAz": false,
#        "MapPublicIpOnLaunch": false,
#        "State": "available",
#        "SubnetId": "subnet-0b37af2257c044351",
#        "VpcId": "vpc-02645ba38f23e937d",
#        "OwnerId": "980075630834",
#        "AssignIpv6AddressOnCreation": false,
#        "Ipv6CidrBlockAssociationSet": [],
#        "Tags": [
#            {
#                "Key": "Name",
#                "Value": "dev2-subnet-public1-us-east-2a"
#            }
#        ],
#        "SubnetArn": "arn:aws:ec2:us-east-2:980075630834:subnet/subnet-0b37af2257c044351",
#:...skipping...
#{
#    "Subnet": {
#        "AvailabilityZone": "us-east-2a",
#        "AvailabilityZoneId": "use2-az1",
#        "AvailableIpAddressCount": 4091,
#        "CidrBlock": "11.0.0.0/20",
#        "DefaultForAz": false,
#        "MapPublicIpOnLaunch": false,
#        "State": "available",
#        "SubnetId": "subnet-0b37af2257c044351",
#        "VpcId": "vpc-02645ba38f23e937d",
#        "OwnerId": "980075630834",
#        "AssignIpv6AddressOnCreation": false,
#        "Ipv6CidrBlockAssociationSet": [],
#        "Tags": [
#            {
#                "Key": "Name",
#                "Value": "dev2-subnet-public1-us-east-2a"
#            }
#        ],
#        "SubnetArn": "arn:aws:ec2:us-east-2:980075630834:subnet/subnet-0b37af2257c044351",
#        "EnableDns64": false,
#        "Ipv6Native": false,
#        "PrivateDnsNameOptionsOnLaunch": {
#            "HostnameType": "ip-name",
#            "EnableResourceNameDnsARecord": false,
#            "EnableResourceNameDnsAAAARecord": false
#        }
#    }
#}

#Subnet creation call - this will be my private subnet

#aws ec2 create-subnet --vpc-id vpc-02645ba38f23e937d --cidr-block 11.0.128.0/20 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=dev2-subnet-private1-us-east-2a}]'

#   "Subnet": {
#        "AvailabilityZone": "us-east-2a",
#        "AvailabilityZoneId": "use2-az1",
#        "AvailableIpAddressCount": 4091,
#        "CidrBlock": "11.0.128.0/20",
#        "DefaultForAz": false,
#        "MapPublicIpOnLaunch": false,
#        "State": "available",
#        "SubnetId": "subnet-082b99b23b33626d4",
#        "VpcId": "vpc-02645ba38f23e937d",
#        "OwnerId": "980075630834",
#        "AssignIpv6AddressOnCreation": false,
#        "Ipv6CidrBlockAssociationSet": [],
#        "Tags": [
#            {
#                "Key": "Name",
#                "Value": "dev2-subnet-private1-us-east-2a"
#            }
#        ],
#        "SubnetArn": "arn:aws:ec2:us-east-2:980075630834:subnet/subnet-082b99b23b33626d4",
#        "EnableDns64": false,
#        "Ipv6Native": false,
#        "PrivateDnsNameOptionsOnLaunch": {
#            "HostnameType": "ip-name",
#            "EnableResourceNameDnsARecord": false,
#            "EnableResourceNameDnsAAAARecord": false
#        }
#    }
#}

#Create the internet gateway
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=dev2-igw}]'

#{
#    "InternetGateway": {
#        "Attachments": [],
#        "InternetGatewayId": "igw-0cad51f0b9945cbf4",
#        "OwnerId": "980075630834",
#        "Tags": [
#            {
#                "Key": "Name",
#                "Value": "dev2-igw"
#            }
#        ]
#    }
#}

# Attach the internet gateway IGW to the VPC
#https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/attach-internet-gateway.html

aws ec2 attach-internet-gateway --internet-gateway-id igw-0cad51f0b9945cbf4 --vpc-id vpc-02645ba38f23e937d

#NO RESPONSE from output of command above!

#Create a route table to be used by the public subnet
aws ec2 create-route-table --vpc-id vpc-02645ba38f23e937d

#{
#    "RouteTable": {
#        "Associations": [],
#        "PropagatingVgws": [],
#        "RouteTableId": "rtb-0d1d7b6f7219a66bb",
#        "Routes": [
#            {
#                "DestinationCidrBlock": "11.0.0.0/16",
#                "GatewayId": "local",
#                "Origin": "CreateRouteTable",
#                "State": "active"
#            }
#        ],
#        "Tags": [],
#        "VpcId": "vpc-02645ba38f23e937d",
#        "OwnerId": "980075630834"
#    }
#}


# Create (add) the route to the route table for all traffic to go to the IGW
aws ec2 create-route --route-table-id rtb-0d1d7b6f7219a66bb --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0cad51f0b9945cbf4

#{
#    "Return": true
#}

#Associate the route with the public subnet
aws ec2 associate-route-table --route-table-id rtb-0d1d7b6f7219a66bb --subnet-id subnet-0b37af2257c044351

#{
#    "AssociationId": "rtbassoc-05d15619eddd55073",
#    "AssociationState": {
#        "State": "associated"
#    }
#}

#Create a route table to be used by the private subnet
aws ec2 create-route-table --vpc-id vpc-02645ba38f23e937d

#{
#    "RouteTable": {
#        "Associations": [],
#        "PropagatingVgws": [],
#        "RouteTableId": "rtb-02999a7044e057013",
#        "Routes": [
#            {
#                "DestinationCidrBlock": "11.0.0.0/16",
#                "GatewayId": "local",
#                "Origin": "CreateRouteTable",
#                "State": "active"
#            }
#        ],
#        "Tags": [],
#        "VpcId": "vpc-02645ba38f23e937d",
#        "OwnerId": "980075630834"
#    }
#}

#Associate the route with the private subnet
aws ec2 associate-route-table --route-table-id rtb-02999a7044e057013 --subnet-id subnet-082b99b23b33626d4

#{
#    "AssociationId": "rtbassoc-012af6a572584f2af",
#    "AssociationState": {
#        "State": "associated"
#    }
#}
