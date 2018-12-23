Set-PSDebug -Trace 1

$build = (Get-ChildItem Env:BUILD_NUMBER).Value
$dockerVolumesPath = (Get-ChildItem Env:DOCKER_VOLUMES_PATH).Value

$backendPath = Join-Path $dockerVolumesPath 'backend'
$srcPath = Join-Path $dockerVolumesPath 'src'

mkdir $backendPath
mv src $srcPath

docker run --rm -v "$($backendPath):/var/backend" -v "$($srcPath):/var/src" g3rv4/traducir-builder dotnet publish /var/src/Traducir.Api -c Release -f netcoreapp2.1 -o /var/backend "/p:AssemblyVersion=$($build)"

mv $backendPath app

Exit $LASTEXITCODE