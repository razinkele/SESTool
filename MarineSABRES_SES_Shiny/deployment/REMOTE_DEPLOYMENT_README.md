# Remote Deployment from Windows to laguna.ku.lt

This directory contains tools for deploying the MarineSABRES SES Tool from your Windows development machine to the Shiny Server on laguna.ku.lt.

## Ownership Model

Files are deployed with **razinka:shiny** ownership:
- `razinka` (passwordless SSH user) owns the files — can deploy without sudo
- `shiny` group gives Shiny Server (`run_as shiny`) read access via group permissions
- Only `systemctl restart` requires sudo

## Quick Start

### Option 1: PowerShell (Recommended for Windows)
```powershell
# Interactive deployment
.\deploy-remote.ps1

# Test deployment (dry run — lists files without uploading)
.\deploy-remote.ps1 -DryRun

# Force deployment without prompts
.\deploy-remote.ps1 -Force

# Exclude SESModels directory (faster upload)
.\deploy-remote.ps1 -ExcludeModels
```

### Option 2: Bash Script (Linux/Mac)
```bash
# Interactive deployment
./remote-deploy.sh

# Test deployment (dry run)
./remote-deploy.sh --dry-run

# Exclude SESModels directory
./remote-deploy.sh --exclude-models
```

## Prerequisites

### 1. SSH Access to laguna.ku.lt
You must have SSH key-based access configured for the razinka user:

```bash
# Test SSH connection
ssh razinka@laguna.ku.lt

# If this fails, set up SSH keys:
ssh-keygen -t rsa -b 4096
ssh-copy-id razinka@laguna.ku.lt
```

### 2. Required Tools (Built into Windows 10/11)
No additional software needed. The deployment uses native Windows tools:
- `ssh` — remote commands (OpenSSH Client)
- `scp` — file upload (OpenSSH Client)
- `tar` — archive creation (bsdtar)

If OpenSSH is not enabled:
**Settings > Apps > Optional Features > OpenSSH Client**

### 3. R Environment (for pre-deploy validation)
- R installed with required packages
- Rscript available in PATH

## Files Overview

| File | Purpose |
|------|---------|
| `deploy-remote.ps1` | **Main deployment script** — native Windows (tar + scp + ssh) |
| `deploy-remote.cmd` | **Double-click launcher** — calls deploy-remote.ps1 |
| `remote-deploy.sh` | **Bash alternative** — for Linux/Mac users (tar + scp + ssh) |
| `pre-deploy-check-remote.R` | **R validation** — checks app integrity before deployment |
| `remote-deploy-config.txt` | **Configuration** — deployment settings reference |

## Deployment Process

The deployment uses **tar + scp** (no rsync required):

### Phase 1: Pre-Deployment Validation (local)
- Validate required files (app.R, global.R, etc.)
- Check R syntax in all scripts
- Verify translation JSON files
- Test SSH connectivity to laguna.ku.lt

### Phase 2: Archive and Upload
- Create `.tar.gz` archive excluding dev files (.git, tests, deployment, etc.)
- Upload single archive to laguna.ku.lt via `scp`

### Phase 3: Deploy on Server (via ssh)
- Clear existing app directory
- Extract archive into `/srv/shiny-server/marinesabres/`
- Set ownership to `razinka:shiny`, permissions to 755
- Clear stale translation cache

### Phase 4: Restart and Verify
- Restart Shiny Server (`sudo systemctl restart shiny-server`)
- Report deployed version and server status

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH connection
ssh razinka@laguna.ku.lt

# Check SSH config
cat ~/.ssh/config

# Generate new SSH key if needed
ssh-keygen -t rsa -b 4096 -C "your-email@ku.lt"
```

### Permission Denied on Remote Server
```bash
# Check if razinka user has sudo access on laguna.ku.lt
ssh razinka@laguna.ku.lt sudo whoami

# Check directory ownership
ssh razinka@laguna.ku.lt "ls -la /srv/shiny-server/ | grep marinesabres"
```

### Application Not Starting
```bash
# Check logs on remote server
ssh razinka@laguna.ku.lt "sudo tail -f /var/log/shiny-server/marinesabres.log"

# Check Shiny Server status
ssh razinka@laguna.ku.lt "sudo systemctl status shiny-server"
```

### Old Version Still Showing
1. **Clear browser cache**: Ctrl+Shift+R (or Cmd+Shift+R on Mac)
2. **Force restart on server**:
   ```bash
   ssh razinka@laguna.ku.lt "sudo deployment/force-restart-shiny.sh"
   ```
3. **Try Incognito/Private mode**

## Post-Deployment

### Access Your Application
- **URL:** http://laguna.ku.lt:3838/marinesabres/
- **Clear browser cache:** Ctrl+Shift+R
- **Incognito mode:** For testing without cache

### Monitor Application
```bash
# View application logs
ssh razinka@laguna.ku.lt "sudo tail -f /var/log/shiny-server/marinesabres.log"

# Check server status
ssh razinka@laguna.ku.lt "sudo systemctl status shiny-server"

# Validate deployment
ssh razinka@laguna.ku.lt "sudo /srv/shiny-server/marinesabres/deployment/validate-deployment.sh"
```

## Security Notes

- Deployment uses SSH (encrypted) with key-based authentication
- No passwords stored in scripts
- Files uploaded as compressed archive via `scp` over SSH
- Sensitive files (.env, credentials) excluded from archive

## SSH Config Example

Create `~/.ssh/config` for convenience:
```
Host laguna
    HostName laguna.ku.lt
    User razinka
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

## Common Issues Quick Reference

| Issue | Solution |
|-------|----------|
| "Permission denied" | Check SSH key setup: `ssh razinka@laguna.ku.lt` |
| "Connection refused" | Check network/VPN access to laguna.ku.lt |
| "scp not found" | Enable OpenSSH in Windows Optional Features |
| "Application not loading" | Clear browser cache, check logs |
| "Old version showing" | Hard refresh (Ctrl+Shift+R), try Incognito |

## First-Time Setup Checklist

- [ ] SSH key access to razinka@laguna.ku.lt working
- [ ] R and required packages installed locally
- [ ] Test deployment with `.\deploy-remote.ps1 -DryRun`
- [ ] Successful deployment to laguna.ku.lt
- [ ] Application accessible at http://laguna.ku.lt:3838/marinesabres/
- [ ] Browser cache cleared and tested
