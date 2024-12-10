# Generate an SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the Private Key Locally as a .pem File
resource "local_file" "private_key" {
  filename = "${path.module}/my-ssh-key.pem"
  content  = tls_private_key.ssh_key.private_key_pem
  file_permission = "0400" # Set strict file permissions for the private key
}

# Save the Public Key to AWS
resource "aws_key_pair" "ssh_key" {
  key_name   = "my-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Create VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat" {
  tags = {
    Name = "NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "NAT Gateway"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}


# Security Groups
# App Security Group
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow inbound traffic for the app"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from the internet
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from the internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB Security Group
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow inbound traffic for the database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app_sg.id] # Allow MySQL traffic only from the app security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-04b54ebf295fe01d7" # Amazon Linux 2 AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.app_sg.id]
  key_name      = aws_key_pair.ssh_key.key_name

  user_data = templatefile("${path.module}/user_data.sh", {
    DB_HOST     = "${aws_db_instance.app_db.address}",
    DB_USER     = "${aws_db_instance.app_db.username}",
    DB_PASSWORD = "${aws_db_instance.app_db.password}",
    DB_NAME     = "appdb"
  })

  # Provisioning files to the instance
  provisioner "file" {
    source      = "${path.module}/src/appdb.sql"  # Local path to the SQL file
    destination = "/home/ec2-user/appdb.sql"
  }

  provisioner "file" {
    source      = "${path.module}/src/app.py"  # Local path to the Flask app
    destination = "/home/ec2-user/app.py"
  }

  provisioner "file" {
    source      = "${path.module}/src/Dockerfile"  # Local path to the Dockerfile
    destination = "/home/ec2-user/Dockerfile"
  }

  # SSH connection configuration for provisioners
  connection {
    type        = "ssh"
    user        = "ec2-user"                             # Default user for Amazon Linux
    private_key = file("${path.module}/my-ssh-key.pem")  # Path to your private key file
    host        = self.public_ip                        # Use the instance's public IP
  }

  depends_on = [aws_db_instance.app_db]
}


# Database Instance
resource "aws_db_instance" "app_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  publicly_accessible    = false
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  tags = {
    Name = "MyAppDatabase"
  }
}


# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "RDS Subnet Group"
  }
}
resource "aws_route_table_association" "private_rt_assoc_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}
