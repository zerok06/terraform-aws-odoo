#!/bin/bash

# Exit on any error and enable logging
set -e
exec > >(tee /var/log/odoo-docker-install.log) 2>&1

echo "=========================================="
echo "Starting Odoo Docker installation script"
echo "Date: $(date)"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
sudo apt update -y

# Install required packages
echo "Installing required packages..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
echo "Installing Docker..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add ubuntu user to docker group
echo "Adding ubuntu user to docker group..."
sudo usermod -aG docker ubuntu

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directories for Odoo
echo "Creating Odoo directories..."
sudo mkdir -p /opt/odoo
sudo mkdir -p /opt/odoo/addons
sudo mkdir -p /opt/odoo/config

# Set proper permissions
sudo chown -R ubuntu:ubuntu /opt/odoo

# Create Odoo configuration file
echo "Creating Odoo configuration..."
cat > /opt/odoo/config/odoo.conf << 'ODOO_CONFIG'
[options]
admin_passwd = StrongMasterPassword123
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo
addons_path = /mnt/extra-addons
logfile = /var/log/odoo/odoo-server.log
logrotate = True
ODOO_CONFIG

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > /opt/odoo/docker-compose.yml << 'DOCKER_COMPOSE'
version: '3.8'
services:
  web:
    image: odoo:17.0
    depends_on:
      - db
    ports:
      - "80:8069"
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo
    restart: unless-stopped
    networks:
      - odoo-network

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo-db-data:/var/lib/postgresql/data/pgdata
    restart: unless-stopped
    networks:
      - odoo-network

volumes:
  odoo-web-data:
  odoo-db-data:

networks:
  odoo-network:
    driver: bridge
DOCKER_COMPOSE

# Start Docker services
echo "Starting Docker services..."
cd /opt/odoo
sudo docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 60

# Create health check script
echo "Creating health check script..."
cat > /usr/local/bin/odoo-docker-health-check << 'HEALTH_CHECK'
#!/bin/bash
if curl -s http://localhost:80 > /dev/null; then
    echo "Odoo is running on port 80"
    exit 0
else
    echo "Odoo is not responding on port 80"
    exit 1
fi
HEALTH_CHECK

sudo chmod +x /usr/local/bin/odoo-docker-health-check

# Create systemd service for docker-compose
echo "Creating systemd service for docker-compose..."
sudo tee /etc/systemd/system/odoo-docker.service << 'SYSTEMD_SERVICE'
[Unit]
Description=Odoo Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/odoo
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SYSTEMD_SERVICE

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable odoo-docker
sudo systemctl start odoo-docker

# Display final information
echo "=========================================="
echo "Odoo Docker installation completed successfully!"
echo "=========================================="
echo ""
echo "Access URLs:"
echo "  Odoo: http://$(curl -s ifconfig.me)"
echo ""
echo "Default credentials:"
echo "  Database: odoo"
echo "  Email: admin"
echo "  Password: admin"
echo ""
echo "SSH connection:"
echo "  ssh -i ./.ssh/terraform_rsa.pem ubuntu@$(curl -s ifconfig.me)"
echo ""
echo "Docker commands:"
echo "  View logs: sudo docker-compose -f /opt/odoo/docker-compose.yml logs"
echo "  Restart: sudo docker-compose -f /opt/odoo/docker-compose.yml restart"
echo "  Stop: sudo docker-compose -f /opt/odoo/docker-compose.yml down"
echo ""
echo "Systemd service:"
echo "  Status: sudo systemctl status odoo-docker"
echo "  Restart: sudo systemctl restart odoo-docker"
echo ""
echo "Logs:"
echo "  Odoo logs: sudo docker logs odoo_web_1"
echo "  PostgreSQL logs: sudo docker logs odoo_db_1"
echo "  Installation log: sudo tail -f /var/log/odoo-docker-install.log"