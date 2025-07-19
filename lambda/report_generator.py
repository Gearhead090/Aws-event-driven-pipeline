import boto3
import os
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

REPORTS_BUCKET = os.environ.get('REPORTS_BUCKET_NAME')

def handler(event, context):
    yesterday = datetime.utcnow() - timedelta(days=1)
    date_prefix = yesterday.strftime('%Y-%m-%d')
    
    metadata_prefix = f"processed-metadata/{date_prefix}/"
    
    print(f"Generating report for {date_prefix}")

    try:
        response = s3_client.list_objects_v2(
            Bucket=REPORTS_BUCKET,
            Prefix=metadata_prefix
        )

        if 'Contents' not in response:
            print("No files found to process for this date.")
            return { 'statusCode': 200, 'body': 'No files to process.' }

        file_count = len(response['Contents'])
        total_size = sum(item['Size'] for item in response['Contents'])

        report_content = (
            f"Daily Summary Report - {date_prefix}\n"
            f"----------------------------------------\n"
            f"Total files processed: {file_count}\n"
            f"Total size of files: {total_size} bytes\n"
        )
        
        report_key = f"daily-summaries/summary-report-{date_prefix}.txt"
        
        s3_client.put_object(
            Bucket=REPORTS_BUCKET,
            Key=report_key,
            Body=report_content
        )

        print(f"Daily summary report created successfully at {report_key}")

        return {
            'statusCode': 200,
            'body': 'Report generated successfully!'
        }

    except Exception as e:
        print(f"Error generating report: {e}")
        raise e
