import json
import os
import time

import boto3
import pg8000


def lambda_handler(event, context):
    print("Starting report DB init")
    secret_arn = os.environ["SECRET_ARN"]
    report_db = os.environ["REPORT_DB_NAME"]
    print(f"Secret ARN: {secret_arn}")
    print(f"Target report DB: {report_db}")

    client = boto3.client("secretsmanager")
    print("Fetching secret from Secrets Manager")
    secret = client.get_secret_value(SecretId=secret_arn)
    payload = json.loads(secret["SecretString"])

    host = payload["host"]
    port = int(payload.get("port", 5432))
    username = payload["username"]
    password = payload["password"]
    admin_db = payload["db_upload"]
    print(f"DB host: {host}")
    print(f"DB port: {port}")
    print(f"DB admin database: {admin_db}")
    print(f"DB username: {username}")

    attempts = 10
    backoff_seconds = 5
    last_error = None

    for attempt in range(1, attempts + 1):
        try:
            print(f"Attempt {attempt}/{attempts}: connecting to database")
            conn = pg8000.connect(
                user=username,
                password=password,
                host=host,
                port=port,
                database=admin_db,
                timeout=10,
            )
            conn.autocommit = True

            cursor = conn.cursor()
            print("Checking if report database exists")
            cursor.execute(
                "SELECT 1 FROM pg_database WHERE datname = %s",
                (report_db,),
            )
            exists = cursor.fetchone() is not None
            print(f"Report database exists: {exists}")

            if not exists:
                print("Creating report database")
                cursor.execute(f"CREATE DATABASE {report_db}")
                print("Report database created")

            cursor.close()
            conn.close()
            print("Report DB init completed")

            return {"created": not exists, "database": report_db}
        except Exception as exc:
            print(f"Attempt {attempt} failed: {type(exc).__name__}: {exc}")
            last_error = exc
            if attempt < attempts:
                print(f"Waiting {backoff_seconds}s before retry")
                time.sleep(backoff_seconds)

    raise RuntimeError(f"Failed to initialize report database: {last_error}")
