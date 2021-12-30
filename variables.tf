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
