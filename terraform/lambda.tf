resource "aws_lambda_function" "lambda" {
  function_name = "${local.name}_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.8"
  timeout       = 300
  s3_bucket     = aws_s3_bucket.lambda_bucket.bucket
  s3_key        = aws_s3_object.lambda_object.key
  environment {
    variables = {
      BUCKET               = aws_s3_bucket.testdata_bucket.bucket
      FILEPATH             = "acceptance_url_list.csv"
      ENDPOINT             = "${local.custom_endpoint}:8080"
      ACCEPTANCE_THRESHOLD = "90"
    }
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "${local.name}_lambda_sg"
  description = "${local.name}_lambda_sg"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}_lambda_sg"
  }
}

resource "aws_s3_object" "lambda_object" {
  key    = "${local.name}/dist.zip"
  bucket = aws_s3_bucket.lambda_bucket.bucket
  source = data.archive_file.lambda_zip_file.output_path
}

data "archive_file" "lambda_zip_file" {
  type        = "zip"
  output_path = "${path.module}/${local.name}-lambda.zip"
  source_file = "${path.module}/../lambda/app.py"
}
