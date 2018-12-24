Set-PSDebug -Trace 1

$folder = Join-Path '/var/docker-deploy' (Get-ChildItem Env:DOCKER_DEPLOY_FOLDER).Value

docker-compose --no-ansi -f "$($folder)/docker-compose.yml" stop 2>&1
if($LASTEXITCODE){
    Exit $LASTEXITCODE
}

rm -rf "$($folder)/volumes/app"
mv app "$($folder)/volumes"

docker-compose --no-ansi -f "$($folder)/docker-compose.yml" up -d 2>&1
if($LASTEXITCODE){
    Exit $LASTEXITCODE
}

# Give it 5 seconds for it to start
Start-Sleep -s 5

# Run migrations
$instanceNames = (Get-ChildItem Env:INSTANCE_NAMES).Value
foreach ($instanceName in $instanceNames.Split(',')){
    Write-Output "Running migrations on $instanceName"
    docker exec $instanceName curl -f -i http://localhost:5000/app/api/admin/migrate 2>&1
    if($LASTEXITCODE){
        Exit $LASTEXITCODE
    }
}

# Clear the cache
$cfEmail = (Get-ChildItem Env:CF_EMAIL).Value
$cfApiKey = (Get-ChildItem Env:CF_API_KEY).Value
$cfZone = (Get-ChildItem Env:CF_ZONE).Value

$headers = @{
    "X-Auth-Email"=$cfEmail;
    "X-Auth-Key"=$cfApiKey;
    "Content-Type"="application/json"
}

$body = @{
    purge_everything=$true
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zones/$($cfZone)/purge_cache" -Method 'DELETE' -Headers $headers -Body $body