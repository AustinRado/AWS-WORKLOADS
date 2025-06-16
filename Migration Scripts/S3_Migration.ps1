
# PowerShell script to migrate Azure Blob objects to AWS S3

# Prompt user for Azure storage account details
$azureAccountName = Read-Host "Enter Azure Storage Account Name"
$azureAccountKey = Read-Host "Enter Azure Storage Account Key" 
$azureConnectionString = Read-Host "Enter Azure Connection String"
$s3BucketName = Read-Host "Enter S3 Bucket Name"
$azureContainerName = Read-Host "Enter Azure Blob Container Name"

# Install Azure and AWS PowerShell modules if not present
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -AllowClobber -Force
}

if (-not (Get-Module -ListAvailable -Name AWSPowerShell)) {
    Install-Module -Name AWSPowerShell -AllowClobber -Force
}

# Connect to Azure using provided connection string
Try {
    $context = New-AzStorageContext -ConnectionString $azureConnectionString
    Write-Host "Connected to Azure Storage Account: $azureAccountName"
} Catch {
    Write-Host "Error connecting to Azure: $_"
    exit
}

# Retrieve blobs from Azure Storage
Try {
    $blobs = Get-AzBlob -Container $azureContainerName -Context $context
    Write-Host "Retrieved $($blobs.Count) blobs from Azure container: $azureContainerName"
} Catch {
    Write-Host "Error retrieving blobs from Azure: $_"
    exit
}

# Connect to AWS
Try {
    Initialize-AWSDefaultConfiguration -AccessKey 'YourAccessKey' -SecretKey 'YourSecretKey' -Region 'eu-west-1'
    Write-Host "Connected to AWS"
} Catch {
    Write-Host "Error connecting to AWS: $_"
    exit
}

# Upload blobs to S3
Try {
    foreach ($blob in $blobs) {
        $blobName = $blob.Name
        $blobStream = Get-AzBlobContent -Blob $blobName -Container $azureContainerName -Context $context
        Write-Host "Uploading blob '$blobName' to S3 bucket '$s3BucketName'"
        Write-S3Object -BucketName $s3BucketName -Key $blobName -File $blobStream
    }
    Write-Host "All blobs successfully uploaded to S3 bucket: $s3BucketName"
} Catch {
    Write-Host "Error uploading blobs to S3: $_"
    exit
}