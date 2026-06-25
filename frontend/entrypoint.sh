#!/bin/sh
# Replace placeholder host with actual API host (EC2 public IP)
if [ -n "$API_HOST" ]; then
  find /usr/share/nginx/html -name '*.js' -exec sed -i "s|PLACEHOLDER_HOST|${API_HOST}|g" {} +
fi
exec nginx -g "daemon off;"
