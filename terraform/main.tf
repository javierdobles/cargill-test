
#
# We use this to try and catch AWS resources that haven't had their provider
# explicitly set.
#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.63.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
}
}

provider "null" {
  # Configuration options
}

provider "aws" {
  alias   = "atlantic"
  region  = "us-east-1"
  access_key = "access-here"
  secret_key = "secret-here"
}


provider "random" {}
provider "template" {}


