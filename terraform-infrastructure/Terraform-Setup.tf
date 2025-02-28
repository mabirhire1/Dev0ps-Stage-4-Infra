provider "aws" {
  region = "us-east-2"
}

# Creating VPC
resource "aws_vpc" "mabi_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "mabi_vpc"
  }
}

# Creating public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.mabi_vpc.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"
  tags = {
    Name = "public-subnet"
  }
}

# Creating private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.mabi_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2c"
  tags = {
    Name = "mabi_private-subnet"
  }
}

# Creating internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mabi_vpc.id
  tags = {
    Name = "mabi_internet-gateway"
  }
}

# Creating public routing table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.mabi_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "mabi_publicRBT"
  }
}

# Creating routing table association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Creating security group for the test server
resource "aws_security_group" "todo_sg" {
  vpc_id = aws_vpc.mabi_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "todo_sg"
  }
}

# Generating keypair
resource "aws_key_pair" "mabi_ssh-key" {
  key_name   = "mabi_ssh-key"
  public_key = file("~/.ssh/mabi_ssh-key.pub")
}

# EC2 Instance
resource "aws_instance" "todo-app" {
  ami             = "ami-0e1bed4f06a3b463d"
  instance_type   = "t2.large"
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.todo_sg.id]
  key_name        = aws_key_pair.mabi_ssh-key.id
  tags = {
    Name = "todo-app"
  }
}

# Associate the existing EIP with the EC2 instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.todo-app.id
  allocation_id = "eipalloc-018af126cf948ea79"  
}

# Output the Elastic IP directly
output "instance_ip" {
  value       = "3.21.42.203"  
  description = "The public IP of the EC2 instance"
}

# Create Ansible variables file with the IP address
resource "local_file" "ansible_vars" {
  content = <<-EOF
---
terraform_output:
  elastic_ip: "3.21.42.203" 
EOF
  filename = "${path.module}/ansible-setup/terraform_vars.yml"
}

# Wait for EC2 instance to be ready
resource "null_resource" "wait_for_instance" {
  depends_on = [
    aws_instance.todo-app,
    aws_eip_association.eip_assoc
  ]

  # Use remote-exec to wait for SSH to be available (This will block until SSH is ready)
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/mabi_ssh-key")
      host        = "3.21.42.203"
      timeout     = "5m"
    }
    
    # Just a minimal command to test SSH access
    inline = ["echo 'Instance is ready!'"]
  }
}

# Run Ansible after instance is confirmed ready
resource "null_resource" "run_ansible" {
  depends_on = [
    null_resource.wait_for_instance,
    local_file.ansible_vars
  ]
  
   provisioner "local-exec" {
    command = "ssh-keygen -R 3.21.42.203 && sleep 120 && ansible-playbook -i ansible-setup/inventory.yaml --extra-vars '@ansible-setup/terraform_vars.yml' ansible-setup/playbook.yaml"
  }
}