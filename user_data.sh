#!/bin/bash

# Update system and install required packages
dnf update -y
dnf install -y mariadb105 docker

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Set and export environment variables for current session
export DB_HOST="${DB_HOST}"
export DB_USER="${DB_USER}"
export DB_PASSWORD="${DB_PASSWORD}"
export DB_NAME="${DB_NAME}"

# Persist environment variables for future sessions
echo "DB_HOST=${DB_HOST}" >> /etc/environment
echo "DB_USER=${DB_USER}" >> /etc/environment
echo "DB_PASSWORD=${DB_PASSWORD}" >> /etc/environment
echo "DB_NAME=${DB_NAME}" >> /etc/environment

# Load variables into the current shell session explicitly
source /etc/environment

# Change to the working directory
cd /home/ec2-user/

# Restore the database using the appdb.sql file
mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -h "${DB_HOST}" "${DB_NAME}" < /home/ec2-user/appdb.sql

# Build the Docker image
docker build -t flask-app .

# Run the Docker container with dynamic environment variables
docker run -d -p 80:80 \
  -e DB_HOST="${DB_HOST}" \
  -e DB_USER="${DB_USER}" \
  -e DB_PASSWORD="${DB_PASSWORD}" \
  -e DB_NAME="${DB_NAME}" \
  flask-app
