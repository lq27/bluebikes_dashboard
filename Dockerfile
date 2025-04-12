FROM python:alpine3.20

RUN pip install pandas  
RUN pip install argparse 

COPY '202502-bluebikes-tripdata.csv' '/202502-bluebikes-tripdata.csv'
COPY '201501-hubway-tripdata.csv' '/201501-bluebikes-tripdata.csv'
COPY 'schema_validation.py' '/schema_validation.py'

CMD [ "python",  "/schema_validation.py"]