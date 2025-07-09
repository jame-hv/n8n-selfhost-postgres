#!/bin/bash

# n8n Enterprise Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
check_env() {
    if [ ! -f .env ]; then
        log_warning ".env file not found. Creating from template..."
        cp .env.example .env
        log_info "Please edit .env file with your configuration before starting services"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check if openssl is available for key generation
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL is not installed. Please install OpenSSL for key generation."
        exit 1
    fi
    
    log_success "All prerequisites are met!"
}

# Create data directories
create_directories() {
    log_info "Creating data directories..."
    
    mkdir -p data/postgres/data data/redis/data data/n8n
    touch data/postgres/.gitkeep data/redis/.gitkeep data/n8n/.gitkeep
    touch data/postgres/data/.gitkeep data/redis/data/.gitkeep
    
    # Set proper permissions
    chmod 755 data data/postgres data/redis data/n8n
    chmod 755 data/postgres/data data/redis/data
    
    log_success "Data directories created successfully!"
}

# Generate secure keys
generate_keys() {
    log_info "Generating secure encryption keys..."
    
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 32)
    
    echo ""
    echo "Generated keys (add these to your .env file):"
    echo "N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY"
    echo "N8N_JWT_SECRET=$JWT_SECRET"
    echo ""
    
    # Return the keys for auto-setup
    echo "$ENCRYPTION_KEY|$JWT_SECRET"
}

# Auto setup function
setup() {
    log_info "Starting n8n Enterprise auto-setup..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Create directories
    create_directories
    echo ""
    
    # Check if .env already exists
    if [ -f .env ]; then
        log_warning ".env file already exists!"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled. Using existing .env file."
            return
        fi
    fi
    
    # Copy template
    if [ ! -f .env.example ]; then
        log_error ".env.example not found! Please make sure all files are present."
        exit 1
    fi
    
    cp .env.example .env
    log_success ".env file created from template!"
    echo ""
    
    # Generate encryption keys automatically
    log_info "Generating encryption keys..."
    KEYS=$(generate_keys | tail -n 1)
    ENCRYPTION_KEY=$(echo "$KEYS" | cut -d'|' -f1)
    JWT_SECRET=$(echo "$KEYS" | cut -d'|' -f2)
    echo ""
    
    # Interactive configuration
    log_info "Let's configure your n8n Enterprise setup..."
    echo ""
    
    # Database password
    echo -n "Enter PostgreSQL password (or press Enter for random): "
    read -s POSTGRES_PASS
    echo
    if [ -z "$POSTGRES_PASS" ]; then
        POSTGRES_PASS=$(openssl rand -base64 16)
        log_info "Generated random PostgreSQL password"
    fi
    
    # Domain configuration
    echo -n "Enter your domain name (or press Enter for localhost): "
    read DOMAIN
    if [ -z "$DOMAIN" ]; then
        DOMAIN="localhost"
        PROTOCOL="http"
        WEBHOOK_URL="http://localhost:5678"
        SECURE_COOKIE="false"
    else
        PROTOCOL="https"
        WEBHOOK_URL="https://$DOMAIN"
        SECURE_COOKIE="true"
    fi
    
    # Enterprise license
    echo -n "Enter your n8n Enterprise license key (required): "
    read -s LICENSE_KEY
    echo
    if [ -z "$LICENSE_KEY" ]; then
        log_warning "No license key provided. You can add it later in the .env file."
        LICENSE_KEY="your_enterprise_license_key_here"
    fi
    
    # Email configuration
    echo ""
    log_info "Email configuration (optional - press Enter to skip):"
    echo -n "SMTP Host: "
    read SMTP_HOST
    echo -n "SMTP Port (587): "
    read SMTP_PORT
    if [ -z "$SMTP_PORT" ]; then
        SMTP_PORT="587"
    fi
    echo -n "SMTP User: "
    read SMTP_USER
    echo -n "SMTP Password: "
    read -s SMTP_PASS
    echo
    echo -n "Sender Email: "
    read SMTP_SENDER
    
    # Update .env file with user inputs
    log_info "Updating configuration file..."
    
    # Escape special characters for safe sed replacement
    escape_for_sed() {
        printf '%s\n' "$1" | sed 's/[[\.*^$()+?{|]/\\&/g'
    }
    
    # Escape variables
    POSTGRES_PASS_ESC=$(escape_for_sed "$POSTGRES_PASS")
    ENCRYPTION_KEY_ESC=$(escape_for_sed "$ENCRYPTION_KEY")
    JWT_SECRET_ESC=$(escape_for_sed "$JWT_SECRET")
    LICENSE_KEY_ESC=$(escape_for_sed "$LICENSE_KEY")
    DOMAIN_ESC=$(escape_for_sed "$DOMAIN")
    WEBHOOK_URL_ESC=$(escape_for_sed "$WEBHOOK_URL")
    
    # Use different sed syntax for macOS and use | as delimiter to avoid conflicts
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|your_secure_postgres_password_here|$POSTGRES_PASS_ESC|g" .env
        sed -i '' "s|your_32_character_encryption_key_here|$ENCRYPTION_KEY_ESC|g" .env
        sed -i '' "s|your_jwt_secret_here|$JWT_SECRET_ESC|g" .env
        sed -i '' "s|your_enterprise_license_key_here|$LICENSE_KEY_ESC|g" .env
        sed -i '' "s|N8N_HOST=localhost|N8N_HOST=$DOMAIN_ESC|g" .env
        sed -i '' "s|N8N_PROTOCOL=http|N8N_PROTOCOL=$PROTOCOL|g" .env
        sed -i '' "s|WEBHOOK_URL=http://localhost:5678|WEBHOOK_URL=$WEBHOOK_URL_ESC|g" .env
        sed -i '' "s|N8N_SECURE_COOKIE=false|N8N_SECURE_COOKIE=$SECURE_COOKIE|g" .env
        
        if [ -n "$SMTP_HOST" ]; then
            SMTP_HOST_ESC=$(escape_for_sed "$SMTP_HOST")
            SMTP_USER_ESC=$(escape_for_sed "$SMTP_USER")
            SMTP_PASS_ESC=$(escape_for_sed "$SMTP_PASS")
            SMTP_SENDER_ESC=$(escape_for_sed "$SMTP_SENDER")
            
            sed -i '' "s|smtp.gmail.com|$SMTP_HOST_ESC|g" .env
            sed -i '' "s|N8N_SMTP_PORT=587|N8N_SMTP_PORT=$SMTP_PORT|g" .env
            sed -i '' "s|your_email@domain.com|$SMTP_USER_ESC|g" .env
            sed -i '' "s|your_app_password|$SMTP_PASS_ESC|g" .env
            # Update sender email (appears twice, so target the sender line specifically)
            sed -i '' "s|N8N_SMTP_SENDER=your_email@domain.com|N8N_SMTP_SENDER=$SMTP_SENDER_ESC|g" .env
        fi
    else
        # Linux
        sed -i "s|your_secure_postgres_password_here|$POSTGRES_PASS_ESC|g" .env
        sed -i "s|your_32_character_encryption_key_here|$ENCRYPTION_KEY_ESC|g" .env
        sed -i "s|your_jwt_secret_here|$JWT_SECRET_ESC|g" .env
        sed -i "s|your_enterprise_license_key_here|$LICENSE_KEY_ESC|g" .env
        sed -i "s|N8N_HOST=localhost|N8N_HOST=$DOMAIN_ESC|g" .env
        sed -i "s|N8N_PROTOCOL=http|N8N_PROTOCOL=$PROTOCOL|g" .env
        sed -i "s|WEBHOOK_URL=http://localhost:5678|WEBHOOK_URL=$WEBHOOK_URL_ESC|g" .env
        sed -i "s|N8N_SECURE_COOKIE=false|N8N_SECURE_COOKIE=$SECURE_COOKIE|g" .env
        
        if [ -n "$SMTP_HOST" ]; then
            SMTP_HOST_ESC=$(escape_for_sed "$SMTP_HOST")
            SMTP_USER_ESC=$(escape_for_sed "$SMTP_USER")
            SMTP_PASS_ESC=$(escape_for_sed "$SMTP_PASS")
            SMTP_SENDER_ESC=$(escape_for_sed "$SMTP_SENDER")
            
            sed -i "s|smtp.gmail.com|$SMTP_HOST_ESC|g" .env
            sed -i "s|N8N_SMTP_PORT=587|N8N_SMTP_PORT=$SMTP_PORT|g" .env
            sed -i "s|your_email@domain.com|$SMTP_USER_ESC|g" .env
            sed -i "s|your_app_password|$SMTP_PASS_ESC|g" .env
            # Update sender email (appears twice, so target the sender line specifically)
            sed -i "s|N8N_SMTP_SENDER=your_email@domain.com|N8N_SMTP_SENDER=$SMTP_SENDER_ESC|g" .env
        fi
    fi
    
    log_success "Configuration completed!"
    echo ""
    
    # Ask if user wants to start services now
    read -p "Do you want to start the services now? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Setup completed! Run './manage.sh start' when ready."
    else
        echo ""
        start
        echo ""
        log_success "Setup completed successfully!"
        echo ""
        log_info "Next steps:"
        echo "1. Open your browser and go to: $WEBHOOK_URL"
        echo "2. Follow the setup wizard to create your admin account"
        echo "3. Start inviting team members!"
        echo ""
        if [ "$DOMAIN" != "localhost" ]; then
            log_warning "For production deployment with domain '$DOMAIN':"
            echo "- Make sure your domain points to this server"
            echo "- Set up SSL certificates (recommended: Let's Encrypt)"
            echo "- Configure a reverse proxy (nginx/Traefik)"
        fi
    fi
}

# Start services
start() {
    check_env
    log_info "Starting n8n Enterprise stack..."
    docker-compose up -d
    log_success "Services started successfully!"
    echo ""
    log_info "n8n will be available at: http://localhost:5678"
    log_info "Use 'docker-compose logs -f' to view logs"
}

# Stop services
stop() {
    log_info "Stopping n8n Enterprise stack..."
    docker-compose down
    log_success "Services stopped successfully!"
}

# Restart services
restart() {
    log_info "Restarting n8n Enterprise stack..."
    docker-compose restart
    log_success "Services restarted successfully!"
}

# View logs
logs() {
    if [ -n "$1" ]; then
        docker-compose logs -f "$1"
    else
        docker-compose logs -f
    fi
}

# Show status
status() {
    log_info "Service status:"
    docker-compose ps
}

# Backup database
backup() {
    log_info "Creating database backup..."
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    docker-compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_FILE"
    log_success "Database backup created: $BACKUP_FILE"
}

# Restore database
restore() {
    if [ -z "$1" ]; then
        log_error "Please specify backup file: ./manage.sh restore backup_20240101_120000.sql"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        log_error "Backup file not found: $1"
        exit 1
    fi
    
    log_warning "This will overwrite the current database!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Stopping n8n to restore database..."
        docker-compose stop n8n n8n-worker
        
        log_info "Restoring database from: $1"
        docker-compose exec -T postgres psql -U n8n n8n < "$1"
        
        log_info "Starting services..."
        docker-compose start n8n n8n-worker
        
        log_success "Database restored successfully!"
    else
        log_info "Restore cancelled"
    fi
}

# Scale workers
scale() {
    if [ -z "$1" ]; then
        log_error "Please specify number of workers: ./manage.sh scale 3"
        exit 1
    fi
    
    log_info "Scaling workers to $1 replicas..."
    docker-compose up -d --scale n8n-worker="$1"
    log_success "Workers scaled to $1 replicas"
}

# Update images
update() {
    log_info "Updating Docker images..."
    docker-compose pull
    docker-compose up -d
    log_success "Images updated successfully!"
}

# Clean up
cleanup() {
    log_warning "This will remove all containers, networks, and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down -v
        docker system prune -f
        log_success "Cleanup completed!"
    else
        log_info "Cleanup cancelled"
    fi
}

# Show help
help() {
    echo "n8n Enterprise Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup       Auto-setup n8n Enterprise (interactive)"
    echo "  start       Start all services"
    echo "  stop        Stop all services"
    echo "  restart     Restart all services"
    echo "  status      Show service status"
    echo "  logs [svc]  Show logs (optionally for specific service)"
    echo "  backup      Create database backup"
    echo "  restore <f> Restore database from backup file"
    echo "  scale <n>   Scale workers to n replicas"
    echo "  update      Update Docker images"
    echo "  keys        Generate encryption keys"
    echo "  cleanup     Remove all containers and volumes"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 start"
    echo "  $0 logs n8n"
    echo "  $0 scale 4"
    echo "  $0 backup"
    echo "  $0 restore backup_20240101_120000.sql"
}

# Main script logic
case "$1" in
    setup)
        setup
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$2"
        ;;
    backup)
        backup
        ;;
    restore)
        restore "$2"
        ;;
    scale)
        scale "$2"
        ;;
    update)
        update
        ;;
    keys)
        generate_keys
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        help
        ;;
    *)
        if [ -z "$1" ]; then
            log_info "Welcome to n8n Enterprise Management!"
            echo ""
            log_info "For first-time setup, run: $0 setup"
            echo ""
            help
        else
            log_error "Unknown command: $1"
            echo ""
            help
        fi
        exit 1
        ;;
esac
