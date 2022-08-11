data "aws_iam_policy_document" "codepipeline_trust_policy" {
  statement {
    sid     = "Trust"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${local.name}_codepipeline_role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_trust_policy.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    sid       = "PassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test = "StringEqualsIfExists"
      values = [
        "cloudformation.amazonaws.com",
        "elasticbeanstalk.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
      variable = "iam:PassedToService"
    }
  }
  statement {
    sid    = "Codecommit"
    effect = "Allow"
    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "misc"
    effect = "Allow"
    actions = [
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "sqs:*",
      "ecs:*"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "lambda"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:ListFunctions"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "codebuild"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "codedeploy"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${local.name}_codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

data "aws_iam_policy_document" "codebuild_trust_policy" {
  statement {
    sid     = "Trust"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    sid = "S3"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.testdata_bucket.arn,
      "${aws_s3_bucket.testdata_bucket.arn}/*",
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
      "arn:aws:s3:::codepipeline-${data.aws_region.current.name}-*"
    ]
  }
  statement {
    sid       = "codepipeline"
    actions   = ["codepipeline:*"]
    resources = [aws_codepipeline.codepipeline.arn]
  }
  statement {
    sid       = "codebuild"
    actions   = ["codebuild:*"]
    resources = ["*"]
  }
  statement {
    sid       = "ecr"
    actions   = ["ecr:*"]
    resources = ["*"]
  }
  statement {
    sid = "logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    sid = "vpc"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild_role_${local.name}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_trust_policy.json
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-policy_${local.name}"
  path        = "/"
  description = "codebuild_policy_${local.name}"
  policy      = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  policy_arn = aws_iam_policy.codebuild_policy.arn
  role       = aws_iam_role.codebuild_role.id
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid = "AllowPushPull"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:TagResource",
      "ecr:UntagResource"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.codebuild_role.arn]
    }
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr_repo.name
  policy     = data.aws_iam_policy_document.ecr_policy.json
}

resource "aws_iam_role" "cloudwatch_events_service_role" {
  name               = "${local.name}_cloudwatch_service_role"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_events_trust_policy.json
}

data "aws_iam_policy_document" "cloudwatch_events_trust_policy" {
  statement {
    sid     = "Trust"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_events_policy" {
  statement {
    actions   = ["codepipeline:Start*"]
    resources = [aws_codepipeline.codepipeline.arn]
  }
}

resource "aws_iam_policy" "cloudwatch_event_policy" {
  name   = "${local.name}_buildenv_image_build_policy"
  policy = data.aws_iam_policy_document.cloudwatch_events_policy.json
}

resource "aws_iam_role_policy_attachment" "managed_events_service" {
  role       = aws_iam_role.cloudwatch_events_service_role.name
  policy_arn = aws_iam_policy.cloudwatch_event_policy.arn
}

data "aws_iam_policy_document" "ecs_task_trust_policy" {
  statement {
    sid     = "Trust"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.name}_ECS_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust_policy.json
}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ECSTask-policy-${local.name}"
  path        = "/"
  description = "ECSTask-policy-${local.name}"
  policy      = data.aws_iam_policy_document.ecs_task_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  policy_arn = aws_iam_policy.ecs_task_policy.arn
  role       = aws_iam_role.ecs_task_role.id
}

resource "aws_iam_role_policy_attachment" "ecs_task_managed_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "codedeploy_trust_policy" {
  statement {
    sid     = "Trust"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name               = "codedeploy_role_${local.name}"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_trust_policy.json
}

data "aws_iam_policy_document" "codedeploy_policy" {
  statement {
    sid    = "iam"
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "iam:GetRole"
    ]
    resources = [aws_iam_role.ecs_task_role.arn]
  }
  statement {
    sid    = "s3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
    ]
  }
  statement {
    sid    = "misc"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:CreateTaskSet",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteTaskSet",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule",
      "lambda:InvokeFunction",
      "cloudwatch:DescribeAlarms",
      "sns:Publish",
      "s3:GetObject",
      "s3:GetObjectMetadata",
      "s3:GetObjectVersion"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  name   = "${local.name}-codedeploy_policy"
  role   = aws_iam_role.codedeploy_role.id
  policy = data.aws_iam_policy_document.codedeploy_policy.json
}

data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    sid     = "Trust"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.name}_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["codedeploy:PutLifecycleEventHookExecutionStatus"]
    resources = ["*"]
  }
  statement {
    sid = "S3"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:HeadObject"
    ]
    resources = [
      aws_s3_bucket.testdata_bucket.arn,
      "${aws_s3_bucket.testdata_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${local.name}-policy-lambda"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.id
}
