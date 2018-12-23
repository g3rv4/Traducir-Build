Set-PSDebug -Trace 1

$dockerVolumesPath = (Get-ChildItem Env:DOCKER_VOLUMES_PATH).Value
ls $dockerVolumesPath

rm -rf ("$($dockerVolumesPath)/*")
ls $dockerVolumesPath

Exit $LASTEXITCODE