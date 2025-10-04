locals {
  roles = [
    "roles/iam.serviceAccountUser",
    "roles/secretmanager.secretAccessor"
  ]
}
# ----------------------------------------------------------------------------------------------------------------------
# App Service Account
# ----------------------------------------------------------------------------------------------------------------------
resource "google_service_account" "sa" {
  project      = local.project_id
  account_id   = local.service_account_name
  display_name = local.service_account_name
  description  = "Graph Router Service Account"

  lifecycle {
    prevent_destroy = true
  }
}
# ----------------------------------------------------------------------------------------------------------------------
# Role Assignment
# ----------------------------------------------------------------------------------------------------------------------
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(local.roles)

  project = local.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.sa.email}"
}
