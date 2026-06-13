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
### 4. Enable Renovate (Required)
- [ ] Create a **Classic PAT** (Settings → Developer settings → Personal access tokens → Tokens (classic))
  - Scopes: `repo` (full control) + `workflow` (update workflows)
- [ ] Add the token as repository secret **`RENOVATE_TOKEN`** (Settings → Secrets and variables → Actions)
- [ ] Optional: enable **Settings → General → Pull Requests → Allow auto-merge**
- [ ] Renovate will create a PR to pin your GitHub Actions to SHAs

### 5. Deploy
```bash
sudo bootc switch --transport registry ghcr.io/YOUR_USERNAME/YOUR_REPO:stable
sudo systemctl reboot
```

## Optional: Production Features

### Enable Signing (Recommended)
```bash
cosign generate-key-pair
# Add cosign.key to GitHub Secrets as SIGNING_SECRET
# Uncomment signing in .github/workflows/build-image.yml
```
