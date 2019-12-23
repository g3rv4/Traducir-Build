Set-PSDebug -Trace 1

$dockerAppPath = $env:DOCKER_APPPATH
$dockerNginxPath = $env:DOCKER_NGINXPATH
$staticFilesPath = $env:STATIC_FILESPATH
$instanceNames = $env:DOCKER_INSTANCENAMES.Split(',')

$appPath = "$($env:SYSTEM_DEFAULTWORKINGDIRECTORY)/App/Traducir.$($env:RELEASE_ARTIFACTS_APP_BUILDNUMBER)"

docker-compose --no-ansi -f "$($dockerAppPath)/docker-compose.yml" stop
if ($LASTEXITCODE) {
    Exit $LASTEXITCODE
}

rm -rf "$($dockerAppPath)/volumes/app"
mv $appPath "$($dockerAppPath)/volumes/app"

rm -rf "$($staticFilesPath)"
mv "$($dockerAppPath)/volumes/app/wwwroot" $staticFilesPath

docker-compose --no-ansi -f "$($dockerAppPath)/docker-compose.yml" up -d
if ($LASTEXITCODE) {
    Exit $LASTEXITCODE
}

# Give it 5 seconds for it to start
Start-Sleep -s 5

# Run migrations
foreach ($instanceName in $instanceNames) {
    Write-Output "Running migrations on $instanceName"
    docker exec $instanceName wget http://localhost:5000/admin/migrate
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