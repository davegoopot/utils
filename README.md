# Remote Package Upgrade via Email Control

This document outlines methods to configure the server to listen for an email reply and trigger the `apt upgrade` command automatically.

## Concept
1. The server sends the package status email (current setup).
2. You reply to that email with a specific keyword (e.g., "UPGRADE").
3. The server detects this reply and executes the upgrade command.

## Implementation Options

### 1. IMAP Polling Script (Recommended)
A script (Python or Bash with `curl`/`fetchmail`) runs periodically via cron to check an email inbox.

*   **Workflow:**
    1.  Script logs into your email account (e.g., Gmail, Yahoo) via IMAP.
    2.  Searches for unread messages from `dave@goopot.co.uk` with Subject `Re: script output...`.
    3.  Parses the email body for the command keyword `RUN_UPGRADE`.
    4.  If found:
        *   Executes `sudo apt upgrade -y`.
        *   Sends a confirmation email back.
        *   Moves the trigger email to an archive folder.

*   **Requirements:**
    *   Python (with `imaplib`) or `fetchmail`.
    *   An App Password (if using Gmail/Outlook with 2FA).

### 2. Local MTA Pipe (Advanced)
If this server acts as its own mail server (running Postfix/Exim).

*   **Workflow:**
    1.  Configure an email alias (e.g., `cmd@myserver.com`) in `/etc/aliases`.
    2.  Pipe incoming mail for that alias directly to a script:
        `cmd: "|/path/to/processor_script.sh"`
*   **Requirements:**
    *   Publicly accessible port 25.
    *   DNS MX records pointing to this server.

## Security Best Practices
*   **Sender Allowlist:** The script must strictly verify the `From` address.
*   **Command Whitelist:** **NEVER** execute the content of the email directly. Only use the email to trigger a pre-defined command on the server.
*   **Secret Token:** (Optional) Require a generated secret string in the subject line or body to prevent spoofing.
