# Ultimate CI/CD Pipeline using Jenkins and Terraform for AWS EKS


1. Create Private bucket for storing Terraform Remote State files --> terraform-eks-cicd-7001

2. Create Jenkins Server on EC2 using tools - Jenkins, git, Terraform and Kubectl

3. Configure Jenkins Server

4. Create Terraform configuration files for EKS Cluster in private VPC

5. Add stages in the Jenkins pipeline for terraform init, plan and apply for EKS cluster

6. Creaye Manigest files - Deployment.yaml and Service.yaml for a simple NGinx application

7. Add another stage in the jenkins pipeline to apply these manifest files

8. Run the pipeline

Below is the repo which is going to be used in the Jenkins pipeline during `SCM checkout`.

https://github.com/vishal2505/terraform-eks-cicd/tree/main

