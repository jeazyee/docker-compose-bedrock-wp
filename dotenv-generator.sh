#!/bin/bash

# Define the function to generate a random string
function generate_random_string() {
  openssl rand -base64 64 | tr -d '\n'
}

# Define the environment variable values
AUTH_KEY=$(generate_random_string)
SECURE_AUTH_KEY=$(generate_random_string)
LOGGED_IN_KEY=$(generate_random_string)
NONCE_KEY=$(generate_random_string)
AUTH_SALT=$(generate_random_string)
SECURE_AUTH_SALT=$(generate_random_string)
LOGGED_IN_SALT=$(generate_random_string)
NONCE_SALT=$(generate_random_string)

# Create the .env file with the environment variable values
cat > .env <<EOF
AUTH_KEY='$AUTH_KEY'
SECURE_AUTH_KEY='$SECURE_AUTH_KEY'
LOGGED_IN_KEY='$LOGGED_IN_KEY'
NONCE_KEY='$NONCE_KEY'
AUTH_SALT='$AUTH_SALT'
SECURE_AUTH_SALT='$SECURE_AUTH_SALT'
LOGGED_IN_SALT='$LOGGED_IN_SALT'
NONCE_SALT='$NONCE_SALT'
EOF

echo ".env file has been created successfully."
