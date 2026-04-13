
# LogoFAIL, UEFI, and Rust Bounds Safety – Working Notes & Discovery Log

## Purpose
This document captures the full reasoning, discovery, and explanatory narrative developed to explain how Rust’s safety guarantees would have prevented LogoFAIL-class UEFI vulnerabilities. It is intended to be portable and uploaded into another AI agent or shared with collaborators.

---

## Context: LogoFAIL
LogoFAIL is a class of UEFI firmware vulnerabilities disclosed by Binarly in late 2023 affecting image parsers (e.g., BMP, PNG) executed during the DXE phase of boot. Improper handling of image metadata (dimensions, compression fields) allows memory corruption and arbitrary code execution before Secure Boot enforcement.

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
5. Memory before or after buffer is overwritten
6. Control flow is hijacked (code/data injection)

This pattern has existed in firmware for more than a decade and has been repeatedly rediscovered in different image parsers.

---

## How Rust Structurally Blocks This Bug Class

### 1. Negative Indices Are Unrepresentable
Rust slice and Vec indexing requires `usize`. Signed integers (`i32`, `isize`) cannot be used as indices.

```rust
let i: isize = -1;
let v = vec![0u8; 10];
v[i]; // compile-time error
```

The exploit path is blocked before compilation completes.

---

### 2. Explicit Casts Still Trigger Bounds Checks

```rust
let i: isize = -1;
let idx = i as usize;
v[idx] = 0;
```

- `-1 as usize` becomes a very large positive value
- Rust emits an explicit bounds check
- The memory write never executes; execution panics before corruption

---

### 3. All Safe Indexing Is Bounds Checked
In safe Rust, all of the following are bounds checked by language guarantee:
- `[]`
- `.get()` / `.get_mut()`
- slicing operations

Silent out-of-bounds memory writes are not possible in safe code.

---

### 4. Pointer Arithmetic Requires `unsafe`

The only way to recreate a LogoFAIL-style memory write primitive in Rust is to explicitly opt into `unsafe` and perform raw pointer arithmetic:

```rust
unsafe {
    *ptr.offset(i) = value;
}
```

This makes the risk explicit, auditable, and reviewable by design.

---

## Mapping LogoFAIL Root Causes to Rust Guarantees

| LogoFAIL Root Cause | Rust Safe-Code Outcome |
|-------------------|------------------------|
| Signed index used as offset | Compile-time type error |
| Integer underflow / overflow | Panic before memory write |
| Unchecked pointer arithmetic | Requires explicit `unsafe` |
| Silent memory corruption | Impossible in safe code |

---

## Why This Matters for Firmware

Image parsing during boot occurs in a high-privilege, pre-OS execution environment. Rust eliminates entire vulnerability classes not through coding guidelines or testing discipline, but by making unsafe states unrepresentable in the type system.

This does not eliminate logic bugs, but it prevents the memory corruption primitives required for persistent firmware compromise.

---

## Literature and Public Analysis Review (As of April 2026)

A targeted review of public material was conducted to determine whether any existing analysis explicitly connects LogoFAIL vulnerabilities to Rust’s safety model.

**Findings:**
- Official LogoFAIL materials (Binarly blogs, Black Hat talks, CVE write-ups, press coverage) provide detailed exploitation analysis of C-based firmware parsers but do **not** discuss Rust or memory-safe language alternatives.
- Public Rust/UEFI efforts (e.g., `uefi-rs`, Rust UEFI documentation) focus on enablement and API design, not on mapping Rust guarantees to known firmware exploit classes.
- General Rust discussions around bounds checking and memory safety exist, but they are language-internal and do not reference LogoFAIL or pre-OS firmware attack surfaces.

**Conclusion:**
No public, LogoFAIL-focused analysis was found that explains how Rust’s type system and bounds checking would have structurally prevented this vulnerability class. The framing presented in this document appears to fill a currently unaddressed explanatory gap between firmware exploitation research and memory-safe systems programming.

---

## Booth Demonstration Strategy (Summary)

### 3-Second Hook
> “This UEFI exploit class is impossible in safe Rust.”

### Visual Proof
Side-by-side comparison:
- C-style image parser using signed indices
- Rust equivalent that fails to compile or panics before memory access

### Interactive Demo
Single-action demo:
- Run C version → memory write succeeds
- Run Rust version → compile error or runtime panic

### QR Code
Links to this document for deeper technical context.

---

## Key Framing Sentence

> “LogoFAIL isn’t about image parsing. It’s about allowing negative numbers to touch memory. Rust makes that unrepresentable.”

---

## End of Document
