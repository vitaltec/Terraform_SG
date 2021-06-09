provider "aws" {
 region = "us-east-1" 
}

## VPC
resource "aws_vpc" "midnightVPC" {
  cidr_block = var.midnightVPCCidr

}
## Subnet
resource "aws_subnet" "midnightSubnet" {
  vpc_id = aws_vpc.midnightVPC.id
  cidr_block = var.midnightSubnetCidr
  availability_zone = var.az
}

## Internet Gateway
resource "aws_internet_gateway" "midnightIG" {
  vpc_id = aws_vpc.midnightVPC.id

  tags = {
    Name = "midnightIG"
  }
}

## route table
resource "aws_route_table" "midnightRT" {
  vpc_id = aws_vpc.midnightVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.midnightIG.id
  }

  tags = {
    Name = "midnightRT"
  }
}

## Route Table association
resource "aws_route_table_association" "midnightRTassc" {
  subnet_id      = aws_subnet.midnightSubnet.id
  route_table_id = aws_route_table.midnightRT.id
}

## EC2 Instace
resource "aws_instance" "myInstance" {
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.midnightSubnet.id
    vpc_security_group_ids = [ aws_security_group.midnightSG.id ]
  
}

## EIP
resource "aws_eip" "midnightEIP" {
  vpc      = true
  
}

## EIP association
resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.myInstance.id
  allocation_id = aws_eip.midnightEIP.id
}
## Getting my public Ip address

data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}

## Security group
resource "aws_security_group" "midnightSG" {
  name        = "midnightSG"
  description = "Allow TLS inbound traffic"
  vpc_id = aws_vpc.midnightVPC.id

  ingress {
    description      = "Allow HTTP Only From The EIP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["${aws_eip.midnightEIP.public_ip}/32"]
    
  }
  ingress {
    description      = "Allow SSH From my IP and the EIP "
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${aws_eip.midnightEIP.public_ip}/32", "${chomp(data.http.myIP.body)}/32"]
   
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "midnightSG"
  }
  depends_on = [
    aws_eip.midnightEIP
  ]
}