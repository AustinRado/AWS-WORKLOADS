
# PowerShell script to migrate Azure Blob objects to AWS S3

# Prompt user for Azure storage account details
$azureAccountName = Read-Host "Enter Azure Storage Account Name"
$azureAccountKey = Read-Host "Enter Azure Storage Account Key" 
$s3BucketName = Read-Host "Enter S3 Bucket Name"
$azureContainerName = Read-Host "Enter Azure Blob Container Name"

# Install Azure and AWS PowerShell modules if not present
if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
    Install-Module -Name Az.Storage -AllowClobber -Force
}

if (-not (Get-Module -ListAvailable -Name AWS.Tools.S3)) {
    Install-Module -Name AWS.Tools.S3 -AllowClobber -Force
}

# Connect to Azure using account name and key
Try {
    # Import the Az.Storage module explicitly
    Import-Module Az.Storage -ErrorAction Stop
    
    $context = New-AzStorageContext -StorageAccountName $azureAccountName -StorageAccountKey $azureAccountKey -ErrorAction Stop
    Write-Host "Connected to Azure Storage Account: $azureAccountName"
} Catch {
    Write-Host "Error connecting to Azure: $_"
    exit
}

# Retrieve blobs from Azure Storage
Try {
    $blobs = Get-AzStorageBlob -Container $azureContainerName -Context $context
    Write-Host "Retrieved $($blobs.Count) blobs from Azure container: $azureContainerName"
} Catch {
    Write-Host "Error retrieving blobs from Azure: $_"
    exit
}

# Connect to AWS
Try {
    $awsAccessKey = Read-Host "Enter AWS Access Key"
    $awsSecretKey = Read-Host "Enter AWS Secret Key"
    $awsRegion = Read-Host "Enter AWS Region (e.g., eu-west-1)"
    
    # Import AWS module explicitly
    Import-Module AWSPowerShell -ErrorAction Stop
    
    Set-AWSCredential -AccessKey $awsAccessKey -SecretKey $awsSecretKey
    Set-DefaultAWSRegion -Region $awsRegion
    Write-Host "Connected to AWS"
} Catch {
    Write-Host "Error connecting to AWS: $_"
    exit
}

# Upload blobs to S3
Try {
    foreach ($blob in $blobs) {
        $blobName = $blob.Name
        $tempFile = [System.IO.Path]::GetTempFileName()
        Get-AzStorageBlobContent -Blob $blobName -Container $azureContainerName -Context $context -Destination $tempFile -Force
        Write-Host "Uploading blob '$blobName' to S3 bucket '$s3BucketName'"
        Write-S3Object -BucketName $s3BucketName -Key $blobName -File $tempFile
        Remove-Item -Path $tempFile -Force
    }
    Write-Host "All blobs successfully uploaded to S3 bucket: $s3BucketName"
} Catch {
    Write-Host "Error uploading blobs to S3: $_"
    exit
}