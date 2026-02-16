# APT Package Update Email Notification System

This directory contains scripts for monitoring and reporting apt package updates via email.

## Quick Installation

Run the installer with sudo privileges:

```bash
cd apt
sudo ./install.sh
```

The installer will:
1. Install `mailutils` if not already present
2. Prompt for recipient email address
3. Create configuration file (`.env`)
4. Set up a cron job to run package checks automatically

## Manual Setup

If you prefer to set up manually:

### 1. Install Dependencies

```bash
sudo apt update
sudo apt install mailutils
```

### 2. Configure Environment

Create a `.env` file in this directory:

```bash
RECIPIENT=your-email@example.com
```

### 3. Test the Scripts

```bash
# Check for package updates
./update-packages.sh

# Test email functionality
echo "Test email" | ./email-output.sh
```

### 4. Set Up Cron Job

Add to your crontab (e.g., `sudo crontab -e`):

```cron
# Run daily at 8 AM
0 8 * * * /path/to/apt/update-packages.sh | /path/to/apt/email-output.sh
```

## Scripts

- **install.sh** - Interactive installer that sets up everything
- **update-packages.sh** - Checks for available package updates
- **email-output.sh** - Sends stdin content via email
- **.env** - Configuration file (created by installer or manually)

## Configuration

The `.env` file supports the following variables:

- `RECIPIENT` - Email address to receive notifications (required)

## Troubleshooting

### Email not sending

1. Verify mailutils is installed: `which mail`
2. Check system mail logs: `sudo tail -f /var/log/mail.log`
3. Test email manually: `echo "test" | mail -s "test" your-email@example.com`

### Cron job not running

1. Check cron is running: `sudo systemctl status cron`
2. View cron logs: `grep CRON /var/log/syslog`
3. Verify cron job exists: `crontab -l`

### Permission issues

Ensure the `.env` file has correct ownership and permissions:

```bash
# For user 'youruser'
sudo chown youruser:youruser .env
chmod 600 .env
```

## Security

- The `.env` file is created with restrictive permissions (600)
- Email recipient is validated during installation
- Scripts use absolute paths to prevent PATH-based attacks
- Cron schedule format is validated
