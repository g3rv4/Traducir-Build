Set-PSDebug -Trace 1

$backendFolder = Join-Path '/var/docker-deploy' (Get-ChildItem Env:DOCKER_DEPLOY_FOLDER).Value
$frontendFolder = Join-Path '/var/docker-deploy/nginx/volumes/html' (Get-ChildItem Env:DOCKER_DEPLOY_FRONTEND_FOLDER).Value
$staticHost = (Get-ChildItem Env:STATIC_HOST).Value

docker-compose --no-ansi -f "$($backendFolder)/docker-compose.yml" stop 2>&1
if ($LASTEXITCODE) {
    Exit $LASTEXITCODE
}

# have the links on index.html link to the static host instead of using relative urls (so that we can leverage CF)
$content = Get-Content app/frontend/index.html
$content = $content.Replace('src="/', "src=""https://$staticHost/").Replace('href="/', "href=""https://$staticHost/")
$content > app/frontend/index.html

# replace the frontend
rm -rf $frontendFolder
cp -r app/frontend $frontendFolder

# replace the backend
rm -rf "$($backendFolder)/volumes/app"
mv app "$($backendFolder)/volumes"

docker-compose --no-ansi -f "$($backendFolder)/docker-compose.yml" up -d 2>&1
if ($LASTEXITCODE) {
    Exit $LASTEXITCODE
}

# Give it 5 seconds for it to start
Start-Sleep -s 5

# Run migrations
$instanceNames = (Get-ChildItem Env:INSTANCE_NAMES).Value.Split(',')
foreach ($instanceName in $instanceNames) {
    Write-Output "Running migrations on $instanceName"
    docker exec $instanceName curl -f -i http://localhost:5000/app/api/admin/migrate 2>&1
    if ($LASTEXITCODE) {
        Exit $LASTEXITCODE
    }
}

# when messing with multiple containers, nginx may get confused... restarting it clears it up
if ($instanceNames.Count -gt 1) {
    docker-compose --no-ansi -f /var/docker-deploy/nginx/docker-compose.yml restart 2>&1
    if ($LASTEXITCODE) {
        Exit $LASTEXITCODE
    }
}