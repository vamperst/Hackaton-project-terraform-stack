terraform {
  backend "s3" {
    bucket = "hackathon-fiap-2dvp-336387"
    key    = "state/hackaton-cicd-deploy"
    region = "us-east-1"
  }
}