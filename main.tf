provider "google" {
  credentials = file("bluebikes-dashboard-d13c1660cfeb.json")  # the service account key 
  project     = "bluebikes-dashboard"
  region      = "us-central1"
}

resource "google_storage_bucket" "tripdata_lake" {
  name          = "tripdata-lake"
  location      = "US"
  force_destroy = true  # Deletes even if not empty; set to false if you want safety
  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 31  # Optional: auto-delete objects older than 1 month; 
                # our workflow should auto-delete csvs in the bucket once done loading them into BQ anyway
    }
  }
}

# BigQuery dataset (schema)
resource "google_bigquery_dataset" "tripdata_dataset" {
  dataset_id = "tripdata"  # match GCP_BQ_DATASET
  location   = "US"
  delete_contents_on_destroy = true
}

# BigQuery table
resource "google_bigquery_table" "all_trip_data" {
  dataset_id = google_bigquery_dataset.tripdata_dataset.dataset_id
  table_id   = "all_trip_data"

  schema = jsonencode([
    { name = "unique_row_id",     type = "BYTES",    mode = "NULLABLE" },
    { name = "fileid",            type = "STRING",   mode = "NULLABLE" },
    { name = "ride_id",           type = "STRING",   mode = "NULLABLE" },
    { name = "rideable_type",     type = "STRING",   mode = "NULLABLE" },
    { name = "started_at",        type = "TIMESTAMP",mode = "NULLABLE" },
    { name = "ended_at",          type = "TIMESTAMP",mode = "NULLABLE" },
    { name = "start_station_name",type = "STRING",   mode = "NULLABLE" },
    { name = "start_station_id",  type = "STRING",   mode = "NULLABLE" },
    { name = "end_station_name",  type = "STRING",   mode = "NULLABLE" },
    { name = "end_station_id",    type = "STRING",   mode = "NULLABLE" },
    { name = "start_lat",         type = "FLOAT",    mode = "NULLABLE" },
    { name = "start_lng",         type = "FLOAT",    mode = "NULLABLE" },
    { name = "end_lat",           type = "FLOAT",    mode = "NULLABLE" },
    { name = "end_lng",           type = "FLOAT",    mode = "NULLABLE" },
    { name = "member_casual",     type = "STRING",   mode = "NULLABLE" },
    { name = "bikeid",            type = "STRING",   mode = "NULLABLE" }
  ])

  deletion_protection = false
}