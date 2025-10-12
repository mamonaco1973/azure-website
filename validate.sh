#!/bin/bash
# ================================================================================================
# Wait for HTTP 200 from website (ignores SSL errors)
# ================================================================================================

cd ./01-website
DOMAIN=$(terraform console <<< "var.domain_name" | tr -d '"')
cd ..
URL="https://www.${DOMAIN}"

echo "NOTE: Waiting for $URL to return HTTP 200..."

while true; do
  # Perform curl with:
  # -k : ignore SSL certificate validation errors
  # -s : silent mode (no progress)
  # -o /dev/null : discard body
  # -w "%{http_code}" : print HTTP status code only
  STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$URL")

  if [ "$STATUS" -eq 200 ]; then
    echo "NOTE: URL is now reachable: $URL"
    break
  else
    echo "WARNING: $URL not available yet... (Status: $STATUS)"
    echo "WARNING: Waiting 1 minute before retrying..."
    sleep 60
  fi
done
