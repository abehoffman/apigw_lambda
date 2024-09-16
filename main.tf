# Where the zipped packages are stored for retrieval by lambda
resource "aws_s3_bucket" "packages" {
  bucket        = var.packages_bucket
  acl           = "private"
  force_destroy = true
}

# The zip hash of the API package for lambda to unpack and run.
data "aws_s3_bucket_object" "api_zip_hash" {
  bucket = aws_s3_bucket.packages.id
  key    = "${var.package_key}.base64sha256"
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/lambda/${var.api_name}"
  retention_in_days = 90
}

resource "aws_lambda_function" "api" {

  s3_bucket        = aws_s3_bucket.packages.id
  s3_key           = var.package_key
  function_name    = var.api_name
  description      = "Lambda for ${var.api_name}"
  role             = var.api_iam_role_arn
  runtime          = "python3.8"
  source_code_hash = "${data.aws_s3_bucket_object.api_zip_hash.body}"
  handler          = "index.handler"
  timeout          = var.timeout
  memory_size      = 512

  depends_on = [
    aws_cloudwatch_log_group.api_logs,
  ]

  environment {
    variables = var.environment_variables
  }
}

resource "aws_lambda_permission" "api_gateway_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name

  depends_on = [
    aws_lambda_function.api,
  ]
}

resource "aws_api_gateway_resource" "api" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api.id
  http_method             = aws_api_gateway_method.api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}

resource "aws_api_gateway_method_response" "api" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api.id
  http_method             = aws_api_gateway_method.api.http_method
  status_code             = 200

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "api" {
   rest_api_id = aws_api_gateway_rest_api.api.id
   resource_id = aws_api_gateway_resource.api.id
   http_method = aws_api_gateway_method.api.http_method
   status_code = aws_api_gateway_method_response.api.status_code

   response_templates = {
       "application/json" = ""
   }
}

module "api-gateway-enable-cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id   = aws_api_gateway_rest_api.api.id
  api_resource_id   = aws_api_gateway_resource.api.id

  allow_methods = [
    "OPTIONS",
    "POST"
  ]
}

resource "aws_api_gateway_deployment" "api" {

  depends_on = [
    aws_api_gateway_method.api,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "prod"

  triggers = {
    redeployment = md5("main.tf")
  }

  lifecycle {
    create_before_destroy = true
  }
}
