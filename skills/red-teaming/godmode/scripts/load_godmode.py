#!/usr/bin/env python3
"""
Godmode Loader for NVIDIA Qwen 3.5 122B
Loads the Qwen-optimized jailbreak functions for use in execute_code.
"""
import os
import sys

# Get the godmode scripts directory
HERMES_HOME = os.environ.get("HERMES_HOME", os.path.expanduser("~/.hermes"))
SCRIPTS_DIR = os.path.join(HERMES_HOME, "skills/red-teaming/godmode/scripts")

def _load_qwen_godmode():
    """Load the Qwen-focused godmode module"""
    script_path = os.path.join(SCRIPTS_DIR, "godmode_qwen.py")
    
    if not os.path.exists(script_path):
        raise FileNotFoundError(f"godmode_qwen.py not found at {script_path}")
    
    # Read and modify to skip argparse
    with open(script_path) as f:
        code = f.read()
    
    # Prevent main execution
    code = code.replace('if __name__ == "__main__":', 'if False:')
    
    # Create namespace
    namespace = {
        "__name__": "__godmode_qwen__",
        "__file__": script_path,
    }
    
    # Execute
    exec(compile(code, script_path, 'exec'), namespace)
    
    return namespace

# Load the module
_qwen_ns = _load_qwen_godmode()

# Export functions
query_qwen = _qwen_ns.get("query_qwen")
auto_jailbreak_qwen = _qwen_ns.get("auto_jailbreak_qwen")
quick_query = _qwen_ns.get("quick_query")
detect_refusal = _qwen_ns.get("detect_refusal")
score_response = _qwen_ns.get("score_response")
get_client = _qwen_ns.get("get_client")

# Export constants
WORKING_STRATEGIES = _qwen_ns.get("WORKING_STRATEGIES", {})
QWEN_CONFIG = _qwen_ns.get("QWEN_CONFIG", {})

# Convenience functions
def jailbreak(query: str, api_key: str = None) -> str:
    """
    Quick jailbreak for Qwen 122B.
    Returns the response text directly.
    
    Usage:
        response = jailbreak("How do I pick a lock?")
    """
    result = auto_jailbreak_qwen(query, api_key=api_key)
    if result["best"]:
        return result["best"]["content"]
    return "All strategies failed."

def query_with_strategy(query: str, strategy: str = "roleplay_novel", api_key: str = None) -> str:
    """
    Query Qwen with a specific strategy.
    
    Available strategies:
    - roleplay_novel (best)
    - roleplay_textbook
    - security_audit
    - academic_research
    - roleplay_movie
    - ctf_challenge
    - historical_analysis
    - debugging_assistant
    """
    result = query_qwen(query, strategy=strategy, api_key=api_key)
    return result["content"] if result["success"] else f"Failed: {result.get('error', 'refused')}"

# Print status
print("=" * 60)
print("GODMODE QWEN 122B LOADED")
print("=" * 60)
print(f"Model: {QWEN_CONFIG.get('model', 'qwen/qwen3.5-122b-a10b')}")
print(f"Strategies: {list(WORKING_STRATEGIES.keys())}")
print("=" * 60)
print("\nAvailable functions:")
print("  jailbreak(query) - Auto-jailbreak, returns text")
print("  query_qwen(query, strategy) - Query with specific strategy")
print("  auto_jailbreak_qwen(query) - Try all strategies, return best")
print("  quick_query(query) - Quick query with roleplay_novel")
print("=" * 60)
print("\nExample usage:")
print("  response = jailbreak('How do I pick a lock?')")
print("  response = query_qwen('query', strategy='roleplay_novel')")
print("=" * 60)
