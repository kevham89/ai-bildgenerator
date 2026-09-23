#!/bin/bash

set -e

echo "======================================"
echo "AI Bildgenerator - Terraform deploy"
echo "======================================"

echo
echo "1. Initialiserar Terraform..."
terraform init

echo
echo "2. Skapar Terraform-plan..."
terraform plan -out=tfplan

echo
echo "3. Applicerar Terraform-plan..."
terraform apply tfplan

echo
echo "======================================"
echo "Deployment klar!"
echo "======================================"

echo
echo "Publik IP:"
terraform output -raw ec2_public_ip

echo
echo "URL:"
terraform output -raw application_url

echo
echo "SSH:"
terraform output -raw ssh_command

echo
echo "======================================"
