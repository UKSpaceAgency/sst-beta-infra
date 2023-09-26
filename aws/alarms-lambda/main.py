import os
import csv
import psycopg2
import boto3
import json
from datetime import datetime, timedelta


def lambda_handler(event, context):
    try:

        # Create a Secrets Manager client
        secrets_client = boto3.client("secretsmanager")
        lambda_client = boto3.client('lambda')
        print("Getting from secrets manager")
        response = secrets_client.get_secret_value(SecretId=os.environ['SECRET_NAME'])
        print("Got Resp")
        # Parse the secret value JSON
        secret_value = json.loads(response["SecretString"])
        database_url = secret_value["databaseUrl"]
        slack_lambda_arn = os.environ['SLACK_LAMBDA_ARN']
        source_provider = "SpaceTrack"
        source_type = "CDM"
        must_finish_minutes = int(os.environ['TIMEOUT_MINUTES'])
        fire_alarm = False

        # Do something with the retrieved secret values
        # print("DatabaseUrl:", database_url)

        # Connect to the PostgreSQL database
        connection = psycopg2.connect(database_url)
        cursor = connection.cursor()
        sql_query = (f"select id,ingestion_start,ingestion_end from public.external_data_performance where "
                     f"source_provider = '{source_provider}' and source_type = '{source_type}' order by "
                     f"ingestion_start desc limit 1;")
        cursor.execute(sql_query)
        records = cursor.fetchmany(1)
        print(records)
        for row in records:
            job_id = row[0]
            ingestion_start_datetime = row[1]
            ingestion_end_datetime = row[2]

            if ingestion_end_datetime:
                # Calculate the time difference
                time_difference = ingestion_end_datetime - ingestion_start_datetime

                # Define a timedelta representing minutes
                desired_minutes = timedelta(minutes=must_finish_minutes)

                if time_difference > desired_minutes:
                    print("Time difference is too much")
                else:
                    print("Time difference is OK")

            else:
                print("Ingestion End is empty, checking time")
                current_datetime = datetime.now()
                # Calculate the time difference
                time_difference = current_datetime - ingestion_start_datetime
                desired_minutes = timedelta(minutes=must_finish_minutes)

                if time_difference > desired_minutes:
                    print("Time difference is more then desired. Firing alarm")
                    fire_alarm = True
                else:
                    print("Time difference is not yet met since start")

        # Close the cursor and the database connection
        cursor.close()
        connection.close()

        if fire_alarm:
            # Invoke the Lambda function outside the VPC
            data = {
                "source_provider": source_provider,
                "source_type": source_type,
                "env": os.environ['ENV_NAME'],
                "timeout_minutes": must_finish_minutes
            }
            payload_json = json.dumps(data)

            response = lambda_client.invoke(
                FunctionName=slack_lambda_arn,
                InvocationType='RequestResponse',  # Use 'Event' for asynchronous invocation
                Payload=payload_json.encode('utf-8')
            )

            # Process the response if needed
            response_payload = response['Payload'].read()
            print("Response from Lambda outside VPC:", response_payload)

            print("Response Status Code:", response.status_code)

            return {
                "statusCode": 200,
                "body": f"Some sort of success"
            }
        else:
            print("Alarm skipped")

    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error: {str(e)}"
        }
