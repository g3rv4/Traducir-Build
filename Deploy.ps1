Set-PSDebug -Trace 1

$folder = Join-Path '/var/docker-deploy' (Get-ChildItem Env:DOCKER_DEPLOY_FOLDER).Value

docker-compose -f "$($folder)/docker-compose.yml" stop

rm -rf "$($folder)/volumes/app"
mv app "$($folder)/volumes"

docker-compose -f "$($folder)/docker-compose.yml" up -d

Exit $LASTEXITCODE