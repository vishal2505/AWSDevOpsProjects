# Ultimate CI/CD Pipeline using Jenkins and Terraform for AWS EKS


1. Create Private bucket for storing Terraform Remote State files --> terraform-eks-cicd-7001

2. Create Jenkins Server on EC2 using tools - Jenkins, git, Terraform and Kubectl

3. 

### Errors -

```
tf-aws-ec2  $  terraform init

Initializing the backend...
Initializing modules...
╷
│ Error: Failed to get existing workspaces: S3 bucket does not exist.
│ 
│ The referenced S3 bucket must have been previously created. If the S3 bucket
│ was created within the last minute, please wait for a minute or two and try
│ again.
│ 
│ Error: NoSuchBucket: The specified bucket does not exist
│       status code: 404, request id: FR6YJRYDT6VECCQS, host id: 1bQdGEjfEcGerIFQJo0myOx4MDObCTPzFr4vUEBFDMtmKL686fKlky5KxA5wBv2gGiZsRKkyjwk=
```