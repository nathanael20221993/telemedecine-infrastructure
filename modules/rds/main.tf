resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.environment}-db-subnet-group"
  })
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-rds-sg"
  })
}

# Génération de mot de passe aléatoire sécurisé
resource "random_password" "db_password" {
  count   = var.db_password == "" ? 1 : 0
  length  = 32
  special = true
}

# Stockage sécurisé du mot de passe
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.environment}/telemedecine/db-password"
  type  = "SecureString"
  value = var.db_password != "" ? var.db_password : random_password.db_password[0].result

  tags = merge(var.common_tags, {
    Name = "${var.environment}-db-password"
  })
}

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-telemedecine-db"

  # Engine
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = var.db_instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = aws_ssm_parameter.db_password.value

  # Network
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Availability
  multi_az = var.multi_az

  # Performance Insights
  performance_insights_enabled = var.environment != "dev"
  monitoring_interval         = var.environment == "prod" ? 60 : 0

  # Protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # Logs
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-telemedecine-db"
    DataType    = "medical"
    Compliance  = "rgpd"
  })
}

# Read replicas pour la production
resource "aws_db_instance" "read_replica" {
  count = var.environment == "prod" ? 2 : 0

  identifier = "${var.environment}-telemedecine-db-replica-${count.index + 1}"
  
  replicate_source_db = aws_db_instance.main.id
  instance_class      = "db.t3.medium"
  
  monitoring_interval = 60
  
  tags = merge(var.common_tags, {
    Name = "${var.environment}-telemedecine-db-replica-${count.index + 1}"
    Type = "ReadReplica"
  })
}
