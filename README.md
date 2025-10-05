# Apollo GraphOS Router as Cloud Run Service

## 📖 Overview

In this guide, we’ll deploy a router endpoint to Google Cloud Run with Terraform, following an approach inspired by
Apollo’s official
deployment [guide](https://www.apollographql.com/docs/graphos/routing/self-hosted/containerization/gcp).

---
## ✨ Highlights
- ![Apollo GraphQL](https://img.shields.io/badge/-ApolloGraphQL-311C87?&logo=apollo-graphql) Apollo GraphQL
- ![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white) Containerization with Docker
- ![GCP](https://img.shields.io/badge/Google%20Cloud-4285F4?logo=googlecloud&logoColor=white) Google Cloud Platform (GCP) 
- ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white) Infrastructure as Code via Terraform
- ![Azure DevOps Pipeline](https://img.shields.io/badge/AzureDevOps-Pipelines-0078D4?logo=microsoft-azure&logoColor=white) Automated CI/CD using Azure DevOps Pipelines (Terraform validation + deployment)

---
## 🚀 Getting Started

### Prerequisites
Before proceeding, ensure the following are installed and configured:

- **Google Cloud Project**
    - Create a free [Google Cloud Account](https://console.cloud.google.com/)
    - Install the [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- **Terraform**
    - Install the [Terraform CLI](https://developer.hashicorp.com/terraform/install)
- **Apollo GraphQL Account**
    - Create a free [Apollo GraphQL Account](https://www.apollographql.com/)
    - Create a `Graph` (Supergraph)
    - Store these values to your GCP Secret Manager
        - `apollo-api-key` -> APOLLO_KEY
            - e.g. service:<graph-name>:<unique-key>
        - `apollograph-id` -> APOLLO_GRAPH_REF (e.g. `<graph-name>@current`) 
    - This [repository](https://github.com/mel-cdn/python-strawberry-graphql-fastapi-apollo) provides the infrastructure and pipeline setup needed to deploy and publish a **Subgraph** to an **Apollo Supergraph**

### Authenticate Google Cloud Credentials
```bash
# Authenticate your GCP account
gcloud init

# Set your default project
gcloud config set project <my-project-id>

# Configure application default credentials (for SDKs and integrations)
gcloud auth application-default login
```

### Installation
```bash
# Clone repository
git clone https://github.com/mel-cdn/apollo-graphos-router-google-cloud-run.git
cd apollo-graphos-router-google-cloud-run
```

### Deployment via Terraform
```bash
# Move to Terraform path
cd ./terraform

# Initialize Terraform with your remote backend
terraform init --backend-config="bucket=<terraform-state-gcs-bucket>"  

# Format Terraform configuration files
terraform fmt

# Validate configuration
terraform validate

# Generate execution plan
terraform plan \    
  -var="project_prefix=$(GCP_PREFIX)" \
  -var="environment=$(ENVIRONMENT)" \
  -var="region=$(GCP_REGION)" \
  -var="root_domain_name=$(ROOT_DOMAIN_NAME)" \
  -out=tfplan

# Apply changes
terraform apply tfplan
```

### Publish Subgraph to Supergraph
```bash
APOLLO_KEY=<APOLLO_KEY> rover subgraph publish <APOLLO_GRAPH_REF> \
  --schema="./tmp/schema.graphql" \
  --name="subgraph-name" \
  --routing-url="https://<subgraph-graphql-api-url>/graphql"
```