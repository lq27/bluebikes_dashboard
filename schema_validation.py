import csv
import sys
import argparse
import pandas as pd 

def get_schema(csv_file) :
    with open(csv_file, "r") as f:
        reader = csv.reader(f)
        header = next(reader)

    print(header)
    return header

def validate_schema(csv_file, expected_headers):

    # Read the CSV header
    try:
        with open(csv_file, "r") as f:
            reader = csv.reader(f)
            actual_headers = next(reader)
            
            # Check if header matches expected columns
            missing_columns = set(expected_headers) - set(actual_headers)
            extra_columns = set(actual_headers) - set(expected_headers)
            
            if missing_columns or extra_columns:
                print("Schema validation failed!")
                print(f"Missing columns: {missing_columns}")
                print(f"Unexpected columns: {extra_columns}")
                sys.exit(1)
              
            print("Schema validation passed!")
            sys.exit(0)
    except Exception as e:
        print(f"Error validating schema: {e}")
        print(actual_headers)
        return actual_headers
        sys.exit(1)

if __name__ == "__main__":
    # parser = argparse.ArgumentParser(description='Validate CSV schema')
    # parser.add_argument('--csv-file', required=True, help='Path to CSV file')
    # parser.add_argument('--schema', required=True, help='Schema as JSON string')
    
    # args = parser.parse_args()
    
    # is_valid = validate_schema(args.csv_file, args.schema)
    
    # # Exit with appropriate status code
    # sys.exit(0 if is_valid else 1)

    # csv_file = "/home/abbythecat27/bluebikes_dashboard/202502-bluebikes-tripdata.csv"
    csv_file1 = "/202502-bluebikes-tripdata.csv"
    schema1 = get_schema(csv_file1)
    csv_file2 = "/201501-bluebikes-tripdata.csv"
    is_valid = validate_schema(csv_file2, schema1)
    print("is valid? ", is_valid)
    # # Exit with appropriate status code
    sys.exit(0 if is_valid else 1)