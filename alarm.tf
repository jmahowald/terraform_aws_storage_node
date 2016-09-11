variable "disk_threshold" {default = "80"}

resource "aws_cloudwatch_metric_alarm" "disk" {
  count="${var.count}"
  alarm_name = "storage-alarm instance ${count.index}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "DiskSpaceUtilization"
  namespace = "System/Linux"
  period = "60"
  statistic = "Average"
  threshold = "${var.disk_threshold}"
  alarm_description = "This metric monitors disk utilization"
  /*insufficient_data_actions = []*/
  alarm_actions = ["${aws_sns_topic.storage_alarm.arn}"]

  # The disk util tool we use sets the following dimensions
  # (although filesystem + MountPath look redundant for me)
  dimensions {
    Filesystem="/dev/xvda1"
    InstanceId= "${element(aws_instance.storage_node.*.id,count.index)}"
    MountPath="/"
  }
}

resource "aws_sns_topic" "storage_alarm" {
  name = "storage_alarm"
  display_name = "Disk usage exceeds ${var.disk_threshold}"
}

//Useful for putting into an app, or sending email, sms
output "storage_alarm_arn" {
  value = "${aws_sns_topic.storage_alarm.id}"
}
