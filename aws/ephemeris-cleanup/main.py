import os
import csv
import psycopg2
import boto3
import json
from datetime import datetime, timedelta


def lambda_handler(event, context):
    try:
        print(event)
        # Create a Secrets Manager client
        secrets_client = boto3.client("secretsmanager")
        lambda_client = boto3.client('lambda')
        print("Getting from secrets manager")
        response = secrets_client.get_secret_value(SecretId=os.environ['SECRET_NAME'])
        print("Got Resp")
        # Parse the secret value JSON
        secret_value = json.loads(response["SecretString"])
        database_url = secret_value["databaseUrl"]

        # Iterate through the records in the payload and print the S3 object keys
        for record in event['Records']:
            if record['eventSource'] == 'aws:s3' and 's3' in record:
                s3_object_key = record['s3']['object']['key']
                # s3_object_key in real will be: ephemeris/22078/1638138109.oem
                print(f"S3 Object Key: {s3_object_key}")

        # Connect to the PostgreSQL database
        connection = psycopg2.connect(database_url)
        cursor = connection.cursor()
        sql_query = (f"select 1;")
        cursor.execute(sql_query)
        records = cursor.fetchmany(1)
        print(records)

        # Close the cursor and the database connection
        cursor.close()
        connection.close()


    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error: {str(e)}"
        }
