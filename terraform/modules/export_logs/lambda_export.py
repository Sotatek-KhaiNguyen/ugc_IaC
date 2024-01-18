import boto3
import json
import os
from datetime import datetime

dev_postgresql_log = os.environ.get("dev_postgresql_log")
dev_redis_engine_logs = os.environ.get("dev_redis_engine_logs")
dev_redis_slowly_logs = os.environ.get("dev_redis_slowly_logs")
dev_s3_achived_logs = os.environ.get("dev_s3_achived_logs")

def lambda_handler(event, context):
    log_group_names = ['/aws/rds/instance/mysql-db/error', '/aws/rds/instance/postgresql-db/postgresql', 'redis_slow/dev-ugc']
    bucket_name = dev_s3_achived_logs
    # log_group_names = [dev_postgresql_log, dev_redis_engine_logs, dev_redis_slowly_logs]
    # bucket_name = dev_s3_achived_logs

    # Create AWS clients
    logs_client = boto3.client('logs')
    s3_client = boto3.client('s3')

    for log_group_name in log_group_names:
        # Retrieve log streams from the log group
        log_streams = logs_client.describe_log_streams(logGroupName=log_group_name)

        for stream in log_streams['logStreams']:
            stream_name = stream['logStreamName']

            # Get log events from the stream
            log_events = logs_client.get_log_events(logGroupName=log_group_name, logStreamName=stream_name)

            # Process and format the log events
            formatted_logs = [json.dumps(event) for event in log_events['events']]

            # Define the S3 object key
            now = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
            object_key = f'{log_group_name}/{stream_name}-{now}.json'

            # Write logs to S3
            s3_client.put_object(Bucket=bucket_name, Key=object_key, Body='\n'.join(formatted_logs))

    return {
        'statusCode': 200,
        'body': json.dumps('Log transfer completed')
    }