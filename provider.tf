provider "kubernetes" {
    
    host = data.aws_eks_cluster.fp-cluster.endpoint
    token = data.aws_eks_cluster_auth.fp-cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.fp-cluster.certificate_authority.0.data)
}

provider "aws" {
  region = "eu-west-3"
}