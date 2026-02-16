#!/bin/bash

# Installer script for apt package update email notification system
# This script sets up the mailing software, environment file, and cron job

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

echo "==================================="
echo "APT Package Update Email Installer"
echo "==================================="
echo ""

# Check if running with appropriate privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges to install packages and set up cron jobs."
    echo "Please run with sudo: sudo $0"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install required packages
echo "Checking for required packages..."
PACKAGES_TO_INSTALL=()

if ! command_exists mail; then
    PACKAGES_TO_INSTALL+=("mailutils")
fi

if ! command_exists postfix; then
    PACKAGES_TO_INSTALL+=("postfix")
fi

if ! dpkg -l | grep -q libsasl2-modules; then
    PACKAGES_TO_INSTALL+=("libsasl2-modules")
fi

if ! dpkg -l | grep -q ca-certificates; then
    PACKAGES_TO_INSTALL+=("ca-certificates")
fi

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo "Installing packages: ${PACKAGES_TO_INSTALL[*]}"
    apt update
    DEBIAN_FRONTEND=noninteractive apt install -y "${PACKAGES_TO_INSTALL[@]}"
    echo "✓ Packages installed successfully"
else
    echo "✓ All required packages are already installed"
fi

# Set up environment file
echo ""
echo "Setting up environment configuration..."
if [ -f "$ENV_FILE" ]; then
    echo "Environment file already exists at: $ENV_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing environment file."
        SKIP_ENV=true
    fi
fi

if [ -z "$SKIP_ENV" ]; then
    read -r -p "Enter recipient email address: " RECIPIENT_EMAIL
    
    # Validate email format
    if [ -z "$RECIPIENT_EMAIL" ]; then
        echo "ERROR: Email address cannot be empty"
        exit 1
    fi
    
    # Validate email format (basic validation to catch obvious mistakes)
    if [[ ! "$RECIPIENT_EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        echo "ERROR: Invalid email format. Please enter a valid email address."
        exit 1
    fi
    
    # Create .env file
    cat > "$ENV_FILE" << EOF
# Configuration for apt package update email notifications
RECIPIENT=$RECIPIENT_EMAIL
EOF
    
    chmod 600 "$ENV_FILE"
    echo "✓ Environment file created at: $ENV_FILE"
fi

# Configure Gmail SMTP
echo ""
echo "Setting up Gmail/Google Workspace SMTP configuration..."
read -r -p "Do you want to configure Gmail/Google Workspace SMTP for sending emails? (y/N): " -n 1 -r SETUP_GMAIL
echo

if [[ $SETUP_GMAIL =~ ^[Yy]$ ]]; then
    echo ""
    echo "Gmail/Google Workspace SMTP Setup:"
    echo "==================================="
    echo "Note: You will need a Google App Password (not your regular password)"
    echo "      This works for both Gmail (@gmail.com) and Google Workspace accounts"
    echo "To create an App Password:"
    echo "  1. Enable 2-Step Verification on your Google account"
    echo "  2. Go to: https://myaccount.google.com/apppasswords"
    echo "  3. Generate an App Password for 'Mail'"
    echo ""
    
    read -r -p "Enter your Gmail/Google Workspace email address: " GMAIL_ADDRESS
    
    if [ -z "$GMAIL_ADDRESS" ]; then
        echo "ERROR: Email address cannot be empty"
        exit 1
    fi
    
    # Validate email address format (supports both @gmail.com and Google Workspace domains)
    if [[ ! "$GMAIL_ADDRESS" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        echo "ERROR: Please enter a valid email address"
        exit 1
    fi
    
    read -r -s -p "Enter your Google App Password: " GMAIL_APP_PASSWORD
    echo
    
    if [ -z "$GMAIL_APP_PASSWORD" ]; then
        echo "ERROR: Google App Password cannot be empty"
        exit 1
    fi
    
    # Configure Postfix for Gmail SMTP
    echo "Configuring Postfix for Gmail/Google Workspace SMTP..."
    
    # Backup existing main.cf
    if [ -f /etc/postfix/main.cf ]; then
        cp /etc/postfix/main.cf "/etc/postfix/main.cf.backup.$(date +%Y%m%d%H%M%S)"
        echo "✓ Backed up existing Postfix configuration"
    fi
    
    # Update main.cf with Gmail SMTP settings
    cat >> /etc/postfix/main.cf << EOF

# Gmail/Google Workspace SMTP Configuration (added by apt installer)
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
EOF
    
    # Create sasl_passwd file
    echo "[smtp.gmail.com]:587 $GMAIL_ADDRESS:$GMAIL_APP_PASSWORD" > /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
    
    # Clear sensitive variables from memory
    unset GMAIL_APP_PASSWORD
    
    # Restart Postfix
    systemctl restart postfix
    
    echo "✓ Gmail/Google Workspace SMTP configuration complete"
    
    # Test email
    echo ""
    read -r -p "Do you want to send a test email now? (y/N): " -n 1 -r SEND_TEST
    echo
    
    if [[ $SEND_TEST =~ ^[Yy]$ ]]; then
        # Load RECIPIENT from .env if not already set
        if [ -z "$RECIPIENT_EMAIL" ] && [ -f "$ENV_FILE" ]; then
            # shellcheck source=/dev/null
            source "$ENV_FILE"
            RECIPIENT_EMAIL="$RECIPIENT"
        fi
        
        TEST_RECIPIENT="${RECIPIENT_EMAIL:-$GMAIL_ADDRESS}"
        echo "Sending test email to $TEST_RECIPIENT..."
        if echo "This is a test email from the APT Package Update Email Notification System." | mail -s "Test Email - APT Notification System" "$TEST_RECIPIENT"; then
            echo "✓ Test email sent successfully"
            echo "  Please check your inbox (and spam folder) for the test email"
        else
            echo "✗ Failed to send test email"
            echo "  Check /var/log/mail.log for details"
        fi
    fi
else
    echo "Skipping Gmail/Google Workspace SMTP configuration"
    echo "Note: You will need to configure your mail system manually for email delivery"
fi

# Set up cron job
echo ""
echo "Setting up cron job..."
CRON_SCHEDULE="0 8 * * *"  # Default: 8 AM daily (system local time)
read -r -p "Enter cron schedule (default: $CRON_SCHEDULE - 8 AM daily): " USER_SCHEDULE

if [ -n "$USER_SCHEDULE" ]; then
    # Basic validation: cron schedule should have 5 fields (min hour day month weekday)
    FIELD_COUNT=$(echo "$USER_SCHEDULE" | awk '{print NF}')
    if [ "$FIELD_COUNT" -ne 5 ]; then
        echo "WARNING: Cron schedule should have 5 fields (minute hour day month weekday)"
        echo "Using default schedule: $CRON_SCHEDULE"
    else
        CRON_SCHEDULE="$USER_SCHEDULE"
    fi
fi

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    read -r -p "Enter username for cron job (default: root): " CRON_USER
    CRON_USER="${CRON_USER:-root}"
else
    CRON_USER="$ACTUAL_USER"
fi

# Update .env file ownership to match cron user
if [ -f "$ENV_FILE" ] && [ "$CRON_USER" != "root" ]; then
    chown "$CRON_USER:$CRON_USER" "$ENV_FILE"
    echo "✓ Environment file ownership set to: $CRON_USER"
fi

# Verify required scripts exist
if [ ! -f "$SCRIPT_DIR/update-packages.sh" ]; then
    echo "ERROR: Required script not found: $SCRIPT_DIR/update-packages.sh"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/email-output.sh" ]; then
    echo "ERROR: Required script not found: $SCRIPT_DIR/email-output.sh"
    exit 1
fi

# Create the cron command
CRON_CMD="$SCRIPT_DIR/update-packages.sh | $SCRIPT_DIR/email-output.sh"
CRON_ENTRY="$CRON_SCHEDULE $CRON_CMD"

# Check if cron job already exists
TEMP_CRON=$(mktemp)
trap 'rm -f "$TEMP_CRON"' EXIT  # Ensure cleanup on exit

crontab -u "$CRON_USER" -l 2>/dev/null > "$TEMP_CRON" || true

if grep -Fq "$CRON_CMD" "$TEMP_CRON"; then
    echo "Cron job already exists for user: $CRON_USER"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove old entry and add new one
        grep -Fv "$CRON_CMD" "$TEMP_CRON" > "${TEMP_CRON}.new" || true
        mv "${TEMP_CRON}.new" "$TEMP_CRON"
        echo "$CRON_ENTRY" >> "$TEMP_CRON"
        crontab -u "$CRON_USER" "$TEMP_CRON"
        echo "✓ Cron job updated"
    else
        echo "Keeping existing cron job"
    fi
else
    # Add new cron job
    echo "$CRON_ENTRY" >> "$TEMP_CRON"
    crontab -u "$CRON_USER" "$TEMP_CRON"
    echo "✓ Cron job added for user: $CRON_USER"
fi

# Display current cron jobs
echo ""
echo "Current cron jobs for $CRON_USER:"
crontab -u "$CRON_USER" -l 2>/dev/null | grep -F "$CRON_CMD" || echo "  (none found)"

echo ""
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "Configuration:"
echo "  - Environment file: $ENV_FILE"
echo "  - Update script: $SCRIPT_DIR/update-packages.sh"
echo "  - Email script: $SCRIPT_DIR/email-output.sh"
echo "  - Cron user: $CRON_USER"
echo "  - Cron schedule: $CRON_SCHEDULE"
echo ""
echo "You can manually test the setup by running:"
echo "  $CRON_CMD"
echo ""
echo "To modify the cron schedule, run:"
echo "  sudo crontab -u $CRON_USER -e"
echo ""
