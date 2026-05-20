import json
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):

    print("EVENT:", event)

    if 'Records' not in event:
        return {"status": "skipped"}

    for record in event['Records']:
        if record['eventName'] in ['INSERT', 'MODIFY']:

            data = record['dynamodb'].get('NewImage', {})

            item = {
                "city": data.get('city', {}).get('S'),
                "temp": float(data.get('temp', {}).get('N', 0)),
                "humidity": int(data.get('humidity', {}).get('N', 0))
            }

            s3.put_object(
                Bucket='weather-bucket003',
                Key=f"weather/{context.aws_request_id}.json",
                Body=json.dumps(item)
            )

    return {"status": "success"}