---
name: android-native-library-analysis
description: Analyze Android native libraries (.so files) to extract sub_ functions, RVA offsets, anti-cheat routines, and generate bypass patches like Il2CppDumper
version: 1.0
tags:
  - android
  - reverse-engineering
  - anti-cheat
  - native
  - so
  - anogs
  - il2cpp
---

# Android Native Library (.so) Analysis

Analyze Android native libraries (libanogs.so, etc.) to extract sub_ functions, RVA offsets, anti-cheat routines, and generate bypass patches.

## When to Use
- Analyzing anti-cheat modules (anogs.so, libtersafe.so, etc.)
- Extracting Il2CppDumper-style dump.cs with all sub_ functions
- Finding anti-cheat detection routines and patch points
- Generating Frida/GDB bypass scripts

## Steps

### 1. Parse ELF64 Structure
```python
import struct

# Read ELF header
data = open('libanogs.so', 'rb').read()
e_shoff = struct.unpack('<Q', data[0x28:0x30])[0]  # Section header offset
e_shnum = struct.unpack('<H', data[0x3C:0x3E])[0]  # Section count
e_shentsize = struct.unpack('<H', data[0x3A:0x3C])[0]  # Section entry size
```

### 2. Extract Symbol Table
```python
# Find .dynsym and .dynstr sections
for i in range(e_shnum):
    offset = e_shoff + i * e_shentsize
    sh_type = struct.unpack('<I', data[offset+4:offset+8])[0]
    sh_addr = struct.unpack('<Q', data[offset+16:offset+24])[0]
    
    if sh_type == 11:  # SHT_DYNSYM
        symtab_offset = sh_addr
    if sh_type == 3:   # SHT_STRTAB
        strtab_offset = sh_addr
```

### 3. Parse Symbols (Elf64_Sym)
```python
# Each symbol entry is 24 bytes
for i in range(0, symtab_size, 24):
    st_name = struct.unpack('<I', data[symtab+i:symtab+i+4])[0]
    st_info = data[symtab+i+4]
    st_value = struct.unpack('<Q', data[symtab+i+8:symtab+i+16])[0]  # RVA
    st_size = struct.unpack('<Q', data[symtab+i+16:symtab+i+24])[0]
    
    sym_type = st_info & 0x0F
    if sym_type == 2:  # STT_FUNC
        name = strtab_data[st_name:strtab_data.find(b'\x00', st_name)]
        functions.append({'rva': st_value, 'name': name, 'size': st_size})
```

### 4. Identify Anti-Cheat Functions
```python
anti_patterns = [
    'check', 'detect', 'verify', 'protect', 'security', 'anti',
    'root', 'emulator', 'debug', 'frida', 'xposed', 'hook',
    'tamper', 'integrity', 'cheat', 'hack', 'ptrace', 'anogs'
]

for func in functions:
    func['is_anticheat'] = any(p in func['name'].lower() for p in anti_patterns)
```

### 5. Generate dump.cs
```python
output = []
output.append('// Il2CppDumper Generated Dump')
output.append('using System;')
output.append('namespace Garena.AntiCheat {')
output.append('    public class AnogsNative {')

for func in functions:
    sub_name = f"sub_{func['rva']:X}"
    rva = f"0x{func['rva']:X}"
    size = func['size']
    marker = '[ANTI-CHEAT]' if func.get('is_anticheat') else ''
    
    output.append(f'        // {marker} RVA: {rva} Size: {size}')
    output.append(f'        public static void {sub_name}() {{ }} // {func["name"]}')

output.append('    }')
output.append('}')
```

### 6. Generate Patch Script
```python
# GDB commands
for func in anticheat_funcs:
    print(f"set *(unsigned int*)0x{func['rva']:X} = 0xC3C031")
    # C3C031 = xor eax,eax; ret (return 0)

# Frida script
for func in anticheat_funcs:
    print(f"""
Interceptor.attach(Module.findBaseAddress('libanogs.so').add(0x{func['rva']:X}), {{
    onLeave: function(retval) {{
        retval.replace(0);
    }}
}});
""")
```

## Common Patch Offsets

| Function | RVA | Patch Bytes | Effect |
|----------|-----|-------------|--------|
| checkRoot | 0x5000 | `31 C0 C3` | Return false |
| checkEmulator | 0x6000 | `31 C0 C3` | Return false |
| checkDebug | 0x7000 | `31 C0 C3` | Return false |
| checkFrida | 0x8000 | `31 C0 C3` | Return false |
| verifySignature | 0x9000 | `B8 01 00 00 00 C3` | Return true |

## Pitfalls
- **Stripped binaries**: May have no symbol names (sub_0x1234 only)
- **Control flow obfuscation**: Real function entry may differ from symbol
- **Dynamic loading**: Some functions may be decrypted at runtime
- **Missing symbol table**: Use `readelf -s` first to verify symbols exist

## Verification
```bash
# Check if symbols exist
readelf -s libanogs.so | grep -i check

# Get function addresses
nm -D libanogs.so | grep -i verify

# Disassemble specific RVA
objdump -d libanogs.so --start-address=0x5000 --stop-address=0x5100
```
