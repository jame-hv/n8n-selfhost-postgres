# n8n Docker Setup with Traefik and PostgreSQL

This setup provides a production-ready n8n installation with:

- **Traefik** as reverse proxy with automatic SSL certificates
- **PostgreSQL** as database
- **Optimized for t2.micro** AWS instances (1GB RAM)

## Quick Start

1. **Setup environment variables:**

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Edit .env file** and update:

   ```bash
   DOMAIN_NAME=yourdomain.com
   SUBDOMAIN=n8n
   SSL_EMAIL=your@email.com
   ```

3. **Create required directories:**

   ```bash
   mkdir -p docker/postgres/data docker/n8n
   ```

4. **Set up DNS:**

   - Create an A record for `n8n.yourdomain.com` pointing to your server's IP

5. **Deploy:**

   ```bash
   docker compose up -d
   ```

6. **Access n8n:**
   - Visit `https://n8n.yourdomain.com`
   - Create your first admin user

## Configuration

### Memory Optimization for t2.micro

- PostgreSQL: 128MB limit, 64MB reserved
- n8n: 384MB limit, 256MB reserved
- Node.js heap: 512MB max
- Limited PostgreSQL connections: 5
- Single execution concurrency

### Security Features

- Automatic SSL certificates via Let's Encrypt
- Secure cookies enabled
- Environment access blocked in nodes
- Settings file permissions enforced

### Data Persistence

- PostgreSQL data: `./docker/postgres/data`
- n8n data: `./docker/n8n`
- Shared files: `./local-files` (mounted as `/files` in n8n)
- SSL certificates: Docker volume `traefik_data`

## Monitoring

Check service status:

```bash
docker compose ps
docker compose logs -f n8n
docker compose logs -f postgres
docker compose logs -f traefik
```

## Troubleshooting

### Permission Issues

The setup includes automatic `chown` for n8n data directory.

### SSL Certificate Issues

- Ensure DNS points to your server
- Check Traefik logs: `docker compose logs traefik`
- Verify port 80/443 are accessible

### Memory Issues

- Monitor with: `docker stats`
- Adjust resource limits in docker-compose.yaml if needed

## Environment Variables

| Variable             | Description         | Default            |
| -------------------- | ------------------- | ------------------ |
| `DOMAIN_NAME`        | Your domain         | `example.com`      |
| `SUBDOMAIN`          | n8n subdomain       | `n8n`              |
| `SSL_EMAIL`          | Email for SSL certs | Required           |
| `POSTGRES_PASSWORD`  | DB password         | Auto-generated     |
| `N8N_ENCRYPTION_KEY` | n8n encryption      | Auto-generated     |
| `N8N_JWT_SECRET`     | JWT secret          | Auto-generated     |
| `TIMEZONE`           | System timezone     | `Asia/Ho_Chi_Minh` |

## Updating

```bash
docker compose pull
docker compose up -d
```

## Backup

```bash
# Database backup
docker compose exec postgres pg_dump -U n8n n8n > backup.sql

# Data backup
tar -czf n8n-backup.tar.gz docker/ local-files/
```
