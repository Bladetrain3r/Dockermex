# Take a tag as an input
# Check if Dockerfile.tag exists in the Dockerfiles directory
# Build image with the Dockerfile.tag

# Usage: .\taggeddocker.ps1 -tag mytag

param(
    [string]$tag
    
)

if ($tag -eq $null) {
    Write-Host "Please provide a tag"
    exit
}

$dockerfile = "Dockerfiles\Dockerfile.$tag"

if (Test-Path $dockerfile) {
    docker build -t dockermex:$(${tag}.ToLower()) -f $dockerfile .
} else {
    Write-Host "Dockerfile.$tag does not exist"
}