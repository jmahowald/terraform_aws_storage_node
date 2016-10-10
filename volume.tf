
variable "storage_dir" {default = "/var/data"}
variable "aws_availability_zone" {}
variable "image_user" {default = "ec2-user"}
variable "force_detach" {default = "false"}
resource "aws_volume_attachment" "default" {
  force_detach = "${var.force_detach}"
  device_name = "/dev/sdb"
  count = "${var.count}"
  volume_id = "${element(aws_ebs_volume.data.*.id,count.index)}"
  instance_id = "${element(aws_instance.storage_node.*.id, count.index)}"
}

resource "aws_ebs_volume" "data" {
  availability_zone = "${var.aws_availability_zone}"
  size = "${var.volume_size_gb}"
  type = "${var.volume_type}"
  count = "${var.count}"
  tags = {
   Name = "storage-vol-${count.index}"
   Owner = "${var.owner}"
 }
}


resource "null_resource" "attach" {
  count = "${var.count}"
  triggers  {
    volume_id = "${element(aws_ebs_volume.data.*.id,count.index)}"
    instance_id = "${element(aws_instance.storage_node.*.id,count.index)}"
    device_name = "${element(aws_volume_attachment.default.*.device_name, count.index)}"
  }

  connection {
    host = "${element(aws_instance.storage_node.*.private_ip, count.index)}"
    user =  "${var.image_user}"
    agent = "false"
    key_file = "${var.ssh_keypath}"
  }

  provisioner "remote-exec" {
    inline = [
    #No idea why I can't specify /xvdb for instance_type
    #but specify /dev/sdb gets renamed
    #it's a kernel level thing
    #http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html
    #Ideally I could use variable interpolation

    #If you are making a brand new non snapshotted volume then
    #you need to run mkfs.  Don't run that if you are using a snapshot
      "sudo mkfs -t ext4  /dev/xvdb",
      "sudo mkdir ${var.storage_dir}",
      "sudo mount /dev/xvdb ${var.storage_dir}"
    ]
  }
}
