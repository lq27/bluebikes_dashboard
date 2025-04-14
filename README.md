# bluebikes_dashboard
A dashboard for BlueBikes ride data. 
https://lookerstudio.google.com/reporting/c24a4d8d-e304-447a-9f6c-e8abd83e2cad

### Background & Motivation: 
Bluebikes is a a bikesharing platform serving the Boston metro area, serving XXX riders each XXX. 
As you can imagine, connecting riders with bikes at convenient location is a complex logistical task. As a bike rider myself, I have faced the dreaded empty bike dock at the station nearest my house, particularly during peak transport hours. 
With millions of rides worth of data over 10+ years, we can analyze rider usage to identify patterns that can help Bluebikes with their bike distribution and forecasting to ensure that bikes are available to every rider that needs one. 

### About the data

Bluebikes (formerly hubway) makes monthly data available as a CSV file. This data describes every trip taken that month. 
TODO insert link to data here. 

- Data is available from 2015-Present
- The data columns vary over time, but the key data points provided for each ride include:
    - Ride ID
    - Bicycle type (electric or regular)
    - Start and End station
    - Start and End latitude
    - Start and end date/time
    - Membership type (whether member or casual user)
  
### Data pipeline overview 

- The Bluebikes data lives in AWS S3 storage.
- Google Cloud Platform hosts the cloud storage. I have also used the GCP Compute Engine as a virtual machine, but you can run the code locally if you'd like.
- GCP BigQuery is the data warehouse
- Kestra is the orchestrator
  - Download from S3, data cleaning/standardization, upload to GCP Bucket, and BigQuery transformations are all done through Kestra
- Python is used during the data cleaning step in Kestra for data standardization
- Finally, Looker Studio is used for data visualizations 

### The expected schema

unique_row_id: a unique hash code for the row data (generated during ingestion) - BYTES
fileid: the name of the source csv file for the row data (added during ingestion) - STRING
ride_id: ride identifier, comes from source csv data - STRING
rideable_type: whether electric or classic bike - STRING
started_at: when the ride started - TIMESTAMP
ended_at: when the ride ended - TIMESTAMP
start_station_name: where the ride started - STRING
start_station_id: ID number of the station where the ride started - STRING
end_station_name: where the ride ended - STRING
end_station_id: ID number of the station where the ride ended - STRING
start_lat: latitude of start station - FLOAT
start_lng: longitude of start station - FLOAT
end_lat: latitude of end station - FLOAT
end_lng: longitude of end station - FLOAT
member_casual: whether rider was a blubikes member or a casual user - STRING
bikeid: ID of the bike used - STRING


   
