# API Gateway + Lambda

A terraform module to provision API infrastructure using API Gateway and Lambda.

## Usage

```hcl
# A basic IAM role
resource "aws_iam_role" "api_execution" {
  name = "${var.api_name}_api_execution"

  assume_role_policy = jsonencode(assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": [
              "apigateway.amazonaws.com",
              "lambda.amazonaws.com"
            ]
          },
          "Effect": "Allow"
        }
      ]
    }
  )
}

# A basic policy that enables logging
resource "aws_iam_role_policy" "api_execution" {
  name = "${var.api_name}_api_execution"
  role = aws_iam_role.api_execution.id

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": [
            "arn:aws:logs:*:*:*"
          ]
        }
      ]
    }
  )
}

module "api" {
  source = "git@github.com:abehoffman/apigw_lambda.git"

  # the name of the api
  api_name = <api_name>

  # the Amazon Resource Name (arn) of the execution role
  api_iam_role_arn = <aws_iam_role.api_execution.arn>

  # The s3 bucket the package is stored in for retrieval by lambda
  packages_bucket = <packages_bucket>

  # The key of the package
  package_key = <package_key>

  # The timeout of the lambda (OPTIONAL)
  timeout = <timeout>

  # The environment variables for the lambda (OPTIONAL)
  environment_variables = {
    <variable> = <value>
  }

  # The runtime for the lambda (OPTIONAL)
  runtime = <runtime>
}
```

This will create an API Gateway instance that invokes the lambda function running your package code. It also, by default provides logging infrastructure. Under the hood, it uses [terraform-aws-api-gateway-enable-cors](https://github.com/squidfunk/terraform-aws-api-gateway-enable-cors) to provide CORS.

## Configuration

`api_name`: the name of the api (will be the name used by AWS to describe the infrastructure)

`api_iam_role_arn`: the Amazon Resource Name (arn) of the associated IAM role. At a minimum, this role needs to allow the invocation of API Gateway and Lambda AWS services as seen above.

`packages_bucket`: The name of the s3 bucket the package is stored in for retrieval by lambda.

`package_key`: The key of the package to be retrieved by Lambda.

## Outputs

`invoke_url`: the API gateway invoke url
