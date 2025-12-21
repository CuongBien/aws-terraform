# ========================================
# TFSEC IGNORE RULES
# ========================================
# Add these inline comments to suppress false positives
# Copy and paste into respective files
# ========================================

# ===== modules/core/security/main.tf =====

# Line 29 - ALB HTTP ingress (before aws_security_group_rule.alb_ingress_http)
#tfsec:ignore:aws-ec2-no-public-ingress-sgr # Public-facing ALB requires internet access

# Line 39 - ALB HTTPS ingress (before aws_security_group_rule.alb_ingress_https)
#tfsec:ignore:aws-ec2-no-public-ingress-sgr # Public-facing ALB requires internet access

# Line 49 - ALB egress (before aws_security_group_rule.alb_egress_all)
#tfsec:ignore:aws-ec2-no-public-egress-sgr # ALB needs outbound to target groups

# Line 91 - Internal ALB egress (before aws_security_group_rule.internal_alb_egress_all)
#tfsec:ignore:aws-ec2-no-public-egress-sgr # Internal ALB needs outbound to targets

# Line 153 - Web tier egress (before aws_security_group_rule.web_egress_all)
#tfsec:ignore:aws-ec2-no-public-egress-sgr # Web tier needs internet for updates and APIs

# Line 205 - App tier egress (before aws_security_group_rule.app_egress_all)
#tfsec:ignore:aws-ec2-no-public-egress-sgr # App tier needs internet for updates and APIs

# Line 247 - DB egress (before aws_security_group_rule.db_egress_all)
#tfsec:ignore:aws-ec2-no-public-egress-sgr # DB needs outbound for monitoring and backups

# Line 299 - Bastion egress (before aws_security_group_rule.bastion_egress_to_internet)
#tfsec:ignore:aws-ec2-no-public-egress-sgr # Bastion needs internet for management

# ===== modules/core/networking/main.tf =====

# Line 32 - Public subnets (before resource "aws_subnet" "public")
#tfsec:ignore:aws-ec2-no-public-ip-subnet # Public subnets for bastion and ALB

# Line 279 - VPC endpoint SG (before resource "aws_security_group" "vpc_endpoint")
#tfsec:ignore:aws-ec2-no-public-egress-sgr # VPC endpoints need AWS service access

# ===== modules/edge/alb/main.tf =====

# Line 81 - HTTP listener (before resource "aws_lb_listener" "http")
#tfsec:ignore:aws-elb-http-not-used # HTTP listener for redirect to HTTPS

# ===== modules/nacl/main.tf =====

# Line 16 - Public NACL inbound from VPC (before aws_network_acl_rule.public_inbound_from_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# Line 20 - Same resource, protocol -1
# (Already covered above)

# Line 25 - Public NACL outbound to VPC (before aws_network_acl_rule.public_outbound_to_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# Line 36 - Public SSH (before aws_network_acl_rule.public_inbound_ssh)
#tfsec:ignore:aws-ec2-no-public-ingress-acl # SSH for bastion host access

# Line 48 - Public HTTP (before aws_network_acl_rule.public_inbound_http)
#tfsec:ignore:aws-ec2-no-public-ingress-acl # HTTP for ALB public access

# Line 60 - Public HTTPS (before aws_network_acl_rule.public_inbound_https)
#tfsec:ignore:aws-ec2-no-public-ingress-acl # HTTPS for ALB public access

# Line 72 - Public ephemeral (before aws_network_acl_rule.public_inbound_ephemeral_internet)
#tfsec:ignore:aws-ec2-no-public-ingress-acl # Ephemeral ports for return traffic

# Line 158 - Web private inbound from VPC (before aws_network_acl_rule.web_private_inbound_from_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# Line 167 - Web private outbound to VPC (before aws_network_acl_rule.web_private_outbound_to_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# Line 189 - Web ephemeral (before aws_network_acl_rule.web_inbound_ephemeral_internet)
#tfsec:ignore:aws-ec2-no-public-ingress-acl # Ephemeral ports for return traffic

# Line 248 - App private inbound from VPC (before aws_network_acl_rule.app_private_inbound_from_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# Line 257 - App private outbound to VPC (before aws_network_acl_rule.app_private_outbound_to_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# Line 291 - App ephemeral (before aws_network_acl_rule.app_inbound_ephemeral_internet)
#tfsec:ignore:aws-ec2-no-public-ingress-acl # Ephemeral ports for return traffic

# Line 362 - DB private inbound from VPC (before aws_network_acl_rule.db_private_inbound_from_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# Line 371 - DB private outbound to VPC (before aws_network_acl_rule.db_private_outbound_to_vpc)
#tfsec:ignore:aws-ec2-no-excessive-port-access # Allow all protocols within VPC

# ===== infrastructure_aws/iam.tf =====

# Line 62 - VPC Flow Logs policy (before resource "aws_iam_policy" "vpc_flow_logs_policy")
#tfsec:ignore:aws-iam-no-policy-wildcards # CloudWatch Logs requires wildcard for log group creation
