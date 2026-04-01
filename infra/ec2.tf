resource "aws_instance" "servidor" {
  ami           = var.ami_id
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/user_data.sh", {
    ECR_REGISTRY = split("/", aws_ecr_repository.app_repo.repository_url)[0]
  })

  vpc_security_group_ids = [aws_security_group.bia-dev.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }
}