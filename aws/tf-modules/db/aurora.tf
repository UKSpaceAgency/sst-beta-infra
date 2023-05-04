resource "aws_db_subnet_group" "default" {
  name = "subnet-group-for-pg"
  subnet_ids = var.db_subnet_ids
}

resource "aws_rds_cluster" "pg-aurora-cluster" {
  cluster_identifier      = "aurora-cluster-for-${var.env_name}"
  #db_subnet_group_name    = var.db_subnet_group_name
  vpc_security_group_ids  = var.vpc_security_group_ids
  engine_mode             = "provisioned"
  master_username         = "postgres"
  master_password         = "postgres"
  database_name           = "mys"
  backup_retention_period = 10
  skip_final_snapshot     = true
  deletion_protection     = false
  engine                  = "aurora-postgresql"
  engine_version          = "14.6"
  apply_immediately       = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  #storage_encrypted = true

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "pg-serverless-instance" {
  cluster_identifier = aws_rds_cluster.pg-aurora-cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.pg-aurora-cluster.engine
  engine_version     = aws_rds_cluster.pg-aurora-cluster.engine_version
}