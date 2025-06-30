#!/bin/bash

# FreeDOOM WAD Builder Script (Linux/macOS)
# This script builds FreeDOOM WADs from source using Docker and extracts them as artifacts
# 
# Usage: ./build-freedoom.sh [OPTIONS]
# 
# Options:
#   --keep-container    Don't remove the container after extraction
#   --keep-image        Don't remove the image after completion
#   --verbose          Show verbose output during build
#   --help             Show this help message
#
# This script will:
# 1. Build the FreeDOOM builder container
# 2. Run the container to build WADs
# 3. Extract WAD files to the current directory
# 4. Clean up temporary containers and images
# 5. Verify the extracted WADs

set -e  # Exit on any error

# Configuration
CONTAINER_NAME="freedoom-builder-temp"
IMAGE_NAME="freedoom-builder"
OUTPUT_DIR="."
DOCKERFILE_PATH="Dockerfile.freedoom"

# Default options
KEEP_CONTAINER=false
KEEP_IMAGE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-container)
            KEEP_CONTAINER=true
            shift
            ;;
        --keep-image)
            KEEP_IMAGE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "FreeDOOM WAD Builder for Dockermex"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --keep-container    Don't remove the container after extraction"
            echo "  --keep-image        Don't remove the image after completion"
            echo "  --verbose          Show verbose output during build"
            echo "  --help             Show this help message"
            echo ""
            echo "This script builds FreeDOOM WADs from source and extracts them"
            echo "as artifacts for use with Dockermex."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Functions for colored output
log_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# Header
echo -e "${CYAN}🎮 FreeDOOM WAD Builder for Dockermex${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker is not available. Please install Docker and try again."
    exit 1
fi

docker_version=$(docker --version)
log_info "Docker found: $docker_version"

# Check if Dockerfile exists
if [[ ! -f "$DOCKERFILE_PATH" ]]; then
    log_error "Dockerfile not found: $DOCKERFILE_PATH"
    log_info "Make sure you're running this script from the iwads/freeware directory"
    exit 1
fi

# Clean up any existing containers/images if they exist
log_step "Cleaning up any existing containers and images..."

# Remove existing container if it exists
if docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    log_info "Removing existing container: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || log_warning "Failed to remove existing container"
fi

# Remove existing image if it exists
if docker images --filter "reference=$IMAGE_NAME" --format "{{.Repository}}" | grep -q "^$IMAGE_NAME$"; then
    log_info "Removing existing image: $IMAGE_NAME"
    docker rmi -f "$IMAGE_NAME" > /dev/null 2>&1 || log_warning "Failed to remove existing image"
fi

# Build the FreeDOOM builder image
log_step "Building FreeDOOM builder container image..."
log_info "This may take several minutes as it downloads and compiles FreeDOOM from source..."

if [[ "$VERBOSE" == true ]]; then
    docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" .
else
    docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" . > /dev/null
fi

log_step "Container image built successfully"

# Run the container to build WADs
log_step "Running container to build FreeDOOM WADs..."

if [[ "$VERBOSE" == true ]]; then
    docker run --name "$CONTAINER_NAME" "$IMAGE_NAME"
else
    docker run --name "$CONTAINER_NAME" "$IMAGE_NAME" > /dev/null
fi

log_step "FreeDOOM WADs built successfully"

# Extract WAD files from the container
log_step "Extracting WAD files..."

# Create a temporary directory for extraction
TEMP_DIR=$(mktemp -d)

# Copy WADs from container
docker cp "$CONTAINER_NAME:/app/output/." "$TEMP_DIR/"

# Check if WADs were extracted
WAD_FILES=($(find "$TEMP_DIR" -name "*.wad" -type f))

if [[ ${#WAD_FILES[@]} -eq 0 ]]; then
    log_error "No WAD files found in container"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Move WADs to current directory
for wad_file in "${WAD_FILES[@]}"; do
    wad_name=$(basename "$wad_file")
    dest_path="$OUTPUT_DIR/$wad_name"
    mv "$wad_file" "$dest_path"
    
    # Get file size in MB
    size_mb=$(du -m "$dest_path" | cut -f1)
    log_info "Extracted: $wad_name (${size_mb} MB)"
done

# Clean up temp directory
rm -rf "$TEMP_DIR"

log_step "WAD files extracted to current directory"

# Clean up container and image (unless flags are set)
log_step "Cleaning up..."

if [[ "$KEEP_CONTAINER" == false ]]; then
    docker rm "$CONTAINER_NAME" > /dev/null 2>&1 && log_info "Removed container: $CONTAINER_NAME" || log_warning "Failed to remove container"
else
    log_info "Keeping container: $CONTAINER_NAME (--keep-container flag specified)"
fi

if [[ "$KEEP_IMAGE" == false ]]; then
    docker rmi "$IMAGE_NAME" > /dev/null 2>&1 && log_info "Removed image: $IMAGE_NAME" || log_warning "Failed to remove image"
else
    log_info "Keeping image: $IMAGE_NAME (--keep-image flag specified)"
fi

# Verify extracted WADs
log_step "Verifying extracted WADs..."

EXTRACTED_WADS=($(find "$OUTPUT_DIR" -maxdepth 1 -name "*freedoom*.wad" -type f))

if [[ ${#EXTRACTED_WADS[@]} -eq 0 ]]; then
    log_warning "No FreeDOOM WAD files found in output directory"
else
    echo ""
    echo -e "${GREEN}📦 Successfully extracted FreeDOOM WADs:${NC}"
    echo -e "${GREEN}==========================================${NC}"
    
    for wad in "${EXTRACTED_WADS[@]}"; do
        wad_name=$(basename "$wad")
        size_mb=$(du -m "$wad" | cut -f1)
        echo -e "${WHITE}  📁 $wad_name - ${size_mb} MB${NC}"
    done
    
    echo ""
    echo -e "${CYAN}🎯 These WADs are now ready to use with Dockermex!${NC}"
    echo -e "${WHITE}   You can reference them in your server configurations.${NC}"
fi

echo ""
log_step "FreeDOOM WAD build process completed successfully!"

# Show usage instructions
echo ""
echo -e "${YELLOW}📋 Usage Instructions:${NC}"
echo -e "${YELLOW}=====================${NC}"
echo -e "${WHITE}  • Use 'freedoom1.wad' for Doom I (Ultimate Doom) maps${NC}"
echo -e "${WHITE}  • Use 'freedoom2.wad' for Doom II maps and most PWADs${NC}"
echo -e "${WHITE}  • Update your .env file to point IWAD_FOLDER to this directory${NC}"
echo -e "${WHITE}  • Reference these WADs in your Odamex server configurations${NC}"
echo ""
