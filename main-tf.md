provider"aws" {

    region="us-east-1"

    access_key="AKIA6N6COK6MBM42LZKG"

    secret_key="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"

}

resource"aws_subnet""subnet-1" {

  vpc_id     =aws_vpc.first-vpc.id

  cidr_block="10.0.1.0/24"

  tags={

    Name = "prod-subnet"

  }

}

resource"aws_vpc""first-vpc" {

  cidr_block="10.0.0.0/16"

  tags={

    Name = "production-vpc"

  }

}


resource"aws_vpc""second-vpc" {

  cidr_block="10.1.0.0/16"

  tags={

    Name = "Dev-vpc"

  }

}

resource"aws_subnet""subnet-2" {

  vpc_id     =aws_vpc.second-vpc.id

  cidr_block="10.1.1.0/24"

  tags={

    Name = "Dev-subnet"

  }

}