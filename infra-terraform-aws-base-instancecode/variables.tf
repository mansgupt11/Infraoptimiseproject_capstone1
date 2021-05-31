variable "aws_access_key" {
}

variable "aws_secret_key" {
}

variable "region" {
        default = "us-east-1"
}

variable "vpc_cicd" {
    default = "10.0.0.0/16"
}

variable "tagvari" {
    description = "This variable is using under all tags"
    default = "Sl-InfraProj1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "key_name" {
    description = "This variable is using under ec2-key genration"
    default = "aws-ec2-key"
}


variable "kuberimage" {
    description = "This variable is using for image"
    default = "ami-09e67e426f25ce0d7" #ubuntu 20 image
    }

variable "vmtypefree" {
    description = "This variable is using for free version of "
    default = "t3.micro"
    }

    variable "subnet1-cidr"{
    default = "10.0.1.0/24"
    }

 variable "subnet2-cidr" {
    default = "10.0.2.0/24"
}

variable "routepublicall" {
    default = ["0.0.0.0/0"]
}

#data "aws_subnet_ids" "subnet" {
 # vpc_id = aws_vpc.production.id

#}


#function to fatch both subnetids to put VMs in both subnets so that aws don't assign them in one AZ
locals {
  subs = concat([aws_subnet.production-public-1.id], [aws_subnet.production-public-2.id])
}

variable "ec2-vmcount" {
    description = "This variable is using for VM count"
    default = "3"
}