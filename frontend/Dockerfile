# Stage 1: Build the React application
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ENV REACT_APP_USER_SERVICE_URL=http://PLACEHOLDER_HOST:3001
ENV REACT_APP_PRODUCT_SERVICE_URL=http://PLACEHOLDER_HOST:3002
ENV REACT_APP_CART_SERVICE_URL=http://PLACEHOLDER_HOST:3003
ENV REACT_APP_ORDER_SERVICE_URL=http://PLACEHOLDER_HOST:3004
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
