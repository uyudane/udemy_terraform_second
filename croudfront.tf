# ---------------------------------------------
# CloudFront cache distribution
# ---------------------------------------------

# ディストリビューション
resource "aws_cloudfront_distribution" "cf" {
  # ---------------------------------------------
  # 基本設定
  # ---------------------------------------------
  enabled         = true # 有効か
  is_ipv6_enabled = true
  comment         = "cache distribution"

  # 料金クラスは、Amazon CloudFront からコンテンツを配信する際に支払う料金を低減するためのオプションとなります。
  # https://aws.amazon.com/jp/cloudfront/pricing/
  # https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  price_class     = "PriceClass_All" # 基本、これでいいらしい

  # ---------------------------------------------
  # オリジン
  # ---------------------------------------------
  # ALB用
  origin {
    domain_name = aws_route53_record.route53_record.fqdn
    origin_id   = aws_lb.alb.name # ビヘイビアから参照される、オリジンを識別するユニークな名前

    custom_origin_config {
      origin_protocol_policy = "match-viewer" # http-only, https-only
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      http_port              = 80
      https_port             = 443
    }
  }

  # S3用
  origin {
    domain_name = aws_s3_bucket.s3_static_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.s3_static_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_s3_origin_access_identity.cloudfront_access_identity_path
    }
  }

  # ---------------------------------------------
  # ビヘイビア
  # ---------------------------------------------
  # どういうURLを受け付けて、どこに振り分けるのかを決める
  default_cache_behavior {
    # defaultでは、パスパターンは不要
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true # HTTPポート番号 # headersはHTTPSポート番号
      cookies {
        forward = "all"
      }
    }

    target_origin_id       = aws_lb.alb.name
    viewer_protocol_policy = "redirect-to-https"
    # ELB側はキャッシュしない！
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  ordered_cache_behavior {
    # パスパターン
    path_pattern     = "/public/*"
    # 許可するメソッド
    allowed_methods  = ["GET", "HEAD"]
    # キャッシュするメソッド
    cached_methods   = ["GET", "HEAD"]
    # 転送先のオリジンID
    target_origin_id = aws_s3_bucket.s3_static_bucket.id

    # 転送するリクエストデータ
    forwarded_values {
      query_string = false
      headers      = []

      cookies {
        forward = "none" # forward* = "all,none,whitelist"
      }
    }

    # 最小キャッシュ期間
    min_ttl                = 0
    # デフォルトキャッシュ期間
    default_ttl            = 86400 # 1日
    # 最大キャッシュ期間
    max_ttl                = 31536000 # 1年
    # 圧縮するか
    compress               = true
    viewer_protocol_policy = "redirect-to-https" # allow-all, https-only, redirect-to-https
  }

  # ---------------------------------------------
  # アクセス制限
  # ---------------------------------------------
  restrictions {
    # どこの国からといった地域ごとのアクセス制限をかけることができる
    geo_restriction {
      restriction_type = "none"
    }
  }
  # ドメイン名でアクセスする時に、どんな名前でアクセスするかを設定。
  # Route53でも設定する必要あり
  aliases = ["dev.${var.domain}"] # ドメイン名でアクセスする時に、どんな名前でアクセスするかを設定。

  # ---------------------------------------------
  # 証明書
  # ---------------------------------------------
  viewer_certificate {
    # cloudfront_default_certificate = true
    acm_certificate_arn      = aws_acm_certificate.virginia_cert.arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method       = "sni-only"
  }
}

# S3にアクセスする際に、クラウドフロントがどういったユーザとしてアクセスするかを定義する
resource "aws_cloudfront_origin_access_identity" "cf_s3_origin_access_identity" {
  comment = "S3 static bucket access identity"
}

resource "aws_route53_record" "route53_cloudfront" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "dev.${var.domain}"
  type    = "A"

  # クラウドフロントに転送する
  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = true
  }
}
