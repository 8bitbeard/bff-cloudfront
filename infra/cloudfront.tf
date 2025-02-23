resource "aws_cloudfront_distribution" "api_gateway_cf" {
  origin {
    domain_name = "default-origin"
    origin_id   = "default-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  dynamic "origin" {
    for_each = local.api_configs

    content {
      domain_name = origin.value.domain
      origin_id   = "${origin.value.api_name}-origin"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.route_configs

    content {
      target_origin_id = ordered_cache_behavior.value.api_name

      path_pattern           = "${ordered_cache_behavior.value.context_path}/${ordered_cache_behavior.value.path_pattern}"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      forwarded_values {
        query_string = true
        headers      = ["*"]

        cookies {
          forward = "none"
        }
      }

      min_ttl     = ordered_cache_behavior.value.cache_duration
      default_ttl = ordered_cache_behavior.value.cache_duration
      max_ttl     = ordered_cache_behavior.value.cache_duration
    }
  }

  # Default behavior para fallback (sem cache)
  dynamic "ordered_cache_behavior" {
    for_each = [for api in local.api_configs : api]

    content {
      target_origin_id = ordered_cache_behavior.value.api_name

      path_pattern           = "${ordered_cache_behavior.value.context_path}/*"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      forwarded_values {
        query_string = true
        headers      = ["*"]

        cookies {
          forward = "none"
        }
      }

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0
    }
  }

  # Default behavior (sem cache)
  default_cache_behavior {
    target_origin_id = "default-origin"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"] # Apenas GET e HEAD são armazenados em cache

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for API BFF"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:123456789012:certificate/abcd-1234-efgh-5678"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

