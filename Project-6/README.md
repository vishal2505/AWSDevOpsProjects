## Serverless Blog Web App using ECS, ECR, Docker - Blue Green Deployment

### Automated Infra creation using Terraform

#### Steps -

1. Create new virtual env and install libraries
```
conda create -n ecsproject_py310 python=3.10 
conda activate ecsproject_py310
pip install flask boto3
```

2. Create folders for various files -

Explanation:

    - app.py: The main Python file where you'll create your Flask application, define routes, and handle logic.
    - requirements.txt: List of Python libraries required for the application, used for dependency management.
    - Dockerfile: Instructions for building the Docker image that will package your application and its dependencies.
    - templates/: Folder containing HTML templates used to render the user interface.
    - static/: Folder for static assets like CSS, JavaScript, and images.
    - tests/: Folder for unit tests to ensure code quality.

3. start writing html/code in the respective files.

4. Test locally.

5. Create Dockerfile:

    - Define instructions to build a Docker image for your application.
    - Include necessary dependencies and configuration.
    - Expose the appropriate port.

6. Create CodeBuild Project:

    *I have to create different repo for codebuild project as Codebuild project in AWS has to sources from github repostiry and root directory.*
    *Here is the repo for CodeBuild project. BAsically it has the same code asd `blog-app` folder as in this repo.
    [https://github.com/vishal2505/MyBlogApp]
    - In the AWS Management Console, navigate to CodeBuild and create a new project.
    - Set up source code location (GitHub repository or S3 bucket).
    - Choose a build environment image (compatible with Python and Flask).
    - Define build commands to:
    - Install dependencies.
    - Run tests (optional).
    - Build the Docker image.
    - Push the image to Amazon ECR (Elastic Container Registry).

7. Create ECS Cluster and Task Definition and Service for Blue Service:

    - In the ECS console, create a cluster and task definition.
    - Specify container image from ECR.
    - Define CPU and memory requirements.
    - Set container port mappings.

8. Create ALB, target group and http listener which forward traffice to the Blue Service

    - Use CodeBuild to trigger automatic deployments whenever code changes or manually trigger a build.
    - CodeBuild will build the image, push it to ECR, and update the task definition in ECS.

9. Test the application via load balancer URL.

10. MAke change in the web app code and commit the changes.

11. Enable Automatic Code build trigger to build the image upon code merge. Tag this image as new "Green" image. Image will be pushed to ECR.

12. Create another ECS task and service which is gonna pull the "Green" image from ECR.

13. Create new ALB Target group for the ECS Green Service and update listener rule for 50-50%.

14. Gradually shift traffic from Blue to Green using weighted target groups.
        
15. Once all traffic is on Green, terminate the Blue service.



