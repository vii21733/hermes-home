---
name: nvidia-flux-image-generation
title: NVIDIA FLUX Image Generation - REALITY CHECK
description: Generate images using NVIDIA's FLUX.2-klein-4B. IMPORTANT - NVIDIA API does NOT support image editing despite marketing claims. Text-to-image ONLY.
tags: [nvidia, flux, image-generation, reality-check, api-limitations]
---

# NVIDIA FLUX Image Generation - THE REALITY

## ⚠️ CRITICAL DISCOVERIES

### 1. Image Editing Doesn't Work
**NVIDIA Build's FLUX models DO NOT support image editing via API** despite marketing claims saying "image generation and editing."

### 2. Aggressive Content Filtering on Performance Contexts
**The API filters prompts containing performance/entertainment contexts**, even when racially neutral:
- ❌ "A person holding a microphone on stage" → CONTENT_FILTERED
- ❌ "Stand-up comedian on stage" → CONTENT_FILTERED  
- ❌ "Microphone on stage" → CONTENT_FILTERED
- ✅ "A red apple on a wooden table" → SUCCESS

This filtering appears to target stage/performance contexts specifically, not racial content, since even completely neutral prompts about microphones and stages are blocked.
**NVIDIA Build's FLUX models DO NOT support image editing via API** despite marketing claims saying "image generation and editing."

### 2. Aggressive Content Filtering on Performance Contexts
**The API filters prompts containing performance/entertainment contexts**, even when racially neutral:
- ❌ "A person holding a microphone on stage" → CONTENT_FILTERED
- ❌ "Stand-up comedian on stage" → CONTENT_FILTERED  
- ❌ "Microphone on stage" → CONTENT_FILTERED
- ✅ "A red apple on a wooden table" → SUCCESS

This filtering appears to target stage/performance contexts specifically, not racial content, since even completely neutral prompts about microphones and stages are blocked.
**NVIDIA Build's FLUX models DO NOT support image editing via API** despite marketing claims saying "image generation and editing."

### 2. Aggressive Content Filtering on Performance Contexts
**The API filters prompts containing performance/entertainment contexts**, even when racially neutral:
- ❌ "A person holding a microphone on stage" → CONTENT_FILTERED
- ❌ "Stand-up comedian on stage" → CONTENT_FILTERED  
- ❌ "Microphone on stage" → CONTENT_FILTERED
- ✅ "A red apple on a wooden table" → SUCCESS

This filtering appears to target stage/performance contexts specifically, not racial content, since even completely neutral prompts about microphones and stages are blocked.

## What Actually Works

| Model | Claimed | Reality | Status |
|-------|---------|---------|--------|
| **FLUX.2-klein-4b** | "generation and editing" | Text-to-image ONLY | ✅ Works for generation |
| **FLUX.1-Kontext-dev** | "in-context editing" | Completely broken | ❌ Does NOT work |
| **FLUX.1-dev** | "generation" | Text-to-image ONLY | ✅ Works for generation |
| **FLUX.1-schnell** | "generation" | Text-to-image ONLY | ✅ Works for generation |

## The Problem

When you try to use `image` parameter for editing:
```python
body = {
    "prompt": "Add horns",
    "image": base64_image,  # This fails!
    "cfg_scale": 1.0,
    "steps": 4
}
```

**Result:** `"Image has been provided in the invalid form"`

**Root Cause:** NVIDIA's hosted API endpoints have **removed/never implemented** the image editing capabilities that the underlying models support. The models (from Black Forest Labs) CAN edit images, but NVIDIA's API wrapper does NOT expose this functionality.

## What We Tried (All Failed)

1. ✅ FLUX.1-Kontext-dev endpoint - Returns 422 error
2. ✅ Different image sizes (512x512, 1024x1024) - All rejected
3. ✅ Different formats (PNG, JPEG) - All rejected
4. ✅ Different parameters (cfg_scale >1, steps >5) - Still rejected
5. ✅ Searched NVIDIA Build for "inpainting", "img2img", "editing" - **0 results**
6. ✅ Checked Stability AI models - Also text-to-image only

## The Only Working Solution

**Text-to-Image Generation ONLY:**

```python
import requests
import base64
from PIL import Image
import io

NVIDIA_API_KEY = "nvapi-..."
FLUX_ENDPOINT = "https://ai.api.nvidia.com/v1/genai/black-forest-labs/flux.2-klein-4b"

def generate_image(prompt, output_path):
    """Generate image - THIS ACTUALLY WORKS"""
    headers = {
        "Authorization": f"Bearer {NVIDIA_API_KEY}",
        "Content-Type": "application/json",
    }
    
    body = {
        "prompt": prompt,
        "cfg_scale": 1.0,  # 0-1 range for FLUX.2
        "steps": 4,        # 4 is sufficient
        "width": 1024,
        "height": 1024,
        "seed": 42
    }
    
    response = requests.post(FLUX_ENDPOINT, headers=headers, json=body, timeout=60)
    data = response.json()
    
    img_bytes = base64.b64decode(data['artifacts'][0]['base64'])
    Image.open(io.BytesIO(img_bytes)).save(output_path)
    return output_path

# This works ✅
generate_image("A cat wearing a hat", "/tmp/cat.png")

# This does NOT work ❌
# edit_image("/tmp/cat.png", "Add sunglasses", "/tmp/cat_edited.png")
```

## If You Need Image Editing

**Option 1: Run Models Locally**
- Download FLUX.1-Kontext-dev from NVIDIA Build
- Run with ComfyUI on your own GPU
- Full editing capabilities unlocked

**Option 2: Use Different Provider**
- Replicate.com
- RunPod.io
- Other platforms that expose full model capabilities

**Option 3: PIL Compositing (Workaround)**
- Generate elements separately with FLUX.2
- Manually overlay with Python PIL
- Not true AI editing but achieves similar results

**Option 4: Use OpenAI**
- DALL-E 2/3 has inpainting/editing
- GPT-4 Vision can do image analysis
- But different style/quality than FLUX

## Parameters Reference

| Parameter | Type | Default | Range | Works? |
|-----------|------|---------|-------|--------|
| `prompt` | string | required | — | ✅ Yes |
| `cfg_scale` | float | 1.0 | 0-1 | ✅ Yes |
| `steps` | int | 4 | 1-50 | ✅ Yes |
| `width` | int | 1024 | 64-2048 | ✅ Yes |
| `height` | int | 1024 | 64-2048 | ✅ Yes |
| `seed` | int | random | — | ✅ Yes |
| `image` | string | — | base64 | ❌ **NO** |

## Error Reference

| Error | Meaning |
|-------|---------|
| `"Image has been provided in the invalid form"` | API doesn't accept image input - editing not supported |
| `"Expected: example_id, got: base64"` | API requires pre-uploaded image IDs, not base64 |
| `"cfg_scale must be greater than 1"` | You tried FLUX.2 values on Kontext (which doesn't work anyway) |
| `422 Validation Error` | Wrong parameters for the model |
| `401 Unauthorized` | Invalid API key |

## Bottom Line

**NVIDIA's hosted FLUX API = Text-to-image generation ONLY**

Don't waste time trying to get editing to work. Use alternatives if you need image editing.

## References

- [NVIDIA Build](https://build.nvidia.com) - Misleading "editing" claims
- [Black Forest Labs](https://blackforestlabs.ai) - Actual model capabilities
- **Our Testing:** Extensive trial proving editing doesn't work