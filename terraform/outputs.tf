output "service_url" {
  value       = google_cloud_run_v2_service.service.uri
  description = "API service URL"
}

output "domain_url" {
  value       = "https://${google_cloud_run_domain_mapping.map.name}"
  description = "Custom domain URL (after DNS validation completes)"
}

output "dns_records" {
  description = "DNS record required in your domain hosting for validation"
  value       = google_cloud_run_domain_mapping.map.status[0].resource_records
}
