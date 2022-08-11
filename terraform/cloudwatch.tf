resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/ecs/${local.name}"
  retention_in_days = 30
  tags              = {
    Owner       = "Terraform"
    Application = local.name
  }
}
