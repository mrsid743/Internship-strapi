# **Strapi Internship Tasks: From Local Setup to Automated Deployment**

This repository documents the process of setting up, containerizing, deploying, and automating a Strapi application. The project covers local setup, Dockerization, orchestration with Docker Compose, infrastructure provisioning on AWS with Terraform, and setting up a CI/CD pipeline using GitHub Actions.

## **📋 Table of Contents**

* [Prerequisites](https://www.google.com/search?q=%23-prerequisites)  
* [Task 1: Local Strapi Setup](https://www.google.com/search?q=%23-task-1-local-strapi-setup)  
* [Task 2: Dockerizing the Strapi Application](https://www.google.com/search?q=%23-task-2-dockerizing-the-strapi-application)  
* [Task 3: Multi-Container Setup with Docker Compose](https://www.google.com/search?q=%23-task-3-multi-container-setup-with-docker-compose)  
* [Task 4: Deploying to AWS EC2 with Terraform](https://www.google.com/search?q=%23-task-4-deploying-to-aws-ec2-with-terraform)  
* [Task 5: Automating Deployment with GitHub Actions (CI/CD)](https://www.google.com/search?q=%23-task-5-automating-deployment-with-github-actions-cicd)  
* [Task 6: Deploying to AWS ECS Fargate with Terraform](https://www.google.com/search?q=%23-task-6-deploying-to-aws-ecs-fargate-with-terraform)

## **🛠️ Prerequisites**

Before you begin, ensure you have the following installed and configured:

* **Node.js** (v18 or later)  
* **npm** or **yarn**  
* **Docker** and **Docker Compose**  
* **Terraform**  
* An **AWS Account** with programmatic access (Access Key ID and Secret Access Key)  
* A **Docker Hub Account**  
* A **GitHub Account**  
* **AWS CLI**

## **✅ Task 1: Local Strapi Setup**

**Objective:** Clone the official Strapi repository, run it locally, and create a sample content type.

### **Steps**

1. Clone the Strapi Repository  
   You can create a new Strapi project using the create-strapi-app command.  
   npx create-strapi-app@latest my-strapi-project \--quickstart

2. **Navigate to the Project Directory**  
   cd my-strapi-project

3. Run Strapi in Development Mode  
   The \--quickstart flag will automatically start the development server. If it doesn't, use the following command:  
   npm run develop  
   \# or  
   yarn develop

4. Create Your First Admin User  
   Once the server starts, navigate to http://localhost:1337/admin. You'll be prompted to create the first administrator account. Fill in the details to access the Admin Panel.  
5. **Create a Sample Content Type**  
   * In the Admin Panel, go to **Content-Type Builder** \> **Create new collection type**.  
   * Enter a **Display name** (e.g., "Article").  
   * Add fields like title (Text) and content (Rich Text).  
   * Click **Save** and wait for the server to restart.  
   * You can now add content to your new "Article" collection type\!  
6. Push to GitHub  
   Initialize a Git repository, commit your changes, and push it to your GitHub account.  
   git init  
   git add .  
   git commit \-m "Initial Strapi setup"  
   git branch \-M main  
   git remote add origin \[https://github.com/\](https://github.com/)\<your-username\>/\<your-repo-name\>.git  
   git push \-u origin main

## **✅ Task 2: Dockerizing the Strapi Application**

**Objective:** Create a Dockerfile to containerize the Strapi application for portable and consistent environments.

### **Steps**

1. Create a Dockerfile  
   In the root of your Strapi project, create a file named Dockerfile with the following content:  
   \# Use the official Node.js 18 image as a base  
   FROM node:18-alpine

   \# Set the working directory inside the container  
   WORKDIR /opt/app

   \# Copy package.json and package-lock.json (or yarn.lock)  
   COPY ./package.json ./  
   COPY ./yarn.lock ./

   \# Install dependencies  
   RUN yarn install \--frozen-lockfile

   \# Copy the rest of the application source code  
   COPY ./ .

   \# Build the Strapi admin panel  
   ENV NODE\_ENV=production  
   RUN yarn build

   \# Expose the port Strapi runs on  
   EXPOSE 1337

   \# Start the Strapi application  
   CMD \["yarn", "start"\]

2. Build the Docker Image  
   Open your terminal in the project root and run the following command to build the image. Replace \<your-dockerhub-username\> with your actual Docker Hub username.  
   docker build \-t \<your-dockerhub-username\>/strapi-app .

3. Run the Docker Container  
   Run the container to test if the image works correctly.  
   docker run \-p 1337:1337 \<your-dockerhub-username\>/strapi-app

   You should now be able to access your Strapi application at http://localhost:1337.

## **✅ Task 3: Multi-Container Setup with Docker Compose**

**Objective:** Set up a complete development environment using Docker Compose, including Strapi, a PostgreSQL database, and an Nginx reverse proxy.

### **Project Structure**

.  
├── nginx/  
│   └── nginx.conf  
├── src/  
│   └── (Your Strapi app files)  
├── .env  
├── docker-compose.yml  
└── Dockerfile

### **Steps**

1. Create a Docker Network (Optional, as Docker Compose can do this automatically)  
   This ensures all containers can communicate with each other using their service names.  
   docker network create strapi-net

2. Create docker-compose.yml  
   This file defines the services: strapi, postgres, and nginx.  
   version: '3.8'

   services:  
     strapi:  
       container\_name: strapi  
       build: .  
       image: \<your-dockerhub-username\>/strapi-app  
       environment:  
         DATABASE\_CLIENT: postgres  
         DATABASE\_HOST: postgres  
         DATABASE\_PORT: 5432  
         DATABASE\_NAME: ${DATABASE\_NAME}  
         DATABASE\_USERNAME: ${DATABASE\_USERNAME}  
         DATABASE\_PASSWORD: ${DATABASE\_PASSWORD}  
         HOST: 0.0.0.0  
         PORT: 1337  
       volumes:  
         \- ./src:/opt/app  
       ports:  
         \- "1337:1337"  
       depends\_on:  
         \- postgres  
       networks:  
         \- strapi-net

     postgres:  
       container\_name: postgres  
       image: postgres:14-alpine  
       environment:  
         POSTGRES\_DB: ${DATABASE\_NAME}  
         POSTGRES\_USER: ${DATABASE\_USERNAME}  
         POSTGRES\_PASSWORD: ${DATABASE\_PASSWORD}  
       volumes:  
         \- strapi-data:/var/lib/postgresql/data  
       ports:  
         \- "5432:5432"  
       networks:  
         \- strapi-net

     nginx:  
       container\_name: nginx  
       image: nginx:1.21-alpine  
       volumes:  
         \- ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf  
       ports:  
         \- "80:80"  
       depends\_on:  
         \- strapi  
       networks:  
         \- strapi-net

   volumes:  
     strapi-data:

   networks:  
     strapi-net:  
       driver: bridge

3. Configure Nginx as a Reverse Proxy  
   Create nginx/nginx.conf to forward requests from port 80 to the Strapi container on port 1337\.  
   server {  
       listen 80;  
       server\_name localhost;

       location / {  
           proxy\_pass http://strapi:1337;  
           proxy\_set\_header Host $host;  
           proxy\_set\_header X-Real-IP $remote\_addr;  
           proxy\_set\_header X-Forwarded-For $proxy\_add\_x\_forwarded\_for;  
           proxy\_set\_header X-Forwarded-Proto $scheme;  
       }  
   }

4. **Create .env file** for credentials.  
   DATABASE\_NAME=strapi\_db  
   DATABASE\_USERNAME=strapi\_user  
   DATABASE\_PASSWORD=strapi\_password

5. Run the Environment  
   From your project root, run:  
   docker-compose up \--build

   You can now access the Strapi admin panel at http://localhost/admin. 🎉

## **✅ Task 4: Deploying to AWS EC2 with Terraform**

**Objective:** Automate the provisioning of an AWS EC2 instance and deploy the Dockerized Strapi application using Terraform.

### **Steps**

1. Push Your Docker Image to Docker Hub  
   First, log in and push the image you built in Task 2\.  
   docker login  
   docker push \<your-dockerhub-username\>/strapi-app:latest

2. Create Terraform Configuration Files  
   Create a file named main.tf. This file will define the AWS provider, a security group to allow HTTP and SSH traffic, and the EC2 instance itself.  
   terraform {  
     required\_providers {  
       aws \= {  
         source  \= "hashicorp/aws"  
         version \= "\~\> 5.0"  
       }  
     }  
   }

   provider "aws" {  
     region \= "us-east-1" \# Or your preferred region  
   }

   resource "aws\_security\_group" "strapi\_sg" {  
     name        \= "strapi-sg"  
     description \= "Allow HTTP and SSH inbound traffic"

     ingress {  
       from\_port   \= 80  
       to\_port     \= 80  
       protocol    \= "tcp"  
       cidr\_blocks \= \["0.0.0.0/0"\]  
     }

     ingress {  
       from\_port   \= 22  
       to\_port     \= 22  
       protocol    \= "tcp"  
       cidr\_blocks \= \["0.0.0.0/0"\] \# For production, restrict this to your IP  
     }

     egress {  
       from\_port   \= 0  
       to\_port     \= 0  
       protocol    \= "-1"  
       cidr\_blocks \= \["0.0.0.0/0"\]  
     }  
   }

   resource "aws\_instance" "strapi\_server" {  
     ami           \= "ami-0c55b159cbfafe1f0" \# Amazon Linux 2 AMI (us-east-1)  
     instance\_type \= "t2.micro"  
     security\_groups \= \[aws\_security\_group.strapi\_sg.name\]

     user\_data \= \<\<-EOF  
                 \#\!/bin/bash  
                 sudo yum update \-y  
                 sudo yum install \-y docker  
                 sudo service docker start  
                 sudo usermod \-a \-G docker ec2-user  
                 docker pull \<your-dockerhub-username\>/strapi-app:latest  
                 docker run \-d \-p 80:1337 \--restart always \<your-dockerhub-username\>/strapi-app:latest  
                 EOF

     tags \= {  
       Name \= "Strapi-Instance"  
     }  
   }

   output "public\_ip" {  
     value \= aws\_instance.strapi\_server.public\_ip  
   }

3. Initialize and Apply Terraform  
   Run the following commands in the directory containing your main.tf file.  
   \# Initialize Terraform  
   terraform init

   \# Preview the changes  
   terraform plan

   \# Apply the changes to create the infrastructure  
   terraform apply \--auto-approve

4. Verify Deployment  
   After terraform apply completes, it will output the public IP address of the EC2 instance. Access your Strapi app by navigating to http://\<your-ec2-public-ip\>.

## **✅ Task 5: Automating Deployment with GitHub Actions (CI/CD)**

**Objective:** Create a full CI/CD pipeline. The CI workflow builds and pushes a Docker image on every push to main, and the CD workflow uses Terraform to deploy the new image to EC2 when manually triggered.

### **Prerequisites**

* Add the following secrets to your GitHub repository (**Settings \> Secrets and variables \> Actions**):  
  * AWS\_ACCESS\_KEY\_ID: Your AWS access key.  
  * AWS\_SECRET\_ACCESS\_KEY: Your AWS secret key.  
  * DOCKERHUB\_USERNAME: Your Docker Hub username.  
  * DOCKERHUB\_TOKEN: Your Docker Hub access token.

### **1\. CI Workflow: Build and Push Docker Image**

Create .github/workflows/ci.yml to automatically build and push the Docker image to Docker Hub.

name: CI \- Build and Push Docker Image

on:  
  push:  
    branches:  
      \- main

jobs:  
  build-and-push:  
    runs-on: ubuntu-latest  
    outputs:  
      image\_tag: ${{ steps.meta.outputs.version }}  
    steps:  
      \- name: Checkout code  
        uses: actions/checkout@v3

      \- name: Log in to Docker Hub  
        uses: docker/login-action@v2  
        with:  
          username: ${{ secrets.DOCKERHUB\_USERNAME }}  
          password: ${{ secrets.DOCKERHUB\_TOKEN }}

      \- name: Extract metadata (tags, labels) for Docker  
        id: meta  
        uses: docker/metadata-action@v4  
        with:  
          images: ${{ secrets.DOCKERHUB\_USERNAME }}/strapi-app  
          tags: |  
            type=sha,prefix=,format=short

      \- name: Build and push Docker image  
        uses: docker/build-push-action@v4  
        with:  
          context: .  
          push: true  
          tags: ${{ steps.meta.outputs.tags }}  
          labels: ${{ steps.meta.outputs.labels }}

### **2\. CD Workflow: Deploy with Terraform**

Create .github/workflows/terraform.yml to manually trigger the deployment.

name: CD \- Deploy to EC2 with Terraform

on:  
  workflow\_dispatch:  
    inputs:  
      image\_tag:  
        description: 'Image tag to deploy (e.g., latest or commit SHA)'  
        required: true  
        default: 'latest'

jobs:  
  deploy:  
    runs-on: ubuntu-latest  
    steps:  
      \- name: Checkout code  
        uses: actions/checkout@v3

      \- name: Configure AWS Credentials  
        uses: aws-actions/configure-aws-credentials@v2  
        with:  
          aws-access-key-id: ${{ secrets.AWS\_ACCESS\_KEY\_ID }}  
          aws-secret-access-key: ${{ secrets.AWS\_SECRET\_ACCESS\_KEY }}  
          aws-region: us-east-1

      \- name: Setup Terraform  
        uses: hashicorp/setup-terraform@v2

      \- name: Terraform Init  
        run: terraform init

      \- name: Terraform Plan  
        run: terraform plan \-var="image\_tag=${{ github.event.inputs.image\_tag }}"

      \- name: Terraform Apply  
        run: terraform apply \-auto-approve \-var="image\_tag=${{ github.event.inputs.image\_tag }}"

### **Update main.tf for Dynamic Image Tags**

Modify your main.tf to accept the image tag as a variable.

\# ... (provider and security group config) ...

variable "image\_tag" {  
  description \= "The Docker image tag to deploy"  
  type        \= string  
  default     \= "latest"  
}

resource "aws\_instance" "strapi\_server" {  
  \# ... (ami, instance\_type, etc.) ...

  user\_data \= \<\<-EOF  
              \#\!/bin/bash  
              sudo yum update \-y  
              sudo yum install \-y docker  
              sudo service docker start  
              sudo usermod \-a \-G docker ec2-user  
              docker pull \<your-dockerhub-username\>/strapi-app:${var.image\_tag}  
              \# Stop and remove old container if it exists  
              docker stop $(docker ps \-q \--filter "ancestor=\<your-dockerhub-username\>/strapi-app") || true  
              docker rm $(docker ps \-aq \--filter "ancestor=\<your-dockerhub-username\>/strapi-app") || true  
              docker run \-d \-p 80:1337 \--restart always \<your-dockerhub-username\>/strapi-app:${var.image\_tag}  
              EOF  
    
  \# ... (tags) ...  
}

\# ... (output) ...

Now, your complete CI/CD pipeline is set up\! 🚀

## **✅ Task 6: Deploying to AWS ECS Fargate with Terraform**

**Objective:** Deploy a scalable Strapi application on AWS using ECS Fargate, with all infrastructure managed by Terraform.

### **Steps**

1. Create an ECR Repository with Terraform  
   First, we need a private registry to store our Docker image. Create a file named ecr.tf and add the following code to define an AWS ECR repository.  
   resource "aws\_ecr\_repository" "strapi\_ecr\_repo" {  
     name                 \= "strapi-app"  
     image\_tag\_mutability \= "MUTABLE"

     image\_scanning\_configuration {  
       scan\_on\_push \= true  
     }  
   }

2. Build and Push the Docker Image to ECR  
   Before creating the rest of the infrastructure, you must push your application's Docker image to the new ECR repository.  
   * First, apply the Terraform configuration to create the repository:  
     terraform init  
     terraform apply \-target=aws\_ecr\_repository.strapi\_ecr\_repo \--auto-approve

   * Next, run the following commands to authenticate Docker with ECR, then build, tag, and push your image.  
     \# Set environment variables for your AWS Account ID and Region  
     export AWS\_ACCOUNT\_ID=$(aws sts get-caller-identity \--query Account \--output text)  
     export AWS\_REGION=us-east-1 \# Or your preferred region  
     export ECR\_REPO\_URI="${AWS\_ACCOUNT\_ID}.dkr.ecr.${AWS\_REGION}\[.amazonaws.com/strapi-app\](https://.amazonaws.com/strapi-app)"

     \# 1\. Authenticate Docker to your ECR registry  
     aws ecr get-login-password \--region $AWS\_REGION | docker login \--username AWS \--password-stdin $ECR\_REPO\_URI

     \# 2\. Build the Docker image (ensure Dockerfile is in the current directory)  
     docker build \-t strapi-app .

     \# 3\. Tag the image for ECR  
     docker tag strapi-app:latest $ECR\_REPO\_URI:latest

     \# 4\. Push the image to ECR  
     docker push $ECR\_REPO\_URI:latest

3. Write Terraform Code for ECS Fargate Infrastructure  
   Create a new file, ecs.tf, to define the cluster, load balancer, security groups, task definition, and service. This configuration uses the default VPC for simplicity.  
   \# Fetch default VPC and subnets to deploy resources into them  
   data "aws\_vpc" "default" {  
     default \= true  
   }

   data "aws\_subnets" "default" {  
     filter {  
       name   \= "vpc-id"  
       values \= \[data.aws\_vpc.default.id\]  
     }  
   }

   \# Security Group for the Application Load Balancer (allows public HTTP traffic)  
   resource "aws\_security\_group" "alb\_sg" {  
     name        \= "strapi-alb-sg"  
     description \= "Allow HTTP inbound traffic for ALB"  
     vpc\_id      \= data.aws\_vpc.default.id

     ingress {  
       from\_port   \= 80  
       to\_port     \= 80  
       protocol    \= "tcp"  
       cidr\_blocks \= \["0.0.0.0/0"\]  
     }

     egress {  
       from\_port   \= 0  
       to\_port     \= 0  
       protocol    \= "-1"  
       cidr\_blocks \= \["0.0.0.0/0"\]  
     }  
   }

   \# Security Group for the Fargate Service (only allows traffic from our ALB)  
   resource "aws\_security\_group" "fargate\_sg" {  
     name        \= "strapi-fargate-sg"  
     description \= "Allow inbound traffic from ALB for Fargate"  
     vpc\_id      \= data.aws\_vpc.default.id

     ingress {  
       from\_port       \= 1337  
       to\_port         \= 1337  
       protocol        \= "tcp"  
       security\_groups \= \[aws\_security\_group.alb\_sg.id\]  
     }

     egress {  
       from\_port   \= 0  
       to\_port     \= 0  
       protocol    \= "-1"  
       cidr\_blocks \= \["0.0.0.0/0"\]  
     }  
   }

   \# Application Load Balancer (ALB) to route traffic to the service  
   resource "aws\_lb" "strapi\_alb" {  
     name               \= "strapi-alb"  
     internal           \= false  
     load\_balancer\_type \= "application"  
     security\_groups    \= \[aws\_security\_group.alb\_sg.id\]  
     subnets            \= data.aws\_subnets.default.ids  
   }

   resource "aws\_lb\_target\_group" "strapi\_tg" {  
     name        \= "strapi-tg"  
     port        \= 1337  
     protocol    \= "HTTP"  
     vpc\_id      \= data.aws\_vpc.default.id  
     target\_type \= "ip"  
     health\_check {  
       path                \= "/\_health"  
       healthy\_threshold   \= 2  
       unhealthy\_threshold \= 2  
       timeout             \= 3  
       interval            \= 30  
     }  
   }

   resource "aws\_lb\_listener" "strapi\_listener" {  
     load\_balancer\_arn \= aws\_lb.strapi\_alb.arn  
     port              \= 80  
     protocol          \= "HTTP"

     default\_action {  
       type             \= "forward"  
       target\_group\_arn \= aws\_lb\_target\_group.strapi\_tg.arn  
     }  
   }

   \# ECS Cluster  
   resource "aws\_ecs\_cluster" "strapi\_cluster" {  
     name \= "strapi-cluster"  
   }

   \# ECS Task Definition  
   resource "aws\_ecs\_task\_definition" "strapi\_task" {  
     family                   \= "strapi-task"  
     network\_mode             \= "awsvpc"  
     requires\_compatibilities \= \["FARGATE"\]  
     cpu                      \= "256"  \# 0.25 vCPU  
     memory                   \= "512"  \# 512 MB  
     execution\_role\_arn       \= aws\_iam\_role.ecs\_task\_execution\_role.arn

     container\_definitions \= jsonencode(\[  
       {  
         name      \= "strapi"  
         image     \= "${aws\_ecr\_repository.strapi\_ecr\_repo.repository\_url}:latest"  
         essential \= true  
         portMappings \= \[  
           {  
             containerPort \= 1337  
             hostPort      \= 1337  
           }  
         \]  
         \# NOTE: For a production setup, database credentials should be injected  
         \# securely using AWS Secrets Manager, not hardcoded.  
         environment \= \[  
           { name \= "HOST", value \= "0.0.0.0" },  
           { name \= "PORT", value \= "1337" }  
         \]  
       }  
     \])  
   }

   \# ECS Service  
   resource "aws\_ecs\_service" "strapi\_service" {  
     name            \= "strapi-service"  
     cluster         \= aws\_ecs\_cluster.strapi\_cluster.id  
     task\_definition \= aws\_ecs\_task\_definition.strapi\_task.arn  
     launch\_type     \= "FARGATE"  
     desired\_count   \= 1

     network\_configuration {  
       subnets         \= data.aws\_subnets.default.ids  
       security\_groups \= \[aws\_security\_group.fargate\_sg.id\]  
       assign\_public\_ip \= true \# Required for Fargate to pull the ECR image  
     }

     load\_balancer {  
       target\_group\_arn \= aws\_lb\_target\_group.strapi\_tg.arn  
       container\_name   \= "strapi"  
       container\_port   \= 1337  
     }

     depends\_on \= \[aws\_lb\_listener.strapi\_listener\]  
   }

   \# IAM Role for ECS Task Execution  
   resource "aws\_iam\_role" "ecs\_task\_execution\_role" {  
     name \= "ecs\_task\_execution\_role"  
     assume\_role\_policy \= jsonencode({  
       Version \= "2012-10-17",  
       Statement \= \[{  
         Action \= "sts:AssumeRole",  
         Effect \= "Allow",  
         Principal \= {  
           Service \= "ecs-tasks.amazonaws.com"  
         }  
       }\]  
     })  
   }

   resource "aws\_iam\_role\_policy\_attachment" "ecs\_task\_execution\_role\_policy" {  
     role       \= aws\_iam\_role.ecs\_task\_execution\_role.name  
     policy\_arn \= "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"  
   }

   \# Output the public URL of the ALB  
   output "strapi\_url" {  
     description \= "Public URL of the Strapi application"  
     value       \= "http://${aws\_lb.strapi\_alb.dns\_name}"  
   }

4. Initialize and Deploy the Infrastructure  
   Now, run Terraform to deploy the entire ECS stack.  
   terraform init  
   terraform plan  
   terraform apply \--auto-approve

5. Verify Deployment  
   Once terraform apply is complete, it will output the strapi\_url. Navigate to this URL in your browser to access your Strapi application, now running scalably on ECS Fargate\!