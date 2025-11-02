# Get latest Node.js 20 solution stack
data "aws_elastic_beanstalk_solution_stack" "nodejs" {
  most_recent = true
  name_regex  = "64bit Amazon Linux 2023.*Node.js 20"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_application
resource "aws_elastic_beanstalk_application" "todo_app" {
  name        = "nodejs-todo-app"
  description = "Node.js to-do application"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "app_versions" {
  bucket        = "${var.name}-beanstalk-versions-${random_string.bucket_suffix.result}"
  force_destroy = true
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "app_versions" {
  bucket = aws_s3_bucket.app_versions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

#https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "../app"
  output_path = "../app.zip"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.app_versions.bucket
  key    = "app-${data.archive_file.app_zip.output_md5}.zip"
  source = data.archive_file.app_zip.output_path
  etag   = data.archive_file.app_zip.output_md5
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_application_version
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "app-${data.archive_file.app_zip.output_md5}"
  application = aws_elastic_beanstalk_application.todo_app.name
  description = "Application version created by Terraform"
  bucket      = aws_s3_bucket.app_versions.bucket
  key         = aws_s3_object.app_version.key
}

# Security group for Application Load Balancer
resource "aws_security_group" "beanstalk_alb" {
  name_prefix = "beanstalk-alb-"
  description = "Security group for Beanstalk Application Load Balancer"
  vpc_id      = module.vpc.vpc.id

  tags = {
    Name = "beanstalk-alb-sg"
  }
}

# Security group for EC2 instances
resource "aws_security_group" "beanstalk_instances" {
  name_prefix = "beanstalk-instances-"
  description = "Security group for Beanstalk EC2 instances"
  vpc_id      = module.vpc.vpc.id

  tags = {
    Name = "beanstalk-instances-sg"
  }
}

# Security group rules
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

resource "aws_security_group_rule" "alb_egress" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.beanstalk_instances.id
  security_group_id        = aws_security_group.beanstalk_alb.id
  description              = "Allow ALB to forward traffic to instances on port 8080"
}

resource "aws_security_group_rule" "instances_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.beanstalk_alb.id
  security_group_id        = aws_security_group.beanstalk_instances.id
  description              = "Allow traffic from ALB to instances on port 8080"
}

resource "aws_security_group_rule" "instances_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.beanstalk_instances.id
  description       = "Allow HTTPS outbound for package downloads"
}

resource "aws_security_group_rule" "instances_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.beanstalk_instances.id
  description       = "Allow HTTP outbound for package downloads"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_environment
resource "aws_elastic_beanstalk_environment" "todo_env" {
  #checkov:skip=CKV_AWS_312: "Ensure Elastic Beanstalk environments have enhanced health reporting enabled"
  #Reason: SystemType=enhanced is configured, but Checkov expects HealthStreamingEnabled which is not a valid Beanstalk setting
  name                = "nodejs-todo-env"
  application         = aws_elastic_beanstalk_application.todo_app.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.nodejs.name
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

  # Instance Configuration
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2.name
  }

  # Service Role
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service.arn
  }

  # Environment Type (LoadBalanced = with ALB)
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Auto Scaling Configuration
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "3"
  }

  # Load Balancer Configuration
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  # VPC Configuration
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = module.vpc.vpc.id
  }

  # Private subnets for EC2 instances
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", [for subnet in module.vpc.private_subnets : subnet.id])
  }

  # Public subnets for load balancer
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", [for subnet in module.vpc.public_subnets : subnet.id])
  }

  # No public IP for instances in private subnets
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }

  # Use custom security groups
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_instances.id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_alb.id
  }

  # Custom Auto Scaling Triggers
  # Scale up when CPU > 60% (more responsive than default 80%)
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "60"
  }

  # Scale down when CPU < 25% (more conservative than default 10%)
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "25"
  }

  # Monitor CPU utilization
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  # Check every 3 minutes (faster than default 5 minutes)
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "3"
  }

  # How many data points to evaluate
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "EvaluationPeriods"
    value     = "2"
  }

  # Cooldown period between scaling actions (5 minutes)
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Cooldown"
    value     = "300"
  }

  # Enable managed platform updates
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Sun:10:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }
  # Enable enhanced health reporting
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
}