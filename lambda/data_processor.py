import boto3
import os
import json
from datetime import datetime

s3_client = boto3.client('s3')

REPORTS_BUCKET = os.environ.get('REPORTS_BUCKET_NAME')

def handler(event, context):
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']

    print(f"Processing {object_key} from bucket {bucket_name}")

    try:
        processed_data = {
            'source_file': object_key,
            'file_size': event['Records'][0]['s3']['object']['size'],
            'processed_timestamp': datetime.utcnow().isoformat()
        }
        
        destination_key = f"processed-metadata/{datetime.utcnow().strftime('%Y-%m-%d')}/{object_key.split('/')[-1]}.json"
        
        s3_client.put_object(
            Bucket=REPORTS_BUCKET,
            Key=destination_key,
            Body=json.dumps(processed_data, indent=2),
            ContentType='application/json'
        )
        
        print(f"Successfully processed and stored metadata at {destination_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Processing successful!')
        }

    except Exception as e:
        print(f"Error processing file: {e}")
        raise e
