# AWS Event-Driven Data Pipeline

## 📦 Structure
- `infrastructure/` – Terraform code for AWS setup
- `lambda/` – Python Lambda functions
- `ci-cd/` – GitHub Actions config

## 🚀 How to Deploy
1. Clone the repo
2. Configure AWS credentials locally
3. Run `terraform init` and `terraform apply`
4. Push code to `main` to trigger GitHub Actions

## 🔁 How It Works
- New data → S3 or EventBridge → Lambda processes → Report generated daily → Saved to S3

## 🛠 Requirements
- Terraform v1.x
- Python 3.9+
- AWS CLI configured
