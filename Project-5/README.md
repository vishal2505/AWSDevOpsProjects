## Implementing Web Identify Federtation using Cognito and creating a image related CRUD app in S3

### Authenticated user will be able to view/upload/delete objects in S3. Users will be authenticated via Web Identity Federation using Cognito and Google Account.

#### Steps -

1. Create a private S3 bucket with CORS enabled.
2. Create S3 bucket for website hosting and CloudFront distribution for the Content Delivery.
3. Create Google API Project and create client ID. Provide Cloudfront distribution for Javascript origin page.
4. Create Cognito Identiy pool and provide the Google Client ID created in the previous step.
5. Create HTML and Javascript for the front end -
    - There wil be sign in with Google button that will allow users to sign in with their Google Account.
    - After signing in, Google ID token will be generated, We'll be using this toeken and exchange credetials from Cognito and will get the temporary credentials.
    - Using these temporary credential, users will be able to view/upload/dlete objects to S3.


#### Ref Docs -


https://docs.aws.amazon.com/apigateway/latest/developerguide/integrating-api-with-aws-services-s3.html


Connecting to an API Gateway endpoint secured using AWS IAM can be challenging. You need to sign your requests using Signature Version 4. You can use:

Generated API Gateway SDK
AWS Amplify


##### Javascript SDK Example
https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/s3-example-photos-view.html

##### Cognito
https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/loading-browser-credentials-cognito.html


#### Issues and Resolutions -



