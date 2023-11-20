import boto3
from PIL import Image
import os
import time
import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

SRC_BUCKET = os.environ.get('SRC_BUCKET')
TGT_BUCKET = os.environ.get('TGT_BUCKET')

s3 = boto3.client('s3')
cloudwatch = boto3.client('cloudwatch')

def publish_custom_metric(value):
    cloudwatch.put_metric_data(
        Namespace='ImageProcessing',
        MetricData=[
            {
                'MetricName': 'ExecutionTime',
                'Value': value,
                'Unit': 'Milliseconds',
            },
        ]
    )

def lambda_handler(event, context):
    LOGGER.info('Source Bucket: %s', SRC_BUCKET)
    LOGGER.info('Target Bucket: %s', TGT_BUCKET)
    start_time = time.time()

    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        LOGGER.info('Processing file: %s', key)
        download_path = '/tmp/{}'.format(key)
        upload_path = '/tmp/resized-{}'.format(key)

        s3.download_file(bucket, key, download_path)

        with Image.open(download_path) as image:
            resized_image = image.resize((300, 300))

            resized_image.save(upload_path)

        s3.upload_file(upload_path, '{}'.format(TGT_BUCKET), key)
        os.remove(download_path)
        os.remove(upload_path)

    end_time = time.time()
    execution_time = (end_time - start_time) * 1000  # in milliseconds
    LOGGER.info('Total Execution Time: %s ms', execution_time)

    publish_custom_metric(execution_time)
