# n8n Docker Setup with Traefik

This setup provides a production-ready n8n installation with:

- **Traefik** as reverse proxy with automatic SSL certificates
- **External PostgreSQL** database support
- **Production-ready** configuration with SSL and security features

## Quick Start

1. **Create .env file:**

   ```bash
   cp .env.example .env
   ```

   Or create a new .env file with the following content:

   ```bash
   DOMAIN_NAME=yourdomain.com
   SSL_EMAIL=your@email.com
   POSTGRES_HOST=your-postgres-host
   POSTGRES_DB=n8n
   POSTGRES_USER=n8n
   POSTGRES_PASSWORD=your-secure-password
   GENERIC_TIMEZONE=America/New_York
   ```

2. **Edit .env file** and update the values according to your setup.

3. **Create required directories:**

   ```bash
   mkdir -p local-files
   ```

4. **Set up external PostgreSQL database:**

   - Ensure you have a PostgreSQL server accessible from your Docker host
   - Create a database and user for n8n
   - Update the environment variables in your .env file

5. **Set up DNS:**

   - Create an A record for your domain pointing to your server's IP

6. **Deploy:**

   ```bash
   docker compose up -d
   ```

7. **Access n8n:**
   - Visit `https://yourdomain.com`
   - Create your first admin user

## Configuration

### Services

- **Traefik**: Reverse proxy with automatic SSL certificates from Let's Encrypt
- **n8n**: Workflow automation tool with PostgreSQL database support

### Security Features

- Automatic SSL certificates via Let's Encrypt
- HTTPS redirect for all traffic
- Security headers (HSTS, XSS protection, etc.)
- SSL certificate resolver with TLS challenge

### Data Persistence

- n8n data: Docker volume `n8n_data`
- Shared files: `./local-files` (mounted as `/files` in n8n)
- SSL certificates: Docker volume `traefik_data`
- Database: External PostgreSQL (not included in this setup)

## Monitoring

Check service status:

```bash
docker compose ps
docker compose logs -f n8n
docker compose logs -f traefik
```

## Troubleshooting

### Database Connection Issues

- Verify PostgreSQL server is accessible from Docker host
- Check database credentials in .env file
- Ensure PostgreSQL allows SSL connections

### SSL Certificate Issues

- Ensure DNS points to your server
- Check Traefik logs: `docker compose logs traefik`
- Verify port 80/443 are accessible

### Container Issues

- Monitor with: `docker stats`
- Check logs: `docker compose logs [service-name]`

## Environment Variables

| Variable            | Description                | Default    | Required |
| ------------------- | -------------------------- | ---------- | -------- |
| `DOMAIN_NAME`       | Your domain name           | -          | Yes      |
| `SSL_EMAIL`         | Email for SSL certificates | -          | Yes      |
| `POSTGRES_HOST`     | PostgreSQL host            | `postgres` | Yes      |
| `POSTGRES_DB`       | PostgreSQL database name   | `n8n`      | No       |
| `POSTGRES_USER`     | PostgreSQL username        | `n8n`      | No       |
| `POSTGRES_PASSWORD` | PostgreSQL password        | `n8n`      | Yes      |
| `GENERIC_TIMEZONE`  | System timezone            | -          | Yes      |

## Updating

```bash
docker compose pull
docker compose up -d
```

## Backup

```bash
# Database backup (run on PostgreSQL server)
pg_dump -h your-postgres-host -U n8n n8n > backup.sql

# n8n data backup
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-data-backup.tar.gz -C /data .

# Local files backup
tar -czf local-files-backup.tar.gz local-files/
```
