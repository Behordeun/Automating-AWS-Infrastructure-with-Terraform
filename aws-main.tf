# 
# resource "aws_instance" "First_EC2" {
#   ami           = data.aws_ami.amazon_linux.id
#   instance_type = "t2.micro"
#   tags = {
#     Name = var.app_environment
#   }
# }
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   filter {
#     name = "name"
#     values = [
#       "amzn-ami-hvm-*-x86_64-gp2",
#     ]
#   }
#   filter {
#     name = "owner-alias"
#     values = [
#       "amazon",
#     ]
#   }
#    owners      = ["amazon"]
# }