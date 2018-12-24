Set-PSDebug -Trace 2

$folder = Join-Path '/var/docker-deploy' (Get-ChildItem Env:DOCKER_DEPLOY_FOLDER).Value

docker-compose -f "$($folder)/docker-compose.yml" stop

rm -rf "$($folder)/volumes/app"
mv app "$($folder)/volumes"

docker-compose -f "$($folder)/docker-compose.yml" up -d

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

$response = Invoke-RestMethod -Uri "https://api.cloudflare.com/client/v4/zoness/$($cfZone)/purge_cache" -Method 'DELETE' -Headers $headers -Body $body

if (!response.success) {
    Exit 1
}
