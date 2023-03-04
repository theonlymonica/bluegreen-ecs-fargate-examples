resource "aws_codecommit_repository" "repo" {
  repository_name = local.name
  description     = "${local.name} Repository"
  default_branch  = "main"
}

resource "aws_cloudwatch_event_rule" "commit" {
  name        = "${local.name}-capture-commit-event"
  description = "Capture ${local.name} repo commit"

  event_pattern = <<EOF
{
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
   "${aws_codecommit_repository.repo.arn}"
  ],
  "detail": {
    "referenceType": [
      "branch"
    ],
    "referenceName": [
      "main"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "event_target" {
  target_id = "1"
  rule      = aws_cloudwatch_event_rule.commit.name
  arn       = aws_codepipeline.codepipeline.arn
  role_arn  = aws_iam_role.codepipeline_role.arn
}
