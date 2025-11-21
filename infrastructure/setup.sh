#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        echo "Please install Docker first:"
        echo "  curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    print_success "Docker is installed"
}

# Check if Docker Compose is available
check_docker_compose() {
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available!"
        echo "Please install Docker Compose plugin"
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Check if Portainer is already running
check_existing_portainer() {
    if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
        print_warning "Portainer container already exists!"
        read -p "Do you want to remove and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down
            print_success "Removed existing Portainer"
        else
            print_info "Keeping existing Portainer. Exiting."
            exit 0
        fi
    fi
}

# Get server IP
get_server_ip() {
    # Try to get primary network interface IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="localhost"
    fi
    echo "$SERVER_IP"
}

# Main setup
main() {
    print_header "Portainer Setup for Soteria Stack"

    # Pre-flight checks
    print_info "Running pre-flight checks..."
    check_docker
    check_docker_compose
    check_existing_portainer

    # Deploy Portainer
    print_header "Deploying Portainer"
    docker compose up -d

    # Wait for Portainer to be ready
    print_info "Waiting for Portainer to start..."
    sleep 5

    # Check if running
    if docker ps | grep -q portainer; then
        print_success "Portainer is running!"
    else
        print_error "Portainer failed to start. Check logs with: docker compose logs portainer"
        exit 1
    fi

    # Get server IP
    SERVER_IP=$(get_server_ip)

    # Print success message
    print_header "Setup Complete!"
    echo -e "${GREEN}Portainer is now running!${NC}\n"

    echo "Next steps:"
    echo "1. Access Portainer Web UI:"
    echo -e "   ${BLUE}http://${SERVER_IP}:9000${NC}"
    echo ""
    echo "2. Create your admin account (first time only)"
    echo "   - Username: admin"
    echo "   - Password: (create a strong password)"
    echo "   - Save password in Bitwarden!"
    echo ""
    echo "3. Select 'Get Started' to connect to local Docker"
    echo ""
    echo "4. Deploy the Soteria stack:"
    echo "   - Go to Stacks → Add Stack → Repository"
    echo "   - Add your Git repository URL"
    echo "   - Set compose path: docker-compose.yml"
    echo "   - Upload secrets/.env file as environment variables"
    echo "   - Deploy!"
    echo ""
    print_info "For detailed instructions, see infrastructure/README.md"

    # Show logs option
    echo ""
    read -p "Do you want to view Portainer logs? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose logs -f portainer
    fi
}

# Run main function
main
