module "ecr" {
  source = "../../tf-modules/ecr"
}

#extra for dev env
resource "aws_ecr_repository" "frontend2" {
  name = "frontend2"
}