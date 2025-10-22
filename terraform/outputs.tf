output "application_name" {
  description = "Elastic Beanstalk application name"
  value       = aws_elastic_beanstalk_application.todo_app.name
}

output "environment_url" {
  description = "Environment URL"
  value       = aws_elastic_beanstalk_environment.todo_env.endpoint_url
}