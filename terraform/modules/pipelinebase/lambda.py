import boto3
import os
import json
import urllib.parse
import hashlib
import hmac
import io,zipfile
import base64

print('Loading function')
github_secret = os.environ['SECRET_KEY']
# def check_secret(payload, from_github_signature):
#     signature_bytes = bytes(github_secret, 'utf-8')

#     digest = hmac.new(key=signature_bytes, msg=payload.encode('utf-8'), digestmod=hashlib.sha256)
#     signature = digest.hexdigest()
#     print(f"Calculated signature: {signature}")
#     return signature == from_github_signature[7:]

# def check_secret(payload, from_gitlab_signature):
#     secret = os.environ['SECRET_KEY']
#     signature_bytes = bytes(secret, 'utf-8')
#     digest = hmac.new(key=signature_bytes, msg=payload.encode('utf-8'), digestmod=hashlib.sha256)
#     signature = digest.hexdigest()

    
#     # Calculate the expected signature
#     signature = hmac.new(key=bytes(secret, 'utf-8'), msg=bytes(payload, 'utf-8'), digestmod=hashlib.sha256).hexdigest()

#     # GitLab sends the signature in base64 format
#     gitlab_signature = base64.b64decode(from_gitlab_signature).decode('utf-8')

#     print(f"Expected signature: {signature}")
#     print(f"Received signature: {gitlab_signature}")

#     return hmac.compare_digest(signature, gitlab_signature)

def lambda_handler(event, context):
    print("event header:::", event['headers'])
    print("event header:::", event['body'])
    body = json.loads(event['body'])
    branch_name = body['ref'].split("/")[-1]
    repo_name = body['repository']['name']
    commit_id = body['after'][:8]
    # if not check_secret(event['body'],event['headers']['x-hub-signature-256']):
    # # if not check_secret(event['body'],event['headers']['X-Gitlab-Token']):
    #     response = {
    #         "statusCode": 403,
    #         "body": "Access Forbidden"
    #     }
    #     return response
    ##Write file data
    file_data = {
        "branch_name": branch_name,
        "repo_name": repo_name
    }
    file_name = "{}/{}/metadata.zip".format(repo_name,branch_name)
    # with open("/tmp/metadata.zip", 'w') as f:
    #     f.write(json.dumps(file_data))

    file_contents = io.BytesIO(json.dumps(file_data).encode())
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, mode='w') as zipf:
        # Add the file to the zip archive
        zipf.writestr('metadata.json', file_contents.getvalue())
    buffer.seek(0)
    with open('/tmp/metadata.zip', 'wb') as f:
        f.write(buffer.read())
    ##Push to s3
    s3 = boto3.client('s3');
    s3.upload_file("/tmp/metadata.zip",os.environ['BUCKET'],file_name)

    return 200
