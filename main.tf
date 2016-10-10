
# We have a bootstrap

variable "aws_region"{}
variable "subnet_id" {}

//These are tag conventions that I find useful
variable "environment" {}
variable "owner" {}

//We'll need to log onto the instance
variable "key_name" {}
variable "ssh_keypath"{}

variable "user_data" {default = ""}

// TODO we are making assumptions that this is a Amazon
// linux ami, thus we should look up ourselves, not have it passed in

variable "count"{default =  "1"}

variable "node_name_base"{ default="storage-node-"}
variable "role_name"{default="storage"}

variable "security_group_ids" {type = "list"}
variable "instance_type" {default = "t2.micro"}
variable "volume_size_gb" { default = "20"}
variable "volume_type" { default = "gp2"}
variable "metric_interval" {default = "1"}

//Extremely likely to change this format in the future
variable "backup_and_retention" {default = "hourly;30d"}

output "storage_ips" {
  value = ["${aws_instance.storage_node.*.private_ip}"]
}

data "template_file" "crontab" {
    template = <<CRON
*/${metric_interval} * * * * /usr/local/bin/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=${storage_dir} --from-cron
CRON
  vars {
    metric_interval = "${var.metric_interval}"
    storage_dir = "${var.storage_dir}"
  }
}

module "amazon_ami" {
  source = "github.com/jmahowald/tf_aws_ami"
  region = "${var.aws_region}"
}

resource "aws_instance" "storage_node" {
  user_data = "${var.user_data}"
  ami = "${module.amazon_ami.ami_id}"

  subnet_id = "${var.subnet_id}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  count = "${var.count}"
  vpc_security_group_ids = ["${var.security_group_ids}"]

  # hmm, thought this flag would turn on policies but they don't
  monitoring=true
  iam_instance_profile = "${aws_iam_instance_profile.storage_role_policy.id}"

  tags {
    Name = "${var.node_name_base}${count.index}"
    Owner = "${var.owner}"
    Environment = "${var.environment}"
    Role = "${var.role_name}"
    Backups = "${var.backup_and_retention}"
  }

  connection {
    user =  "ec2-user"
    key_file = "${var.ssh_keypath}"
  }

  provisioner "remote-exec" {
    # From http://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/mon-scripts.html
    inline = [
      "sudo yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https",
      "curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O",
      "unzip CloudWatchMonitoringScripts-1.2.1.zip",
      "rm CloudWatchMonitoringScripts-1.2.1.zip",
      "sudo mv aws-scripts-mon /usr/local/bin",
      "cat << 'CRONTAB' > mon.cron",
      "${data.template_file.crontab.rendered}",
      "CRONTAB",
      "crontab mon.cron",
    ]
  }

}
