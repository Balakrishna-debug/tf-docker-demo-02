# Terraform Deployment: Reverse IP Flask App

This guide explains how to deploy a Reverse IP Flask App using Terraform. The app reverses client IPs and stores them in an AWS RDS MySQL database. The code and required files are organized in the `src` folder.

## Prerequisites

1. AWS account with permissions to create resources.
2. Terraform installed on your local machine.
3. A key pair for EC2 access.
4. Docker installed locally for testing the container.

## Project Structure

```
project-folder/
├── src/
│   ├── app.py            # Flask application code
│   ├── appdb.sql         # SQL script for creating the table
│   ├── Dockerfile        # Dockerfile for Flask app
├── main.tf              # Terraform configuration
├── variables.tf         # Terraform variables
├── outputs.tf           # Terraform outputs
├── user_data.sh         # EC2 bootstrap script
├── provider.tf          # AWS provider configuration
└── README.md            # Project documentation
```

## Steps to Deploy

### 1. Clone the Repository

```bash
git clone <repository-url>
cd project-folder
```

### 2. Update Terraform Variables

Edit `variables.tf` to provide your desired values for VPC, RDS, and EC2 configurations. Example:

```hcl
variable "region" {
  default = "us-east-1"
}

variable "db_username" {
  description = "RDS MySQL username"
}

variable "db_password" {
  description = "RDS MySQL password"
}
```

During `terraform apply`, you will be prompted to enter values for `db_username` and `db_password` if they are not set in a `terraform.tfvars` file.

### 3. Initialize Terraform

Run the following command to initialize Terraform:

```bash
terraform init
```

### 4. Validate and Apply Terraform Configuration

To validate the configuration:

```bash
terraform validate
```

To apply the configuration:

```bash
terraform apply
```

You will be prompted to provide values for `db_username` and `db_password` or they can be passed as environment variables:

```bash
TF_VAR_db_username=admin 
TF_VAR_db_password=securepassword
terraform apply
```

Provide `yes` when prompted to create the resources.

### 5. Verify Deployment

1. SSH into the EC2 instance using the public IP and your key pair:
   ```bash
   ssh -i my-key.pem ec2-user@<ec2-public-ip>
   ```

2. Check that the Docker container is running:
   ```bash
   docker ps
   ```

3. Test the Flask app:
   ```bash
   curl http://<ec2-public-ip>
   ```

The app should respond with a reversed IP.

### 6. Clean Up Resources

To destroy the resources and avoid incurring costs:

```bash
terraform destroy
```

## How It Works

1. **Terraform** provisions the infrastructure:
   - A VPC with public and private subnets.
   - An EC2 instance to host the Flask app.
   - An RDS MySQL database for storing reversed IPs.

2. **User Data Script** installs Docker, builds the app image, and runs the container.

3. **Flask App** processes client IPs and stores them in the database.

4. **Docker** ensures the app runs in a consistent environment.

## Database Schema

The `appdb.sql` file in the `src` folder contains the SQL script to create the `ip_logs` table:

```sql
CREATE TABLE ip_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(45),
    reversed_ip VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
