# bluebikes_dashboard
A dashboard for BlueBikes ride data. 
https://lookerstudio.google.com/reporting/c24a4d8d-e304-447a-9f6c-e8abd83e2cad

### Background & Motivation: 

Bluebikes (formerly Hubway) is a bikesharing platform serving the Boston metro area, serving over 20,000 members and making over 4 million bike rides possible in the last year alone. As an urban transportation solution, the system faces a critical logistical challenge: ensuring bikes are available when and where riders need them.

Connecting riders with bikes at convenient location is a complex logistical task. As a Bluebikes user, I've experienced the frustration of arriving at an empty station during peak commuting hours. This common pain point highlights a key opportunity for operational improvement through data analysis.

With a rich dataset spanning over 10 years and encompassing more than 24 million rides, we have the opportunity to uncover usage patterns that can transform Bluebikes' distribution strategy. By leveraging historical data, we can help predict demand fluctuations and optimize bike placement to enhance rider satisfaction while improving operational efficiency.

This project aims primarily to analyze and present broad data about Bluebike usage patterns to provide actionable insights for improving Bluebikes efficiency. A secondary goal is to set up a data pipeline that can be the foundation of more complex analyses involving demand forecasting and predictive analytics. 

### About the data

Bluebikes (formerly hubway) makes monthly data available as a CSV file. This data describes every trip taken that month. 
(https://s3.amazonaws.com/hubway-data/index.html)

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
- Docker is used to spin up the development environment from which Kestra is run. 
- Kestra is the orchestrator
  - Download from S3, data cleaning/standardization, upload to GCP Bucket, and BigQuery transformations are all done through Kestra
- Python is used during the data cleaning step in Kestra for data standardization
- Finally, Looker Studio is used for data visualizations

## Instructions for running this project

These instructions also contain crucial information about the pipeline architecture, design choices, and known issues, so please read carefully even if you aren't replicating this project yourself. 

### Development environment

I chose to use a virtual machine through GCP Compute Engine, but you can choose to develop locally or on another platform. 

You need to have Docker installed in your development environment. I have: "Docker version 27.5.0, build a187fa5". Once installed, you can use Docker to spin up pretty much any environment you want for development or testing (e.g. I created a python container to test the schema normalization python code). 

You also need to have Terraform installed in your development environment. I have: "Terraform v1.10.5 on linux_amd64".

You can alternatively run things locally but you will have to determine the right configuration on your own using the specified packages and software in the Docker files. 

### Google Cloud Platform 

I used GCP BigQuery as the data warehouse for this project, and I used GCP Cloud Storage to do the intermediate upload of CSVs before importing them as regular tables into BQ. 

You can create a free account in GCP with some free credits. Once you've created an account, you can then create a project (I called mine bluebikes-dashboard). 

### Service Account 

You need to create a "service account" for your project so that we can automate some of the data pipeline. The service account will be used by Terraform and Kestra. 

Terraform will set up your GCP infrastructure within the project (and makes it easy to destroy/delete that infrastructure once you are done). It needs to service account to both provision and destroy resources. 

Kestra will orchestrate the workflow; it uses the service account to (1) upload to and delete from GCP Cloud Storage buckets and (2) to load data into BigQuery. 

To create the service account with the right permissions: 
1. Go to "IAM and Admin" > "Service Accounts"
2. Click "Create service account"
3. Grant "Storage Admin" and "BigQuery Admin" permissions to the service account. Save.
4. Click on the service account and navigate to the "Keys" tab
5. Click "Add key" > "Create new key" to create a JSON key.
6. Save this key in a safe place in you development environment where it can be accessed by your terraform and kestra files. DO NOT UPLOAD THIS TO GIT OR ELSEWHERE.

### main.tf: Spin up GCP environment using Terraform

Modify the main.tf script with your service account credentials, project name, region, and bucket name (bucket names must be unique). You can also change the names of the BQ tables and dataset if you'd like.

Then, run it using terraform commands (terraform init, terraform plan, terraform apply; you can use terraform destroy to take down the resources you created). 

Here's what main.tf does:
- Connects to your GCP project using your service account credentials
- Sets up a Cloud Storage bucket called "tripdata-lake" (or whatever name you choose)
  - Sets up an auto-delete rule for anything older than 31 days. This is because I don't want to store any files in GCP; cloud storage is an intermediate step in loading data to the warehouse. The GCP files should be deleted automatically in the Kestra script after loading to BQ, but this is set up just in case. 
- Creates a BQ schema (i.e. a dataset in BQ to house our data tables)
- Creates a BQ table, all_trip_data, and defines its schema. This table will hold all of the trip data in one place.
    - You'll notice the pre-defined schema. See "The expected schema" section below.
 
### docker-compose.yaml: Spin up Kestra and postgres

Now, check out the docker-compose.yaml file. This specifies the environment to spin up for Kestra, which requires postgres for its backend. 

Couple notes:
- I like to run Kestra on my local port 8090, because I often save 8080 for pgadmin (though we aren't using that here). You can change this if you prefer.
- I have mounted a couple different volumes. This part of the script is under development/a known issue that needs to be resolved. I am unable to pass files into Kestra via mounted volumes, unfortunately, despite spending a few hours trying to make it work. The code doesn't affect the running, so I've left it in there to figure out in the future.

To spin up the environment, run "docker compose up" in your terminal. It will take a couple minutes to download and start everything up, especially the first time you run it. 

### Import flows into Kestra (manual)

To access the Kestra UI, go to http://localhost:8090 (or whichever port you specified in docker-compose.yaml). 

Now, create a new namespace and start adding all of the flows into your Kestra instance. (Once I figure out how to do the volume mounting, this step will not longer be necessary). 

Flows to add:
1. bluebikes_kv.yaml:
   - This is called 'bluebikes_kv copy.yaml' in git. This is because my true copy of bluebikes_kv.yaml contains my JSON private key for my GCP service account, which should not be shared.
   - Add your private JSON key to the gcp_creds task.
   - Update any of the values in the key-value pairs according to how you named things in your project.
   - Once in your private development environment, remember to remove the " copy" suffix. Then of course copy it into Kestra.

2. bluebikes_ingest.yaml:
   - This is where a lot of the magic happens. This script is a workhorse!
   - It downloads the CSV data from the source (AWS S3 http link) and unzips it
   - Then it validates and transforms the data to conform to our desired schema, using inline python code
   - If the data passes validation without errors, it is then uploaded to GCS
   - Then, the new data is staged in BigQuery, and unique hash identifiers are created to prevent duplicate data ingestion
   - The new data is merged into the main data table, all_trip_data
   - Finally, the CSV is deleted from kestra and GCP; the staging tables are deleted from BQ. This cleanup happens even if there is an error somewhere in the process.
  
3. bluebikes_purge_logs_execs.yaml:
   - This flow just purges logs and executions from kestra to keep things clean. It is scheduled to run every day to delete data > 1 month old, but can be manually run to delete everything.
  
### Ingest data

Now, it's time to run the ingestion flow to transform our data and load it into BQ.

You'll notice the ingestion flow has a trigger. It is set up to run monthly to ingest data from 2 months prior (this is because a month's worth of data is not ready until the end of the month, and may take a few weeks to be uploaded). This trigger allows us to backfill all of the data from previous years and populate our warehouse. 

We want all the data from Jan 2015 - Feb 2025 (as of writing this in April 2025), so we'll backfill from March 2015 - April 2025 since it ingests data from 2 months prior. 

[[Insert screenshot here of what the backfill should look like]] 

For me, ingestion took about 2 hours to complete. It will depend on your local environment resources and your internet connection. Keep an eye on the kestra logs for errors in execution. 

Known issue - I had 6/123 files fail to ingest. I still have to look into what error is causing this. 5 of the affected files are from 2018 and 1 is from 2015; I am setting this aside for now because those data points are not as valuable as more recent data anyway, but I hope to troubleshoot this soon. 

You can purge logs/execs at this point if you'd like. I kept mine so I could go back to troubleshoot. 

### Generate visualizations and insights

Now all your data should be nicely loaded into BQ! From here the possibilities are endless. 

I chose to do my visualizations in Looker Studio because this was the simplest choice given time constraints and integrates easily with BQ. 

In the future, I will look into a different visualization platform because Looker Studio proves not to be super intuitive or replicable. For example, I cannot share any code for how to generate these visualizations exactly; you'd have to create them by hand like I did. Furthermore, the UI is finicky; it is hard to specify formatting, e.g. consistent colors for classic vs electric bikes across multiple charts, or ordering years in ascending order. 

### The expected schema

This is the expected schema for our final all_trip_data table, and the inline python code in kestra transforms and validates the data so that it fits these specifications before loading into BQ. 

- unique_row_id: a unique hash code for the row data (generated during ingestion) - BYTES
- fileid: the name of the source csv file for the row data (added during ingestion) - STRING
- ride_id: ride identifier, comes from source csv data - STRING
- rideable_type: whether electric or classic bike - STRING
- started_at: when the ride started - TIMESTAMP
- ended_at: when the ride ended - TIMESTAMP
- start_station_name: where the ride started - STRING
- start_station_id: ID number of the station where the ride started - STRING
- end_station_name: where the ride ended - STRING
- end_station_id: ID number of the station where the ride ended - STRING
- start_lat: latitude of start station - FLOAT
- start_lng: longitude of start station - FLOAT
- end_lat: latitude of end station - FLOAT
- end_lng: longitude of end station - FLOAT
- member_casual: whether rider was a blubikes member or a casual user - STRING
-  bikeid: ID of the bike used - STRING

## Thanks and contact 
That's it! Feel free to reach out on git with any questions or ideas about how to improve or extend this project. Thanks for reading, and be safe on your bikes out there :)

## Sources 
A lot of this code was adapted from DataTalksClub Data Engineering Zoomcamp - big thanks to the folks who provided those tutorials. 
