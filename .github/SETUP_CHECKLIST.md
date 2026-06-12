# Repository Setup Checklist

## Initial Setup

### 1. Rename Template
- [ ] Update `finpilot` to your name in: Containerfile, Justfile, README.md, artifacthub-repo.yml

### 2. Enable GitHub Actions
- [ ] Settings → Actions → General → Enable workflows
- [ ] Set "Read and write permissions"

### 3. First Push
```bash
git add .
git commit -m "feat: initial customization"
git push origin main
```

### 4. Deploy
```bash
sudo bootc switch --transport registry ghcr.io/YOUR_USERNAME/YOUR_REPO:stable
sudo systemctl reboot
```

### 5. Enable Renovate (Required)
- [ ] Go to [github.com/apps/renovate](https://github.com/apps/renovate) and click **Install**
- [ ] Select your repository and install the app
- [ ] Renovate will create a PR to pin your GitHub Actions to SHAs

## Optional: Production Features

### Enable Signing (Recommended)
```bash
cosign generate-key-pair
# Add cosign.key to GitHub Secrets as SIGNING_SECRET
# Uncomment signing in .github/workflows/build-image.yml
```

