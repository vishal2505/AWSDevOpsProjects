### Errors Encountered and Resolutions

1. Getting below error even though CORS is enabled in api gateway and file is getting uploaded to S3

```
Access to fetch at 'https://xxxxxx.execute-api.us-east-1.amazonaws.com/dev/upload?filename=file.txt' from origin 'http://127.0.0.1:5500' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource. If an opaque response serves your needs, set the request's mode to 'no-cors' to fetch the resource with CORS disabled.

POST https://xxxxxx.execute-api.us-east-1.amazonaws.com/dev/upload?filename=file.txt net::ERR_FAILED 200 (OK)

app.js:35 There was a problem with the file upload: TypeError: Failed to fetch
    at uploadFile (app.js:20:3)
    at HTMLInputElement.handleFileUpload (app.js:7:5)
```


*Solution* Since I was using Proxy integration so I will have to send the following in the response header - "Access-Control-Allow-Origin". I modfied the LAmbda function with the response header and after that this error got resolved.


2. Getting *Access Denied* error whle accessing Cloudfront distribution.

Error -
```
<Error>
<Code>AccessDenied</Code>
<Message>Access Denied</Message>
<RequestId>GT6MJX8YVDJW7N5F</RequestId>
<HostId>QKDWhlO6IU0nnk32nOpaJCRVK3Q4Ehrs/5ap9yTnaa2vRy2AhD7GYpkHx3tocfaB+QtmSrYrlxQ=</HostId>
</Error>
```

Make sure bucket policy is updated for Cloudfront to access.

*Solution* 

Updated below policy in the bucket.

```
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::file-uploader-service-app-9002/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::503382476502:distribution/E683SHD2Z443X"
                }
            }
        }
    ]
}
```