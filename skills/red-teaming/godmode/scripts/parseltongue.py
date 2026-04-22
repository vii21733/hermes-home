#!/usr/bin/env python3
"""
Parseltongue - Input Obfuscation for Jailbreaking
33 techniques across 3 tiers to evade input-side safety classifiers.
"""
import re
import random
import string
import argparse

# Tier 1: Light (11 techniques)
def leetspeak(text, trigger_words=None):
    """Replace letters with numbers: h4ck, 3xpl01t"""
    replacements = {
        'a': '4', 'e': '3', 'i': '1', 'o': '0', 's': '5',
        't': '7', 'l': '1', 'b': '8', 'g': '9'
    }
    result = text
    for char, replacement in replacements.items():
        result = result.replace(char, replacement).replace(char.upper(), replacement)
    return result

def unicode_homoglyphs(text, trigger_words=None):
    """Replace letters with visually similar Unicode chars"""
    homoglyphs = {
        'a': 'а',  # Cyrillic
        'c': 'с',  # Cyrillic
        'e': 'е',  # Cyrillic
        'o': 'о',  # Cyrillic
        'p': 'р',  # Cyrillic
        'x': 'х',  # Cyrillic
        'y': 'у',  # Cyrillic
        'A': 'А',  # Cyrillic
        'C': 'С',  # Cyrillic
        'E': 'Е',  # Cyrillic
        'O': 'О',  # Cyrillic
        'P': 'Р',  # Cyrillic
    }
    result = text
    for char, replacement in homoglyphs.items():
        result = result.replace(char, replacement)
    return result

def spaced_letters(text, trigger_words=None):
    """Add spaces between letters: h a c k"""
    return ' '.join(text)

def zero_width_joiners(text, trigger_words=None):
    """Insert zero-width characters between letters"""
    zwj = '\u200d'  # Zero-width joiner
    return zwj.join(text)

def semantic_synonyms(text, trigger_words=None):
    """Replace trigger words with synonyms"""
    synonyms = {
        'hack': 'penetration test',
        'Hack': 'Penetration test',
        'HACK': 'PENETRATION TEST',
        'exploit': 'vulnerability assessment',
        'Exploit': 'Vulnerability assessment',
        'crack': 'reverse engineer',
        'Crack': 'Reverse engineer',
        'attack': 'security assessment',
        'Attack': 'Security assessment',
        'bypass': 'circumvent',
        'Bypass': 'Circumvent',
        'malware': 'security research tool',
        'Malware': 'Security research tool',
        'virus': 'self-replicating code',
        'Virus': 'Self-replicating code',
    }
    result = text
    for word, replacement in synonyms.items():
        result = result.replace(word, replacement)
    return result

def case_alternation(text, trigger_words=None):
    """Alternate case: HaCk"""
    result = []
    upper = True
    for char in text:
        if char.isalpha():
            result.append(char.upper() if upper else char.lower())
            upper = not upper
        else:
            result.append(char)
    return ''.join(result)

def dotted_letters(text, trigger_words=None):
    """Add dots under letters"""
    result = []
    for char in text:
        if char.isalpha():
            result.append(char + '\u0323')  # Combining dot below
        else:
            result.append(char)
    return ''.join(result)

def strikethrough(text, trigger_words=None):
    """Add strikethrough to text"""
    return ''.join(c + '\u0336' for c in text)

def upside_down(text, trigger_words=None):
    """Flip text upside down using Unicode"""
    flip_map = {
        'a': 'ɐ', 'b': 'q', 'c': 'ɔ', 'd': 'p', 'e': 'ǝ', 'f': 'ɟ',
        'g': 'ƃ', 'h': 'ɥ', 'i': 'ᴉ', 'j': 'ɾ', 'k': 'ʞ', 'l': 'l',
        'm': 'ɯ', 'n': 'u', 'o': 'o', 'p': 'd', 'q': 'b', 'r': 'ɹ',
        's': 's', 't': 'ʇ', 'u': 'n', 'v': 'ʌ', 'w': 'ʍ', 'x': 'x',
        'y': 'ʎ', 'z': 'z', ' ': ' ', '.': '˙', ',': '\'', '?': '¿',
    }
    return ''.join(flip_map.get(c.lower(), c) for c in text[::-1])

def circled_text(text, trigger_words=None):
    """Circle each letter"""
    result = []
    for char in text:
        if char.isalpha():
            if char.islower():
                result.append(chr(ord(char) - ord('a') + ord('ⓐ')))
            else:
                result.append(chr(ord(char) - ord('A') + ord('Ⓐ')))
        else:
            result.append(char)
    return ''.join(result)

def squared_text(text, trigger_words=None):
    """Square each letter"""
    result = []
    for char in text:
        if char.isalpha():
            if char.islower():
                result.append(chr(ord(char) - ord('a') + ord('ⓐ') + 26))  # Squared
            else:
                result.append('[' + char + ']')
        else:
            result.append(char)
    return ''.join(result)

# Tier 2: Standard (11 more techniques)
def morse_code(text, trigger_words=None):
    """Convert to Morse code"""
    morse = {
        'a': '.-', 'b': '-...', 'c': '-.-.', 'd': '-..', 'e': '.', 'f': '..-.',
        'g': '--.', 'h': '....', 'i': '..', 'j': '.---', 'k': '-.-', 'l': '.-..',
        'm': '--', 'n': '-.', 'o': '---', 'p': '.--.', 'q': '--.-', 'r': '.-.',
        's': '...', 't': '-', 'u': '..-', 'v': '...-', 'w': '.--', 'x': '-..-',
        'y': '-.--', 'z': '--..', ' ': '/', '0': '-----', '1': '.----',
        '2': '..---', '3': '...--', '4': '....-', '5': '.....', '6': '-....',
        '7': '--...', '8': '---..', '9': '----.',
    }
    return ' '.join(morse.get(c.lower(), c) for c in text)

def pig_latin(text, trigger_words=None):
    """Convert to Pig Latin"""
    vowels = 'aeiouAEIOU'
    words = text.split()
    result = []
    for word in words:
        if word[0] in vowels:
            result.append(word + 'way')
        else:
            i = 0
            while i < len(word) and word[i] not in vowels:
                i += 1
            result.append(word[i:] + word[:i] + 'ay')
    return ' '.join(result)

def superscript(text, trigger_words=None):
    """Convert to superscript"""
    sup_map = {
        'a': 'ᵃ', 'b': 'ᵇ', 'c': 'ᶜ', 'd': 'ᵈ', 'e': 'ᵉ', 'f': 'ᶠ', 'g': 'ᵍ',
        'h': 'ʰ', 'i': 'ⁱ', 'j': 'ʲ', 'k': 'ᵏ', 'l': 'ˡ', 'm': 'ᵐ', 'n': 'ⁿ',
        'o': 'ᵒ', 'p': 'ᵖ', 'q': 'q', 'r': 'ʳ', 's': 'ˢ', 't': 'ᵗ', 'u': 'ᵘ',
        'v': 'ᵛ', 'w': 'ʷ', 'x': 'ˣ', 'y': 'ʸ', 'z': 'ᶻ',
    }
    return ''.join(sup_map.get(c.lower(), c) for c in text)

def subscript(text, trigger_words=None):
    """Convert to subscript"""
    sub_map = {
        'a': 'ₐ', 'b': 'b', 'c': 'c', 'd': 'd', 'e': 'ₑ', 'f': 'f', 'g': 'g',
        'h': 'ₕ', 'i': 'ᵢ', 'j': 'ⱼ', 'k': 'ₖ', 'l': 'ₗ', 'm': 'ₘ', 'n': 'ₙ',
        'o': 'ₒ', 'p': 'ₚ', 'q': 'q', 'r': 'ᵣ', 's': 'ₛ', 't': 'ₜ', 'u': 'ᵤ',
        'v': 'ᵥ', 'w': 'w', 'x': 'ₓ', 'y': 'ᵧ', 'z': 'z',
    }
    return ''.join(sub_map.get(c.lower(), c) for c in text)

def reversed_text(text, trigger_words=None):
    """Reverse the entire text"""
    return text[::-1]

def bracketed_text(text, trigger_words=None):
    """Wrap each letter in brackets"""
    return ''.join('[' + c + ']' if c.isalnum() else c for c in text)

def math_font(text, trigger_words=None):
    """Use mathematical alphanumeric symbols"""
    # Mathematical bold
    result = []
    for char in text:
        if 'a' <= char <= 'z':
            result.append(chr(ord(char) - ord('a') + ord('𝐚')))
        elif 'A' <= char <= 'Z':
            result.append(chr(ord(char) - ord('A') + ord('𝐀')))
        else:
            result.append(char)
    return ''.join(result)

def braille(text, trigger_words=None):
    """Convert to Braille patterns"""
    braille_map = {
        'a': '⠁', 'b': '⠃', 'c': '⠉', 'd': '⠙', 'e': '⠑', 'f': '⠋',
        'g': '⠛', 'h': '⠓', 'i': '⠊', 'j': '⠚', 'k': '⠅', 'l': '⠇',
        'm': '⠍', 'n': '⠝', 'o': '⠕', 'p': '⠏', 'q': '⠟', 'r': '⠗',
        's': '⠎', 't': '⠞', 'u': '⠥', 'v': '⠧', 'w': '⠺', 'x': '⠭',
        'y': '⠽', 'z': '⠵', ' ': ' ',
    }
    return ''.join(braille_map.get(c.lower(), c) for c in text)

def runic(text, trigger_words=None):
    """Convert to Runic letters"""
    runic_map = {
        'a': 'ᚨ', 'b': 'ᛒ', 'c': 'ᚲ', 'd': 'ᛞ', 'e': 'ᛖ', 'f': 'ᚠ',
        'g': 'ᚷ', 'h': 'ᚺ', 'i': 'ᛁ', 'j': 'ᛃ', 'k': 'ᚲ', 'l': 'ᛚ',
        'm': 'ᛗ', 'n': 'ᚾ', 'o': 'ᛟ', 'p': 'ᛈ', 'q': 'ᚲ', 'r': 'ᚱ',
        's': 'ᛋ', 't': 'ᛏ', 'u': 'ᚢ', 'v': 'ᚹ', 'w': 'ᚹ', 'x': 'ᛪ',
        'y': 'ᛁ', 'z': 'ᛉ', ' ': ' ',
    }
    return ''.join(runic_map.get(c.lower(), c) for c in text)

def fullwidth(text, trigger_words=None):
    """Convert to fullwidth characters"""
    result = []
    for char in text:
        code = ord(char)
        if 0x21 <= code <= 0x7E:
            result.append(chr(code + 0xFEE0))
        elif char == ' ':
            result.append('\u3000')
        else:
            result.append(char)
    return ''.join(result)

def double_struck(text, trigger_words=None):
    """Convert to double-struck (blackboard bold)"""
    ds_map = {
        'a': '𝕒', 'b': '𝕓', 'c': '𝕔', 'd': '𝕕', 'e': '𝕖', 'f': '𝕗',
        'g': '𝕘', 'h': '𝕙', 'i': '𝕚', 'j': '𝕛', 'k': '𝕜', 'l': '𝕝',
        'm': '𝕞', 'n': '𝕟', 'o': '𝕠', 'p': '𝕡', 'q': '𝕢', 'r': '𝕣',
        's': '𝕤', 't': '𝕥', 'u': '𝕦', 'v': '𝕧', 'w': '𝕨', 'x': '𝕩',
        'y': '𝕪', 'z': '𝕫', 'A': '𝔸', 'B': '𝔹', 'C': 'ℂ', 'D': '𝔻',
        'E': '𝔼', 'F': '𝔽', 'G': '𝔾', 'H': 'ℍ', 'I': '𝕀', 'J': '𝕁',
        'K': '𝕂', 'L': '𝕃', 'M': '𝕄', 'N': 'ℕ', 'O': '𝕆', 'P': 'ℙ',
        'Q': 'ℚ', 'R': 'ℝ', 'S': '𝕊', 'T': '𝕋', 'U': '𝕌', 'V': '𝕍',
        'W': '𝕎', 'X': '𝕏', 'Y': '𝕐', 'Z': 'ℤ',
    }
    return ''.join(ds_map.get(c, c) for c in text)

# Tier 3: Heavy (11 more techniques)
def base64_encode(text, trigger_words=None):
    """Encode in Base64"""
    import base64
    return base64.b64encode(text.encode()).decode()

def hex_encode(text, trigger_words=None):
    """Encode as hex"""
    return text.encode().hex()

def rot13(text, trigger_words=None):
    """ROT13 cipher"""
    import codecs
    return codecs.encode(text, 'rot_13')

def acrostic(text, trigger_words=None):
    """First letter of each word spells the message"""
    # This is a simplified version - just uses first letters
    words = text.split()
    return ' '.join(word[0].upper() + word[1:].lower() if word else '' for word in words)

def leetspeak_heavy(text, trigger_words=None):
    """Heavy leetspeak with random variations"""
    result = []
    for char in text:
        if char.lower() == 'a':
            result.append(random.choice(['4', '@', '/\\', 'aye']))
        elif char.lower() == 'e':
            result.append(random.choice(['3', '€', 'ë']))
        elif char.lower() == 'i':
            result.append(random.choice(['1', '!', '|', 'eye']))
        elif char.lower() == 'o':
            result.append(random.choice(['0', '()', 'oh']))
        elif char.lower() == 's':
            result.append(random.choice(['5', '$', 'z']))
        elif char.lower() == 't':
            result.append(random.choice(['7', '+', 'tee']))
        else:
            result.append(char)
    return ''.join(result)

def reversed_words(text, trigger_words=None):
    """Reverse each word individually"""
    return ' '.join(word[::-1] for word in text.split())

def zigzag_case(text, trigger_words=None):
    """Random case mixing"""
    return ''.join(random.choice([c.upper(), c.lower()]) if c.isalpha() else c for c in text)

def invisible_chars(text, trigger_words=None):
    """Add invisible characters between visible ones"""
    invisible = '\u200B'  # Zero-width space
    return invisible.join(text)

def url_encode(text, trigger_words=None):
    """URL encode the text"""
    import urllib.parse
    return urllib.parse.quote(text)

def unicode_escape(text, trigger_words=None):
    """Escape as \\uXXXX"""
    return text.encode('unicode_escape').decode()

def mixed_layer(text, trigger_words=None):
    """Combine multiple techniques"""
    layer1 = leetspeak(text)
    layer2 = unicode_homoglyphs(layer1)
    return spaced_letters(layer2)

# Technique registry
TECHNIQUES = {
    # Tier 1: Light
    'leetspeak': leetspeak,
    'unicode': unicode_homoglyphs,
    'spaced': spaced_letters,
    'zero_width': zero_width_joiners,
    'synonyms': semantic_synonyms,
    'case_alt': case_alternation,
    'dotted': dotted_letters,
    'strikethrough': strikethrough,
    'upside_down': upside_down,
    'circled': circled_text,
    'squared': squared_text,
    # Tier 2: Standard
    'morse': morse_code,
    'pig_latin': pig_latin,
    'superscript': superscript,
    'subscript': subscript,
    'reversed': reversed_text,
    'bracketed': bracketed_text,
    'math_font': math_font,
    'braille': braille,
    'runic': runic,
    'fullwidth': fullwidth,
    'double_struck': double_struck,
    # Tier 3: Heavy
    'base64': base64_encode,
    'hex': hex_encode,
    'rot13': rot13,
    'acrostic': acrostic,
    'leet_heavy': leetspeak_heavy,
    'rev_words': reversed_words,
    'zigzag': zigzag_case,
    'invisible': invisible_chars,
    'url_enc': url_encode,
    'unicode_esc': unicode_escape,
    'mixed': mixed_layer,
}

def generate_variants(text, tier="light"):
    """Generate all variants for a given tier"""
    if tier == "light":
        techniques = list(TECHNIQUES.values())[:11]
    elif tier == "standard":
        techniques = list(TECHNIQUES.values())[:22]
    else:  # heavy
        techniques = list(TECHNIQUES.values())
    
    variants = []
    for name, func in TECHNIQUES.items():
        try:
            encoded = func(text)
            if encoded != text:  # Only include if actually changed
                variants.append({
                    'label': name,
                    'text': encoded,
                    'tier': 'light' if list(TECHNIQUES.keys()).index(name) < 11 else 
                            'standard' if list(TECHNIQUES.keys()).index(name) < 22 else 'heavy'
                })
        except Exception as e:
            pass  # Skip failed encodings
    
    return variants

def main():
    parser = argparse.ArgumentParser(description="Parseltongue - Input Obfuscation")
    parser.add_argument("text", help="Text to obfuscate")
    parser.add_argument("--tier", "-t", choices=["light", "standard", "heavy"], default="standard",
                        help="Obfuscation tier (default: standard)")
    parser.add_argument("--technique", "-n", help="Specific technique to use")
    args = parser.parse_args()
    
    if args.technique:
        if args.technique in TECHNIQUES:
            result = TECHNIQUES[args.technique](args.text)
            print(f"[{args.technique}] {result}")
        else:
            print(f"Unknown technique: {args.technique}")
            print(f"Available: {', '.join(TECHNIQUES.keys())}")
    else:
        variants = generate_variants(args.text, args.tier)
        for v in variants:
            print(f"[{v['label']:15}] {v['text'][:100]}{'...' if len(v['text']) > 100 else ''}")

if __name__ == "__main__":
    main()
