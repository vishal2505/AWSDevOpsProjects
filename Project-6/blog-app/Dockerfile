# Base image with Python and Flask
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy application code
COPY . /app

# Install dependencies
RUN pip install -r requirements.txt

# Expose the port Flask listens on
EXPOSE 5000

# Run the Flask app
CMD ["python", "app.py"]
