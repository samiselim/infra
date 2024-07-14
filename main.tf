resource "aws_key_pair" "deployer" {
  key_name   = "new-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbtxS9Y4DTwVKH+RaF0d57ggR+Q6fsIa20qyeRVHq5obC9xreQJDCESh6OyCslsTcBMrRVbRVKnOFxafc3TXSOr/PSy4cINz/L05/45JD3o/aZgPJO+rGudVno08upI/VJJzMIRdivwTRB9XT988EKUfKisZfZbT9e+YFhk34zYGD5551nkjOHQYB0kXSOLbC/V7IjQEY91ONj1Ecj6gDRXjX0wHPLUI2O587uF1RVlyLWd1fM1BYA4UmSRF0cDsT/vyHDZab4pr0JZpaRbOG/gStD863QMV51yCDuwzD7aDeQ2mUphcR9HmRLfqdzDJ+kb8P0/OPxgL+yzWs8F/bp5au5JNgvyQTk6fur0TutqcKfOjwAmwqptL+xx//tKUIKRfFOoQgiVEIqyE1vpGnoS3mLiSVyrbU3OmfPA3TfF66KkV+cLfMmVs2al+hds77GkRCKsySCTt6SF31AopC2KyN4BFC6YLIP33ykT51vMx4x2Q9QODFZTR26rB3XOnwrnhYID5FymYYglwbzqNZPQjZ9hcGODqsrok7x4yMqukCf0Jg2Q0ZKvleF7vKPJdTqypxuMuq971Rs7vkpXLhpoAxaXKBsnzNu8EDaPiUSYtd/v5fNid1DCPUw8nsvV/PAMP63bXJepPpZN3dp3+70jaPQpcEQdqktPNve1nbZ6w== sami@DESKTOP-KBEBK9P"
}

module "vpc" {
  source                 = "./modules/VPC"
  vpc_cidr               = var.vpc_cidr
  public_subnets_config  = var.public_subnets_config
  private_subnets_config = var.private_subnets_config
  vpc_name               = var.vpc_name
} 

module "sg" {
  source = "./modules/SG"
  sg_config = var.sg_config
  sg_name = "sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_instance" "privateEC2-1" {
  ami             = data.aws_ami.aws_image_latest.id
  instance_type   = "t2.medium"
  subnet_id       = module.vpc.private_subnet_ids[0]
  security_groups = [module.sg.sg_id]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install fontconfig openjdk-17-jre -y
              java -version

              sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
                https://pkg.jenkins.io/debian/jenkins.io-2023.key
              echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
                https://pkg.jenkins.io/debian binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install jenkins -y

              sudo systemctl enable jenkins
              sudo systemctl start jenkins



              # Add Docker's official GPG key:
              sudo apt-get update
              sudo apt-get install ca-certificates curl -y
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc

              # Add the repository to Apt sources:
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update

              sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

              sudo chmod 777 /var/run/docker.sock

              sudo docker volume create --name sonarqube_data
              sudo docker volume create --name sonarqube_logs
              sudo docker volume create --name sonarqube_extensions

              sudo docker run --rm \
                  -p 9000:9000 \
                  -v sonarqube_data:/opt/sonarqube/data \
                  -v sonarqube_extensions:/opt/sonarqube/extensions \
                  -v sonarqube_logs:/opt/sonarqube/logs \
                  sonarqube:lts-community

              EOF
  key_name = "new-key"
  root_block_device {
    volume_size = 100 
    volume_type = "gp2" 
  }
  tags = {
    Name = "Jenkins-SonarQube"
  }
}
resource "aws_instance" "privateEC2-2" {
  ami             = "ami-0062b622072515714"
  instance_type   = "t2.medium"
  subnet_id       = module.vpc.private_subnet_ids[0]
  security_groups = [module.sg.sg_id]
  key_name = "new-key"

  user_data = <<-EOF
        #!/bin/bash
        sudo apt update
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker


        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
        sudo apt update

        sudo apt install kubeadm kubelet kubectl -y
        sudo apt-mark hold kubeadm kubelet kubectl
        sudo swapoff -a

        sudo kubeadm init

        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

        kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    EOF

  root_block_device {
    volume_size = 100 
    volume_type = "gp2" 
  }
  tags = {
    Name = "kubeadm"
  }
}
resource "aws_instance" "publicEC2" {
  ami             = data.aws_ami.aws_image_latest.id
  instance_type   = "t2.micro"
  subnet_id       = module.vpc.public_subnet_ids[0]
  security_groups = [module.sg.sg_id]
  key_name = "new-key"
  
  root_block_device {
    volume_size = 100 
    volume_type = "gp2" 
  }
  tags = {
    Name = "Bastian"
  }
}

module "lb" {
  source = "./modules/ALB"
  vpc_id = module.vpc.vpc_id
  subnets = concat(module.vpc.private_subnet_ids , module.vpc.public_subnet_ids)
  sg = module.sg.sg_id
  instance_id = aws_instance.privateEC2-1.id
}
