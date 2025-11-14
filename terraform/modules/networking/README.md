# Networking Module

Creates a complete VPC with public and private subnets, NAT gateways, and optional VPC flow logs.

## Features

- VPC with customizable CIDR
- Public and private subnets across multiple AZs
- Internet Gateway for public subnet internet access
- NAT Gateways for private subnet internet access (optional)
- VPC Flow Logs (optional)
- Proper routing tables and associations

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  name_prefix        = "myapp-dev"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  enable_nat_gateway = true
  enable_flow_logs   = true

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| vpc_cidr | CIDR block for VPC | string | "10.0.0.0/16" | no |
| availability_zones | List of availability zones | list(string) | - | yes |
| enable_nat_gateway | Enable NAT Gateway | bool | true | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | false | no |
| flow_logs_retention_days | Flow logs retention in days | number | 7 | no |
| tags | Tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | IDs of public subnets |
| private_subnet_ids | IDs of private subnets |
| nat_gateway_ids | IDs of NAT Gateways |
| public_route_table_id | ID of public route table |
| private_route_table_ids | IDs of private route tables |
| internet_gateway_id | ID of Internet Gateway |
