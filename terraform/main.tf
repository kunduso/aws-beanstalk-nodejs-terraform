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

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "beanstalk_lb" {
  name_prefix = "beanstalk-lb-"
  description = "Security group for Beanstalk load balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "beanstalk-lb-sg"
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_environment
resource "aws_elastic_beanstalk_environment" "todo_env" {
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

  # Environment Type (LoadBalanced = with ALB)
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Auto Scaling Configuration (only applies if LoadBalanced)
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

  # Load Balancer Configuration (only applies if LoadBalanced)
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_lb.id
  }
}