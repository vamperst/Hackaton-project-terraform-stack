terraform {
  backend "s3" {
    bucket = "hackathon-fiap-1dvp-12345"
    key    = "state/hackaton-cicd-deploy"
    region = "us-east-1"
  }
}