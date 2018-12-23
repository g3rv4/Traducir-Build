Set-PSDebug -Trace 1

$build = (Get-ChildItem Env:BUILD_NUMBER).Value
$dockerVolumesPath = (Get-ChildItem Env:DOCKER_VOLUMES_PATH).Value

$frontendPath = Join-Path $dockerVolumesPath 'frontend'
$srcPath = Join-Path $dockerVolumesPath 'src'

mkdir $frontendPath
mv src $srcPath

docker run --rm -v "$($frontendPath):/var/frontend" -v "$($srcPath):/var/src" g3rv4/traducir-builder /bin/bash -c "cd /var/src/Traducir.Web && \
cp -r /var/node_modules node_modules && \
npm run build && \
cp -r ./dist/* /var/frontend/"

mv $frontendPath app

Exit $LASTEXITCODE