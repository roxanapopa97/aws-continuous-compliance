terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-570433319396"
    key    = "terraform/state"
    region = "us-east-1"
  }
}