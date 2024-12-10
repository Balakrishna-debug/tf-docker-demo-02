from flask import Flask, request
import pymysql
import os

app = Flask(__name__)

# Load database configuration from environment variables for security
DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

# Connect to the database
def connect_to_db():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )

@app.route('/')
def reverse_ip():
    # Get client IP and reverse it
    client_ip = request.remote_addr
    reversed_ip = '.'.join(reversed(client_ip.split('.')))

    conn = None  # Initialize conn to avoid UnboundLocalError
    try:
        # Establish a connection to the database
        conn = connect_to_db()
        if conn is not None:
            with conn.cursor() as cursor:
                sql = "INSERT INTO ip_logs (client_ip, reversed_ip) VALUES (%s, %s)"
                cursor.execute(sql, (client_ip, reversed_ip))
                conn.commit()
        else:
            return "Error connecting to the database", 500
    except Exception as e:
        app.logger.error(f"Error: {e}")
        return f"Error: {e}", 500
    finally:
        if conn:  # Ensure conn is closed if it was initialized
            conn.close()

    return f"Reversed IP: {reversed_ip}"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)