# ----------------------------------------------------------------------------------------------------------------------
# Retrieve values from Secret Manager
# ----------------------------------------------------------------------------------------------------------------------
data "google_secret_manager_secret" "apollo-key" {
  secret_id = "apollo-api-key"
}
data "google_secret_manager_secret" "apollo-graph-id" {
  secret_id = "apollo-graph-id"
}

# ----------------------------------------------------------------------------------------------------------------------
# Create Cloud Run Service
# ----------------------------------------------------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "service" {
  project             = local.project_id
  name                = local.service_name
  location            = var.region
  deletion_protection = false

  # Public Access / No Authentication
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.sa.email
    timeout                          = "120s"
    max_instance_request_concurrency = 1


    containers {
      image = local.image_latest_digest
      ports {
        container_port = 4000
      }
      command = ["/dist/router", "--dev"]

      env {
        name = "APOLLO_KEY"
        value_source {
          secret_key_ref {
            secret  = data.google_secret_manager_secret.apollo-key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "APOLLO_GRAPH_REF"
        value_source {
          secret_key_ref {
            secret  = data.google_secret_manager_secret.apollo-graph-id.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
  }
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = local.billing_labels
}

# ----------------------------------------------------------------------------------------------------------------------
# Set Authentication
# ----------------------------------------------------------------------------------------------------------------------
resource "google_cloud_run_service_iam_member" "authentication" {
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  service  = google_cloud_run_v2_service.service.name

  role   = "roles/run.invoker"
  member = "allUsers"

  depends_on = [google_cloud_run_v2_service.service]
}


