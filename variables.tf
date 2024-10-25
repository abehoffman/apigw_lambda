variable "api_name" {
  type = string
  description = "The name of the api."
}

variable "api_iam_role_arn" {
  type = string
  description = "The IAM role arn for the lambda."
}

variable "package_key" {
  type = string
  description = "The key to store the API package for retrieval by lambda."
}

variable "packages_bucket" {
  type = string
  description = "The bucket to store the packages in."
}

variable "timeout" {
  type = number
  description = "The timeout for the lambda."
  default = 30
}

variable "environment_variables" {
  type = map(string)
  description = "The environment variables for the lambda function."
  default = {}
}

variable "runtime" {
  type = string
  description = "The runtime for the lambda funciton."

  default = "python3.8"
}
