variable "bucket_name" {
  type = string
}

variable "ami_id" {}
variable "instance_type" {
  default = "t3.micro"
}
variable "volume_size" {
  default = 15
}
