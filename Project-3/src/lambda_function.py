import json
import os
import boto3
from botocore.exceptions import ClientError
import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

SRC_BUCKET = os.environ.get('USER_BUCKET')

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Get the file content from the POST request
    print(event)
    file_content = event['body']
    
    # Define S3 bucket and key (file path) to store the uploaded file
    file_key = 'uploads/' + event['queryStringParameters']['filename']  # Define your S3 file path
    
    try:
        # Upload the file to S3 bucket
        s3.put_object(Body=file_content, Bucket=SRC_BUCKET, Key=file_key)
        
        # Return a success response
        return {
            'statusCode': 200,
            'body': json.dumps('File uploaded successfully to S3'),
            "headers": {
            "Access-Control-Allow-Origin": "*"
            }
        }
    except ClientError as e:
        # If upload fails, return an error response
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to upload file to S3: {}'.format(str(e)))
        }
