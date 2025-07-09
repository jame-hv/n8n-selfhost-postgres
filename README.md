# n8n Enterprise Docker Compose Setup

This repository contains a production-ready Docker Compose configuration for n8n Enterprise with PostgreSQL and Redis.

## Features

- **n8n Enterprise** - Latest version with enterprise features
- **PostgreSQL 15** - Primary database with optimized settings
- **Redis 7** - Queue management and caching
- **Queue Mode** - Separate worker processes for better performance
- **Health Checks** - Proper health monitoring for all services
- **Data Persistence** - All data stored in `./data/` directory
- **Production Ready** - Optimized for production environments

## Quick Start

1. **Copy environment file:**

   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file:**

   - Set strong passwords for `POSTGRES_PASSWORD`
   - Generate secure keys for `N8N_ENCRYPTION_KEY` and `N8N_JWT_SECRET`
   - Add your enterprise license key to `N8N_LICENSE_KEY`
   - Configure other settings as needed

3. **Generate encryption keys:**

   ```bash
   # Generate encryption key
   openssl rand -base64 32

   # Generate JWT secret
   openssl rand -base64 32
   ```

4. **Start the services:**

   ```bash
   docker-compose up -d
   ```

5. **Access n8n:**
   - Open http://localhost:5678 in your browser
   - Follow the setup wizard to create your first admin user

## Directory Structure

```
n8n/
├── docker-compose.yaml     # Main compose file
├── .env                   # Environment variables (create from .env.example)
├── .env.example          # Environment template
├── data/                 # Persistent data
│   ├── postgres/         # PostgreSQL data
│   ├── redis/           # Redis data
│   └── n8n/             # n8n data (workflows, credentials, etc.)
└── README.md            # This file
```

## Configuration

### Environment Variables

| Variable             | Description                   | Required |
| -------------------- | ----------------------------- | -------- |
| `POSTGRES_PASSWORD`  | PostgreSQL password           | ✅       |
| `N8N_ENCRYPTION_KEY` | n8n encryption key (32 chars) | ✅       |
| `N8N_JWT_SECRET`     | JWT secret for user sessions  | ✅       |
| `N8N_LICENSE_KEY`    | Enterprise license key        | ✅       |
| `N8N_HOST`           | Domain name for n8n           | ✅       |
| `N8N_PROTOCOL`       | http or https                 | ✅       |
| `WEBHOOK_URL`        | Full webhook URL              | ✅       |

### Production Deployment

For production deployment, consider:

1. **SSL/TLS**: Use a reverse proxy (nginx, Traefik) with SSL certificates
2. **Domain**: Set proper domain name in `N8N_HOST`
3. **Security**: Enable secure cookies, use strong passwords
4. **Monitoring**: Add monitoring and alerting
5. **Backups**: Regular database and data backups
6. **Scaling**: Increase worker replicas based on load

### Example nginx reverse proxy config:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Management Commands

### Start services:

```bash
docker-compose up -d
```

### Stop services:

```bash
docker-compose down
```

### View logs:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
```

### Restart services:

```bash
docker-compose restart
```

### Scale workers:

```bash
docker-compose up -d --scale n8n-worker=4
```

### Database backup:

```bash
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql
```

### Database restore:

```bash
docker-compose exec -T postgres psql -U n8n n8n < backup.sql
```

## Monitoring

Health checks are configured for all services:

- PostgreSQL: `pg_isready` check
- Redis: `redis-cli ping` check
- n8n: HTTP health endpoint check

Check service status:

```bash
docker-compose ps
```

## Troubleshooting

### Common Issues:

1. **Permission issues**: Make sure the `data/` directory is writable
2. **Port conflicts**: Change `N8N_PORT` if 5678 is already in use
3. **Memory issues**: Increase Docker memory limits for better performance
4. **License issues**: Verify your enterprise license key is valid

### Useful Commands:

```bash
# Check service health
docker-compose ps

# View detailed logs
docker-compose logs -f --tail=100

# Execute commands in containers
docker-compose exec n8n bash
docker-compose exec postgres psql -U n8n n8n

# Reset everything (WARNING: deletes all data)
docker-compose down -v
sudo rm -rf data/
```

## Security Considerations

- Change all default passwords
- Use strong encryption keys
- Enable HTTPS in production
- Regularly update Docker images
- Monitor for security updates
- Implement proper firewall rules
- Use secrets management for sensitive data

## Support

For n8n Enterprise support, contact the n8n team or check the official documentation at https://docs.n8n.io/
