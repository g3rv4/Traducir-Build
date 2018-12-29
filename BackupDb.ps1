Set-PSDebug -Trace 1

# force loading all the AWS commands, see https://github.com/PowerShell/PowerShell/issues/7759#issuecomment-438719024
Get-Command -Module AWSPowerShell.NetCore | Out-Null

$awsAccessKeyId = (Get-ChildItem Env:AWS_ACCESS_KEY_ID).Value
$awsAccessKeySecret = (Get-ChildItem Env:AWS_ACCESS_KEY_SECRET).Value
$awsBucketName = (Get-ChildItem Env:AWS_S3_BUCKET_NAME).Value
Set-AWSCredential -AccessKey $awsAccessKeyId -SecretKey $awsAccessKeySecret

$date = Get-Date (Get-Date).ToUniversalTime() -Format yyyyMMddHHmmss
$dataPath = '/var/docker-deploy/mssql/volumes/data/data'

$dbPassword = (Get-ChildItem Env:DB_PASSWORD).Value
$dbs = (Get-ChildItem Env:DATABASES).Value.Split(',')
foreach ($db in $dbs){
    $filename = "$db-$date"

    docker exec mssql_mssql_1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $dbPassword -Q "BACKUP DATABASE [$db] TO DISK = N'/var/opt/mssql/data/$filename.bak' WITH NOFORMAT, NOINIT, SKIP, NOREWIND, NOUNLOAD, STATS = 10"

    $filenameWithPath = Join-Path $dataPath $filename
    tar -czf "$filenameWithPath.tgz" -C $dataPath "$filename.bak"

    rm "$filenameWithPath.bak"

    Write-Output "Uploading $filename.tgz"
    Write-S3Object -BucketName $awsBucketName -File "$filenameWithPath.tgz" -Key "$filename.tgz"

    rm "$filenameWithPath.tgz"
}

# Clear the cache (so that the new files are visible)
$cfEmail = (Get-ChildItem Env:CF_EMAIL).Value
$cfApiKey = (Get-ChildItem Env:CF_API_KEY).Value
$cfZone = (Get-ChildItem Env:CF_ZONE).Value

$headers = @{
    "X-Auth-Email"=$cfEmail;
    "X-Auth-Key"=$cfApiKey;
    "Content-Type"="application/json"
}

$body = @{
    files = @('https://db-backups.traducir.win/')
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones/$($cfZone)/purge_cache" -Method 'POST' -Headers $headers -Body $body
