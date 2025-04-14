# bluebikes_dashboard
A dashboard for BlueBikes ride data. 

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
    - Start and End station
    - Start and End latitude
    - Start and end date/time
    - Membership type (whether member or casual user)
    - Bicycle type (electric or regular)
 
### Data pipeline overview 

- The Bluebikes data lives in AWS S3 storage.
- Google Cloud Platform hosts the cloud storage. I have also used the GCP Compute Engine as a virtual machine, but you can run the code locally if you'd like.
- GCP BigQuery is the data warehouse
- Kestra is the orchestrator
  - Download from S3, data cleaning/standardization, upload to GCP Bucket, and BigQuery transformations are all done through Kestra
- Python is used during the data cleaning step in Kestra for data standardization
- Finally, Looker Studio is used for data visualizations 



   
