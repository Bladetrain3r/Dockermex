#!/bin/bash

# Dockermex Quick Setup Script
# This script prepares a fresh clone for immediate use on Ubuntu/Linux

set -e  # Exit on any error

# Default options
WITH_FREEDOOM=false
SKIP_SSL=false
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
        --with-freedoom)
            WITH_FREEDOOM=true
            shift
            ;;
        --skip-ssl)
            SKIP_SSL=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Dockermex Quick Setup Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --with-freedoom    Build FreeDOOM WADs during setup"
            echo "  --skip-ssl         Skip SSL certificate generation"
            echo "  --verbose          Show verbose output"
            echo "  --help             Show this help message"
            echo ""
            echo "This script prepares a fresh Dockermex clone for immediate use by:"
            echo "- Initializing git submodules"
            echo "- Creating .env file with secure random credentials"
            echo "- Creating required directories"
            echo "- Generating self-signed SSL certificates"
            echo "- Optionally building FreeDOOM WADs"
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
    echo -e "${GREEN}[+] $1${NC}"
}

log_info() {
    echo -e "${BLUE}[i] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

log_error() {
    echo -e "${RED}[X] $1${NC}"
}

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# Generate random password function
generate_password() {
    local length=${1:-12}
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length}
}

# Header
log_header "Dockermex Quick Setup"
log_header "====================="
echo ""

# Check if this looks like a fresh clone
if [[ ! -f ".env.template" ]]; then
    log_error "This doesn't appear to be a Dockermex repository root."
    log_info "Please run this script from the main Dockermex directory."
    exit 1
fi

# Check for required tools
log_step "Checking required tools..."

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    log_info "Ubuntu: sudo apt update && sudo apt install docker.io docker-compose-plugin"
    exit 1
fi

# Check OpenSSL for certificate generation
if ! command -v openssl &> /dev/null; then
    log_warning "OpenSSL not found. Installing..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y openssl
    else
        log_error "Cannot install OpenSSL automatically. Please install it manually."
        exit 1
    fi
fi

log_info "All required tools are available"

# 1. Initialize submodules
log_step "Initializing Git submodules..."
if command -v git &> /dev/null; then
    git submodule update --init --recursive
    log_info "Submodules initialized"
else
    log_warning "Git not found. You may need to manually initialize submodules."
fi

# 2. Create .env file with generated secrets
log_step "Creating .env file with secure defaults..."

if [[ -f ".env" ]]; then
    log_warning ".env file already exists. Backing up to .env.backup"
    cp ".env" ".env.backup"
fi

# Generate secure random values
SECRET_KEY=$(generate_password 32)
DB_SALT=$(generate_password 16)
ADMIN_PASSWORD=$(generate_password 12)

# Read template and replace values
cp ".env.template" ".env"
sed -i "s/SECRET_KEY=default/SECRET_KEY=$SECRET_KEY/" ".env"
sed -i "s/DB_SALT=default/DB_SALT=$DB_SALT/" ".env"
sed -i "s/ADMIN_PASSWORD=default/ADMIN_PASSWORD=$ADMIN_PASSWORD/" ".env"
sed -i "s/WAD_DOWNLOAD_URL=wads.foo.bar/WAD_DOWNLOAD_URL=localhost/" ".env"

log_info "Generated secure credentials:"
echo -e "${YELLOW}  Admin Password: $ADMIN_PASSWORD${NC}"
echo -e "${YELLOW}  (Save this password! You'll need it to login)${NC}"

# 3. Create required directories
log_step "Creating required directories..."

DIRECTORIES=(
    "iwads/freeware"
    "iwads/commercial"
    "pwads"
    "sqlite"
    "service-configs"
    ".ssl"
)

for dir in "${DIRECTORIES[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "Created: $dir"
    fi
done

# 4. Generate self-signed SSL certificates
if [[ "$SKIP_SSL" == false ]]; then
    log_step "Generating self-signed SSL certificates..."
    
    # Generate certificates using OpenSSL
    CERT_SUBJECT="/C=US/ST=Local/L=Local/O=Dockermex/CN=localhost"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ".ssl/private.key" \
        -out ".ssl/fullchain.crt" \
        -subj "$CERT_SUBJECT" 2>/dev/null
        
    # Copy for WAD service
    cp ".ssl/private.key" ".ssl/wads.key"
    cp ".ssl/fullchain.crt" ".ssl/wads.crt"
    
    log_info "SSL certificates generated (self-signed for localhost)"
else
    log_info "Skipping SSL certificate generation (--skip-ssl specified)"
    
    # Create placeholder files
    echo "# Placeholder - replace with real private key" > ".ssl/private.key"
    echo "# Placeholder - replace with real certificate" > ".ssl/fullchain.crt"
    cp ".ssl/private.key" ".ssl/wads.key"
    cp ".ssl/fullchain.crt" ".ssl/wads.crt"
fi

# 5. Fix file permissions
log_step "Setting correct file permissions..."
chmod 600 .ssl/* 2>/dev/null || true
chmod +x iwads/freeware/build-freedoom.sh 2>/dev/null || true
log_info "File permissions set"

# 6. Build FreeDOOM WADs if requested
if [[ "$WITH_FREEDOOM" == true ]]; then
    log_step "Building FreeDOOM WADs..."
    
    if [[ -f "iwads/freeware/build-freedoom.sh" ]]; then
        cd "iwads/freeware"
        
        if [[ "$VERBOSE" == true ]]; then
            ./build-freedoom.sh --verbose
        else
            ./build-freedoom.sh
        fi
        
        cd ../..
        log_info "FreeDOOM WADs built successfully"
    else
        log_warning "FreeDOOM build script not found"
    fi
else
    log_info "Skipping FreeDOOM build. You can build later with:"
    echo -e "${WHITE}  cd iwads/freeware && ./build-freedoom.sh${NC}"
fi

# 7. Create a simple getting started file
log_step "Creating getting started guide..."

cat > "GETTING_STARTED.md" << EOF
# Dockermex - Getting Started

Your Dockermex installation is now set up! Here's what was configured:

## Generated Credentials
- Admin Username: admin
- Admin Password: $ADMIN_PASSWORD

## What's Ready
- [x] Environment configuration (.env)
- [x] Required directories created
- [x] SSL certificates (self-signed for localhost)
$(if [[ "$WITH_FREEDOOM" == true ]]; then echo "- [x] FreeDOOM WADs built"; else echo "- [ ] WAD files (run iwads/freeware/build-freedoom.sh to build FreeDOOM)"; fi)

## Next Steps

1. **Start the webapp:**
   \`\`\`bash
   docker compose -f docker-compose-webapp-modsec.yml up -d
   \`\`\`

2. **Access the web interface:**
   - Open https://localhost:443 in your browser
   - Accept the self-signed certificate warning
   - Login with admin/$ADMIN_PASSWORD

3. **Start game servers:**
   \`\`\`bash
   docker compose -f docker-compose-odamex.yml up -d
   \`\`\`

4. **Get WADs (if you haven't built FreeDOOM):**
   - Build FreeDOOM: \`cd iwads/freeware && ./build-freedoom.sh\`
   - Or place commercial WADs in iwads/commercial/

## Troubleshooting

- If SSL issues occur, regenerate certificates or use --skip-ssl
- If containers fail to start, check Docker is running and you have permissions
- For FreeDOOM build issues, ensure Docker has internet access
- On Ubuntu, you may need to add your user to the docker group:
  \`sudo usermod -aG docker \$USER\` (then logout/login)

## Useful Commands

- **View logs:** \`docker compose logs -f\`
- **Stop services:** \`docker compose down\`
- **Rebuild containers:** \`docker compose build --no-cache\`
- **Check container status:** \`docker ps\`

Generated: $(date)
EOF

log_info "Created GETTING_STARTED.md with your credentials and next steps"

# 8. Check Docker permissions
log_step "Checking Docker permissions..."
if groups "$USER" | grep -q docker; then
    log_info "User $USER is in docker group - Docker commands should work"
else
    log_warning "User $USER is not in docker group"
    log_info "You may need to run: sudo usermod -aG docker $USER"
    log_info "Then logout and login again for changes to take effect"
fi

echo ""
log_step "Setup complete!" 
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${WHITE}  1. Start webapp: docker compose -f docker-compose-webapp-modsec.yml up -d${NC}"
echo -e "${WHITE}  2. Open: https://localhost:443${NC}"  
echo -e "${WHITE}  3. Login with admin/$ADMIN_PASSWORD${NC}"
echo ""
echo -e "${WHITE}See GETTING_STARTED.md for detailed instructions.${NC}"
echo ""

# Show system info
log_info "System Information:"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown Linux")"
echo "  Docker: $(docker --version)"
echo "  Docker Compose: $(docker compose version 2>/dev/null || echo "Not available")"
