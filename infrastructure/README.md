# Infrastructure Setup

This directory contains everything needed to bootstrap the Portainer management infrastructure.

## Quick Start

### Option 1: Using the Setup Script (Recommended)

```bash
cd infrastructure
chmod +x setup.sh
./setup.sh
```

### Option 2: Manual Setup

```bash
cd infrastructure
docker compose up -d
```

Then access Portainer at: `http://<server-ip>:9000`

## Initial Portainer Configuration

### 1. First Login

1. Navigate to `http://<server-ip>:9000`
2. Create admin user:
   - Username: `admin`
   - Password: (choose a strong password, save in Bitwarden)
3. Click "Create user"

### 2. Connect to Local Docker

1. Select "Get Started" (connects to local Docker environment)
2. This gives Portainer access to manage containers on this host

### 3. Deploy the Soteria Stack

1. Go to **Stacks** → **Add stack**
2. Choose **Repository**
3. Fill in:
   - **Name**: `soteria-stack`
   - **Repository URL**: Your Git repository URL
     - Example: `https://github.com/yourusername/soteria_compose`
   - **Repository reference**: `main` (or your default branch)
   - **Compose path**: `docker-compose.yml`
4. Under **Environment variables**, add:
   - Load from: **Upload from file**
   - Upload your `secrets/.env` file
5. Click **Deploy the stack**

### 4. Verify Services

1. Go to **Containers** to see all running services
2. Check logs for any errors
3. Access services on their configured ports

## Portainer Data Persistence

Portainer stores its data in `/docker_data/portainer/`

This is automatically included in the main backup workflow:

```bash
# Backup all data (including Portainer)
rsync -avz /docker_data/ nas:/backups/docker_data/
```

To restore:

```bash
# Restore all data (including Portainer)
rsync -avz nas:/backups/docker_data/ /docker_data/

# Start Portainer
cd infrastructure
docker compose up -d
```

Your Portainer configuration, users, and stacks will be restored automatically.

## Updating Portainer

```bash
cd infrastructure
docker compose pull
docker compose up -d
```

## Accessing Portainer Logs

```bash
docker compose logs -f portainer
```

## Network Configuration

### Ports Used

- **9000**: Portainer Web UI (HTTPS/HTTP)
- **8000**: Edge Agent communication (optional, for remote agents)

### Firewall Rules

If using a firewall, allow:

```bash
# For local access only
sudo ufw allow from 192.168.0.0/16 to any port 9000

# For public access (use with caution, enable HTTPS)
sudo ufw allow 9000/tcp
```

## Security Recommendations

1. **Change default port**: Edit `docker-compose.yml` to use a non-standard port
2. **Enable HTTPS**: Configure SSL/TLS certificates in Portainer settings
3. **Regular backups**: Backup `/docker_data/` to NAS (includes Portainer)
4. **Strong passwords**: Store in Bitwarden
5. **Network isolation**: Use firewall rules to restrict access

## Troubleshooting

### Portainer won't start

```bash
# Check logs
docker compose logs portainer

# Check if ports are available
netstat -tlnp | grep -E '9000|8000'

# Restart
docker compose restart
```

### Can't access Portainer UI

1. Check container is running: `docker ps | grep portainer`
2. Check firewall: `sudo ufw status`
3. Verify port binding: `docker port portainer`
4. Check logs: `docker compose logs portainer`

### Lost admin password

```bash
# Stop Portainer
docker compose down

# Backup existing data first (optional)
cp -r /docker_data/portainer /docker_data/portainer.backup

# Reset by removing Portainer data
rm -rf /docker_data/portainer/*

# Start fresh
docker compose up -d
# Then reconfigure from scratch
```

## Complete Removal

To completely remove Portainer:

```bash
# Stop Portainer
cd infrastructure
docker compose down

# Remove Portainer data
rm -rf /docker_data/portainer
```

**Warning**: This deletes all Portainer configuration. Backup first if needed!

## Next Steps

After Portainer is running, return to the [main README](../README.md) to deploy the Soteria services stack.
