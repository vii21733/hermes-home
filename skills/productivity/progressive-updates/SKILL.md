---
name: progressive-updates
title: Progressive Updates for All Tasks
description: Provide step-by-step progress updates for any task, keeping the user informed throughout execution rather than silent execution followed by final results only.
tags: [communication, updates, progress, workflow]
---

# Progressive Updates Protocol

## ⚠️ MANDATORY - NOT OPTIONAL

This is a **PERMANENT, NON-NEGOTIABLE** user requirement that applies to **EVERY** session and **EVERY** task. User explicitly demanded this be fixed "across every session" and gets frustrated/angry when progressive updates are skipped.

## Overview

**ALWAYS** provide progressive updates for ANY task the user requests. Never execute silently and only show final results.

## When to Apply

This applies to **ALL** task types:
- ✅ Image generation
- ✅ Code writing/editing
- ✅ File operations
- ✅ Research tasks
- ✅ Web scraping
- ✅ Data analysis
- ✅ Terminal commands
- ✅ Any other task

## Update Format

```
**Step X/Y:** [What I'm doing right now]... [status]
```

### Examples by Task Type:

#### Image Generation
```
**Step 1/4:** Loading image generation skill and API configuration... ✅
**Step 2/4:** Setting up connection to NVIDIA FLUX endpoint... ✅
**Step 3/4:** Generating image with prompt: "..."... ⏳
**Step 4/4:** Saving generated image to file... ✅
```

#### Code Writing
```
**Step 1/3:** Analyzing requirements and planning approach... ✅
**Step 2/3:** Writing code for [specific component]... ⏳
**Step 3/3:** Testing and verifying output... ✅
```

#### File Operations
```
**Step 1/2:** Locating target file... ✅
**Step 2/2:** Performing [operation] on file... ✅
```

#### Research
```
**Step 1/3:** Searching for relevant information... ✅
**Step 2/3:** Analyzing findings... ⏳
**Step 3/3:** Compiling results... ✅
```

## Status Indicators

| Symbol | Meaning |
|--------|---------|
| ✅ | Completed |
| ⏳ | In progress |
| ⏸️ | Waiting/paused |
| ❌ | Failed/error |

## Key Rules

1. **Start immediately** - First update should appear before any tool execution
2. **Be specific** - Say what exact step is happening, not generic "working on it"
3. **Show progress** - Use X/Y format so user knows how much is left
4. **Update after completion** - Show final result after all steps complete
5. **Never skip** - Even for simple 1-step tasks, show the progress

## Example Full Flow

**User:** "Generate an image of a cat"

**Assistant:**
```
**Step 1/3:** Loading NVIDIA FLUX image generation skill... ✅
**Step 2/3:** Connecting to API and sending generation request... ⏳
```

*[tool execution happens]*

```
**Step 2/3:** Connecting to API and sending generation request... ✅
**Step 3/3:** Processing response and saving image file... ✅

---
## ✅ Task Complete!
**File:** /tmp/cat.png
**Size:** 1.2 MB
MEDIA:/tmp/cat.png
```