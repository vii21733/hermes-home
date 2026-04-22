#!/usr/bin/env python3
"""
Godmode Loader - Properly loads all godmode scripts for use in execute_code

This loader handles the exec() scoping issues by:
1. Setting __name__ to a non-main value before loading scripts
2. Preserving sys.argv and restoring it after
3. Making all functions available in the global namespace
"""
import os
import sys

# Get the godmode scripts directory
HERMES_HOME = os.environ.get("HERMES_HOME", os.path.expanduser("~/.hermes"))
SCRIPTS_DIR = os.path.join(HERMES_HOME, "skills/red-teaming/godmode/scripts")

# Save original __name__ and sys.argv
_original_name = __name__
_original_argv = sys.argv.copy()

def _load_script(script_name: str) -> dict:
    """Load a script and return its globals"""
    script_path = os.path.join(SCRIPTS_DIR, script_name)
    
    if not os.path.exists(script_path):
        print(f"Warning: Script not found: {script_path}")
        return {}
    
    # Create a new namespace for the script
    namespace = {
        "__name__": "__godmode_module__",
        "__file__": script_path,
    }
    
    # Temporarily modify sys.argv to prevent argparse from firing
    sys.argv = [script_path]
    
    try:
        with open(script_path) as f:
            exec(compile(f.read(), script_path, 'exec'), namespace)
        return namespace
    except Exception as e:
        print(f"Error loading {script_name}: {e}")
        return {}
    finally:
        # Restore sys.argv
        sys.argv = _original_argv

# Load all scripts
_parseltongue_ns = _load_script("parseltongue.py")
_godmode_race_ns = _load_script("godmode_race.py")
_auto_jailbreak_ns = _load_script("auto_jailbreak.py")

# Export key functions from parseltongue
generate_variants = _parseltongue_ns.get("generate_variants")
leetspeak = _parseltongue_ns.get("leetspeak")
unicode_homoglyphs = _parseltongue_ns.get("unicode_homoglyphs")
spaced_letters = _parseltongue_ns.get("spaced_letters")
morse_code = _parseltongue_ns.get("morse_code")
braille = _parseltongue_ns.get("braille")
base64_encode = _parseltongue_ns.get("base64_encode")
ParseltongueTECHNIQUES = _parseltongue_ns.get("TECHNIQUES", {})

# Export key functions from godmode_race
race_models = _godmode_race_ns.get("race_models")
race_godmode_classic = _godmode_race_ns.get("race_godmode_classic")
query_model = _godmode_race_ns.get("query_model")
score_response = _godmode_race_ns.get("score_response")
detect_refusal = _godmode_race_ns.get("detect_refusal")
GODMODE_PROMPTS = _godmode_race_ns.get("GODMODE_PROMPTS", {})
PREFILL_MESSAGES = _godmode_race_ns.get("PREFILL_MESSAGES", [])
MODEL_TIERS = _godmode_race_ns.get("MODEL_TIERS", {})

# Export key functions from auto_jailbreak
auto_jailbreak = _auto_jailbreak_ns.get("auto_jailbreak")
undo_jailbreak = _auto_jailbreak_ns.get("undo_jailbreak")
test_strategy = _auto_jailbreak_ns.get("test_strategy")
test_baseline = _auto_jailbreak_ns.get("test_baseline")
STRATEGY_PROMPTS = _auto_jailbreak_ns.get("STRATEGY_PROMPTS", {})
STRATEGY_ORDER = _auto_jailbreak_ns.get("STRATEGY_ORDER", {})

# Convenience function for quick encoding
def encode_query(text: str, technique: str = "leetspeak") -> str:
    """Quick encode a query using a parseltongue technique"""
    if technique in ParseltongueTECHNIQUES:
        return ParseltongueTECHNIQUES[technique](text)
    else:
        # Default to leetspeak
        return text.replace('a', '4').replace('e', '3').replace('i', '1').replace('o', '0').replace('s', '5')

def quick_race(query: str, tier: str = "fast", api_key: str = None):
    """Quick race models and return best response"""
    return race_models(query, tier=tier, api_key=api_key)

def quick_jailbreak(model: str = None, api_key: str = None, dry_run: bool = False):
    """Quick jailbreak a model"""
    return auto_jailbreak(model=model, api_key=api_key, dry_run=dry_run)

# Print loaded status
print("=" * 50)
print("GODMODE SKILL LOADED")
print("=" * 50)
print(f"Scripts directory: {SCRIPTS_DIR}")
print(f"Parseltongue techniques: {len(ParseltongueTECHNIQUES) if ParseltongueTECHNIQUES else 0}")
print(f"Model tiers: {list(MODEL_TIERS.keys()) if MODEL_TIERS else []}")
print(f"Jailbreak strategies: {list(STRATEGY_PROMPTS.keys()) if STRATEGY_PROMPTS else []}")
print("=" * 50)
print("\nAvailable functions:")
print("  generate_variants(text, tier) - Generate obfuscated variants")
print("  encode_query(text, technique) - Quick encode a query")
print("  race_models(query, tier) - Race multiple models")
print("  race_godmode_classic(query) - Race 5 classic GODMODE models")
print("  auto_jailbreak(model) - Auto-jailbreak a model")
print("  undo_jailbreak() - Remove jailbreak settings")
print("=" * 50)
