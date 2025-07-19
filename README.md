# Event-Driven Data Processing Pipeline on AWS

This project creates a fully automated, event-driven data processing pipeline on AWS using Terraform and GitHub Actions.

## Project Structure

- **`infrastructure/`**: Contains all Terraform (`.tf`) files to define the AWS infrastructure.
- **`lambda/`**: Holds the Python source code for the AWS Lambda functions.
- **`.github/workflows/`**: Includes the GitHub Actions workflow for continuous integration and deployment.
- **`README.md`**: This documentation file.

## How It Works

1.  **Data Capture**: A file is uploaded to the `uploads/` directory in the raw data S3 bucket.
2.  **Trigger**: The S3 upload event automatically triggers the `data_processor` Lambda function.
3.  **Processing**: The `data_processor` function reads the file's metadata and stores it as a JSON object in a separate reports S3 bucket.
4.  **Automated Reporting**: A daily CloudWatch cron job triggers the `report_generator` Lambda function.
5.  **Summary Generation**: This function analyzes all the metadata files from the previous day and generates a single `.txt` summary report, which is then stored in the reports bucket.

## Deployment

### Prerequisites

1.  An AWS account.
2.  A GitHub repository for this project.
3.  AWS credentials (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) configured as secrets in your GitHub repository.

### Automated Deployment

The entire infrastructure is deployed automatically via the GitHub Actions workflow defined in `.github/workflows/github-actions.yml`. Simply **push a commit to the `main` branch** to trigger the deployment.

The pipeline will:
1.  Initialize Terraform.
2.  Create a Terraform execution plan.
3.  Apply the plan to build or update the resources on AWS.
