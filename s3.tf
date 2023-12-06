resource "aws_s3_bucket" "lb_logs" {
  bucket = "ruk-bucket"

  tags = {
    Name        = "ruk-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "version" {
  bucket = aws_s3_bucket.lb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

