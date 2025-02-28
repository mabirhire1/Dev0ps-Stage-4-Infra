# Infrastructure Automation with Terraform and Ansible
This repository contains infrastructure-as-code (IaC) setup for deploying and configuring a web application using Terraform and Ansible. 
The automation creates AWS infrastructure and then configures the server with Docker and all necessary dependencies for running a containerized application.

## Repository Structure

      ansible-setup/
      ├── roles/
      │   ├── dependencies/tasks/
      │   │   └── main.yaml          # Installs system packages and Docker
      │   └── deployment/tasks/
      │       └── main.yaml          # Sets up and deploys application with Docker Compose
      ├── inventory.yaml             # Ansible inventory file
      ├── playbook.yaml              # Main Ansible playbook
      ├── ansible.cfg                # Ansible configuration
      ├── .gitignore                 # Git ignore file
      └── Terraform-Setup.tf         # Terraform configuration
  

# Infrastructure Overview
## This project automates the full setup of a web application infrastructure:
### Terraform creates the AWS infrastructure:

1. VPC with public and private subnets
2. Internet Gateway and routing configuration
3. Security groups with necessary ports (22, 80, 443)
4. EC2 instance with Elastic IP


### Ansible configures the server environment:

  1. Installs system dependencies (git, Docker, Docker Compose)
  2. Sets up Docker repository and GPG keys
  3. Clones application repository
  4. Configures Let's Encrypt for SSL
  5. Deploys application using Docker Compose

# Requirements

Terraform >= 0.14
Ansible >= 2.9
AWS CLI configured with appropriate credentials
SSH key pair for server access

# Quick Start
1. AWS Infrastructure Deployment

terraform init (Initialize Terraform)

terraform plan (Review the planned changes)

terraform apply (Apply the infrastructure changes)

Terraform will:

 - Create all necessary AWS resources
 - Output the public IP of the created instance
 - Generate required variables for Ansible
 - Trigger the Ansible playbook once the EC2 instance is ready

2. Automatic Application Configuration 
   The Ansible playbook runs automatically after Terraform completes and:
   
   - Installs all required system packages:
      - git
      - Docker (docker-ce, docker-ce-cli, containerd.io)
      - Docker Compose
        
   - Configures Docker:
      - Adds Docker GPG key
      - Sets up the Docker repository
      - Adds the current user to the Docker group

   - Deploys the application:
      - Creates the application directory
      - Clones the application repository
      - Creates the Let's Encrypt directory for SSL certificates
      - Updates the domain in docker-compose.yml
      - Starts the application with Docker Compose
    
# Configuration Files
## Terraform Configuration
### The Terraform-Setup.tf file contains all the AWS infrastructure setup:

    AWS VPC (CIDR: 10.0.0.0/16)
    Public subnet in us-east-2b (CIDR: 10.0.5.0/24)
    Private subnet in us-east-2c (CIDR: 10.0.3.0/24)
    Internet Gateway and route tables
    Security group allowing SSH, HTTP, and HTTPS
    EC2 instance (t2.large) with Ubuntu AMI
    Elastic IP association

## Ansible Configuration
 ### The Ansible setup is organized into roles:
  - dependencies/tasks/main.yaml: System preparation
      Installs basic packages (lsb-release, git)
      Configures Docker repository
      Installs Docker packages
      Adds user to Docker group
      Installs Python packages

  - deployment/tasks/main.yaml: Application deployment
      Creates application directory
      Clones application repository
      Configures Let's Encrypt
      Updates domain in docker-compose.yml
      Deploys application using Docker Compose

  - Security Considerations
      SSH key authentication is used for secure server access
      Security groups limit access to essential ports only (SSH, HTTP, HTTPS)
      The application is deployed in a Docker container for isolation
    
  - Customization
      To customize this deployment for your own application:
      Update the AWS region and AMI ID in the Terraform configuration
      Modify the security group settings as needed
      Update the Ansible deployment tasks with your application repository
      Adjust Docker Compose settings for your specific application requirements

  - Troubleshooting
      If you encounter issues:
      Check Terraform state with terraform state list
      Verify AWS resources in the AWS Console
      Check Ansible logs for configuration errors
      SSH into the instance to verify Docker and application status
