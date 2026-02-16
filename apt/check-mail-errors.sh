#!/bin/bash

# Script to diagnose Gmail SMTP issues and display relevant error logs

echo "=========================================="
echo "Gmail SMTP Troubleshooting Helper"
echo "=========================================="
echo ""

# Check if running with sufficient privileges
if [ "$EUID" -ne 0 ]; then
    echo "Note: Some checks require root privileges for full diagnostics."
    echo "Run with: sudo $0"
    echo ""
fi

# 1. Check Postfix status
echo "1. Checking Postfix service status..."
if systemctl is-active --quiet postfix; then
    echo "   ✓ Postfix is running"
else
    echo "   ✗ Postfix is NOT running"
    echo "   Start with: sudo systemctl start postfix"
fi
echo ""

# 2. Check Postfix configuration
echo "2. Checking Postfix Gmail SMTP configuration..."
if [ -f /etc/postfix/main.cf ]; then
    if grep -q "smtp.gmail.com" /etc/postfix/main.cf; then
        echo "   ✓ Gmail SMTP relay configured"
        echo "   Relay host: $(grep 'relayhost.*smtp.gmail.com' /etc/postfix/main.cf | head -1)"
    else
        echo "   ✗ Gmail SMTP relay NOT configured in /etc/postfix/main.cf"
    fi
else
    echo "   ✗ /etc/postfix/main.cf not found"
fi
echo ""

# 3. Check SASL password file
echo "3. Checking SASL password file..."
if [ -f /etc/postfix/sasl_passwd ]; then
    echo "   ✓ sasl_passwd file exists"
    PERMS=$(stat -c %a /etc/postfix/sasl_passwd 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        echo "   ✓ Permissions correct (600)"
    else
        echo "   ⚠ Permissions: $PERMS (should be 600)"
        echo "   Fix with: sudo chmod 600 /etc/postfix/sasl_passwd"
    fi
    
    if [ -f /etc/postfix/sasl_passwd.db ]; then
        echo "   ✓ sasl_passwd.db (hashed) exists"
    else
        echo "   ✗ sasl_passwd.db missing - password file not hashed"
        echo "   Fix with: sudo postmap /etc/postfix/sasl_passwd"
    fi
else
    echo "   ✗ /etc/postfix/sasl_passwd not found"
fi
echo ""

# 4. Show recent mail log errors
echo "4. Recent mail errors (last 50 lines from /var/log/mail.log)..."
echo "   ================================================"
if [ -f /var/log/mail.log ]; then
    # Show recent errors related to SMTP, authentication, or Gmail
    if ! tail -50 /var/log/mail.log | grep -i -E "(error|warn|fatal|authentication failed|sasl|smtp|gmail|535|530)" | tail -20; then
        echo "   No recent errors found in mail.log"
    fi
else
    echo "   ✗ /var/log/mail.log not found"
    echo "   Try: /var/log/syslog or journalctl -u postfix"
fi
echo "   ================================================"
echo ""

# 5. Check for common issues
echo "5. Common Gmail SMTP issues to check:"
echo ""
echo "   Authentication errors (535, 534):"
echo "   - Verify you're using a Google App Password, not your regular password"
echo "   - Check 2-Step Verification is enabled: https://myaccount.google.com/security"
echo "   - Regenerate App Password: https://myaccount.google.com/apppasswords"
echo ""
echo "   Connection errors (cannot connect to smtp.gmail.com):"
echo "   - Check firewall allows outbound port 587"
echo "   - Test: telnet smtp.gmail.com 587"
echo ""
echo "   TLS/SSL errors:"
echo "   - Ensure ca-certificates is installed: sudo apt install ca-certificates"
echo ""

# 6. Provide commands for manual testing
echo "6. Manual testing commands:"
echo ""
echo "   View full mail log:"
echo "   sudo tail -100 /var/log/mail.log"
echo ""
echo "   Watch mail log in real-time:"
echo "   sudo tail -f /var/log/mail.log"
echo ""
echo "   Send test email:"
echo "   echo 'Test message' | mail -s 'Test Subject' your-email@example.com"
echo ""
echo "   Check Postfix queue:"
echo "   mailq"
echo ""
echo "   View detailed Postfix logs:"
echo "   sudo journalctl -u postfix -n 50"
echo ""
echo "   Test SMTP connection:"
echo "   telnet smtp.gmail.com 587"
echo ""

echo "=========================================="
echo "End of diagnostics"
echo "=========================================="
