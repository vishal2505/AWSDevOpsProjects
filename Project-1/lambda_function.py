import json
import boto3
import time


CF_CLIENT = boto3.client('cloudformation')
EC2_CLIENT = boto3.client('ec2')
 
def restore_ssh_security_group(resource_id, expected_properties):
    # Instantiate Security Group resource
    security_group = boto3.resource('ec2').SecurityGroup(resource_id)
    # Retrieve all security group rules
    rules = EC2_CLIENT.describe_security_group_rules(Filters=[{'Name': 'group-id', 'Values': [resource_id]}])
 
    # Revoke ALL ingress security group rules
    # Skip egress rules 
    if len(rules['SecurityGroupRules']) > 0:
        revoked_rules = []
        for rule in rules['SecurityGroupRules']:
            if rule['IsEgress'] == True:
                continue
            revoked_rules.append(rule['SecurityGroupRuleId'])
        if len(revoked_rules) > 0:
            security_group.revoke_ingress(SecurityGroupRuleIds = revoked_rules)
    # In the event of a deleted expected security group rule,
    # authorize ingress security rule using expected properties
    security_group.authorize_ingress(
                                        CidrIp=expected_properties['CidrIp'],
                                        FromPort=expected_properties['FromPort'],
                                        ToPort=expected_properties['ToPort'],
                                        IpProtocol=expected_properties['IpProtocol']
                                    )
    print("Restored SSH Security Group Successfully")
    return
 
def lambda_handler(event, context):
    STACK_NAME = event['STACK_NAME']                       #"SecurityGroupCFStack"
    RESOURCE_TYPE = event['RESOURCE_TYPE']                 #"AWS::EC2::SecurityGroup"
    SECURITY_GROUP_NAME = event['SECURITY_GROUP_NAME']     #"SSHSecurityGroup"
    # Initiate a stack drift detection
    stack_drift_detection = CF_CLIENT.detect_stack_drift( StackName=STACK_NAME )
    stack_drift_detection_id = stack_drift_detection["StackDriftDetectionId"]
    print(f"Stack Drift Detection ID: {stack_drift_detection_id}")
    drift_detection_status = ""
    
    while drift_detection_status not in ["DETECTION_COMPLETE",  "DETECTION_FAILED"]:
        check_stack_drift_detection_status = CF_CLIENT.describe_stack_drift_detection_status(
            StackDriftDetectionId=stack_drift_detection_id
        )
        drift_detection_status = check_stack_drift_detection_status["DetectionStatus"]
        # Delay status check for 1 second to avoid CloudFormation API throttling
        time.sleep(1)
    print(f"Completed. Detection Status: {drift_detection_status}")
    
    # Alert if detection fails then continue with successfully reported resources
    if drift_detection_status == "DETECTION_FAILED":
            print("The stack drift detection did not complete successfully")
 
    # Check if the stack has drifted
    if check_stack_drift_detection_status["StackDriftStatus"] == "DRIFTED":
    
        # Retrieve resources that have drifted in ca-lab-demo stack
        stack_resource_drift = CF_CLIENT.describe_stack_resource_drifts(
            StackName=STACK_NAME
        )
    
        # Iterate over drifted resources
        for drifted_stack_resource in stack_resource_drift["StackResourceDrifts"]:
            resource_type = drifted_stack_resource["ResourceType"]
            security_group_name = drifted_stack_resource["LogicalResourceId"]
            resource_id = drifted_stack_resource["PhysicalResourceId"]
   
            # If the drifted resource is the SSH Security Group resource, 
            # restore security group rules using expected resource properties
            if resource_type == RESOURCE_TYPE and security_group_name == SECURITY_GROUP_NAME:
                expected_properties = json.loads(drifted_stack_resource["ExpectedProperties"])["SecurityGroupIngress"][0]
                restore_ssh_security_group(resource_id, expected_properties)
    else:
        print("No Drift Detected")