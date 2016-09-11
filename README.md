This terraform module aids in the creation of
storage nodes.  If I were able to get a good
docker volume plugin going it might not have existed.

As it stands, while you should use auto scaling groups
for docker clusters (or any) you still sometimes want
to pin data to a disk, and are willing to sacrifice
some availability for simplicity. i.e. your database always
lives on storage-node-0

This project puts in place best practices for that. It creates the necessary policies and installs the recommended utilities
to monitor disk usage.  It has tags that can allow separate processes to do backups with retention policies -e.g. [Serverless EC2 Snapshots](https://serverlesscode.com/post/lambda-schedule-ebs-snapshot-backups/)
