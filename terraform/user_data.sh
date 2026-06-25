#!/bin/bash
set -e

# -----------------------------------------------
# 1. Install Docker
# -----------------------------------------------
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# -----------------------------------------------
# 2. Create Docker network
# -----------------------------------------------
docker network create ecommerce

# -----------------------------------------------
# 3. Run MongoDB container
# -----------------------------------------------
docker run -d \
  --name mongodb \
  --network ecommerce \
  -p 27017:27017 \
  mongo:6

# Wait for MongoDB to be ready
sleep 10

# -----------------------------------------------
# 4. Pull and run backend services
# -----------------------------------------------

# User Service (port 3001)
docker run -d \
  --name user-service \
  --network ecommerce \
  -p 3001:3001 \
  -e PORT=3001 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_users \
  -e JWT_SECRET=ecommerce-jwt-secret-key-2026 \
  ${dockerhub_username}/ecommerce-user-service

# Product Service (port 3002)
docker run -d \
  --name product-service \
  --network ecommerce \
  -p 3002:3002 \
  -e PORT=3002 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_products \
  ${dockerhub_username}/ecommerce-product-service

# Cart Service (port 3003)
docker run -d \
  --name cart-service \
  --network ecommerce \
  -p 3003:3003 \
  -e PORT=3003 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_carts \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  ${dockerhub_username}/ecommerce-cart-service

# Order Service (port 3004)
docker run -d \
  --name order-service \
  --network ecommerce \
  -p 3004:3004 \
  -e PORT=3004 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_orders \
  -e CART_SERVICE_URL=http://cart-service:3003 \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  -e USER_SERVICE_URL=http://user-service:3001 \
  ${dockerhub_username}/ecommerce-order-service

# -----------------------------------------------
# 5. Get public IP and run frontend
# -----------------------------------------------
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

docker run -d \
  --name frontend \
  --network ecommerce \
  -p 80:80 \
  -e API_HOST=$PUBLIC_IP \
  ${dockerhub_username}/ecommerce-frontend

echo "=== All services deployed successfully ==="
echo "Frontend: http://$PUBLIC_IP"
echo "User Service: http://$PUBLIC_IP:3001/health"
echo "Product Service: http://$PUBLIC_IP:3002/health"
echo "Cart Service: http://$PUBLIC_IP:3003/health"
echo "Order Service: http://$PUBLIC_IP:3004/health"
