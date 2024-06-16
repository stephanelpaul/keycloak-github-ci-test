#!/bin/bash

set -e

# Variables
KEYCLOAK_URL="http://localhost:8080"
REALM="test-realm"
CLIENT_ID="test-client"
CLIENT_SECRET="test-client-secret"
USERNAME="test-user"
PASSWORD="test-password"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"

# Function to get access token
get_token() {
  TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${ADMIN_USERNAME}" \
    -d "password=${ADMIN_PASSWORD}" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | jq -r '.access_token')
  echo $TOKEN
}

# Get admin access token
ADMIN_TOKEN=$(get_token)

# Create a new realm
curl -s -X POST "${KEYCLOAK_URL}/admin/realms" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
        "realm": "'"${REALM}"'",
        "enabled": true
      }'

echo "Created realm: ${REALM}"

# Create a new client
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
        "clientId": "'"${CLIENT_ID}"'",
        "secret": "'"${CLIENT_SECRET}"'",
        "enabled": true,
        "directAccessGrantsEnabled": true
      }'

echo "Created client: ${CLIENT_ID}"

# Create a new user
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
        "username": "'"${USERNAME}"'",
        "enabled": true,
        "credentials": [
          {
            "type": "password",
            "value": "'"${PASSWORD}"'",
            "temporary": false
          }
        ]
      }'

echo "Created user: ${USERNAME}"

# Verify that the user exists
USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${USERNAME}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

if [ "$USER_ID" != "null" ]; then
  echo "User ${USERNAME} exists with ID: ${USER_ID}"
else
  echo "User ${USERNAME} does not exist."
  exit 1
fi

echo "All tests passed!"
