# **Strapi Internship Tasks: From Local Setup to Automated Deployment**

This repository documents the process of setting up, containerizing, deploying, and automating a Strapi application. The project covers local setup, Dockerization, orchestration with Docker Compose, infrastructure provisioning on AWS with Terraform, and setting up a CI/CD pipeline using GitHub Actions.

## **📋 Table of Contents**

* [Prerequisites](https://www.google.com/search?q=%23-prerequisites)  
* [Task 1: Local Strapi Setup](https://www.google.com/search?q=%23-task-1-local-strapi-setup)  
* [Task 2: Dockerizing the Strapi Application](https://www.google.com/search?q=%23-task-2-dockerizing-the-strapi-application)  
* [Task 3: Multi-Container Setup with Docker Compose](https://www.google.com/search?q=%23-task-3-multi-container-setup-with-docker-compose)  
* [Task 4: Deploying to AWS EC2 with Terraform](https://www.google.com/search?q=%23-task-4-deploying-to-aws-ec2-with-terraform)  
* [Task 5: Automating Deployment with GitHub Actions (CI/CD)](https://www.google.com/search?q=%23-task-5-automating-deployment-with-github-actions-cicd)

## **🛠️ Prerequisites**

Before you begin, ensure you have the following installed and configured:

* **Node.js** (v18 or later)  
* **npm** or **yarn**  
* **Docker** and **Docker Compose**  
* **Terraform**  
* An **AWS Account** with programmatic access (Access Key ID and Secret Access Key)  
* A **Docker Hub Account**  
* A **GitHub Account**

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