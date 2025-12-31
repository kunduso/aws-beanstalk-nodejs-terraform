# Security groups for Elastic Beanstalk environment

# Security group for Application Load Balancer
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "beanstalk_alb" {
  #checkov:skip=CKV2_AWS_5: "Security group is attached to ALB via Beanstalk environment configuration"
  name_prefix = "beanstalk-alb-"
  description = "Security group for Beanstalk Application Load Balancer"
  vpc_id      = module.vpc.vpc.id

  tags = {
    Name = "beanstalk-alb-sg"
  }
}

# Security group for EC2 instances
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "beanstalk_instances" {
  #checkov:skip=CKV2_AWS_5: "Security group is attached to EC2 instances via Beanstalk environment configuration"
  name_prefix = "beanstalk-instances-"
  description = "Security group for Beanstalk EC2 instances"
  vpc_id      = module.vpc.vpc.id

  tags = {
    Name = "beanstalk-instances-sg"
  }
}

# Security group rules
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "alb_ingress" {
  #checkov:skip=CKV_AWS_260: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 80"
  #Reason: Skipping for demo purposes to showcase Elastic Beanstalk functionality. 
  #        For production workloads, implement proper access controls and consider using HTTPS with restricted CIDR blocks.
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.beanstalk_alb.id
  description       = "Allow HTTP traffic from internet to ALB"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "alb_egress" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.beanstalk_instances.id
  security_group_id        = aws_security_group.beanstalk_alb.id
  description              = "Allow ALB to forward traffic to instances on port 8080"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "instances_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.beanstalk_alb.id
  security_group_id        = aws_security_group.beanstalk_instances.id
  description              = "Allow traffic from ALB to instances on port 8080"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "instances_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.beanstalk_instances.id
  description       = "Allow HTTPS outbound for package downloads"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "instances_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.beanstalk_instances.id
  description       = "Allow HTTP outbound for package downloads"
}