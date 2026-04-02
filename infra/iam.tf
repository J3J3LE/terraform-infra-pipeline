##############################################
# IAM ROLE - EC2 / SSM / ECS
##############################################

resource "aws_iam_role" "ssm_role" {
  name = "role-acesso-ssm-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = [
          "ec2.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      }
    }]
  })

  tags = {
    Name        = "role-acesso-ssm-${var.environment}"
    Environment = var.environment
  }
}

##############################################
# POLICY ATTACHMENTS (AWS MANAGED)
##############################################

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_full" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_full" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "rds_full" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

##############################################
# POLICY CUSTOM (SECRETS MANAGER)
##############################################

resource "aws_iam_role_policy" "secrets_policy" {
  name = "allow-secrets-manager-${var.environment}"
  role = aws_iam_role.ssm_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = "*"
    }]
  })
}

##############################################
# INSTANCE PROFILE (EC2)
##############################################

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "projeto-ssm-profile-${var.environment}"
  role = aws_iam_role.ssm_role.name
}