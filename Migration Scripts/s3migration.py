import os
from azure.storage.blob import BlobServiceClient
import boto3
from botocore.exceptions import NoCredentialsError

# ==== CONFIGURATION ====

# Azure Blob config
AZURE_CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=YOUR_ACCOUNT;AccountKey=YOUR_KEY;EndpointSuffix=core.windows.net"
AZURE_CONTAINER_NAME = "your-container-name"

# AWS S3 config
S3_BUCKET_NAME = " " # optional path in S3
S3_UPLOAD_PREFIX = ""  # optional path in S3 (e.g. 'backup/')

# Temp download folder
TEMP_DIR = "temp_downloads"
os.makedirs(TEMP_DIR, exist_ok=True)

# ==== AZURE CLIENT ====

azure_blob_service = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING)
container_client = azure_blob_service.get_container_client(AZURE_CONTAINER_NAME)

# ==== AWS CLIENT ====

s3_client = boto3.client("s3")

# ==== MAIN MIGRATION LOGIC ====

def migrate_blobs():
    print(f"📥 Listing blobs in Azure container: {AZURE_CONTAINER_NAME}...")
    blobs = container_client.list_blobs()

    for blob in blobs:
        blob_name = blob.name
        print(f"➡️ Migrating blob: {blob_name}")

        local_file_path = os.path.join(TEMP_DIR, os.path.basename(blob_name))

        # Download from Azure
        with open(local_file_path, "wb") as download_file:
            download_stream = container_client.download_blob(blob_name)
            download_file.write(download_stream.readall())

        # Upload to S3
        s3_key = os.path.join(S3_UPLOAD_PREFIX, blob_name).replace("\\", "/")  # S3 key should use forward slashes

        try:
            s3_client.upload_file(local_file_path, S3_BUCKET_NAME, s3_key)
            print(f"✅ Uploaded to S3: s3://{S3_BUCKET_NAME}/{s3_key}")
        except NoCredentialsError:
            print("❌ AWS credentials not found. Make sure they're configured.")
            return

        # Clean up
        os.remove(local_file_path)

    print("🎉 Migration complete!")

# ==== RUN ====
if __name__ == "__main__":
    migrate_blobs()
