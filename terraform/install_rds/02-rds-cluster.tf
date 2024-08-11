resource "aws_db_instance" "book-coupon" {
  identifier                            = "database-1"
  allocated_storage                     = 20
  storage_type                          = "gp2"
  engine                                = "postgres"
  engine_version                        = "15.4" # Actualiza según tu versión de PostgreSQL
  instance_class                        = "db.t3.micro"
  username                              = var.user
  password                              = var.pass
  skip_final_snapshot                   = true
  vpc_security_group_ids                = [ aws_security_group.rds-sg.id ]
  multi_az                              = false
  publicly_accessible                   = true
  deletion_protection                   = false
  enabled_cloudwatch_logs_exports       = []
  iam_database_authentication_enabled   = false
  storage_encrypted                     = true
  storage_throughput                    = 0
  max_allocated_storage                 = 1000
  parameter_group_name                  = "default.postgres15"
  copy_tags_to_snapshot                 = true
  performance_insights_enabled          = true
  apply_immediately                     = true
  db_subnet_group_name                  = var.db_subnet_group_name
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "default VPC security group"
  vpc_id      = var.default_vpc

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "PostgreSQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}