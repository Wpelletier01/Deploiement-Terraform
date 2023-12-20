terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  
  }
}

# Information de connection a aws
provider "aws" {

  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]

}


# Va chercher le nom de l'executeur
resource "terraform_data" "username" {
  
  provisioner "local-exec" {

    command = "echo -n $USER >  ${path.module}/tmp-user.txt"
    
  }
  # enlever le fichier temporaire lors de la destruction
  provisioner "local-exec" {
     
    command = "rm -f ${path.module}/tmp-user.txt"
    when    = destroy

  }
}

# entrepose le nom de l'executeur
data "local_file" "username" {
  
  filename = "${path.module}/tmp-user.txt"
  depends_on = [ terraform_data.username ]
  
}

# Genere la paire de cle ssh
resource "terraform_data" "ssh-gen" {
  depends_on = [ data.local_file.username ]
  provisioner "local-exec" {

    command = "ssh-keygen -f /home/${data.local_file.username.content}/.ssh/tp3 -t rsa -b 2048 -N '' <<< Y"

  }


}

# On va lire le contenu de la cle public ssh generer
data "local_file" "public_key" {
  filename = "/home/${data.local_file.username.content}/.ssh/tp3.pub"
  depends_on = [ terraform_data.ssh-gen ]
  
}
# On va chercher le contenu de la cle prive generer
data "local_file" "private_key" {

  filename = "/home/${data.local_file.username.content}/.ssh/tp3"
  depends_on = [ terraform_data.ssh-gen ]

}

# Ajoute une paire de cle dans aws
resource "aws_key_pair" "ssh-cle-envoi" {

  key_name = var.keypair_name
  public_key = data.local_file.public_key.content
  depends_on = [ data.local_file.public_key ]

}

# Aller chercher votre adresse ip
data "http" "public-ip-executor" {
  url = "http://ipv4.icanhazip.com"
}

# Creer un groupe de securiter
resource "aws_security_group" "mattermost-securiter" {
  
  name = "mattermost-securiter"
  description = "le groupe de securiter pour notre serveur Mattermost"

}

## Creation des regle pour notre groupe de securiter

# accepte connection ssh juste par l'executeur du module terraform
resource "aws_security_group_rule" "ssh" {

  type = "ingress"
  security_group_id = aws_security_group.mattermost-securiter.id 
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0"]
  depends_on = [ data.http.public-ip-executor ]

}

# accepte tous les connection HTTP
resource "aws_security_group_rule" "http" {

  type = "ingress"
  security_group_id = aws_security_group.mattermost-securiter.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0"]

}

# accepte tous les connection HTTPS
resource "aws_security_group_rule" "https" {

  type = "ingress"
  security_group_id = aws_security_group.mattermost-securiter.id
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0"]

}

# permettre au serveur de se connecter a internet
resource "aws_security_group_rule" "all" {

  type = "egress"
  security_group_id = aws_security_group.mattermost-securiter.id
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

}


# va chercher le ami le plus recent de Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true 

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64*"]
  }

  # Pour la virtualisation complete 
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.canonical-owner]

}


# Creer une instance dans aws
resource "aws_instance" "serveur-mattermost" {
    
  key_name = var.keypair_name
  vpc_security_group_ids = [aws_security_group.mattermost-securiter.id]
  instance_type = "t2.small"
  ami = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  tags = {
    Name = "Serveur MatterMost"
  }




  provisioner "remote-exec" {

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = data.local_file.private_key.content
      host = self.public_ip
  
    }


    inline = [ 
      "sudo useradd -m -s /bin/bash -G sudo ${data.local_file.username.content}",
      "sudo passwd -d ${data.local_file.username.content}",
      "sudo mkdir /home/${data.local_file.username.content}/.ssh",
      "sudo cp ~/.ssh/authorized_keys /home/${data.local_file.username.content}/.ssh/",
      "sudo chown -R ${data.local_file.username.content}:${data.local_file.username.content} /home/${data.local_file.username.content}/.ssh",
      "sudo mkdir -p /home/${data.local_file.username.content}/script/exec",
      "sudo mkdir -p /home/${data.local_file.username.content}/script/config",
      "sudo chown -R ${data.local_file.username.content}:${data.local_file.username.content} /home/${data.local_file.username.content}/script"
    ]
    
  }

  connection {
    type = "ssh"
    user = data.local_file.username.content
    private_key = data.local_file.private_key.content
    host = self.public_ip
  
  }

  provisioner "file" {


    source = "${path.module}/script/exec/mattermost-db.sh"
    destination = "/home/${data.local_file.username.content}/script/exec/mattermost-db.sh"   
  }

  provisioner "file" {


    source = "${path.module}/script/exec/mysql_secure.sh"
    destination = "/home/${data.local_file.username.content}/script/exec/mysql_secure.sh"    
  }

  provisioner "file" {
    source = "${path.module}/script/exec/mattermost-install.sh"
    destination = "/home/${data.local_file.username.content}/script/exec/mattermost-install.sh"    
  }

  provisioner "file" {


    source = "${path.module}/script/exec/update-domain-ip.sh"
    destination = "/home/${data.local_file.username.content}/script/exec/update-domain-ip.sh"    
  }
  
  provisioner "file" {

    source = "${path.module}/script/config/mattermost.service"
    destination = "/home/${data.local_file.username.content}/script/config/mattermost.service"   
  }

  provisioner "file" {

    source = "${path.module}/script/config/nginx-base.conf"
    destination = "/home/${data.local_file.username.content}/script/config/nginx-base.conf"   
  }


  provisioner "remote-exec" {


    
    inline = [  
      "sudo chmod +x -R script/exec",
      "sudo script/exec/mattermost-install.sh ${var.DOMAIN}  ${var.NOIP_USER} ${var.NOIP_PASSWD}"
    ]

  }


}





