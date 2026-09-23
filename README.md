# AI Image Generator

A simple AI image generator built with Flask and Hugging Face. The application is deployed automatically to an AWS EC2 instance using Terraform.

Users can enter a text prompt and send it to the application. The application then uses the Hugging Face Inference API to generate an image.

## Technologies

* **Python** – Application programming language
* **Flask** – Web application framework
* **Hugging Face** – AI image generation
* **Gunicorn** – Runs the Flask application
* **Nginx** – Web server and reverse proxy
* **AWS EC2** – Hosts the application
* **Terraform** – Creates and configures the AWS infrastructure
* **GitHub** – Stores the source code

## How it works

The application uses the following setup:

```text
User
  |
  v
Nginx :80
  |
  v
Gunicorn :8000
  |
  v
Flask application
  |
  v
Hugging Face Inference API
  |
  v
Generated image
```

Nginx receives requests from the internet and forwards them to Gunicorn. Gunicorn runs the Flask application, which sends the image generation request to Hugging Face.

## Project structure

```text
ai-bildgenerator/
├── app.py
├── main.tf
├── outputs.tf
├── requirements.txt
├── run-deploy.sh
├── terraform.tfvars.example
├── user-data.sh
├── variables.tf
├── templates/
│   └── index.html
├── keys/
│   └── ec2kp.pem
└── .env
```

Some of these files are only present locally and are intentionally not uploaded to GitHub.

## Hugging Face Token

The application requires a Hugging Face API token to generate images.

The token is stored in a local `.env` file when the application runs.

Example:

```env
HUGGINGFACE_TOKEN='your_token_here'
```

The token can also be provided to Terraform through `terraform.tfvars`:

```hcl
aws_region        = "eu-north-1"
instance_type     = "t3.micro"
key_name          = "ec2kp"
huggingface_token = "your_token_here"
```

`terraform.tfvars` and `.env` are included in `.gitignore` and must **not** be committed to GitHub.

A template file called `terraform.tfvars.example` is included in the repository to show which variables are required.

## Deployment

The deployment is automated using the `run-deploy.sh` script.

Before deploying, make sure AWS CLI and Terraform are configured and that the required Terraform variables are available.

Run:

```bash
./run-deploy.sh
```

The script performs the following steps:

1. Initializes Terraform.
2. Creates a Terraform plan.
3. Applies the Terraform plan.
4. Displays the public IP address.
5. Displays the application URL.
6. Displays the SSH command.

Terraform creates the required AWS resources automatically.

## AWS Infrastructure

The Terraform configuration creates:

* A VPC
* A public subnet
* An Internet Gateway
* A public route table
* A Security Group
* An EC2 instance
* An Elastic IP address

The EC2 instance uses **Amazon Linux 2023**.

The default instance type is:

```text
t3.micro
```

The AWS region is:

```text
eu-north-1
```

## Automatic Server Setup

When Terraform creates the EC2 instance, `user-data.sh` automatically configures the server.

The script:

1. Updates Amazon Linux.
2. Installs Git, Python, pip and Nginx.
3. Clones the GitHub repository.
4. Creates a Python virtual environment.
5. Installs the Python dependencies.
6. Creates the `.env` file with the Hugging Face token.
7. Creates a Gunicorn systemd service.
8. Starts Gunicorn.
9. Configures Nginx as a reverse proxy.
10. Starts Nginx.
11. Checks the application's `/health` endpoint.

This means the server does not need to be manually configured after the EC2 instance is created.

## Application

The Flask application provides three main routes.

### `/`

The main web interface where users can enter an image prompt.

### `/generate`

Accepts a POST request containing a text prompt.

Example request:

```json
{
  "prompt": "An astronaut riding a unicorn in deep space"
}
```

The application sends the prompt to Hugging Face and returns the generated image as a Base64 data URL.

### `/health`

A simple health check endpoint.

Example:

```bash
curl http://SERVER_IP/health
```

Expected response:

```json
{
  "status": "ok"
}
```

## Connecting to the Server

Terraform displays the SSH command after deployment.

It will look similar to:

```bash
ssh -i keys/ec2kp.pem ec2-user@SERVER_IP
```

The private key is stored locally in the `keys` directory and is excluded from Git.

## Useful Server Commands

Check the Flask/Gunicorn service:

```bash
sudo systemctl status ai-bildgenerator
```

Restart the application:

```bash
sudo systemctl restart ai-bildgenerator
```

Check Nginx:

```bash
sudo systemctl status nginx
```

Restart Nginx:

```bash
sudo systemctl restart nginx
```

View the installation log:

```bash
sudo cat /var/log/ai-bildgenerator-install.log
```

View application logs:

```bash
sudo journalctl -u ai-bildgenerator
```

## Security

The following files contain sensitive information and should never be committed to GitHub:

```text
.env
terraform.tfvars
keys/
*.pem
terraform.tfstate
```

These files are excluded through `.gitignore`.

The Hugging Face token is also marked as a sensitive Terraform variable.

For a production deployment, additional security measures should be considered, such as restricting SSH access instead of allowing connections from all IP addresses and using HTTPS.

## Current Limitations

The application depends on the Hugging Face Inference API for image generation.

Image generation therefore depends on the availability and usage limits of the Hugging Face account and API.

The AWS server itself does not generate the images. It sends the request to Hugging Face and returns the generated result to the user.

## GitHub

The source code for the project is hosted on GitHub:

`https://github.com/kevham89/ai-bildgenerator`

## Summary

This project demonstrates how a Python web application can be deployed to AWS using infrastructure as code.

The deployment is automated with Terraform, while the EC2 instance configures itself using `user-data.sh`. Nginx handles incoming web traffic, Gunicorn runs the Flask application, and Hugging Face provides the AI image generation.
