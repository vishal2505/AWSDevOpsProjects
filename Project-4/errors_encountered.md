### Errors Encountered and Resolutions

1. Getting below error ewhile making cals to STS for getting temporary credentials.

```     
        
POST https://sts.amazonaws.com/ 403 (Forbidden)

app.js:48 AccessDenied: User: arn:aws:sts::503382476502:assumed-role/FileStorageAppRole/CognitoIdentityCredentials is not authorized to perform: sts:GetFederationToken on resource: arn:aws:sts::503382476502:federated-user/MyTemporaryCredentials
    at constructor.o (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:14:23990)
    at constructor.callListeners (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:15:16753)
    at constructor.emit (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:15:16462)
    at constructor.emitEvent (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:15:4122)
    at constructor.e (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:15:555)
    at a.runTo (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:16:14399)
    at https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:16:14606
    at constructor.<anonymous> (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:15:765)
    at constructor.<anonymous> (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:15:4177)
    at constructor.callListeners (https://sdk.amazonaws.com/js/aws-sdk-2.2.19.min.js:15:16859)
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