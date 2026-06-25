# E-Commerce Microservices - Deployment Documentation

## Architecture Overview

```
                    ┌─────────────────────────────────────────────┐
                    │              AWS VPC (10.0.0.0/16)          │
                    │  ┌───────────────────────────────────────┐  │
                    │  │     Public Subnet (10.0.1.0/24)       │  │
                    │  │                                       │  │
  Internet ──IGW──▶│  │   EC2 Instance (t2.medium)            │  │
                    │  │   ┌─────────────────────────────┐     │  │
                    │  │   │  Docker Engine               │     │  │
                    │  │   │                              │     │  │
                    │  │   │  ┌──────────┐ ┌───────────┐ │     │  │
  :80 ─────────────┼──┼───┼─▶│ Frontend │ │  MongoDB  │ │     │  │
                    │  │   │  │ (nginx)  │ │  (:27017) │ │     │  │
                    │  │   │  └──────────┘ └───────────┘ │     │  │
  :3001 ───────────┼──┼───┼─▶│ User Svc │               │     │  │
  :3002 ───────────┼──┼───┼─▶│ Product  │               │     │  │
  :3003 ───────────┼──┼───┼─▶│ Cart Svc │               │     │  │
  :3004 ───────────┼──┼───┼─▶│ Order Svc│               │     │  │
                    │  │   │  └──────────┘               │     │  │
                    │  │   └─────────────────────────────┘     │  │
                    │  └───────────────────────────────────────┘  │
                    └─────────────────────────────────────────────┘
```

## Prerequisites

- **AWS Account** with programmatic access (Access Key ID & Secret)
- **AWS CLI** configured (`aws configure`)
- **Terraform** >= 1.0 installed
- **Docker** installed locally (for building and pushing images)
- **DockerHub** account (free tier is fine)
- **AWS Key Pair** created in the target region (for SSH access)

---

## Step 1: Application Setup (Docker)

### 1.1 Clone the Repository

```bash
git clone https://github.com/AtharvaAI/E-CommerceStore.git
cd E-CommerceStore
```

### 1.2 Build Docker Images

Replace `<your-dockerhub-username>` with your actual DockerHub username:

```bash
# Backend services
docker build -t <your-dockerhub-username>/ecommerce-user-service    ./backend/user-service
docker build -t <your-dockerhub-username>/ecommerce-product-service ./backend/product-service
docker build -t <your-dockerhub-username>/ecommerce-cart-service    ./backend/cart-service
docker build -t <your-dockerhub-username>/ecommerce-order-service   ./backend/order-service

# Frontend
docker build -t <your-dockerhub-username>/ecommerce-frontend        ./frontend
```

### 1.3 Test Locally (Optional)

```bash
# Create network
docker network create ecommerce-test

# Start MongoDB
docker run -d --name mongodb --network ecommerce-test -p 27017:27017 mongo:6

# Start backend services
docker run -d --name user-service --network ecommerce-test -p 3001:3001 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_users \
  -e JWT_SECRET=test-secret \
  <your-dockerhub-username>/ecommerce-user-service

docker run -d --name product-service --network ecommerce-test -p 3002:3002 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_products \
  <your-dockerhub-username>/ecommerce-product-service

docker run -d --name cart-service --network ecommerce-test -p 3003:3003 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_carts \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  <your-dockerhub-username>/ecommerce-cart-service

docker run -d --name order-service --network ecommerce-test -p 3004:3004 \
  -e MONGODB_URI=mongodb://mongodb:27017/ecommerce_orders \
  -e CART_SERVICE_URL=http://cart-service:3003 \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  -e USER_SERVICE_URL=http://user-service:3001 \
  <your-dockerhub-username>/ecommerce-order-service

# Start frontend
docker run -d --name frontend --network ecommerce-test -p 80:80 \
  -e API_HOST=localhost \
  <your-dockerhub-username>/ecommerce-frontend

# Verify health endpoints
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
curl http://localhost:3004/health

# Open http://localhost in browser to see frontend
```

**Cleanup local test:**
```bash
docker stop frontend order-service cart-service product-service user-service mongodb
docker rm frontend order-service cart-service product-service user-service mongodb
docker network rm ecommerce-test
```

### 1.4 Push Images to DockerHub

```bash
docker login

docker push <your-dockerhub-username>/ecommerce-user-service
docker push <your-dockerhub-username>/ecommerce-product-service
docker push <your-dockerhub-username>/ecommerce-cart-service
docker push <your-dockerhub-username>/ecommerce-order-service
docker push <your-dockerhub-username>/ecommerce-frontend
```

---

## Step 2: Infrastructure Provisioning with Terraform

### 2.1 Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region         = "us-east-1"
instance_type      = "t2.medium"
key_name           = "your-aws-key-pair-name"
dockerhub_username = "your-dockerhub-username"
```

### 2.2 Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

### 2.3 Verify Outputs

After `terraform apply` completes, you will see:

```
Outputs:

public_ip           = "54.xxx.xxx.xxx"
public_dns          = "ec2-54-xxx-xxx-xxx.compute-1.amazonaws.com"
frontend_url        = "http://54.xxx.xxx.xxx"
user_service_health = "http://54.xxx.xxx.xxx:3001/health"
...
```

---

## Step 3: Verification

### 3.1 Wait for Deployment

The EC2 user-data script takes **3-5 minutes** to complete (Docker install + image pulls). You can SSH in to monitor:

```bash
ssh -i your-key.pem ubuntu@<public_ip>
sudo tail -f /var/log/cloud-init-output.log
```

### 3.2 Verify Backend Services

```bash
curl http://<public_ip>:3001/health   # → {"service":"User Service","status":"OK","port":3001}
curl http://<public_ip>:3002/health   # → {"service":"Product Service","status":"OK","port":3002}
curl http://<public_ip>:3003/health   # → {"service":"Cart Service","status":"OK","port":3003}
curl http://<public_ip>:3004/health   # → {"service":"Order Service","status":"OK","port":3004}
```

### 3.3 Verify Frontend

Open `http://<public_ip>` in a browser — the React e-commerce homepage should load.

### 3.4 Verify Docker Containers on EC2

```bash
ssh -i your-key.pem ubuntu@<public_ip>
docker ps    # Should show 6 containers: frontend, 4 backend services, mongodb
```

---

## Terraform Resources Summary

| Resource                | Name                  | Purpose                               |
|-------------------------|-----------------------|---------------------------------------|
| `aws_vpc`               | ecommerce-vpc         | Virtual Private Cloud (10.0.0.0/16)   |
| `aws_internet_gateway`  | ecommerce-igw         | Internet access for public subnet     |
| `aws_subnet`            | ecommerce-public-subnet | Public subnet (10.0.1.0/24)         |
| `aws_route_table`       | ecommerce-public-rt   | Routes traffic to IGW                 |
| `aws_security_group`    | ecommerce-sg          | Allows SSH, HTTP, ports 3000-3004     |
| `aws_instance`          | ecommerce-server      | EC2 running all Docker containers     |

## Port Mapping

| Service         | Container Port | Host Port | Access          |
|-----------------|---------------|-----------|-----------------|
| Frontend (nginx)| 80            | 80        | Public (HTTP)   |
| User Service    | 3001          | 3001      | Public + Internal |
| Product Service | 3002          | 3002      | Public + Internal |
| Cart Service    | 3003          | 3003      | Public + Internal |
| Order Service   | 3004          | 3004      | Public + Internal |
| MongoDB         | 27017         | 27017     | Internal only   |

## Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Containers not running | SSH into EC2, check `docker ps -a` and `docker logs <container>` |
| Frontend not accessible | Wait 3-5 min for user-data to complete; check SG rules |
| Health endpoint timeout | Verify EC2 is in `running` state; check `cloud-init-output.log` |
| Docker pull fails | Ensure images are public on DockerHub |
| Terraform apply fails | Verify AWS credentials and key pair exist in the target region |
