import boto3
from pprint import pprint

USE2 = "us-east-2"
def get_tag(tags, key='Name'):

  if not tags: return ''

  for tag in tags:
  
    if tag['Key'] == key:
      return tag['Value']
    
  return ''

ec2_client = boto3.client('ec2', region_name=USE2)

response = ec2_client.describe_volumes()

instances_and_volumes = []

for item in response["Volumes"]:
    instance_and_volume = {
        "volumeId": item["VolumeId"],
        "instanceId": item["Attachments"][0]["InstanceId"] if len(item["Attachments"]) > 0 else ''
    }
    instances_and_volumes.append(instance_and_volume)

ec2_resource = boto3.resource('ec2', region_name=USE2)

instance_details = ec2_resource.instances.filter(InstanceIds=[x['instanceId'] for x in instances_and_volumes])
for instance in instance_details:
    for instance_and_volume in instances_and_volumes:
        if instance.id == instance_and_volume["instanceId"]:
            instance_and_volume["instanceName"] = get_tag(instance)

pprint(instances_and_volumes)
