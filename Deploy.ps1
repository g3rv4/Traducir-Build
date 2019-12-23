Set-PSDebug -Trace 1

$dockerPath = $env:DOCKER_PATH
$dockerNginxPath = $env:DOCKER_NGINX_PATH
$instanceNames = $env:DOCKER_INSTANCE_NAMES.Split(',')

docker-compose --no-ansi -f "$($dockerPath)/docker-compose.yml" stop
if ($LASTEXITCODE) {
    Exit $LASTEXITCODE
}

rm -rf "$($dockerPath)/volumes/app"
mv app "$($dockerPath)/volumes"

docker-compose --no-ansi -f "$($dockerPath)/docker-compose.yml" up -d
if ($LASTEXITCODE) {
    Exit $LASTEXITCODE
}

# Give it 5 seconds for it to start
Start-Sleep -s 5

# Run migrations
foreach ($instanceName in $instanceNames) {
    Write-Output "Running migrations on $instanceName"
    docker exec $instanceName curl -f -i http://localhost:5000/app/api/admin/migrate
    if ($LASTEXITCODE) {
        Exit $LASTEXITCODE
    }
}

# when messing with multiple containers, nginx gets confused... restarting it clears it up
if ($instanceNames.Count -gt 1) {
    docker-compose --no-ansi -f "$($dockerNginxPath)/docker-compose.yml" restart
    if ($LASTEXITCODE) {
        Exit $LASTEXITCODE
    }
}