# ------------------------------
# RDS parameter group
# ------------------------------
resource "aws_db_parameter_group" "mysql_standalone_parametergroup" {
  name   = "${var.project}-${var.environment}-mysql-standalone-parametergroup"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# ------------------------------
# RDS option group
# ------------------------------
resource "aws_db_option_group" "mysql_standalone_optiongroup" {
  name                 = "${var.project}-${var.environment}-mysql-standalone-optiongroup"
  engine_name          = "mysql"
  major_engine_version = "8.0"
}

# ------------------------------
# RDS subnet group
# ------------------------------
resource "aws_db_subnet_group" "mysql_standalone_subnetroup" {
  name = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
  subnet_ids = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1c.id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
    project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# RDS instance
# ------------------------------
resource "random_string" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "mysql_standalone" {
  # 基本設定
  engine         = "mysql"
  engine_version = "8.0.28"

  identifier = "${var.project}-${var.environment}-mysql-standalone" # RDSインスタンスのリソース名

  username = "admin"
  password = random_string.db_password.result

  instance_class = "db.t2.micro"

  # ストレージ
  allocated_storage     = 20 # 割り当てるストレージサイズ
  max_allocated_storage = 50 # オートスケールさせる最大ストレージサイズ
  storage_type          = "gp2"
  storage_encrypted     = false

  # ネットワーク
  multi_az               = false
  availability_zone      = "ap-northeast-1a"
  db_subnet_group_name   = aws_db_subnet_group.mysql_standalone_subnetroup.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  port                   = 3306

  # DB設定
  name                 = "tastylog" # データベース名
  parameter_group_name = aws_db_parameter_group.mysql_standalone_parametergroup.name
  option_group_name    = aws_db_option_group.mysql_standalone_optiongroup.name

  # バックアップ
  backup_window              = "04:00-05:00"
  backup_retention_period    = 7
  maintenance_window         = "Mon:05:00-Mon:08:00"
  auto_minor_version_upgrade = false

  # 誤操作防止
  deletion_protection = false
  skip_final_snapshot = true

  apply_immediately = true

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone"
    project = var.project
    Env     = var.environment
  }
}
