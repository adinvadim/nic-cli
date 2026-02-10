#!/bin/bash
# NIC.RU OAuth2 authentication helper
# Usage: source auth.sh && get_nic_token

set -e

SECRETS_DIR="${HOME}/.openclaw/workspace/.secrets"
CREDENTIALS_FILE="${SECRETS_DIR}/nic-ru-credentials"
TOKEN_FILE="${SECRETS_DIR}/nic-ru-token.json"

# Load credentials from file or environment
load_credentials() {
    if [[ -f "$CREDENTIALS_FILE" ]]; then
        source "$CREDENTIALS_FILE"
    fi
    
    if [[ -z "$NIC_APP_LOGIN" || -z "$NIC_APP_PASSWORD" || -z "$NIC_USERNAME" || -z "$NIC_PASSWORD" ]]; then
        echo "Error: Missing NIC.RU credentials" >&2
        echo "Set environment variables or create ${CREDENTIALS_FILE} with:" >&2
        echo "  NIC_APP_LOGIN=your_app_login" >&2
        echo "  NIC_APP_PASSWORD=your_app_password" >&2
        echo "  NIC_USERNAME=your_nic_username" >&2
        echo "  NIC_PASSWORD=your_nic_password" >&2
        return 1
    fi
}

# Get OAuth2 token from NIC.RU
get_nic_token() {
    load_credentials || return 1
    
    local response
    response=$(curl -s -X POST "https://api.nic.ru/oauth/token" \
        -u "${NIC_APP_LOGIN}:${NIC_APP_PASSWORD}" \
        -d "grant_type=password" \
        -d "username=${NIC_USERNAME}" \
        -d "password=${NIC_PASSWORD}" \
        -d "scope=(GET|PUT|POST|DELETE):/dns-master/.+")
    
    local token
    token=$(echo "$response" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    
    if [[ -z "$token" ]]; then
        echo "Error: Failed to get token" >&2
        echo "Response: $response" >&2
        return 1
    fi
    
    # Save token
    mkdir -p "$SECRETS_DIR"
    local expires_at
    expires_at=$(date -v+1H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -d "+1 hour" +%Y-%m-%dT%H:%M:%S)
    
    cat > "$TOKEN_FILE" <<EOF
{
  "access_token": "$token",
  "expires_at": "$expires_at",
  "saved_at": "$(date +%Y-%m-%dT%H:%M:%S)"
}
EOF
    chmod 600 "$TOKEN_FILE"
    
    echo "$token"
}

# Read saved token
read_token() {
    if [[ -f "$TOKEN_FILE" ]]; then
        grep -o '"access_token":"[^"]*' "$TOKEN_FILE" | cut -d'"' -f4
    fi
}

# Interactive setup
setup_credentials() {
    echo "NIC.RU API Credentials Setup"
    echo "============================"
    echo
    echo "You need OAuth2 application credentials from NIC.RU."
    echo "Get them at: https://www.nic.ru/manager/oauth.cgi"
    echo
    
    read -p "App Login: " app_login
    read -sp "App Password: " app_password
    echo
    read -p "NIC Username: " username  
    read -sp "NIC Password: " password
    echo
    
    mkdir -p "$SECRETS_DIR"
    cat > "$CREDENTIALS_FILE" <<EOF
NIC_APP_LOGIN=$app_login
NIC_APP_PASSWORD=$app_password
NIC_USERNAME=$username
NIC_PASSWORD=$password
EOF
    chmod 600 "$CREDENTIALS_FILE"
    
    echo
    echo "✓ Credentials saved to $CREDENTIALS_FILE"
    echo "  Now run: nic-dns auth"
}

# If run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        setup)
            setup_credentials
            ;;
        token)
            get_nic_token
            ;;
        read)
            read_token
            ;;
        *)
            echo "Usage: $0 {setup|token|read}"
            echo "  setup - Interactive credential setup"
            echo "  token - Get new OAuth token"
            echo "  read  - Read saved token"
            ;;
    esac
fi
