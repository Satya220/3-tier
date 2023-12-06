# data "aws_subnet" "public" {
#   filter {
#     name   = "tag:Name"
#     values = ["pub"]
#   }
# }

# data "aws_subnet" "public_2" {
#   filter {
#     name   = "tag:Name"
#     values = ["pub_2"]
#   }
# }

data "aws_ami" "example" {
  most_recent      = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}