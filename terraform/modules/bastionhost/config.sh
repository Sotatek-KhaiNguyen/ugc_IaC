#!/bin/bash
echo "Copying the SSH Key Of Local Machine to the server"
echo -e ${var.ssh_public_key} >> /home/ubuntu/.ssh/authorized_keys
sudo apt update
sudo apt install unzip -y
    # curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    # unzip awscliv2.zip
    # sudo ./aws/install
    # aws --version
    # aws configure --profile default set region ${var.common.region}
    # aws configure --profile default set aws_access_key_id ${jsondecode(data.aws_secretsmanager_secret_version.ugc_secret_version.secret_string)["key"]}
    # aws configure --profile default set aws_secret_access_key ${jsondecode(data.aws_secretsmanager_secret_version.ugc_secret_version.secret_string)["secret"]}
    # aws configure list