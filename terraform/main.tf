terraform {
  backend "gcs" {
    # Will be populated on deploy or add it manually here.
    bucket = ""
    prefix = "pg-apollo-graphos-router"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
  required_version = ">= 1.2.0"
}

provider "google" {
  project = "${var.project_prefix}-${var.environment}"
  region  = var.region
}

locals {
  billing_labels = {
    infra = "playground"
  }
  project_id           = "${var.project_prefix}-${var.environment}"
  service_name         = "pg-apollo-graphos-router"
  service_account_name = "pg-graph-router-sa"
}

# ----------------------------------------------------------------------------------------------------------------------
# Domain Mapping
# ----------------------------------------------------------------------------------------------------------------------
resource "google_cloud_run_domain_mapping" "map" {
  location = var.region
  name     = "${var.environment != "prod" ? "${var.environment}." : ""}playground.graph.${var.root_domain_name}"

  spec {
    route_name = google_cloud_run_v2_service.service.name
  }

  metadata {
    namespace = local.project_id
    labels    = local.billing_labels
  }
}

