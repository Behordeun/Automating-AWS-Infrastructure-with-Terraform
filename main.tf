provider "aws" {
    region = "us-east-1"
    access_key="AKIA6N6COK6MBM42LZKG"
    secret_key="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"
}

#references
resource "aws_instance" "my-first-server" {
    ami = "ami-04505e74c0741db8d"
    instance_type = "t2.micro"
    tags = {
         name = "ubuntu"
    }
}