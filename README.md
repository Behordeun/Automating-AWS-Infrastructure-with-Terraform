# Automating-AWS-Infrastructure-with-Terraform

This project introduces beginners to ***Cloud Infrastructure Automation: A case study of Amazon Web Service (AWS)***.

**Prerequisites**

1. Terraform installation:

* This can be downloaded [here](https://www.terraform.io/downloads). Choose the correct installation package for your operating system (OS). Choose **amd64** if you run an x64 processor-based computer.
* For windows, create a terraform folder and copy (or cut) the downloaded terraform file into the created folder. This can be achieved from the terminal by running:

  ```
  cd
  mkdir terraform
  cd terraform
  copy <path to the downloaded terraform file/terraform.exe> c:/terraform
  ```
* Navigate to **environment variables** under **system properties** and add **c:/terraform** to your path. Alternatively, this can be achieved from the terminal by running:

  ```
  export PATH=$PATH:~/terraform
  ```

2. Creation of ***AWS account***: You can create a trial account that comes with 300 USD free credit, which is valid for 12 months. This can be done [here](https://portal.aws.amazon.com/billing/signup?refid=ps_a134p000003yhmnaae&trkcampaign=acq_paid_search_brand&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start). Simply fill out the necessary details, and you are good to go with your free tier account.
3. Navigate to ***IAM*** under your ***AWS Console*** and click on ***Key Management***. Create a new key pair, download the IAM key (please keep this secured, as you only get to see the credentials on your AWS console once, except for the downloaded CSV file containing the credentials).
4. Download ***AWS CLI***. See the installation guide [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
5. Download the appropriate version of ***Microsoft Visual Studio Code (VSC)*** for your computer [here](https://code.visualstudio.com/download). Please note that you can use any ***IDE*** of your choice. However, VSC is the most recommended for this project.
6. Create a new file named ***main.tf*** (note that you can use a name of your choice for this file). Specify your service provider in a code block as follows:

   ```
   provider "aws" {
   access_key = "AWS_ACCESS_KEY_ID"
   secret_key = "AWS_ACCESS_SECRET_KEY"
   region = "YOUR_AWS_REGION"
   }
   ```

   Note that the above keys can be found in the CSV file from step 3 above. However, it should be noted that AWS is highly sensitive, and does not overlook credential leakage (expose of sensitive keys and/or details) on public domains such as ***GitHub***.
7. Next, we proceed to create resources in our AWS instance, by automating the process right from our terraform file. This project created 9 resources in our AWS instance right from terraform. These resources are:

   ```
   # 1: Create a Virtual Private Cloud (vpc)

   resource"aws_vpc""prod-vpc" {
     cidr_block="10.0.0.0/16"
     tags={
       Name = "production"
     }
   }
   ```

   **NB:**

* You can change the cidr_block IP to an IP of choice, but you need to ensure that the provided IP is usable.

  ```
  # 2: Create Internet Gateway

  resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.prod-vpc.id

    tags = {
      Name = "internet_gateway"
    }
  }
  ```

```
# 3: Create a Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod Route Table"
  }
}
```

```
# 4: Create a Subnet

resource"aws_subnet""subnet-1" {

  vpc_id     =aws_vpc.prod-vpc.id

  cidr_block="10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags={

    Name = "prod-subnet"

  }

}
```

```
# 5: Associate Subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
```

```
# 6: Create a Security Group to allow ports 22, 80, 443

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "<write as you like>"
  }
  tags = {
    Name = "allow_web_traffic"
  }
}
```

```
# 7: Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]
}
```

```
# 8: Assign an elastic ip to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}
```

```
# 9: Create Ubuntu server and install/enable apache2

resource "aws_instance" "web_server" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name      = "aws-main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web_server_nic.id
     }

     user_data = <<-EOF
                    #!/bin/bash
                    sudo apt update -y
                    sudo apt install apache2 =y
                    sudo systemctl start apache2
                    sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                    EOF
      tags= {
        Name = "web_server"
      }
}
```

**NB:**

<<<<<<< HEAD
1. The above resources are present in the ***main.tf*** file.
2. You should try to avoid setting **cidr_block** to ***0.0.0.0/0***. This allows for connection to the instance from anywhere, and makes it vulnerable. Hence, you should try to use a specific IP address.
=======
    The above resources are present in ***main.tf*** file.
>>>>>>> c79b88b6d0d579746e819babaeecf91352e362b5

For the sake of deployment to a public domain, we shall create additional files such as **variables.tf**, and **terraform.tfvars**

The content of **variables.tf** is given below:

```
#AWS authentication variables
variable "aws_access_key" {
  type = string
  description = "AWS Access Key"
}
variable "aws_secret_key" {
  type = string
  description = "AWS Secret Key"
}
#AWS Region
variable "aws_region" {
  type = string
  description = "AWS Region"
  default = "us-east-1"
}
#Define application environment
variable "app_environment" {
  type = string
  description = "Application Environment"
  default = "prod"
}
```

The content of ***terraform.tfvars***

```
#AWS authentication variables
aws_access_key = "AWS_ACCESS_KEY_ID"
aws_secret_key = "AWS_ACCESS_SECRET_KEY"
```

The above keys can be obtained from [AWS IAM](https://console.aws.amazon.com/iamv2/home#/home)

Note however that your AWS account will be temporarily suspended if you expose your credentials. To prevent this exposure, simply create a __.gitignore__ file and add __*.tfvars__ to the file.

After setting up your workflow, run:

```
# initialize terraform

terraform init
```

```
# Check the resources that will be added to your AWS Infrastructure

terraform plan
```

```
# Apply (create) the resources

terraform apply
```

If you run **terraform apply**, you will get a prompt to type **yes**. If you do not want to get any prompt, run

```
terraform apply -auto-approve
```

Feel free to fork this repo, raise a **pull request** to contribute to this project, and raise an issue if you encounter any challenge.

__About the author:__

Muhammad Abiodun Sulaiman is a graduate of Mathematics and Statistics from the prestigious Federal University of Technology, Minna, Niger State, Nigeria with Second-Class Honors. He is a smart, innovative, and seasoned analytics expert with a track record dating back to his undergraduate days.

Muhammad is a Data Science Fellow with Insight2Impact (i2i) facilities. A Microsoft Recognized Data-scientist which he bagged with an overall performance of 85%.  As a top-performing data enthusiast in the DataHack4FI Innovation Award 2019 season 3, He was awarded a gold badge (Medal). He finished up in the top 3 in the Microsoft Capstone Challenge for Mortgage Loan Approval, a Machine Learning Challenge that Involves predictive modelling. Similarly, he finished up in the top 1% in the Data Science Nigeria 2019 Artificial Intelligence preselection Kaggle Challenge, a Machine Learning Challenge that also Involves predictive modelling.

He also finished up in the top 5 Data Scientists who participated in the Data Science Nigeria 2019 AI Bootcamp pre-selection Kaggle Challenge, which involves the application of Artificial Intelligence to build an algorithmic predictive model for staff promotion.

Muhammad doubles as a Google Africa Developers Scholar and a member of the Facebook Developers Circle (DevC), he bagged in 2019, 2020 and 2021 Andela Learning Community (ALC 4.0) scholarships where he got admitted for the Google Cloud Architecture Engineering tracks consecutively.

 As a passionate self-taught Data-scientist who transitioned from being a Data Analyst, who is enthusiastic about training and helping aspiring data enthusiasts towards honing their analytical skills, He started an online coding class in collaboration with a few friends during his service year in 2019 to help interested people (graduates and nongraduates) learn how to code towards a data related career.

He is an experienced Data Scientist and Business Intelligence Analyst with a demonstrated history of working in the Research industry, extracting actionable insights from massive amounts of data, and with in-depth experience in applying advanced machine learning and data mining methods in analyzing data and in handling multiple business problems across Retail and Technology Domain. Skilled in Machine Learning, Deep Learning, Software Engineering (Backend), Statistical Modeling, Data Visualization with strong presentation and communication skills, Strong Business Development, excellent Critical Thinking and Problem-solving skills and attention to detail.

Muhammad currently works as a Co-Founder and Business Intelligence Analyst at Prince_Analyst Concept. Prior to his current role, he was a Data Scientist and Python Back-end Software Engineer at the Nigerian branch of Rhics UK. Muhammad had worked with different teams of Data Analysts/Scientists and Developers on freelance projects. He is also partnering with other innovative minds to develop solutions to varieties of problems across different sectors, health and finance inclusive.

Muhammad had over the last 4 years mentored over 10 data enthusiasts who are either into Business Analytics or Artificial Intelligence and successfully trained over 15 people on either Data Analysis, Data Science or Business Intelligence.

__Author:__ Muhammad Abiodun Sulaiman

__Email:__ prince.behordeun@gmail.com or abiodun.msulaiman@gmail.com

__LinkedIn:__ [Muhammad Abiodun Sulaiman](https://www.linkedin.com/in/muhammad-abiodun-sulaiman)

__Twitter:__ [@Prince_Analyst](https://www.twitter.com/Prince_Analyst)

__Facebook:__ [Muhammad Abiodun Sulaiman](https://www.facebook.com/muhammad.herbehordeun)

__Tel:__ +234-8108316393

![My Pix.png](https://user-images.githubusercontent.com/45925374/140731559-e56f334c-8e89-48b8-92f7-fbe66a7447d9.png)
