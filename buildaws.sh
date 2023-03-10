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

#Sample code to create the S3 Endpoint Gateway
# Decision - should I create the routetable first, so I can include it here... 
# but I don't even have the subnet defined yet...?
#aws ec2 create-vpc-endpoint \
#    --vpc-id vpc-1a2b3c4d \
#    --service-name com.amazonaws.us-east-1.s3 \
#    --route-table-ids rtb-11aa22bb

