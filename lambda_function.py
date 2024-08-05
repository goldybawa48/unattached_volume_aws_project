import boto3
import json
import os

snsarn = os.getenv('SNSTOPIC')

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    sns = boto3.client('sns')
    
    response = ec2.describe_volumes(
        Filters=[
            {
                'Name': 'status',
                'Values': [
                    'available',
                ]
            },
        ]
    )
    
    print(snsarn)
    count = 0
    volume_details = []
    
    for volume in response['Volumes']:
        count += 1
        volume_info = "volume " + str(count) + " = " + json.dumps(volume['VolumeId'], default=str)
        print(volume_info)
        volume_details.append(volume_info)
        
    total_unused_volumes = "Total unused Volumes = " + str(count)
    
    message = "\n".join( [total_unused_volumes] + volume_details)
    
    response = sns.publish(
        TopicArn='arn:aws:sns:us-east-1:811452661392:ebs-sns', # YOUR SNS ARN
        Message=message,
        Subject='ebs report from us-east-1',
    )
    
    print("Message published")
    print(response)