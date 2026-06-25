# Build and Push Docker Images Script
# Run from the project root: .\build-and-push.ps1

$DOCKER_USER = "rohanm95"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Building & Pushing Docker Images" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Build backend services
$services = @(
    @{ Name = "ecommerce-user-service";    Path = "./backend/user-service" },
    @{ Name = "ecommerce-product-service"; Path = "./backend/product-service" },
    @{ Name = "ecommerce-cart-service";    Path = "./backend/cart-service" },
    @{ Name = "ecommerce-order-service";   Path = "./backend/order-service" },
    @{ Name = "ecommerce-frontend";        Path = "./frontend" }
)

foreach ($svc in $services) {
    $tag = "$DOCKER_USER/$($svc.Name)"
    Write-Host "`n>>> Building $tag ..." -ForegroundColor Yellow
    docker build -t $tag $svc.Path
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to build $tag" -ForegroundColor Red
        exit 1
    }
    Write-Host ">>> Built $tag successfully" -ForegroundColor Green
}

# Push all images
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " Pushing Images to DockerHub" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

foreach ($svc in $services) {
    $tag = "$DOCKER_USER/$($svc.Name)"
    Write-Host ">>> Pushing $tag ..." -ForegroundColor Yellow
    docker push $tag
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to push $tag" -ForegroundColor Red
        exit 1
    }
    Write-Host ">>> Pushed $tag successfully" -ForegroundColor Green
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " ALL DONE! Images on DockerHub:" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
foreach ($svc in $services) {
    Write-Host "  - $DOCKER_USER/$($svc.Name)" -ForegroundColor White
}
