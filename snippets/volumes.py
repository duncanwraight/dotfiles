import boto3
import argparse
from pprint import pprint

# parser = argparse.ArgumentParser(description="Region")
# parser.add_argument('--region', default="us-east-2")
# args = parser.parse_args()

def get_useful_tag(tags):
  name = ""
  keys_to_search = ["Name", "aws:autoscaling:groupName", "aws:cloudformation:stack-name"]

  for key in keys_to_search:
    for tag in tags:
      if tag["Key"] == key:
        name = tag["Value"]
    
    if name:
      break

  if not name:
    name = "Unknown"

  return name

def get_volume_sizes(region):
  ec2_client = boto3.client('ec2', region_name=region)
  response = ec2_client.describe_volumes()

  instances_and_volumes = []
  unattached_volumes = []

  for item in response["Volumes"]:
    if len(item["Attachments"]) > 0:
      instance_and_volume = {
        "volumeId": item["VolumeId"],
        "instanceId": item["Attachments"][0]["InstanceId"],
        "size": item["Size"],
        "iops": item["Iops"] if "Iops" in item else 0
      }
      instances_and_volumes.append(instance_and_volume)
    else:
      unattached_volumes.append(item["VolumeId"])

  ec2_resource = boto3.resource('ec2', region_name=region)

  instance_details = ec2_resource.instances.filter(InstanceIds=[x['instanceId'] for x in instances_and_volumes])

  for instance in instance_details:
    for instance_and_volume in instances_and_volumes:
      if instance.id == instance_and_volume["instanceId"]:
        instance_and_volume["instanceName"] = get_useful_tag(instance.tags) if instance.tags and len(instance.tags) > 0 else "No tags"

  sizes = {}
  unknowns = []
  for instance_and_volume in instances_and_volumes:
    applications = ["unknown", "unicorn", "analyst", "ChromiumServer", "squid", "proxy", "maestro", "looker", "nginx", "k8s", "kube", "britannica", "crawl-compare", "jedi", "file-extractor", "commerce", "workflow", "bees", "redshift", "object-store", "nexus"]
    
    found = False
    for application in applications:
      if application.lower() in instance_and_volume["instanceName"].lower():
        found = True
        if application in sizes:
          sizes[application] += instance_and_volume["size"]
        else:
          sizes[application] = instance_and_volume["size"]
      
    if not found:
      unknowns.append(instance_and_volume["instanceName"])

  print("--- REGION: {}".format(region))
  print(sizes)
  print(unknowns)
  print

for region in ["us-east-2", "us-east-1"]:
  get_volume_sizes(region)