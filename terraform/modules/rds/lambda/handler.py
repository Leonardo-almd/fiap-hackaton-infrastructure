import json
import os

import boto3
import pg8000


def lambda_handler(event, context):
    secret_arn = os.environ["SECRET_ARN"]
    report_db = os.environ["REPORT_DB_NAME"]

    client = boto3.client("secretsmanager")
    secret = client.get_secret_value(SecretId=secret_arn)
    payload = json.loads(secret["SecretString"])

    host = payload["host"]
    port = int(payload.get("port", 5432))
    username = payload["username"]
    password = payload["password"]
    admin_db = payload["db_upload"]

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
    cursor.execute(
        "SELECT 1 FROM pg_database WHERE datname = %s",
        (report_db,),
    )
    exists = cursor.fetchone() is not None

    if not exists:
        cursor.execute(f"CREATE DATABASE {report_db}")

    cursor.close()
    conn.close()

    return {"created": not exists, "database": report_db}
