# FreeDOOM WAD Builder Script
# This script builds FreeDOOM WADs from source using Docker and extracts them as artifacts
# 
# Usage: .\build-freedoom.ps1
# 
# This script will:
# 1. Build the FreeDOOM builder container
# 2. Run the container to build WADs
# 3. Extract WAD files to the current directory
# 4. Clean up temporary containers and images
# 5. Verify the extracted WADs

param(
    [switch]$KeepContainer,
    [switch]$KeepImage,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration
$ContainerName = "freedoom-builder-temp"
$ImageName = "freedoom-builder"
$OutputDir = "."
$DockerfilePath = "Dockerfile.freedoom"
Write-Host "FreeDOOM WAD Builder for Dockermex" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Function to write colored output
function Write-Step {
    param($Message, $Color = "Green")
    Write-Host "[+] $Message" -ForegroundColor $Color
}

function Write-Info {
    param($Message)
    Write-Host "[i] $Message" -ForegroundColor Blue
}

function Write-Warning {
    param($Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}

# Check if Docker is available
try {
    $dockerVersion = docker --version
    Write-Info "Docker found: $dockerVersion"
}
catch {
    Write-Error "Docker is not available. Please install Docker and try again."
    exit 1
}

# Check if Dockerfile exists
if (!(Test-Path $DockerfilePath)) {
    Write-Error "Dockerfile not found: $DockerfilePath"
    Write-Info "Make sure you're running this script from the iwads/freeware directory"
    exit 1
}

# Clean up any existing containers/images if they exist
Write-Step "Cleaning up any existing containers and images..."

try {
    $existingContainer = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}"
    if ($existingContainer) {
        Write-Info "Removing existing container: $ContainerName"
        docker rm -f $ContainerName | Out-Null
    }
    
    $existingImage = docker images --filter "reference=$ImageName" --format "{{.Repository}}"
    if ($existingImage) {
        Write-Info "Removing existing image: $ImageName"
        docker rmi -f $ImageName | Out-Null
    }
}
catch {
    Write-Warning "Failed to clean up existing containers/images: $($_.Exception.Message)"
}

# Build the FreeDOOM builder image
Write-Step "Building FreeDOOM builder container image..."
Write-Info "This may take several minutes as it downloads and compiles FreeDOOM from source..."

try {
    if ($Verbose) {
        docker build -f $DockerfilePath -t $ImageName .
    } else {
        docker build -f $DockerfilePath -t $ImageName . | Out-Null
    }
    Write-Step "Container image built successfully"
}
catch {
    Write-Error "Failed to build container image: $($_.Exception.Message)"
    exit 1
}

# Run the container to build WADs
Write-Step "Running container to build FreeDOOM WADs..."

try {
    if ($Verbose) {
        docker run --name $ContainerName $ImageName
    } else {
        docker run --name $ContainerName $ImageName | Out-Null
    }
    Write-Step "FreeDOOM WADs built successfully"
}
catch {
    Write-Error "Failed to run container: $($_.Exception.Message)"
    exit 1
}

# Extract WAD files from the container
Write-Step "Extracting WAD files..."

try {
    # Create a temporary directory for extraction
    $tempDir = Join-Path $env:TEMP "freedoom-wads-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy WADs from container
    docker cp "$ContainerName`:/app/output/." $tempDir
    
    # Move WADs to current directory
    $wadFiles = Get-ChildItem -Path $tempDir -Filter "*.wad"
    
    if ($wadFiles.Count -eq 0) {
        Write-Error "No WAD files found in container"
        exit 1
    }
    
    foreach ($wad in $wadFiles) {
        $destPath = Join-Path $OutputDir $wad.Name
        Move-Item -Path $wad.FullName -Destination $destPath -Force
        Write-Info "Extracted: $($wad.Name) ($(([math]::Round($wad.Length/1MB, 2))) MB)"
    }
    
    # Clean up temp directory
    Remove-Item -Path $tempDir -Recurse -Force
    
    Write-Step "WAD files extracted to current directory"
}
catch {
    Write-Error "Failed to extract WAD files: $($_.Exception.Message)"
    exit 1
}

# Clean up container and image (unless flags are set)
Write-Step "Cleaning up..."

if (!$KeepContainer) {
    try {
        docker rm $ContainerName | Out-Null
        Write-Info "Removed container: $ContainerName"
    }
    catch {
        Write-Warning "Failed to remove container: $($_.Exception.Message)"
    }
} else {
    Write-Info "Keeping container: $ContainerName (--KeepContainer flag specified)"
}

if (!$KeepImage) {
    try {
        docker rmi $ImageName | Out-Null
        Write-Info "Removed image: $ImageName"
    }
    catch {
        Write-Warning "Failed to remove image: $($_.Exception.Message)"
    }
} else {
    Write-Info "Keeping image: $ImageName (--KeepImage flag specified)"
}

# Verify extracted WADs
Write-Step "Verifying extracted WADs..."

$extractedWads = Get-ChildItem -Path $OutputDir -Filter "*.wad" | Where-Object { $_.Name -like "*freedoom*" }

if ($extractedWads.Count -eq 0) {
    Write-Warning "No FreeDOOM WAD files found in output directory"
} else {
    Write-Host ""
    Write-Host "Successfully extracted FreeDOOM WADs:" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    
    foreach ($wad in $extractedWads) {
        $sizeStr = "{0:N2} MB" -f ($wad.Length / 1MB)
        Write-Host " $($wad.Name) - $sizeStr" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host " These WADs are now ready to use with Dockermex!" -ForegroundColor Cyan
    Write-Host " You can reference them in your server configurations." -ForegroundColor Gray
}

Write-Host ""
Write-Step "FreeDOOM WAD build process completed successfully!" "Cyan"

# Show usage instructions
Write-Host ""
Write-Host "  Usage Instructions:" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host "  • Use 'freedoom1.wad' for Doom I (Ultimate Doom) maps" -ForegroundColor White
Write-Host "  • Use 'freedoom2.wad' for Doom II maps and most PWADs" -ForegroundColor White
Write-Host "  • Update your .env file to point IWAD_FOLDER to this directory" -ForegroundColor White
Write-Host "  • Reference these WADs in your Odamex server configurations" -ForegroundColor White
Write-Host ""
