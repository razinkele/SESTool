# Remote Deployment from Windows to laguna.ku.lt

This directory contains tools for deploying the MarineSABRES SES Tool from your Windows development machine to the existing Shiny server on laguna.ku.lt.

## 🚀 Quick Start

### Option 1: PowerShell (Recommended for Windows)
```powershell
# Interactive deployment
.\deploy-remote.ps1

# Test deployment (dry run)
.\deploy-remote.ps1 -DryRun

# Force deployment without prompts
.\deploy-remote.ps1 -Force
```

### Option 2: Bash Script (WSL/Git Bash)
```bash
# Interactive deployment
./remote-deploy.sh

# Test deployment (dry run)
./remote-deploy.sh --dry-run

# Exclude SESModels directory
./remote-deploy.sh --exclude-models
```

## 📋 Prerequisites

### 1. SSH Access to laguna.ku.lt
You must have SSH access configured for the razinka user:

```bash
# Test SSH connection
ssh razinka@laguna.ku.lt

# If this fails, set up SSH keys:
ssh-keygen -t rsa -b 4096
ssh-copy-id razinka@laguna.ku.lt
```

### 2. Required Tools
Choose **ONE** of these environments:

**Option A: Windows Subsystem for Linux (WSL)**
```powershell
# Install WSL
wsl --install

# Install rsync in WSL
wsl sudo apt update && sudo apt install rsync
```

**Option B: Git Bash**
```powershell
# Download from: https://git-scm.com/download/win
# Git Bash includes rsync
```

### 3. R Environment (for validation)
- R installed with required packages
- Rscript available in PATH

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `deploy-remote.ps1` | **PowerShell wrapper** - Windows-native interface |
| `remote-deploy.sh` | **Main deployment script** - Cross-platform bash script |
| `pre-deploy-check-remote.R` | **Validation script** - Checks app before deployment |
| `remote-deploy-config.txt` | **Configuration template** - Customize deployment settings |

## 🔧 Configuration

1. **Copy configuration template:**
   ```bash
   cp remote-deploy-config.txt remote-deploy-config.local.txt
   ```

2. **Edit your settings:**
   ```bash
   # Edit remote-deploy-config.local.txt
   REMOTE_USER="razinka"  # Already configured for laguna.ku.lt
   REMOTE_HOST="laguna.ku.lt"
   ```

## 🎯 Deployment Process

The deployment follows these phases:

### Phase 1: Pre-Deployment Validation
- ✅ Check required files (app.R, global.R, etc.)
- ✅ Validate R syntax in all scripts
- ✅ Check translation JSON files
- ✅ Verify SESModels directory
- ✅ Test SSH connectivity

### Phase 2: Remote Server Preparation
- 🛑 Stop Shiny Server on laguna.ku.lt
- 💾 Create backup of existing application
- 🧹 Kill old R processes and clear caches
- 📁 Prepare deployment directory

### Phase 3: File Upload
- 📤 Upload files via rsync (efficient, resumable)
- 🗂️ Include all directories: modules, functions, server, www, data, translations, **SESModels**
- 🚫 Exclude: .git, logs, temporary files, node_modules

### Phase 4: Service Restart
- 🔧 Set correct file permissions
- 🗑️ Clear translation caches
- ▶️ Start Shiny Server
- ✅ Validate HTTP access

## 🏃‍♂️ Usage Examples

### Basic Deployment
```powershell
# Windows PowerShell
.\deploy-remote.ps1
```

### Test Run (No Changes)
```powershell
# See what would be deployed
.\deploy-remote.ps1 -DryRun
```

### Automated Deployment
```powershell
# Skip all confirmations
.\deploy-remote.ps1 -Force
```

### Exclude Large Models
```powershell
# Skip SESModels directory (faster upload)
.\deploy-remote.ps1 -ExcludeModels
```

### Use Specific Environment
```powershell
# Force Git Bash instead of WSL
.\deploy-remote.ps1 -UseGitBash

# Force WSL instead of Git Bash
.\deploy-remote.ps1 -UseWSL
```

## 🔍 Troubleshooting

### SSH Connection Issues
```bash
# Test SSH connection
ssh razinka@laguna.ku.lt

# Check SSH config
cat ~/.ssh/config

# Generate new SSH key if needed
ssh-keygen -t rsa -b 4096 -C "your-email@ku.lt"
```

### rsync Not Found
**WSL Solution:**
```bash
wsl sudo apt install rsync
```

**Git Bash Solution:**
```bash
# Download Git for Windows: https://git-scm.com/download/win
```

### Permission Denied on Remote Server
```bash
# Check if razinka user has sudo access on laguna.ku.lt
ssh razinka@laguna.ku.lt sudo whoami

# If not, ask system administrator for access
```

### Large File Upload Issues
```bash
# Use exclude models option
./remote-deploy.sh --exclude-models

# Or compress SESModels locally first
tar -czf SESModels.tar.gz SESModels/
```

### Application Not Starting
```bash
# Check logs on remote server
ssh razinka@laguna.ku.lt sudo tail -f /var/log/shiny-server/marinesabres.log

# Check Shiny Server status
ssh razinka@laguna.ku.lt sudo systemctl status shiny-server
```

## 🌐 Post-Deployment

### Access Your Application
- **URL:** http://laguna.ku.lt:3838/marinesabres/
- **Clear browser cache:** Ctrl+Shift+R (or Cmd+Shift+R on Mac)
- **Incognito mode:** For testing without cache

### Monitor Application
```bash
# View application logs
ssh razinka@laguna.ku.lt sudo tail -f /var/log/shiny-server/marinesabres.log

# Check server status
ssh razinka@laguna.ku.lt sudo systemctl status shiny-server

# View system resources
ssh razinka@laguna.ku.lt htop
```

### Rollback if Needed
```bash
# Backups are created automatically in /tmp/marinesabres-backup-YYYYMMDD_HHMMSS
ssh razinka@laguna.ku.lt ls /tmp/marinesabres-backup-*

# Restore from backup
ssh razinka@laguna.ku.lt sudo cp -r /tmp/marinesabres-backup-*/marinesabres /srv/shiny-server/
ssh razinka@laguna.ku.lt sudo systemctl restart shiny-server
```

## 🔐 Security Notes

### SSH Best Practices
- ✅ Use SSH keys (not passwords)
- ✅ Disable password authentication
- ✅ Use specific SSH config for laguna.ku.lt
- ✅ Regularly rotate SSH keys

### File Permissions
- Files deployed with correct Shiny Server permissions
- No sensitive files (secrets, keys) included in deployment
- Temporary files automatically excluded

### Network Security
- Deployment uses SSH (encrypted)
- No plain-text passwords in scripts
- rsync over SSH tunnel

## 📝 Configuration Reference

### SSH Config Example
Create `~/.ssh/config`:
```
Host laguna
    HostName laguna.ku.lt
    User razinka
    IdentityFile ~/.ssh/id_rsa_laguna
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Then deploy with:
```bash
# Uses SSH config alias
./remote-deploy.sh
```

### Environment Variables
Set these in your shell:
```bash
export REMOTE_HOST="laguna.ku.lt"
export REMOTE_USER="razinka"
```

## 🆘 Support

### Common Issues Resolution
1. **"Permission denied"** → Check SSH key setup
2. **"rsync not found"** → Install via WSL or Git Bash
3. **"Connection refused"** → Check network/VPN access to laguna.ku.lt
4. **"Application not loading"** → Clear browser cache, check logs
5. **"Old version showing"** → Hard refresh (Ctrl+Shift+R)

### Getting Help
- Check application logs: `/var/log/shiny-server/marinesabres.log`
- Test with dry run: `--dry-run` or `-DryRun`
- Use force restart on remote server: `sudo deployment/force-restart-shiny.sh`

### Contact Information
- **System Administrator:** Contact KU IT for laguna.ku.lt access
- **Application Support:** Check project documentation
- **Emergency Contact:** Use backup deployment methods

---

## ✅ Checklist for First-Time Setup

- [ ] SSH access to laguna.ku.lt working
- [ ] WSL or Git Bash installed
- [ ] R and required packages installed
- [ ] Configuration file customized
- [ ] Test deployment with `--dry-run`
- [ ] Successful deployment to laguna.ku.lt
- [ ] Application accessible via browser
- [ ] Browser cache cleared and tested

**Ready to deploy!** 🚀