import os
import time

import pg8000


def lambda_handler(event, context):
    print("Starting report DB init")
    report_db = os.environ["REPORT_DB_NAME"]
    host = os.environ["DB_HOST"]
    port = int(os.environ.get("DB_PORT", "5432"))
    username = os.environ["DB_USERNAME"]
    password = os.environ["DB_PASSWORD"]
    admin_db = os.environ["DB_ADMIN_DB"]

    print(f"Target report DB: {report_db}")
    print(f"DB host: {host}")
    print(f"DB port: {port}")
    print(f"DB admin database: {admin_db}")
    print(f"DB username: {username}")
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
