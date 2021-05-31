terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
#Provider defination 
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

###Terraform Production VPC##
resource "aws_vpc" "production" {
  cidr_block           = var.vpc_cicd
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = var.tagvari
  }
}
################# VPC creation Done###################

#####EC2 key file cretion and uploading in AWS and saving local disk######
resource "tls_private_key" "ec2-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
  }
resource "local_file" "cloud_pem" { 
  filename = "${path.module}/aws-ec2-key.pem"
  content = tls_private_key.ec2-key.private_key_pem
  file_permission = "0400"

}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2-key.public_key_openssh
}


################## EC2 key task  done##########

# Terraform Production Subnets
resource "aws_subnet" "production-public-1" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet1-cidr
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = var.tagvari
  }
}

resource "aws_subnet" "production-public-2" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = var.subnet2-cidr
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Name = var.tagvari
  }
}

# Terraform Production GW
resource "aws_internet_gateway" "production-gw" {
  vpc_id = aws_vpc.production.id
  tags = {
    Name = var.tagvari
  }
}

# Terraform Production RT
resource "aws_route_table" "production-public" {
  vpc_id = aws_vpc.production.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.production-gw.id
  }
  tags = {
    Name = var.tagvari
  }
}

####### Terraform Production RTA with subnet1 ######### #########
resource "aws_route_table_association" "production-public-1-a" {
  subnet_id      = aws_subnet.production-public-1.id
  route_table_id = aws_route_table.production-public.id
}
# Terraform Production RTA with subnet2
resource "aws_route_table_association" "production-public-2-a" {
  subnet_id      = aws_subnet.production-public-2.id
  route_table_id = aws_route_table.production-public.id
}
####### Terraform Production RTA with both subnets done #########

## Security Group for ec2 VMs#######################
resource "aws_security_group" "production_private_sg" {
  description = "Allow limited inbound external traffic"
  vpc_id      = aws_vpc.production.id
  name        = "production-sg"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.tagvari
  }
}

## Security Group for ec2 VM completed #######################

#locals {
#subs = concat([aws_subnet.production-public-1.id], [aws_subnet.production-public-2.id])
#}


####################aws kubernets ec2 nodes cretion###############################
resource "aws_instance" "ec2-k8s" {
  ami                    = var.kuberimage
  count                  = var.ec2-vmcount
  instance_type          = var.vmtypefree
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = element(local.subs, count.index)
  #vpc_security_group_ids = [aws_security_group.production_private_sg.id]
  vpc_security_group_ids = [aws_security_group.production_private_sg.id]
  user_data              = file("init-script.sh")
  tags = {
    Name        = "ec2-k8snodes ${count.index + 1}"
    Environment = "Production"
    Project1 = var.tagvari
  }
  }

### EIP mapping to vms
resource "aws_eip" "eip1" {
  instance = element(aws_instance.ec2-k8s.*.id, count.index)
  count    = length (aws_instance.ec2-k8s)
  vpc      = true
   tags = {
    Name = var.tagvari
  }
}
######################################################################################

#ec2 kuber master instance creation
resource "aws_instance" "ec2-k8s-master" {
  ami                    = var.kuberimage
  instance_type          = var.vmtypefree
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.production_private_sg.id]
  subnet_id              = aws_subnet.production-public-2.id
  user_data              = file("init-script-master.sh")
  tags = {
    Name        = "ec2-k8s-master"
    Environment = "Production"
  }
}

### EIP mapping to kubetnets master server
resource "aws_eip" "kuber-mastereip" {
instance = aws_instance.ec2-k8s-master.id
  vpc      = true
    tags = {
    Name = var.tagvari
  }
}

#Securiy group for load balancer (ALB)
resource "aws_security_group" "allow_ports" {
  name        = "alb"
  description = "Allow  inbound traffic"
  vpc_id      = aws_vpc.production.id

  ingress {
    description      = "http from vpc"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

ingress {
    description      = "tomcat port from vpc"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

ingress {
    description      = "TLS from vpc"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ports"
  }
}


########Target group for ALB#########################
resource "aws_lb_target_group" "my-target-group" {
  health_check {
  interval = 10
  path = "/"
  protocol    = "HTTP"
  timeout = 5 
  healthy_threshold = 5
  unhealthy_threshold = 2
  }
  name        = "my-test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.production.id
  tags = {
    Name = var.tagvari
  }
}

#### This is fatching data of both subnets so that same we can assign to ELB##


#######Application load banacer (ALB) ############################
resource "aws_lb" "my-aws-alb" {
  name               = "my-alb"
  internal           = false
  security_groups    = [aws_security_group.allow_ports.id]
  subnets            = [aws_subnet.production-public-1.id,aws_subnet.production-public-2.id]
  #subnets             = data.aws_subnet_ids.subnet.ids 
  #subnets             = aws_subnet.production.*.id
  #subnets            = element(local.subs, count.index)
  ip_address_type = "ipv4"
  load_balancer_type = "application"
 tags = {
    Name = var.tagvari
  }
}

###Listen for target and LB
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my-aws-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    #target_group_arn = aws_lb_target_group.front_end.arn
    target_group_arn = aws_lb_target_group.my-target-group.arn
  }
}
###Attaching ec2-k8s VMs to load balancer
resource "aws_lb_target_group_attachment" "ec2-attach" {
  target_group_arn = aws_lb_target_group.my-target-group.arn
  count = length (aws_instance.ec2-k8s)
  target_id        = aws_instance.ec2-k8s[count.index].id
}
