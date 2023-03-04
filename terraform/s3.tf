resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = lower(join("-", [replace(local.name, "_", "-"), "pipeline-support-bucket"]))
}

resource "aws_s3_bucket_acl" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = lower(join("-", [replace(local.name, "_", "-"), "logs"]))
}

resource "aws_s3_bucket_acl" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

data "aws_iam_policy_document" "logs_bucket_policy" {
  statement {
    sid       = "put"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs_bucket.arn}/*"]
    principals {
      identifiers = [data.aws_elb_service_account.main.arn]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs_bucket.bucket
  policy = data.aws_iam_policy_document.logs_bucket_policy.json
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = lower(join("-", [replace(local.name, "_", "-"), "lambda-bucket"]))
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "lambda_bucket_policy" {
  bucket = aws_s3_bucket.lambda_bucket.bucket
  policy = data.aws_iam_policy_document.lambda_bucket_policy.json
}

data "aws_iam_policy_document" "lambda_bucket_policy" {
  statement {
    sid       = "put"
    actions   = ["s3:*Object*"]
    resources = ["${aws_s3_bucket.lambda_bucket.arn}/*"]
    principals {
      identifiers = [aws_iam_role.lambda_role.arn]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}

resource "aws_s3_bucket" "testdata_bucket" {
  bucket = lower(join("-", [replace(local.name, "_", "-"), "testdata-bucket"]))
}

resource "aws_s3_bucket_acl" "testdata_bucket" {
  bucket = aws_s3_bucket.testdata_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "testdata_bucket" {
  bucket = aws_s3_bucket.testdata_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

