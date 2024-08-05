terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "${var.access-key}"
  secret_key = "${var.secret-ley}"
}


resource "aws_lambda_function" "ebs-checker" {

  filename      = "lambda_function.zip"
  function_name = "ebs-checker"
  role          = aws_iam_role.ebs-checker-lambda-role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  environment {
    variables = {
      SNSTOPIC = aws_sns_topic.ebs-sns.arn
    }

  }

}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]


  }
}



resource "aws_iam_role" "ebs-checker-lambda-role" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "ebs"

    policy = jsonencode(

      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "ebsvolume",
            "Effect" : "Allow",
            "Action" : "ec2:DescribeVolumes",
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : "logs:CreateLogGroup",
            "Resource" : "arn:aws:logs:us-east-1:811452661392:*"
          },

          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "arn:aws:logs:us-east-1:811452661392:log-group:ebs-checker:*"
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "sns:Publish"
            ],
            "Resource" : [
              "arn:aws:sns:us-east-1:811452661392:ebs-sns"
            ]
          }

        ]
      }

    )
  }

}

resource "aws_sns_topic" "ebs-sns" {
  name = "ebs-sns"
}