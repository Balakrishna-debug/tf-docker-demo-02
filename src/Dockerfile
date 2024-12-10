FROM python:3.9-slim

WORKDIR /app

COPY app.py /app/

RUN pip install flask pymysql

# Set default environment variables (override these at runtime)
ENV DB_HOST=your-db-host
ENV DB_USER=your-db-user
ENV DB_PASSWORD=your-db-password
ENV DB_NAME=flask_app

EXPOSE 80

CMD ["python", "app.py"]
