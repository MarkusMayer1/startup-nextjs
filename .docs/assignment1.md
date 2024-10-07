# Summary of Assignment 1 Implementation

The goal of this assignment was to containerize a Next.js web application and build a CI/CD pipeline using GitHub Actions. Below is a step-by-step breakdown of how I approached and solved the task.

1. **Familiarize with the web-app and try building it**:  
   I began by building and running the Next.js application locally to ensure that it worked as expected. This established a baseline for the containerization and pipeline tasks.

  ```console
  npm install
  npm build
  npm start
  ```

2. **Learn about Docker image building**:  
   I explored Docker's image-building process, focusing on multi-stage builds.  I learned how to create a Dockerfile, build an image, and run a container from the image.

3. **Create a Dockerfile for a multi-stage build**:  
   I created a multi-stage Dockerfile for the Next.js application. The first stage handles dependencies and builds the application, while the second stage runs the built application. Then I tested the Dockerfile locally to ensure that it worked as intended.

  ```console
  docker build -t startup-nextjs .
  docker run -p 3000:3000 startup-nextjs
  ```

4. **Get acquainted with GitHub Actions and write the pipeline**:  
   After Dockerizing the application, I moved on to build the CI/CD pipeline using GitHub Actions. I divided the pipeline into the following jobs:

   *  **Lint Job**: Runs on every push to any branch.
   *  **Build Job**: Runs on every push to any branch.
   *  **Audit Job**: Runs only when merging to the `main` or `release` branch.

   The pipeline configuration is stored in `.github/workflows/ci-cd.yml`.

5. **Create necessary branches**:  
   I created the necessary branches (`release` and `feature/test`) to test various scenarios.

6. **Test your implementation**:  
   After the pipeline was set up, I tested it by pushing and merging to different branches, verifying that each step triggered correctly based on the given conditions.

## Bonus Points

### Docker Hub Integration And Azure Container App Deployment:  
I created an Azure Container App on the Azure portal and tested if it was working and if I could access it. Then I navigated to Settings and under Settings to Deploy and filled out all necessary fields and set up the continuous deployment. Azure then automatically generated and pushed the `.github/workflows/startup-nextjs-AutoDeployTrigger-bfe08b7d-cf02-4ec4-8e01-47fc1aef19b9.yml` file which builds and pushes the Docker image to Docker Hub and deploys the container to the Azure Container App I created.

## Conclusion

The initial tasks were relatively straightforward and there were no significant challenges. The first minor difficulty was configuring the audit job to run only on merges to the `main` or `release` branches. Building and pushing the Docker image to Docker Hub was also manageable.

The deployment to Azure Container Apps was relatively difficult and required more time. Initially, I tried to write a deployment job myself but faced issues logging into Azure during the pipeline. I spent some time trying to create a service principal, which was not possible with my student account. Eventually, a colleague mentioned the deployment option in the settings of the Azure Container App, which simplified the process.
