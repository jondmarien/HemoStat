# GPU Support for Docker on Windows

This guide enables NVIDIA GPU support in Docker on Windows to run models like `lakhera2023/devops-slm` locally on your GPU.

## ⚠️ Do You Need This?

**The `devops-slm` model is available on a hosted Hugging Face Inference Endpoint!**

- **Hosted Endpoint (Easier):** `https://bcg2lrpnfylqamcz.us-east-1.aws.endpoints.huggingface.cloud`
  - ✅ No GPU setup required
  - ✅ Works immediately
  - ✅ Already configured in `.env.docker.windows`
  - ❌ Requires internet connection
  - ❌ Shared infrastructure (may be slower)

- **Local GPU Server (This Guide):**
  - ✅ Runs on your RTX 3070Ti
  - ✅ Faster inference (~40-60 tokens/s)
  - ✅ Works offline
  - ✅ Private/local processing
  - ❌ Requires GPU setup (complex)
  - ❌ Uses ~2-3GB VRAM

**To switch between them, edit `.env.docker.windows`:**

```bash
# Option 1: Hosted endpoint (current default)
HF_ENDPOINT_URL=https://bcg2lrpnfylqamcz.us-east-1.aws.endpoints.huggingface.cloud

# Option 2: Local GPU server (uncomment to use)
# HF_ENDPOINT_URL=http://host.docker.internal:8080
```

---

**Continue below only if you want to set up the local GPU server.**

---

## Prerequisites

- ✅ **NVIDIA GPU** (You have: RTX 3070Ti)
- ✅ **NVIDIA Drivers** installed on Windows
- ✅ **Docker Desktop for Windows** installed
- ⚠️ **WSL2** required (we'll verify/install)

## Step 1: Verify/Install WSL2

### Check if WSL2 is Already Installed

Open PowerShell as Administrator and run:

```powershell
wsl --list --verbose
```

**If you see WSL distributions listed with VERSION 2:**

- ✅ WSL2 is installed! Skip to Step 2.

**If you get an error or no distributions:**

- Continue with installation below.

### Install WSL2 (If Needed)

```powershell
# Run as Administrator
wsl --install
```

This installs:

- WSL2
- Ubuntu (default distribution)

**After installation:**

1. Restart your computer
2. Open "Ubuntu" from Start menu
3. Create a username and password when prompted

### Verify Installation

```powershell
wsl --list --verbose
```

You should see:

```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

## Step 2: Install NVIDIA Container Toolkit in WSL2

### Enter WSL2

```powershell
wsl
```

You should now be in a Linux terminal (Ubuntu).

### Install NVIDIA Container Toolkit

Run these commands in WSL2:

```bash
# Configure the repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Update package list
sudo apt-get update

# Install NVIDIA Container Toolkit
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker

# Restart Docker (if running in WSL)
sudo systemctl restart docker 2>/dev/null || true
```

### Exit WSL2

```bash
exit
```

## Step 3: Configure Docker Desktop

### Enable WSL2 Integration

1. Open **Docker Desktop**
2. Go to **Settings** → **Resources** → **WSL Integration**
3. Enable integration with your WSL2 distro (Ubuntu)
4. Click **Apply & Restart**

### Verify GPU Access

Test that Docker can see your GPU:

```powershell
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

**Expected output:**

```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 5XX.XX       Driver Version: 5XX.XX       CUDA Version: 12.X    |
|-------------------------------+----------------------+----------------------+
| GPU  Name            TCC/WDDM | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ... WDDM  | 00000000:01:00.0  On |                  N/A |
|  0%   45C    P8    16W / 290W |    XXXMiB /  8192MiB |      X%      Default |
+-------------------------------+----------------------+----------------------+
```

If you see your RTX 3070Ti details, **GPU support is working!** ✅

## Step 4: Update HemoStat Script

The PowerShell script has been updated to automatically detect and use GPU when available.

Just run:

```powershell
.\scripts\windows\run_local_hf_server.ps1
```

The script will:

- ✅ Detect if GPU is available
- ✅ Add `--gpus all` flag automatically
- ✅ Start the server with GPU acceleration

## Step 5: Verify GPU Usage

After starting the server, check the logs:

```powershell
docker logs -f hemostat-hf-server
```

**Look for:**

```
INFO text_generation_launcher: Detected 1 CUDA devices
INFO text_generation_launcher: Using GPU 0: NVIDIA GeForce RTX 3070 Ti
```

**GPU usage in Windows:**

- Open Task Manager
- Go to "Performance" tab
- Look at "GPU 1 - Compute" (should show usage when model loads)

## Troubleshooting

### Error: "could not select device driver"

**Solution:** Restart Docker Desktop after installing NVIDIA Container Toolkit.

```powershell
# Restart Docker Desktop completely
wsl --shutdown
# Then open Docker Desktop again
```

### Error: "nvidia-smi not found"

**Solution:** Your NVIDIA drivers aren't visible in WSL2.

1. Update NVIDIA drivers on Windows to latest version
2. Ensure WSL2 is using latest kernel:

   ```powershell
   wsl --update
   ```

### Error: "Failed to initialize NVML"

**Solution:** WSL2 integration not enabled in Docker Desktop.

1. Docker Desktop → Settings → Resources → WSL Integration
2. Enable for your Ubuntu distribution
3. Apply & Restart

### GPU Not Detected in Container

**Check Windows drivers:**

```powershell
nvidia-smi
```

**Check WSL2 can see GPU:**

```powershell
wsl
nvidia-smi
exit
```

Both should show your RTX 3070Ti.

## Performance Expectations

With RTX 3070Ti (8GB VRAM):

| Model Size | Load Time | Inference Speed | Memory Usage |
|------------|-----------|-----------------|--------------|
| 1B params  | ~10s      | ~50 tokens/s    | ~2GB         |
| 3B params  | ~20s      | ~30 tokens/s    | ~4GB         |
| 7B params  | ~40s      | ~15 tokens/s    | ~7GB         |

The `devops-slm` model is ~1B parameters, so expect:

- ⚡ Fast loading (~10-15 seconds)
- ⚡ Fast inference (~40-60 tokens/second)
- 💾 Low memory usage (~2-3GB VRAM)

## Reverting to Claude

If GPU setup is too complex or doesn't work, you can always switch back to Claude:

```bash
# In .env.docker.windows
AI_MODEL=claude-3-5-haiku-20241022
HF_ENDPOINT_URL=  # Remove or leave empty
```

Then:

```powershell
docker stop hemostat-hf-server
make windows
```

Claude works immediately without GPU setup! 🚀
