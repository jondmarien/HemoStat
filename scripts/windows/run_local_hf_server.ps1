# Run Local Hugging Face Inference Server
# This script starts a local Text Generation Inference server for lakhera2023/devops-slm

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 69) -ForegroundColor Cyan
Write-Host "Starting Local Hugging Face Inference Server" -ForegroundColor Cyan
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 69) -ForegroundColor Cyan
Write-Host ""

# Load environment
if (Test-Path .env.docker.windows) {
    Write-Host "Loading environment from .env.docker.windows..." -ForegroundColor Yellow
    Get-Content .env.docker.windows | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

$HF_TOKEN = $env:HUGGINGFACE_API_KEY
$MODEL_ID = "lakhera2023/devops-slm"
$PORT = 8080
$CONTAINER_NAME = "hemostat-hf-server"

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Green
Write-Host "  Model: $MODEL_ID" -ForegroundColor White
Write-Host "  Port: $PORT" -ForegroundColor White
Write-Host "  HF Token: " -NoNewline -ForegroundColor White
if ($HF_TOKEN) {
    Write-Host "$($HF_TOKEN.Substring(0,10))..." -ForegroundColor Green
} else {
    Write-Host "NOT SET - Using anonymous access" -ForegroundColor Yellow
}
Write-Host ""

# Check if container already exists
$existing = docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.Names}}"
if ($existing) {
    Write-Host "Removing existing container..." -ForegroundColor Yellow
    docker rm -f $CONTAINER_NAME | Out-Null
}

# Check for GPU support
Write-Host "Checking for GPU support..." -ForegroundColor Cyan
$gpuAvailable = $false
try {
    $gpuTest = docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi 2>&1
    if ($LASTEXITCODE -eq 0) {
        $gpuAvailable = $true
        Write-Host "✓ GPU detected and accessible!" -ForegroundColor Green
    } else {
        Write-Host "⚠ GPU not accessible. Running on CPU (will be slow)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ GPU not available. Running on CPU (will be slow)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "Starting Text Generation Inference server..." -ForegroundColor Cyan
Write-Host "This will download the model (~1GB) on first run..." -ForegroundColor Yellow
if ($gpuAvailable) {
    Write-Host "Using GPU acceleration (NVIDIA)" -ForegroundColor Green
} else {
    Write-Host "⚠ Using CPU (slow - see docs/GPU_SETUP_WINDOWS.md for GPU setup)" -ForegroundColor Yellow
}
Write-Host ""

# Run TGI server
$dockerArgs = @(
    "run", "-d",
    "--name", $CONTAINER_NAME,
    "-p", "${PORT}:80",
    "-v", "hf-models:/data"
)

# Add GPU support if available
if ($gpuAvailable) {
    $dockerArgs += "--gpus"
    $dockerArgs += "all"
}

if ($HF_TOKEN) {
    $dockerArgs += "-e"
    $dockerArgs += "HUGGING_FACE_HUB_TOKEN=$HF_TOKEN"
}

$dockerArgs += "ghcr.io/huggingface/text-generation-inference:latest"
$dockerArgs += "--model-id"
$dockerArgs += $MODEL_ID
$dockerArgs += "--max-total-tokens"
$dockerArgs += "2048"
$dockerArgs += "--max-input-length"
$dockerArgs += "1024"

try {
    $containerId = & docker @dockerArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Server container started: $containerId" -ForegroundColor Green
        Write-Host ""
        Write-Host "Waiting for server to be ready..." -ForegroundColor Yellow
        Write-Host "  (This may take 2-5 minutes on first run while downloading model)" -ForegroundColor Gray
        Write-Host ""
        
        # Wait for server to be ready
        $maxWait = 300  # 5 minutes
        $waited = 0
        $ready = $false
        
        while ($waited -lt $maxWait -and -not $ready) {
            Start-Sleep -Seconds 5
            $waited += 5
            
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:${PORT}/health" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $ready = $true
                }
            } catch {
                Write-Host "." -NoNewline -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host ""
        
        if ($ready) {
            Write-Host "=" -NoNewline -ForegroundColor Green
            Write-Host ("=" * 69) -ForegroundColor Green
            Write-Host "✓ Server is READY!" -ForegroundColor Green
            Write-Host "=" -NoNewline -ForegroundColor Green
            Write-Host ("=" * 69) -ForegroundColor Green
            Write-Host ""
            Write-Host "Server URL: " -NoNewline -ForegroundColor White
            Write-Host "http://localhost:$PORT" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Yellow
            Write-Host "  1. Update .env.docker.windows:" -ForegroundColor White
            Write-Host "     HF_ENDPOINT_URL=http://host.docker.internal:$PORT" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  2. Rebuild analyzer:" -ForegroundColor White
            Write-Host "     docker compose -f docker-compose.yml -f docker-compose.windows.yml --env-file .env.docker.windows up -d --build analyzer" -ForegroundColor Gray
            Write-Host ""
            Write-Host "View logs: docker logs -f $CONTAINER_NAME" -ForegroundColor White
            Write-Host "Stop server: docker stop $CONTAINER_NAME" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "⚠ Server is starting but not ready yet" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Check logs: docker logs -f $CONTAINER_NAME" -ForegroundColor White
            Write-Host "Check health: curl http://localhost:${PORT}/health" -ForegroundColor White
        }
        
    } else {
        Write-Host "✗ Failed to start container" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    exit 1
}
