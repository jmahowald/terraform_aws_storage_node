# Autoscaling lifecycle hook role
# Allows lifecycle hooks to add messages to the SQS queue
resource "aws_iam_role" "storage_metrics_role" {

    name = "${var.role_name}-storage-metrics"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "storage_role_policy" {
  name = "${var.role_name}-iam-policy"
  role = "${aws_iam_role.storage_metrics_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:PutMetricData",
                "cloudwatch:SetAlarmState"
            ],
            "Resource": [
              "*"
            ]
        }
    ]
}
EOF

}

# Attach role to storage nodes because
# for some insane reason, disk utilization isn't
# a built in cloud watch metric
resource "aws_iam_instance_profile" "storage_role_policy" {
  name = "${var.role_name}-storage-metrics-policy"
  roles = ["${aws_iam_role.storage_metrics_role.id}"]
}
