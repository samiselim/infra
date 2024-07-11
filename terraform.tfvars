vpc_name     = "vpc1"
vpc_cidr     = "10.0.0.0/16"

public_subnets_config = {
  subnet_count = [1]
  subnet_cidrs = ["10.0.1.0/24"]
  subnet_azs   = ["eu-west-3a"]
}
private_subnets_config = {
  subnet_count = [1]
  subnet_cidrs = ["10.0.3.0/24"]
  subnet_azs   = ["eu-west-3b"]
}
sg_config = {
  ingress_count = [{count = 5}]
  ingress_rule = [{
    port = 443
    protocol = "tcp"
    cidr = "0.0.0.0/0"
  } , 
  { port = 80
    protocol = "tcp"
    cidr = "0.0.0.0/0"
  },
  { port = 22
    protocol = "tcp"
    cidr = "0.0.0.0/0"
  },
  { port = 8080
    protocol = "tcp"
    cidr = "0.0.0.0/0"
  },
  { port = 9000
    protocol = "tcp"
    cidr = "0.0.0.0/0"
  }]
}