# ---------------------------------------------
# Certificate
# ---------------------------------------------
# for tokyo region
# 証明書の発行

locals {
  uyu = { for dvo in aws_acm_certificate.tokyo_cert.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    type   = dvo.resource_record_type
    record = dvo.resource_record_value
    }
  }
}

resource "aws_acm_certificate" "tokyo_cert" {
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_route53_zone.route53_zone
  ]
}

# 検証用のCNAMEを作成
# acmに紐づく、このファイル自体を削除した時に、関連づくものが消えるのが綺麗なため、
# route53のリソースだが、acm.tfに作成する
# {
#   "*.uyu-test.xyz" = {
#     "alias" = toset([])
#     "allow_overwrite" = true
#     "failover_routing_policy" = tolist([])
#     "fqdn" = "_a8d5ac78c72f4f5667452b05a9780a29.uyu-test.xyz"
#     "geolocation_routing_policy" = tolist([])
#     "health_check_id" = ""
#     "id" = "Z0579615D5M9XERKC5Z9__a8d5ac78c72f4f5667452b05a9780a29.uyu-test.xyz._CNAME"
#     "latency_routing_policy" = tolist([])
#     "multivalue_answer_routing_policy" = tobool(null)
#     "name" = "_a8d5ac78c72f4f5667452b05a9780a29.uyu-test.xyz"
#     "records" = toset([
#       "_2e2ecb18c7239be3a99865aa9cf8becd.gtlqmkpmvp.acm-validations.aws.",
#     ])
#     "set_identifier" = ""
#     "ttl" = 600
#     "type" = "CNAME"
#     "weighted_routing_policy" = tolist([])
#     "zone_id" = "Z0579615D5M9XERKC5Z9"
#   }
# }
resource "aws_route53_record" "route53_acm_dns_resolve" {
  # オブジェクトの形で展開する
  # for文では以下が出来上がる。(上記のlocal uyuで確認)
  #  "*.uyu-test.xyz" = {
  #    "name" = "_a8d5ac78c72f4f5667452b05a9780a29.uyu-test.xyz."
  #    "record" = "_2e2ecb18c7239be3a99865aa9cf8becd.gtlqmkpmvp.acm-validations.aws."
  #    "type" = "CNAME"
  #  }
  for_each = {
    # for文で、配列をオブジェクトに変換する
    # ドメイン名がキーで、バリューでname,type,recordとなる。
    for dvo in aws_acm_certificate.tokyo_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true # すでに存在する場合、上書きして良いか
  zone_id         = aws_route53_zone.route53_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 600                 # キャッシュ有効期限
  records         = [each.value.record] # ルーティング先
}

# ACM証明書検証
resource "aws_acm_certificate_validation" "cert_valid" {
  # ACM証明書ARN
  certificate_arn = aws_acm_certificate.tokyo_cert.arn
  # DNS検証に利用するFQDN
  # FQDNとは、DNS（Domain Name System）などのホスト名、ドメイン名（サブドメイン名）などすべてを省略せずに指定した記述形式のこと。
  # stringの配列に変換する
  validation_record_fqdns = [for record in aws_route53_record.route53_acm_dns_resolve : record.fqdn]
}

# for virginia region
resource "aws_acm_certificate" "virginia_cert" {
  provider = aws.virginia # プロバイダーを上書き

  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_route53_zone.route53_zone
  ]
}
