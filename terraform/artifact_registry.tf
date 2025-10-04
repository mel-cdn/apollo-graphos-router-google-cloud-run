locals {
  repo_name           = "graph-router-images"
  image_name          = local.service_name
  working_dir         = "${path.root}/../"
  image_tag_prefix    = "${var.region}-docker.pkg.dev/${local.project_id}/${local.repo_name}"
  image_tag           = "${local.image_tag_prefix}/${local.image_name}" # For cleanup old images
  image_tag_latest    = "${local.image_tag_prefix}/${local.image_name}:latest"
  image_latest_digest = "${local.image_tag}@${jsondecode(data.local_file.image_digest.content).digest}"
}
# ----------------------------------------------------------------------------------------------------------------------
# Latest Image Digest
# ----------------------------------------------------------------------------------------------------------------------
data "local_file" "image_digest" {
  filename = "${local.working_dir}tmp/digest.json"

  depends_on = [
    null_resource.push-image
  ]
}
# ----------------------------------------------------------------------------------------------------------------------
# Artifact Registry (Docker Repository)
# ----------------------------------------------------------------------------------------------------------------------
resource "google_artifact_registry_repository" "repo" {
  project       = local.project_id
  repository_id = local.repo_name
  description   = "Repository for Graph Router"
  location      = var.region
  format        = "DOCKER"

  labels = local.billing_labels
}

# ----------------------------------------------------------------------------------------------------------------------
# Build Docker docker
# ----------------------------------------------------------------------------------------------------------------------
resource "null_resource" "build-image" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    working_dir = local.working_dir
    command     = <<EOF
        echo "> Building docker image..."
        docker build --platform linux/amd64 --file=docker/Dockerfile -t ${local.image_tag_latest} .
        EOF
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Push Docker docker
# ----------------------------------------------------------------------------------------------------------------------
resource "null_resource" "push-image" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    working_dir = local.working_dir
    command     = <<EOF
        echo "> Authenticating to Artifact Registry..."
        gcloud auth configure-docker ${var.region}-docker.pkg.dev

        echo "> Pushing app image..."
        docker push ${local.image_tag_latest}

        echo "> Retrieving the image's latest digest..."
        mkdir tmp || true
        DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${local.image_tag_latest} | cut -d'@' -f2)
          echo "{ \"digest\": \"$DIGEST\" }" > tmp/digest.json
        EOF
  }
  depends_on = [null_resource.build-image, google_artifact_registry_repository.repo]
}

# ----------------------------------------------------------------------------------------------------------------------
# Cleanup old Docker images
# ----------------------------------------------------------------------------------------------------------------------
resource "null_resource" "cleanup-old-images" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    working_dir = local.working_dir
    command     = <<EOF
        echo "> Cleaning up old app image (keep latest only)..."
        gcloud artifacts docker images list "${local.image_tag}" \
        --include-tags \
        --filter="tags!=latest" \
        | grep sha256 \
        | awk '{print $1 "@" $2}' \
        | xargs -I {} gcloud artifacts docker images delete {} \
        | true
        EOF
  }
  depends_on = [null_resource.push-image]
}
