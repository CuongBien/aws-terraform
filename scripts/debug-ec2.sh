#!/bin/bash
# Debug EC2 health issues

AWS_REGION="ap-southeast-2"

echo "=== Checking Green Web Tier Instances ==="

# Get instance IDs
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region $AWS_REGION \
  --filters \
    "Name=tag:Project,Values=pbl4-three-tier" \
    "Name=tag:Environment,Values=green" \
    "Name=tag:Tier,Values=web" \
    "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "❌ No running green web instances found!"
  exit 1
fi

echo "Found instances: $INSTANCE_IDS"

for INSTANCE_ID in $INSTANCE_IDS; do
  echo ""
  echo "=== Instance: $INSTANCE_ID ==="
  
  # Check IAM role
  echo "--- IAM Instance Profile ---"
  aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' \
    --output text
  
  # Get user-data logs via SSM
  echo ""
  echo "--- User-Data Logs (last 50 lines) ---"
  aws ssm send-command \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["tail -50 /var/log/cloud-init-output.log"]' \
    --query 'Command.CommandId' \
    --output text > /tmp/cmd_id.txt
  
  CMD_ID=$(cat /tmp/cmd_id.txt)
  sleep 3
  
  aws ssm get-command-invocation \
    --region $AWS_REGION \
    --command-id $CMD_ID \
    --instance-id $INSTANCE_ID \
    --query 'StandardOutputContent' \
    --output text
  
  # Check Docker containers
  echo ""
  echo "--- Docker Status ---"
  aws ssm send-command \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["docker ps -a", "docker logs ecommerce-frontend --tail 20 2>&1 || echo No container logs"]' \
    --query 'Command.CommandId' \
    --output text > /tmp/cmd_id.txt
  
  CMD_ID=$(cat /tmp/cmd_id.txt)
  sleep 3
  
  aws ssm get-command-invocation \
    --region $AWS_REGION \
    --command-id $CMD_ID \
    --instance-id $INSTANCE_ID \
    --query 'StandardOutputContent' \
    --output text
  
  # Test health endpoint locally
  echo ""
  echo "--- Local Health Check ---"
  aws ssm send-command \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["curl -v http://localhost/health 2>&1 || wget -O- http://localhost/health 2>&1"]' \
    --query 'Command.CommandId' \
    --output text > /tmp/cmd_id.txt
  
  CMD_ID=$(cat /tmp/cmd_id.txt)
  sleep 3
  
  aws ssm get-command-invocation \
    --region $AWS_REGION \
    --command-id $CMD_ID \
    --instance-id $INSTANCE_ID \
    --query 'StandardOutputContent' \
    --output text
done

echo ""
echo "=== Target Group Health ==="
TG_ARN=$(aws elbv2 describe-target-groups \
  --region $AWS_REGION \
  --names pbl4-three-tier-web-tg-green \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --region $AWS_REGION \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Reason,TargetHealth.Description]' \
  --output table
