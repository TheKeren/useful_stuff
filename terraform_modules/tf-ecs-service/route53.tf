data "aws_route53_zone" "keren-elb-zone" {
  count    = "${local.alb_enabled}"
  provider = "aws.keren.us-east-1"
  name     = "${var.route53_zone_name}"
}

resource "aws_route53_record" "app-alb-frontend" {
  count    = "${local.alb_enabled}"
  provider = "aws.keren.us-east-1"
  zone_id  = "${data.aws_route53_zone.keren-elb-zone.zone_id}"
  name     = "${local.branded_app_name}.${data.aws_route53_zone.keren-elb-zone.name}"
  type     = "CNAME"
  ttl      = 60
  records  = ["${aws_lb.front-end.dns_name}"]
}
