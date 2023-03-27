# ---------------------------------------------
# Route53
# ---------------------------------------------
# ホストゾーン
resource "aws_route53_zone" "route53_zone" {
  name          = var.domain
  force_destroy = true # 削除時にレコードを削除して良いか

  tags = {
    Name    = "${var.project}-${var.environment}-domain"
    project = var.project
    Env     = var.environment
  }
}

# レコード
resource "aws_route53_record" "route53_record" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "dev-elb.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
