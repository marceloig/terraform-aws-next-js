terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Main region where the resources should be created in
# Should be close to the location of your viewers
provider "aws" {
  region = "us-west-2"
}

# Provider used for creating the Lambda@Edge function which must be deployed
# to us-east-1 region (Should not be changed)
provider "aws" {
  alias  = "global_region"
  region = "us-east-1"
}

module "log_storage" {
  source = "cloudposse/s3-log-storage/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  name                     = "logs"
  stage                    = "test"
  namespace                = "solvimm"
  acl                      = "log-delivery-write"
  standard_transition_days = 30
  glacier_transition_days  = 60
  expiration_days          = 90
}

module "tf_next" {
  # source = "milliHQ/next-js/aws"

  deployment_name = "tf-next-example-complete"

  providers = {
    aws.global_region = aws.global_region
  }

  # Uncomment when using in the cloned monorepo for tf-next development
  source = "../.."
  debug_use_local_packages  = false
  s3_bucket_log_external_id = module.log_storage.bucket_id

  depends_on = [
    module.log_storage
  ]

}

output "cloudfront_domain_name" {
  value = module.tf_next.cloudfront_domain_name
}
