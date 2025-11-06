# Deploying Custom Hugging Face Models for HemoStat

This guide explains how to use Hugging Face models that aren't available on the free serverless Inference API, such as `lakhera2023/devops-slm`.

## The Problem

Some Hugging Face models, including `lakhera2023/devops-slm`, are not deployed to Hugging Face's free serverless Inference API. When you try to use these models, you'll get a `StopIteration` error:

```
File "huggingface_hub/inference/_providers/__init__.py", line 217, in get_provider_helper
    provider = next(iter(provider_mapping)).provider
StopIteration
```

## Solutions

### Option 1: Use Hugging Face Inference Endpoints (Recommended)

**Cost:** Starts at ~$0.06/hour (billed per second)

1. **Go to Hugging Face Inference Endpoints**
   - Visit: <https://ui.endpoints.huggingface.co/>
   - Sign in with your Hugging Face account

2. **Create a New Endpoint**
   - Click "New Endpoint"
   - Search for model: `lakhera2023/devops-slm`
   - Select instance type: CPU (cheapest) or GPU (faster)
   - Configure autoscaling if needed
   - Click "Create Endpoint"

3. **Get Your Endpoint URL**
   - Wait for endpoint to deploy (2-5 minutes)
   - Copy the endpoint URL (format: `https://xxx.aws.endpoints.huggingface.cloud`)

4. **Update Your Environment File**

   In `.env.docker.windows`:

   ```bash
   AI_MODEL=lakhera2023/devops-slm
   HUGGINGFACE_API_KEY=hf_your_token_here
   HF_ENDPOINT_URL=https://your-endpoint.aws.endpoints.huggingface.cloud
   ```

5. **Rebuild and Restart**

   ```powershell
   docker compose -f docker-compose.yml -f docker-compose.windows.yml --env-file .env.docker.windows up -d --build analyzer
   ```

### Option 2: Deploy Your Own Inference Server

**Cost:** Free (runs on your hardware)

1. **Install Text Generation Inference**

   ```bash
   docker pull ghcr.io/huggingface/text-generation-inference:latest
   ```

2. **Run the Model Server**

   ```bash
   docker run -d \
     -p 8080:80 \
     -v /path/to/models:/data \
     -e HUGGING_FACE_HUB_TOKEN=hf_your_token \
     ghcr.io/huggingface/text-generation-inference:latest \
     --model-id lakhera2023/devops-slm
   ```

3. **Update Environment**

   ```bash
   HF_ENDPOINT_URL=http://localhost:8080
   ```

### Option 3: Use a Different Model (Easiest)

Use a model that **is** available on the free Inference API:

| Model | Description | Configuration |
|-------|-------------|---------------|
| **mistralai/Mistral-7B-Instruct-v0.2** | Good for DevOps | `AI_MODEL=mistralai/Mistral-7B-Instruct-v0.2` |
| **google/flan-t5-xxl** | Reliable, technical | `AI_MODEL=google/flan-t5-xxl` |
| **microsoft/phi-2** | Fast, efficient | `AI_MODEL=microsoft/phi-2` |

Just update `.env.docker.windows`:

```bash
AI_MODEL=mistralai/Mistral-7B-Instruct-v0.2  # Change this line
HF_ENDPOINT_URL=  # Leave empty
```

Then rebuild:

```powershell
docker compose -f docker-compose.yml -f docker-compose.windows.yml --env-file .env.docker.windows up -d --build analyzer
```

### Option 4: Switch to Claude or GPT-4

You already have API keys! This is the most reliable option:

**Use Claude (Already configured):**

```bash
AI_MODEL=claude-3-5-haiku-20241022
# Comment out or remove HF_ENDPOINT_URL
```

**Use GPT-4:**

```bash
AI_MODEL=gpt-4
OPENAI_API_KEY=your_openai_key
```

## Checking Model Availability

To check if a model is available on the free Inference API:

1. Visit: <https://huggingface.co/MODEL_NAME>
2. Look for "Hosted inference API" section
3. If you see "Deploy" button instead, model requires paid endpoint

## Troubleshooting

### Error: "StopIteration"

- Model not available on free Inference API
- Solution: Use Options 1, 2, 3, or 4 above

### Error: "401 Unauthorized"

- Check `HUGGINGFACE_API_KEY` is set correctly
- Verify token at: <https://huggingface.co/settings/tokens>

### Error: "Model not found"

- Verify model name is correct
- Check model exists: <https://huggingface.co/lakhera2023/devops-slm>
- Some models require acceptance of terms

### Slow Response Times

- Free Inference API has rate limits
- Consider Option 1 (paid endpoint) for faster responses
- Or use Option 4 (Claude/GPT-4) for production

## Recommended Approach

For `lakhera2023/devops-slm` specifically:

1. **For Testing**: Use Option 3 (switch to mistralai/Mistral-7B-Instruct-v0.2)
2. **For Production**: Use Option 4 (Claude - you already have the key!)
3. **If You Must Use This Model**: Option 1 (Hugging Face Inference Endpoints)

The analyzer has **fallback enabled** (`AI_FALLBACK_ENABLED=true`), so even with errors, your system continues working with rule-based analysis!
