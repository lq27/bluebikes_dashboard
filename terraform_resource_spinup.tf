# Provider Configuration
provider "google" {
  credentials = file("/home/abbythecat27/bluebikes_dashboard/bluebikes-dashboard-d13c1660cfeb.json")  # service account JSON file
  project     = "bluebikes-dashboard"  # GCP project ID
  region      = "us-central1"
}

# Create GCP Project
resource "google_project" "bluebikes_dashboard" {
  name       = "bluebikes_dashboard"
  project_id = "bluebikes-dashboard"  # Project ID should be unique across GCP
  org_id     = "<your-organization-id>"  # Optional: Specify your GCP organization ID

  billing_account = "<your-billing-account-id>"  # Optional: Specify billing account ID for the project
}

# Create GCP Storage Bucket
resource "google_storage_bucket" "tripdata_lake" {
  name     = "tripdata_lake"           # Unique name for your GCP bucket
  location = "US"
  storage_class = "STANDARD"
}

# Create Service Account
resource "google_service_account" "storage_admin_sa" {
  account_id   = "storage-admin-sa"  # Unique service account ID
  display_name = "Storage Admin Service Account"
}

# Grant Storage Admin Role to Service Account
resource "google_project_iam_member" "storage_admin_role" {
  role   = "roles/storage.admin"                      # Grant Storage Admin role
  member = "serviceAccount:${google_service_account.storage_admin_sa.email}"  # Assign role to service account
}

# Output the Service Account and Bucket name
output "service_account_email" {
  value = google_service_account.storage_admin_sa.email
}

output "bucket_name" {
  value = google_storage_bucket.tripdata_lake.name
}
