# Script to find the correct CloudWave API Docker image

Write-Host "🔍 Finding Correct CloudWave API Docker Image" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Get GitHub repository information
$repoUrl = git config --get remote.origin.url 2>$null
if ($repoUrl) {
    # Extract username from GitHub URL
    if ($repoUrl -match "github\.com[:/]([^/]+)/") {
        $githubUsername = $matches[1]
        Write-Host "✅ GitHub Username: $githubUsername" -ForegroundColor Green
        
        # Get recent commit SHA
        $commitSha = git rev-parse HEAD 2>$null
        if ($commitSha) {
            $shortSha = $commitSha.Substring(0, 7)
            Write-Host "✅ Current Commit SHA: $commitSha" -ForegroundColor Green
            Write-Host "✅ Short SHA: $shortSha" -ForegroundColor Green
            
            # Construct expected image names
            $expectedImage = "docker.io/$githubUsername/cloudwave-api"
            Write-Host "`n📦 Expected Docker Images:" -ForegroundColor Blue
            Write-Host "   Full SHA: $expectedImage`:$commitSha"
            Write-Host "   Latest:   $expectedImage`:latest"
            
            # Test if images exist
            Write-Host "`n🧪 Testing Image Availability:" -ForegroundColor Blue
            
            Write-Host "Testing: $expectedImage`:$commitSha"
            docker pull "$expectedImage`:$commitSha" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Image with commit SHA exists!" -ForegroundColor Green
                $workingImage = "$expectedImage`:$commitSha"
            } else {
                Write-Host "❌ Image with commit SHA not found" -ForegroundColor Red
            }
            
            Write-Host "Testing: $expectedImage`:latest"
            docker pull "$expectedImage`:latest" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Image with 'latest' tag exists!" -ForegroundColor Green
                if (-not $workingImage) { $workingImage = "$expectedImage`:latest" }
            } else {
                Write-Host "❌ Image with 'latest' tag not found" -ForegroundColor Red
            }
            
            # Provide fix instructions
            Write-Host "`n🔧 Fix Instructions:" -ForegroundColor Yellow
            
            if ($workingImage) {
                Write-Host "✅ Found working image: $workingImage" -ForegroundColor Green
                Write-Host "`nTo fix your deployment:"
                Write-Host "1. Update k8s/base/deployment.yaml:"
                Write-Host "   Change image to: $workingImage"
                Write-Host "`n2. Update k8s/overlays/dev/kustomization.yaml:"
                Write-Host "   Change name to: $expectedImage"
                Write-Host "   Change newTag to: " + $workingImage.Split(':')[1]
                Write-Host "`n3. Apply the changes:"
                Write-Host "   kubectl apply -k k8s/overlays/dev"
            } else {
                Write-Host "❌ No working images found!" -ForegroundColor Red
                Write-Host "`nPossible issues:"
                Write-Host "1. CI/CD pipeline hasn't run successfully yet"
                Write-Host "2. Docker Hub credentials are incorrect"
                Write-Host "3. Repository secrets are not configured"
                Write-Host "`nCheck your GitHub Actions workflow runs:"
                Write-Host "   https://github.com/$githubUsername/YOUR_REPO/actions"
            }
            
        } else {
            Write-Host "❌ Could not get current commit SHA" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Could not extract GitHub username from remote URL" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Could not get GitHub repository URL" -ForegroundColor Red
    Write-Host "Make sure you're in a Git repository directory" -ForegroundColor Yellow
}

Write-Host "`n📋 Manual Check:" -ForegroundColor Blue
Write-Host "1. Go to your GitHub repository"
Write-Host "2. Click 'Actions' tab"
Write-Host "3. Look at recent workflow runs"
Write-Host "4. Check 'Build and push image' step output"
Write-Host "5. Copy the exact image name that was pushed"

Write-Host "`n🌐 Check Docker Hub:" -ForegroundColor Blue
Write-Host "1. Go to https://hub.docker.com"
Write-Host "2. Search for your repositories"
Write-Host "3. Look for 'cloudwave-api' repository"
Write-Host "4. Check what tags are available"