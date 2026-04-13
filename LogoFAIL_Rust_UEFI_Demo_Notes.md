
# LogoFAIL, UEFI, and Rust Bounds Safety – Working Notes & Discovery Log

## Purpose
This document captures the full reasoning, discovery, and explanatory narrative developed to explain how Rust’s safety guarantees would have prevented LogoFAIL-class UEFI vulnerabilities. It is intended to be portable and uploaded into another AI agent or shared with collaborators.

---

## Context: LogoFAIL
LogoFAIL is a class of UEFI firmware vulnerabilities disclosed by Binarly in late 2023 affecting image parsers (e.g., BMP) executed during the DXE phase of boot. Improper handling of image metadata (dimensions, compression fields) allows memory corruption and arbitrary code execution before Secure Boot enforcement.

Core characteristics:
- Attacker-controlled image metadata
- Signedness and integer overflow errors
- Unchecked pointer arithmetic
- Out-of-bounds writes during early boot

---

## Core Industry Bug Pattern (UEFI)

1. Parse untrusted image field (e.g., PixelHeight)
2. Store value in signed integer
3. Use value in offset/index calculation
4. Negative or overflowed value underflows pointer arithmetic
5. Memory before buffer overwritten
6. Control flow hijacked (code/data injection)

This pattern has existed in firmware for over a decade.

---

## How Rust Structurally Blocks This Bug Class

### 1. Negative Indices Are Unrepresentable
Rust slice and Vec indexing requires `usize`. Signed integers (`i32`, `isize`) cannot be used as indices:

```rust
let i: isize = -1;
let v = vec![0u8; 10];
v[i]; // compile-time error
```

The exploit is blocked before compilation.

---

### 2. Explicit Casts Still Trigger Bounds Checks

```rust
let i: isize = -1;
let idx = i as usize;
v[idx] = 0;
```

- `-1 as usize` → very large positive value
- Rust emits `if idx >= len { panic }`
- Memory write never executes

---

### 3. All Safe Indexing Is Bounds Checked
In safe Rust:
- `[]`
- `.get()` / `.get_mut()`
- slicing

are all bounds checked by language guarantee.

---

### 4. Pointer Arithmetic Requires `unsafe`

The only way to recreate the LogoFAIL write primitive is explicit unsafe code:

```rust
unsafe {
    *ptr.offset(i) = value;
}
```

This shifts responsibility to the developer and makes the risk explicit and auditable.

---

## Mapping LogoFAIL to Rust Guarantees

| LogoFAIL Root Cause | Rust Safe-Code Outcome |
|-------------------|------------------------|
| Signed index      | Compile-time error     |
| Integer underflow | Panic before write     |
| Pointer arithmetic| `unsafe` required      |
| Silent corruption | Impossible             |

---

## Why This Matters for Firmware

Image parsing during boot is a high-privilege, pre-OS attack surface. Rust eliminates entire vulnerability classes not by convention, but by making unsafe states unrepresentable.

This does not eliminate logic bugs, but it prevents silent memory corruption—the prerequisite for persistent firmware compromise.

---

## Booth Demonstration Strategy (Summary)

### 3-Second Hook
> “This UEFI exploit class is impossible in safe Rust.”

### Visual Proof
Side-by-side:
- C-like parser with signed index
- Rust equivalent that fails to compile or panics

### Interactive Demo
Button:
- Run C version → memory write succeeds
- Run Rust version → compile error or panic

### QR Code
Link to this document for technical depth.

---

## Key Framing Sentence

> “LogoFAIL isn’t about image parsing. It’s about allowing negative numbers to touch memory. Rust makes that unrepresentable.”

---

## End of Document
