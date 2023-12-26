## Serverless Blog with Comment System using ECS, ECR, Docker - Blue Green Deployment

### WIP

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

    - In the AWS Management Console, navigate to CodeBuild and create a new project.
    - Set up source code location (GitHub repository or S3 bucket).
    - Choose a build environment image (compatible with Python and Flask).
    - Define build commands to:
    - Install dependencies.
    - Run tests (optional).
    - Build the Docker image.
    - Push the image to Amazon ECR (Elastic Container Registry).

7. Create ECS Cluster and Task Definition:

    - In the ECS console, create a cluster and task definition.
    - Specify container image from ECR.
    - Define CPU and memory requirements.
    - Set container port mappings.

8. Deploy to ECS:

    - Use CodeBuild to trigger automatic deployments whenever code changes or manually trigger a build.
    - CodeBuild will build the image, push it to ECR, and update the task definition in ECS.

9. Blue-Green Deployment:

Create two ECS services: Green (current version) and Blue (new version).
Route traffic to the Green service.
Update the task definition in the Blue service with the new image.
Deploy the Blue service with a new task definition revision.
Perform health checks on the Blue service.
If successful, gradually shift traffic from Green to Blue using weighted target groups or a load balancer.
Once all traffic is on Blue, terminate the Green service.

#### Ref Docs -
