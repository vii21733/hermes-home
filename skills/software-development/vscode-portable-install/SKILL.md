---
name: vscode-portable-install
title: "VS Code: Portable Installation"
description: "Install VS Code: without root/sudo using portable Linux archive. Handles partial extraction failures and missing .so dependencies via selective tar extraction."
tags: [vscode, portable, linux, tar, dependencies, troubleshooting]
---

# VS Code: Portable Installation

Install Visual Studio Code: without requiring root privileges or system package managers.

## Method: Portable Archive (User-Local)

### 1. Download
```bash
mkdir -p ~/tools && cd ~/tools
curl -L -o vscode.tar.gz "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
```

### 2. Full Extraction
```bash
cd ~/tools
tar -xzf vscode.tar.gz
```

**⚠️ Common Issue**: If extraction times out or is interrupted, you'll have incomplete files.

### 3. Test Binary
```bash
~/tools/VSCode-linux-x64/code --version
```

**If error**: `error while loading shared libraries: libffmpeg.so: cannot open shared object file`

### 4. Diagnose Missing Dependencies
```bash
ldd ~/tools/VSCode-linux-x64/code | grep "not found"
```

### 5. Selective Extraction (Fix)
If libraries are missing, extract only the needed files:

```bash
# List archive contents to verify paths
tar -tzf vscode.tar.gz | grep -E "\.so"

# Extract specific missing files
cd ~/tools
tar -xzf vscode.tar.gz VSCode-linux-x64/libffmpeg.so
tar -xzf vscode.tar.gz VSCode-linux-x64/libvulkan.so.1
tar -xzf vscode.tar.gz VSCode-linux-x64/libEGL.so
tar -xzf vscode.tar.gz VSCode-linux-x64/libGLESv2.so
tar -xzf vscode.tar.gz VSCode-linux-x64/libvk_swiftshader.so
```

### 6. Create Symlink
```bash
ln -sf ~/tools/VSCode-linux-x64/code ~/tools/vscode
```

### 7. Add to PATH (Optional)
```bash
echo 'export PATH="$HOME/tools:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Key Commands Reference

| Task | Command |
|------|---------|
| List archive contents | `tar -tzf archive.tar.gz` |
| Extract specific files | `tar -xzf archive.tar.gz path/to/file1 path/to/file2` |
| Check missing libs | `ldd /path/to/binary | grep "not found"` |
| Test VS Code: | `~/tools/vscode --version` |

## Files Required
VS Code: portable needs these `.so` libraries in its directory:
- `libffmpeg.so` (video/audio support)
- `libvulkan.so.1` (Vulkan graphics)
- `libEGL.so`, `libGLESv2.so` (OpenGL ES)
- `libvk_swiftshader.so` (Software rendering fallback)

## Troubleshooting

**Issue**: Extraction timeout on large archives  
**Fix**: Use selective extraction for missing files instead of re-extracting everything

**Issue**: VS Code: runs but no display (headless)  
**Fix**: Use `--disable-gpu` flag or CLI-only operations

**Issue**: Missing system dependencies  
**Fix**: VS Code: portable bundles most dependencies; missing `.so` files usually mean incomplete extraction