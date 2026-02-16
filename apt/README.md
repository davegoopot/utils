# APT Package Update Email Notification System

This directory contains scripts for monitoring and reporting apt package updates via email.

## Quick Installation

Run the installer with sudo privileges:

```bash
cd apt
sudo ./install.sh
```

The installer will:
1. Install required packages (`mailutils`, `postfix`, `libsasl2-modules`, `ca-certificates`)
2. Prompt for recipient email address
3. Configure Gmail/Google Workspace SMTP (optional but recommended)
4. Create configuration file (`.env`)
5. Set up a cron job to run package checks automatically

### Gmail/Google Workspace SMTP Setup

The installer can automatically configure Gmail or Google Workspace SMTP for reliable email delivery. This works for both:
- **Gmail accounts** (@gmail.com)
- **Google Workspace accounts** (custom domains like @yourbusiness.com)

You will need:

1. **A Google account with 2-Step Verification enabled**
2. **A Google App Password** (not your regular account password)

#### Creating a Google App Password

1. Enable 2-Step Verification on your Google account:
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Enable "2-Step Verification"

2. Generate an App Password:
   - Go to [App Passwords](https://myaccount.google.com/apppasswords)
   - Select "Mail" and your device
   - Click "Generate"
   - Copy the 16-character password (spaces don't matter)

3. Use this App Password during the installer when prompted

**Note:** Google Workspace accounts use the same SMTP server (smtp.gmail.com) as regular Gmail accounts, so the setup process is identical regardless of your domain.

## Manual Setup

If you prefer to set up manually:

### 1. Install Dependencies

```bash
sudo apt update
sudo apt install mailutils postfix libsasl2-modules ca-certificates
```

During Postfix installation, select "Internet Site" and enter your hostname.

### 2. Configure Gmail/Google Workspace SMTP (Recommended)

Edit the Postfix configuration:

```bash
sudo nano /etc/postfix/main.cf
```

Add these lines at the end:

```
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

Create the password file:

```bash
sudo nano /etc/postfix/sasl_passwd
```

Add this line (replace with your email address and App Password):

```
[smtp.gmail.com]:587 your-email@yourdomain.com:your-app-password
```

**Note:** This works for both Gmail (@gmail.com) and Google Workspace (custom domain) accounts.

Secure and hash the password file:

```bash
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl restart postfix
```

### 3. Configure Environment

Create a `.env` file in this directory:

```bash
RECIPIENT=your-email@example.com
```

### 4. Test the Scripts

```bash
# Check for package updates
./update-packages.sh

# Test email functionality
echo "Test email" | ./email-output.sh
```

### 5. Set Up Cron Job

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
2. Check Postfix logs: `sudo tail -f /var/log/mail.log`
3. Test email manually: `echo "test" | mail -s "test" your-email@example.com`
4. Check Postfix status: `sudo systemctl status postfix`
5. For Gmail/Google Workspace issues:
   - Verify you're using an App Password, not your regular password
   - Check that 2-Step Verification is enabled on your Google account
   - Review Google's sending limits (500 emails/day for Gmail, may vary for Workspace)
   - Check if Google blocked the login attempt (check your Google security alerts)
   - For Google Workspace: Ensure SMTP relay is enabled in your admin console

### Gmail/Google Workspace SMTP Authentication Errors

If you see "authentication failed" errors:

1. Verify the App Password is correct (regenerate if needed)
2. Check the `/etc/postfix/sasl_passwd` file has correct format:
   ```bash
   sudo cat /etc/postfix/sasl_passwd
   ```
   Should show: `[smtp.gmail.com]:587 your-email@yourdomain.com:your-app-password`
3. Ensure the file was hashed: `sudo postmap /etc/postfix/sasl_passwd`
4. Check file permissions: `ls -l /etc/postfix/sasl_passwd*` (should be 600)
5. Restart Postfix: `sudo systemctl restart postfix`
6. For Google Workspace accounts:
   - Verify your admin hasn't restricted SMTP access
   - Check if less secure app access needs to be enabled (workspace admin setting)

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
