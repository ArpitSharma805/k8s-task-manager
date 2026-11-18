# GitHub Webhook Setup for Jenkins

This guide explains how to configure GitHub webhooks to trigger Jenkins builds automatically when code is pushed.

## Prerequisites

- Jenkins installed and accessible
- GitHub repository
- Jenkins configured with GitHub credentials
- Jenkins accessible from GitHub (public URL or tunnel) - **Optional for local development**

**Note:** Webhook testing may be deferred until Jenkins is externally reachable. Manual build triggers are sufficient for Ticket 03 validation.

## Method 1: Using ngrok (for Local Development)

**Optional for local development.**

Since Jenkins is running on localhost (WSL), you'll need to expose it to the internet for GitHub to reach it if you want to test webhooks immediately.

### Install ngrok

Download ngrok from https://ngrok.com/download and authenticate:

```bash
ngrok authtoken <your-auth-token>
```

### Expose Jenkins

```bash
ngrok http 30003
```

This will give you a public URL like: `https://xxxx-xx-xx-xx-xx.ngrok-free.app`

### Configure Jenkins URL

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **Jenkins Location**
3. Set **Jenkins URL** to your ngrok URL (e.g., `https://xxxx-xx-xx-xx-xx.ngrok-free.app`)
4. Click **Save**

## Method 2: Using Jenkins GitHub Plugin

### Install GitHub Plugin

1. Go to **Manage Jenkins** → **Plugins**
2. Install **GitHub Plugin** if not already installed
3. Restart Jenkins

### Configure GitHub Plugin

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **GitHub** section
3. Click **Add GitHub Server**
4. Configure:
   - Name: `github-server`
   - API URL: `https://api.github.com`
   - Credentials: Select your GitHub credentials
5. Click **Test connection** to verify
6. Click **Apply** → **Save**

## Configure Webhook in GitHub

### Option 1: Manual Configuration

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks**
3. Click **Add webhook**
4. Configure:
   - **Payload URL**: `http://<jenkins-url>/github-webhook/`
     - Replace `<jenkins-url>` with your ngrok URL or public URL
     - Example: `https://xxxx-xx-xx-xx-xx.ngrok-free.app/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: Generate a secret and save it (e.g., `openssl rand -hex 32`)
5. Select events to trigger:
   - ✅ Pushes
   - ✅ Pull requests (optional)
6. Click **Add webhook**

### Option 2: Using Jenkins Job Configuration

1. Create a new Pipeline job in Jenkins
2. Configure:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your GitHub repository URL
   - **Credentials**: Your GitHub credentials
   - **Branch**: `*/main`
3. Under **Build Triggers**:
   - ✅ GitHub hook trigger for GITScm polling
4. Click **Save**

### Option 3: Using Jenkins Multibranch Pipeline

1. Create a new Multibranch Pipeline job
2. Configure:
   - **Branch Sources**: Add → GitHub
   - **Owner**: Your GitHub username
   - **Repository**: Your repository name
   - **Credentials**: Your GitHub credentials
   - **Build Configuration**: by Jenkinsfile
3. Click **Save**
4. Jenkins will automatically scan the repository and create jobs for each branch

## Configure Webhook Secret in Jenkins

If you set a secret in GitHub webhook:

1. Go to **Manage Jenkins** → **Configure Global Security**
2. Scroll to **GitHub Plugin Configuration**
3. Add the secret:
   - **Secret**: The secret you generated in GitHub
4. Click **Apply** → **Save**

## Test the Webhook

### Test from GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks**
3. Find your webhook
4. Click the three dots → **Redeliver**
5. Check the response (should be 200 OK)

### Test from Jenkins

1. Go to your Jenkins job
2. Click **Build Now**
3. Check the build runs successfully

### Test with a Real Push

1. Make a change to your repository
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test webhook"
   git push origin main
   ```
3. Check Jenkins - a new build should start automatically

## Troubleshooting

**Note:** Webhook issues are not blocking for Ticket 03. Use manual "Build Now" triggers in Jenkins for initial validation.

### Webhook Returns 404

- Verify the URL is correct: `http://<jenkins-url>/github-webhook/`
- Check Jenkins is running
- Check ngrok is running (if using ngrok)
- Verify Jenkins URL is configured in Jenkins settings

### Webhook Returns 401/403

- Verify webhook secret matches between GitHub and Jenkins
- Check Jenkins security settings
- Verify GitHub credentials are correct

### Build Not Triggering

- Check webhook delivery status in GitHub
- Check Jenkins logs for webhook errors:
  ```bash
  kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-master -f
  ```
- Verify job configuration has webhook trigger enabled
- Check branch matches webhook trigger (e.g., main vs master)
- If webhook fails, use manual "Build Now" trigger for Ticket 03 validation

### ngrok URL Changes

ngrok free tier changes URL on restart. To avoid this:
- Use ngrok paid tier for static domain
- Or configure webhook to use a public server
- Or use a tunneling service with static domain
- Or defer webhook setup until Jenkins is externally reachable

## Security Considerations

⚠️ **Important for Production:**

- Use HTTPS for webhook URL
- Always set a webhook secret
- Restrict webhook to specific branches
- Use GitHub App instead of personal access token
- Implement IP allowlisting for webhooks
- Regularly rotate webhook secrets

## Alternative: Jenkins Polling

If webhooks are not feasible, you can configure Jenkins to poll GitHub:

1. In job configuration, under **Build Triggers**
2. ✅ Poll SCM
3. Schedule: `H/5 * * * *` (every 5 minutes)

This is less efficient but works without public URL.

**For Ticket 03:** Manual "Build Now" triggers are sufficient. Polling and webhooks can be configured later when Jenkins is externally reachable.

## Next Steps

After webhook is configured:

1. Test the webhook with a real push
2. Verify Jenkins builds automatically

**Note:** Webhook configuration is optional for Ticket 03. Manual build triggers using "Build Now" in Jenkins are sufficient for initial validation. Webhook setup can be deferred until Jenkins is externally reachable.

Proceed to [Ticket 04: Security Pipeline](../issues/04-security-pipeline.md) when ready.
