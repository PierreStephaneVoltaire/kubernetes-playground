

resource "aws_security_group" "cluster_sg" {
  name        = "allow_all"
  description = "Allow traffic to eks cluster"
  vpc_id      = module.vpc.vpc_id
}


resource "aws_security_group_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.cluster_sg.id
  cidr_blocks       = var.allowed_ips
  protocol          = "-1"
  to_port           = 0
  from_port         = 0
  type              = "ingress"
}
resource "aws_security_group_rule" "allow_all" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.cluster_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


