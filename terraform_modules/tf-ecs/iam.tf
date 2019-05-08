locals {
  brand_log_group = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/coty/platform/${var.brand}/*"
}

resource "aws_iam_instance_profile" "ecs-admin" {
  name = "${local.full_name}-ecs-admin"
  role = "${aws_iam_role.ecs-admin.name}"
}

resource "aws_iam_role" "ecs-admin" {
  name               = "${local.full_name}-ecs-admin"
  assume_role_policy = "${data.aws_iam_policy_document.ec2-sts.json}"
}

resource "aws_iam_policy_attachment" "ecs-admin" {
  name       = "${local.full_name}-ecs-admin"
  policy_arn = "${aws_iam_policy.ecs-admin.arn}"

  roles = [
    "${aws_iam_role.ecs-admin.name}",
  ]
}

resource "aws_iam_policy" "ecs-admin" {
  name   = "${local.full_name}-ecs-admin"
  policy = "${data.aws_iam_policy_document.ecs-admin.json}"
}

data "aws_iam_policy_document" "ecs-admin" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:DeregisterContainerInstance",
      "ecs:RegisterContainerInstance",
      "ecs:Submit*",
      "ecs:DescribeClusters",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${concat(
        list(
          "${aws_ecs_cluster.ecs-cluster.id}",
          "${aws_ecs_cluster.ecs-cluster.id}/*",
          "${local.brand_log_group}"
      ))}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:CreateCluster",
      "ecs:Poll",
      "ecs:StartTelemetrySession",
      "ecs:DescribeContainerInstances",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:UpdateContainerAgent",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:RunTask",
    ]

    resources = [
      "*",
    ]

    condition {
      test = "ArnEquals"

      values = [
        "${aws_ecs_cluster.ecs-cluster.id}",
      ]

      variable = "ecs:cluster"
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:DiscoverPollEndpoint",
      "ecs:ListClusters",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken",
      "ecr:Describe*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:*",
    ]

    resources = [
      "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*${var.brand}*",
    ]
  }
}

data "aws_iam_policy_document" "ec2-sts" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      identifiers = [
        "ec2.amazonaws.com",
      ]

      type = "Service"
    }
  }
}
