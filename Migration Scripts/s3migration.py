import os
from getpass import getpass
from azure.storage.blob import BlobServiceClient
import boto3
from botocore.exceptions import NoCredentialsError

# ==== PROMPT FOR AZURE CONNECTION STRING ====
AZURE_CONNECTION_STRING = getpass("🔐 Enter your Azure Storage connection string: ").strip()
AZURE_CONTAINER_NAME = input("📦 Enter your Azure container name: ").strip()

# ==== AWS CONFIG ====
S3_BUCKET_NAME = "your-s3-bucket-name"
S3_UPLOAD_PREFIX = ""  # e.g. 'backup/' or leave empty

# ==== SETUP CLIENTS ====
azure_blob_service = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING)
container_client = azure_blob_service.get_container_client(AZURE_CONTAINER_NAME)

s3_client = boto3.client("s3")

# ==== TEMP DIR ====
TEMP_DIR = "temp_downloads"
os.makedirs(TEMP_DIR, exist_ok=True)

# ==== MAIN MIGRATION FUNCTION ====
def migrate_blobs():
    print(f"\n📥 Listing blobs in container: {AZURE_CONTAINER_NAME}...")
    blobs = container_client.list_blobs()

    for blob in blobs:
        blob_name = blob.name
        print(f"➡️ Migrating blob: {blob_name}")

        local_path = os.path.join(TEMP_DIR, os.path.basename(blob_name))

        # Download from Azure
        with open(local_path, "wb") as file:
            data = container_client.download_blob(blob_name)
            file.write(data.readall())

        # Upload to S3
        s3_key = os.path.join(S3_UPLOAD_PREFIX, blob_name).replace("\\", "/")
        try:
            s3_client.upload_file(local_path, S3_BUCKET_NAME, s3_key)
            print(f"✅ Uploaded to s3://{S3_BUCKET_NAME}/{s3_key}")
        except NoCredentialsError:
            print("❌ AWS credentials not found. Please configure them with `aws configure`.")
            return

        os.remove(local_path)

    print("\n🎉 Migration completed!")

# ==== RUN ====
if __name__ == "__main__":
    migrate_blobs()
