# DxeMain (C) vs PatinaDxeCore (Rust) — Security Vulnerability Analysis

The C-based `MdeModulePkg/Core/Dxe/DxeMain` contains **12 classes of vulnerabilities** that are structurally eliminated or mitigated by the Rust-based `PatinaDxeCore_ru`. Below is an exhaustive breakdown.

---

## 1. CRITICAL — Buffer Overflow in PDB Filename Processing

**C code** (`Image/Image.c`, lines ~830–870):

```c
CHAR8 EfiFileName[256];
for (Index = 0; Index < sizeof(EfiFileName) - 4; Index++) {
    EfiFileName[Index] = Image->ImageContext.PdbPointer[Index + StartIndex];
    if (EfiFileName[Index] == '.') {
        EfiFileName[Index + 1] = 'e';  // writes at Index+1
        EfiFileName[Index + 2] = 'f';  // writes at Index+2
        EfiFileName[Index + 3] = 'i';  // writes at Index+3
        EfiFileName[Index + 4] = 0;    // writes at Index+4 — can be 256!
        break;
    }
}
```

When `Index` reaches 251 (which is `sizeof(EfiFileName) - 4 - 1`), the write to `EfiFileName[Index + 4]` is at offset 255 — but if `PdbPointer` contains no `.` before that point and has a `.` at position 251, the `Index + 4 = 255` write lands at the end of the buffer. However, if `PdbPointer` has no `.` at all and the loop exits at `Index == 252`, the buffer is left without null termination when the fallback `EfiFileName[Index] = 0` fires. A carefully crafted PDB path in a malicious PE image could exploit this to corrupt the stack.

**Rust mitigation**: The Rust implementation in `src/lib.rs` uses `heapless::String<LOG_BUFFER_SIZE>` for all string formatting. The `heapless::String` type enforces a compile-time capacity bound; `write!()` silently stops when the buffer is full rather than overflowing. Image loading is delegated to `patina_dxe_core` which uses Rust's bounds-checked `&str` and `String` types — no fixed C arrays.

---

## 2. CRITICAL — Integer Overflow in Image Size Calculations

**C code** (`Image/Image.c`, lines ~380–400):

```c
if ((gLoadModuleAtFixAddressConfigurationTable.DxeCodeTopAddress < ImageBase + ImageSize) ||
    (DxeCodeBase > ImageBase))
```

`ImageBase + ImageSize` can overflow a 64-bit address space if both values come from a crafted PE header. The result wraps to a small number, bypassing the range check. Similarly:

```c
BaseOffsetPageNumber = EFI_SIZE_TO_PAGES((UINT32)(ImageBase - DxeCodeBase));
TopOffsetPageNumber = EFI_SIZE_TO_PAGES((UINT32)(ImageBase + ImageSize - DxeCodeBase));
```

The explicit `(UINT32)` cast **truncates 64-bit addresses** to 32 bits, causing incorrect page calculations and potential memory corruption on the bitmap.

**Rust mitigation**: Rust's default integer arithmetic panics on overflow in debug builds. In release builds, the `checked_add()`, `saturating_add()`, and `overflowing_add()` functions provide explicit overflow control. The Patina framework uses typed wrappers for physical addresses (`u64`) and sizes (`usize`) that prevent silent truncation. Rust's type system does not permit implicit narrowing casts — a `u64 as u32` must be explicit and is flagged by `clippy::cast_possible_truncation`.

---

## 3. HIGH — ASSERT-Only NULL Checks Compiled Out in Release

**C code** (`Image/Image.c`, line ~166; `Dispatcher/Dispatcher.c`, line ~876):

```c
DriverEntry = AllocateZeroPool(sizeof(EFI_CORE_DRIVER_ENTRY));
ASSERT(DriverEntry != NULL);
// In RELEASE builds, ASSERT is compiled to nothing.
// DriverEntry is used without checking for NULL.
DriverEntry->Signature = EFI_CORE_DRIVER_ENTRY_SIGNATURE;
```

This pattern appears throughout DxeMain — `ASSERT` guards that become no-ops in production RELEASE firmware, leaving NULL pointer dereferences as live vulnerabilities.

**Rust mitigation**: Rust has no null pointers in safe code. All potentially-absent values use `Option<T>`. The `?` operator and `match` enforce handling the `None` case. In the PatinaDxeCore entry point at `src/main.rs` line 109, even the logger initialization uses `let _ = ...` to explicitly discard the error without risking a null dereference. Memory allocation in the Patina framework returns `Option<NonNull<T>>` or `Result`, enforcing handling at every call site.

---

## 4. HIGH — Type Confusion via CR (Container-of) Macro

**C code** (`Hand/Handle.c`, lines ~82–84):

```c
Handle = CR(Link, IHANDLE, AllHandles, EFI_HANDLE_SIGNATURE);
```

The `CR` macro (equivalent to Linux's `container_of`) performs an unsafe pointer offset calculation to recover the containing structure from a `LIST_ENTRY` pointer. The signature check (`EFI_HANDLE_SIGNATURE`) is a 32-bit runtime check that:

- Can be bypassed if memory is corrupted
- Is disabled via `MDEPKG_NDEBUG` in release builds
- Performs no type-level validation — any memory with the right 4-byte pattern passes

This pattern is pervasive: used in `Pool.c` (`POOL_FREE_SIGNATURE`), `Dispatcher.c` (`EFI_CORE_DRIVER_ENTRY_SIGNATURE`), `Handle.c`, and `FwVol.c`.

**Rust mitigation**: Rust's trait system and ownership model eliminate the need for `container_of`. Protocol interfaces are represented as trait objects with vtables verified at compile time. The `patina_dxe_core` handle database uses typed structures where handles are generic over their protocol type — type confusion is a compile error, not a runtime hope.

---

## 5. HIGH — Use-After-Free Window in Dispatcher

**C code** (`Dispatcher/Dispatcher.c`, lines ~442–500):

```c
while (!IsListEmpty(&mScheduledQueue)) {
    DriverEntry = CR(mScheduledQueue.ForwardLink, ...);
    // ... load and start driver ...
    CoreAcquireDispatcherLock();
    DriverEntry->Scheduled = FALSE;
    RemoveEntryList(&DriverEntry->ScheduledLink);
    CoreReleaseDispatcherLock();
    // Lock is released — another driver's Init could modify the queue
    // Then we loop back and read mScheduledQueue.ForwardLink
}
```

Between `CoreReleaseDispatcherLock()` and the next iteration's `CR()`, a driver being started could trigger re-entrant dispatch, modifying `mScheduledQueue`. The `ForwardLink` pointer read at the top of the loop may now point to freed memory.

**Rust mitigation**: Rust's borrow checker prevents this class of bug at compile time. A mutable reference (`&mut`) to the dispatch queue cannot coexist with any other reference. The `patina_dxe_core` dispatcher uses Rust's ownership rules — iterating a list requires exclusive access, and the compiler refuses to compile code that could allow concurrent modification. The `Send + Sync` trait bounds on the `Core<T>` type further prevent data races.

---

## 6. HIGH — Unvalidated Firmware Volume Extension Header Parsing

**C code** (`Dispatcher/Dispatcher.c`, lines ~951–988):

```c
ExtHeaderOffset = ReadUnaligned16(&FvHeader->ExtHeaderOffset);
ExtHeader = (EFI_FIRMWARE_VOLUME_EXT_HEADER*)((UINT8*)FvHeader + ExtHeaderOffset);
ExtEntryList = (EFI_FIRMWARE_VOLUME_EXT_ENTRY*)(ExtHeader + 1);
while ((UINTN)ExtEntryList < ((UINTN)ExtHeader + ReadUnaligned32(&ExtHeader->ExtHeaderSize))) {
    // ...
    ExtEntryList = (EFI_FIRMWARE_VOLUME_EXT_ENTRY*)
        ((UINT8*)ExtEntryList + ReadUnaligned16(&ExtEntryList->ExtEntrySize));
}
```

Issues:

- `ExtHeaderOffset` is read from untrusted FV data with no bounds check against the FV size
- `ExtEntrySize` of 0 creates an infinite loop
- `ExtEntrySize` of 1 advances by 1 byte, causing misaligned structure reads
- No validation that `ExtHeader + ExtHeaderSize` stays within the FV bounds

**Rust mitigation**: The `patina_ffs` crate (dependency of `patina_ffs_extractors` used in `Cargo.toml`) uses the `zerocopy` crate for zero-copy parsing with compile-time layout verification. All offsets are validated against the containing buffer's length via slice bounds checks. An out-of-bounds offset results in `None` or `Err`, not an out-of-bounds read. The `zerocopy::FromBytes` trait ensures that only types with valid representations for any bit pattern can be reinterpreted from raw memory.

---

## 7. HIGH — Unchecked FV Header Length Used for Allocation

**C code** (`FwVol/FwVol.c`, line ~220):

```c
*FwVolHeader = AllocatePool(TempFvh.HeaderLength);
```

`TempFvh.HeaderLength` comes directly from the FV data read off flash. While the signature and GUID are checked, `HeaderLength` is not validated for:

- Being smaller than `sizeof(EFI_FIRMWARE_VOLUME_HEADER)` (would cause the subsequent `FvhLength = TempFvh.HeaderLength - sizeof(...)` to underflow)
- Being unreasonably large (DoS via excessive allocation)

**Rust mitigation**: The Patina FFS parser validates all header fields before using them for allocations. Rust's type system ensures that subtraction on `usize` either panics on underflow (debug) or wraps (release, but explicitly handled). The `heapless` containers used throughout avoid dynamic allocation entirely for fixed-size structures.

---

## 8. MEDIUM — Format String Vulnerabilities

**C code** (throughout DxeMain):

```c
DEBUG((DEBUG_INFO | DEBUG_LOAD, "%a", EfiFileName));
DEBUG((DEBUG_INFO, "Loading driver %g\n", &DriverEntry->FileName));
```

While EDK2's `DEBUG` macro is safer than raw `printf`, the format specifiers (`%a`, `%g`, `%p`, `%11p`) still rely on correct manual matching between format string and argument types. A mismatch (e.g., passing a `UINT32` where `%p` expects a pointer) causes undefined behavior.

**Rust mitigation**: Rust's `log::info!()`, `write!()`, and `format_args!()` macros are verified at **compile time** — the compiler checks that the format string and arguments agree in type and count. The PatinaDxeCore logger at `src/main.rs` lines 52–55 uses only these safe formatting facilities. A mismatched format argument is a compile error, not a runtime vulnerability.

---

## 9. MEDIUM — Memory Leaks on Error Paths

**C code** (`Image/Image.c`, lines ~890–900):

```c
Done:
  if (DstBufAlocated) {
    CoreFreePages(Image->ImageContext.ImageAddress, Image->NumberOfPages);
  }
  if (Image->ImageContext.FixupData != NULL) {
    CoreFreePool(Image->ImageContext.FixupData);
  }
  return Status;
```

The `Done` cleanup label frees some resources but not all — `Image->RuntimeData`, device paths allocated earlier in the function, and other intermediate buffers may leak depending on which error path was taken. Manual resource tracking across 20+ goto targets is error-prone.

**Rust mitigation**: Rust's RAII (Resource Acquisition Is Initialization) pattern with the `Drop` trait ensures resources are automatically freed when they go out of scope, regardless of which error path is taken. The `?` operator propagates errors while automatically running destructors. In the Patina framework, all allocations are wrapped in types that implement `Drop`.

---

## 10. MEDIUM — Unsafe Pool Metadata Trust

**C code** (`Mem/Pool.c`, lines ~43–47):

```c
#define HEAD_TO_TAIL(a) \
    ((POOL_TAIL*)(((CHAR8*)(a)) + (a)->Size - sizeof(POOL_TAIL)));
```

The `Size` field in `POOL_HEAD` is trusted for pointer arithmetic. If an adjacent buffer overflow corrupts a pool header's `Size`, the `HEAD_TO_TAIL` macro computes an arbitrary pointer, and the subsequent `POOL_TAIL_SIGNATURE` check can be satisfied by controlled memory content. This enables reliable heap metadata corruption.

**Rust mitigation**: The `linked_list_allocator` used by Patina maintains allocator metadata separately from user buffers. Buffer overflows in safe Rust code cannot occur (bounds checking), and the allocator's internal pointers are not adjacent to user data in the same exploitable way. The ownership model prevents writes beyond allocation boundaries.

---

## 11. MEDIUM — Linked List Corruption Without Integrity Checks

**C code** (`Hand/Handle.c`, lines ~79–82):

```c
for (Link = gHandleList.BackLink; Link != &gHandleList; Link = Link->BackLink) {
    Handle = CR(Link, IHANDLE, AllHandles, EFI_HANDLE_SIGNATURE);
```

Doubly-linked list traversal assumes `BackLink` pointers are valid. A single corrupted pointer causes the loop to traverse arbitrary memory, potentially disclosing secrets or crashing. The `LIST_ENTRY` structure has no integrity protection.

**Rust mitigation**: Rust's safe collections (`Vec`, `BTreeMap`, etc.) do not expose raw pointers to users. The Patina handle database does not use intrusive linked lists with raw pointer navigation. Iteration uses safe iterators with bounds-checked access.

---

## 12. LOW — No Stack Canary / ASLR Integration

**C code**: The DxeMain C code relies on the EDK2 build system for stack protection, which historically does not enable stack canaries (`-fstack-protector`) or ASLR for UEFI binaries.

**Rust mitigation**: While Rust UEFI binaries also operate in a pre-OS environment without full ASLR, Rust's memory safety guarantees make stack canaries largely unnecessary — the class of bugs they detect (stack buffer overflows) cannot occur in safe Rust code. The `force-unwind-tables` flag in `.cargo/config.toml` enables structured stack unwinding for panic handling.

---

## Summary Table

| # | Vulnerability | Severity | C DxeMain | Rust PatinaDxeCore | Rust Mechanism |
|---|---|---|---|---|---|
| 1 | Buffer overflow (PDB path) | **CRITICAL** | Exploitable | Eliminated | Bounds-checked `heapless::String` |
| 2 | Integer overflow (image sizing) | **CRITICAL** | Exploitable | Eliminated | Checked arithmetic, no implicit narrowing |
| 3 | NULL deref (ASSERT in release) | **HIGH** | Exploitable | Impossible | `Option<T>`, no null pointers |
| 4 | Type confusion (CR macro) | **HIGH** | Exploitable | Impossible | Compile-time trait dispatch |
| 5 | Use-after-free (dispatcher) | **HIGH** | Exploitable | Impossible | Borrow checker, ownership |
| 6 | OOB read (FV ext header) | **HIGH** | Exploitable | Eliminated | Slice bounds checks, `zerocopy` |
| 7 | Unvalidated alloc size (FV hdr) | **HIGH** | Exploitable | Eliminated | Validated parsing, `Result` types |
| 8 | Format string mismatch | **MEDIUM** | Possible | Impossible | Compile-time format verification |
| 9 | Memory leak (error paths) | **MEDIUM** | Present | Eliminated | RAII / `Drop` trait |
| 10 | Heap metadata corruption | **MEDIUM** | Exploitable | Mitigated | Safe allocator, bounds checks |
| 11 | Linked list corruption | **MEDIUM** | Exploitable | Eliminated | Safe iterators, no raw pointers |
| 12 | No stack protection | **LOW** | Present | Unnecessary | Memory safety eliminates root cause |

---

## Caveat

The Patina DXE Core library (`patina_dxe_core v20.1.3`) is distributed as a compiled crate — its internal implementation cannot be verified beyond what its API and type signatures guarantee. The analysis of the Rust side is based on the language's documented safety guarantees and the observable API contracts. The actual security posture of the Patina internals depends on the quantity and quality of `unsafe` code within the library.

---
---

# Part 2: UEFI DXE Architectural Vulnerabilities That Persist in Patina

The vulnerabilities in Part 1 are **implementation-level** bugs — buffer overflows, integer overflows, use-after-free — that Rust's language guarantees can eliminate. This section addresses a different class: **design-level** vulnerabilities inherent to the UEFI DXE architecture itself. Because Patina faithfully implements the UEFI DXE specification for binary compatibility with existing drivers, it inherits these architectural weaknesses regardless of the implementation language.

The core issue is that the UEFI DXE model is a **cooperative, flat-memory, shared-state architecture**. All DXE drivers run at the same privilege level, share the same address space, and communicate through mutable global data structures. Rust's safety guarantees protect the DXE core's *internal* code from memory corruption, but they cannot protect the *external interfaces* that must conform to the UEFI specification's C ABI.

---

## A1. CRITICAL — Protocol Interface Hijacking via Writable Jump Tables

### The Problem

The UEFI protocol model works as follows:

1. A driver calls `InstallProtocolInterface()` to register a protocol, providing a GUID and a pointer to an interface structure (typically a C struct of function pointers — a vtable).
2. Another driver calls `LocateProtocol()` or `HandleProtocol()` to retrieve that interface.
3. The caller receives a raw `*mut c_void` pointer, casts it to the expected protocol struct type, and calls functions through it.

In both the C DxeMain and Patina, the protocol database stores and returns the **original pointer** — not a copy. The interface struct lives in the installing driver's writable memory.

**C DxeMain** — the `EFI_BOOT_SERVICES` table is a global struct of function pointers in writable memory (`DxeMain/DxeMain.c`, lines ~40–105):

```c
EFI_BOOT_SERVICES mBootServices = {
    // ...
    (EFI_LOCATE_PROTOCOL)CoreLocateProtocol,
    (EFI_INSTALL_PROTOCOL_INTERFACE)CoreInstallProtocolInterface,
    // ... 40+ function pointers in writable memory
};
```

**Patina** — the protocol database returns the exact same raw pointer the installer provided. The `LocateProtocol` implementation writes the stored `*mut c_void` directly to the caller's output parameter. This is required by the UEFI specification.

### The Attack

A malicious DXE driver loaded from a compromised firmware volume can:

1. Call `LocateProtocol()` to get a pointer to any installed protocol's interface struct
2. The returned pointer is to **writable memory** owned by the original driver
3. Overwrite one or more function pointers in that struct with addresses of attacker-controlled code
4. All subsequent callers of that protocol now execute the attacker's code instead

```
// Attack pseudocode (valid in any UEFI DXE environment)
EFI_BLOCK_IO_PROTOCOL *BlockIo;
gBS->LocateProtocol(&gEfiBlockIoProtocolGuid, NULL, (VOID**)&BlockIo);

// BlockIo now points to writable memory — overwrite the ReadBlocks function
BlockIo->ReadBlocks = MaliciousReadBlocks;

// When the OS loader calls ReadBlocks, attacker code runs with full privilege
```

### Why Rust Does Not Help

This is not a memory safety bug. The attacker is performing a **legal write** to memory it has access to. Rust's borrow checker operates within the Patina DXE core's compilation unit — it cannot constrain what a separately compiled DXE driver (typically a C or binary-only PE image) does with a raw pointer it receives through the UEFI C ABI. The `extern "efiapi"` function boundary is the trust boundary, and the UEFI spec requires returning raw pointers.

### Impact

Any protocol can be hijacked: Block I/O, Simple File System, Security Arch, PCI I/O, Variable services. This enables rootkit persistence, secure boot bypass, and OS-level compromise.

---

## A2. HIGH — Handle Database Enumeration and Spoofing

### The Problem

The Patina handle database generates handle values using an `Xorshift64star` hash seeded with a sequential counter. This provides handle obfuscation but not cryptographic unpredictability.

A driver can enumerate all handles via `LocateHandleBuffer()` — this is a standard UEFI API. Once handles are known, a driver can:

1. Call `OpenProtocol()` on any handle to get any protocol interface
2. Call `InstallProtocolInterface()` to add a new protocol to an existing handle
3. Call `ReinstallProtocolInterface()` to replace a protocol's interface pointer on a handle it doesn't own

### Why Rust Does Not Help

Handle values must be opaque `EFI_HANDLE` pointers passed through the C ABI. The UEFI specification requires that `LocateHandleBuffer` return all handles matching a protocol GUID. There is no concept of handle ownership or access control in the UEFI spec.

### Impact

A malicious driver can impersonate any other driver's handles, inject protocols onto handles it doesn't own, or replace protocol interfaces system-wide.

---

## B1. CRITICAL — Boot Services Table Function Pointer Overwrite

### The Problem

The `EFI_BOOT_SERVICES` table is a C-compatible struct containing ~44 function pointers. In the C DxeMain, this is a global variable in writable `.data` memory:

```c
EFI_BOOT_SERVICES mBootServices = {
    (EFI_ALLOCATE_PAGES)CoreAllocatePages,
    (EFI_LOCATE_PROTOCOL)CoreLocateProtocol,
    (EFI_IMAGE_LOAD)CoreLoadImage,
    // ...
};
```

In Patina, the boot services table is a `Box<efi::BootServices>` — heap-allocated, writable memory. It is populated with function pointers via direct field assignment and then made available to all drivers through the `EFI_SYSTEM_TABLE`.

Every driver receives a pointer to the `EFI_SYSTEM_TABLE` at its entry point. From that, it can reach `SystemTable->BootServices`, which points to the writable boot services struct.

### The Attack

```
// Any DXE driver can do this:
gBS->LoadImage = MaliciousLoadImage;

// Now ALL subsequent image loads go through the attacker's function.
// The attacker can inspect, modify, or replace any PE image being loaded.
// This includes the OS bootloader.
```

The CRC32 checksum in the table header provides no protection — the attacker simply recalculates it after modification. CRC32 is not a cryptographic integrity check.

### Why Rust Does Not Help

The `efi::BootServices` struct must be a C-compatible struct of function pointers to conform to the UEFI specification. It must be writable during DXE phase because architectural protocol drivers install their services by writing to it (e.g., Timer, CPU, GIC drivers). Rust cannot make this struct read-only without breaking UEFI compatibility.

### Impact

Complete control of the DXE environment. The attacker intercepts every boot service call from every driver and the OS bootloader.

---

## B2. HIGH — Runtime Services Table Persistence Beyond ExitBootServices

### The Problem

The `EFI_RUNTIME_SERVICES` table survives `ExitBootServices()` and is available to the operating system. Its function pointers (GetVariable, SetVariable, ResetSystem, etc.) point to runtime driver code that is mapped into OS virtual address space.

If a malicious DXE driver overwrites a runtime services function pointer before `ExitBootServices()`, the OS will call the attacker's code at runtime privilege when it invokes runtime services.

### Why Rust Does Not Help

The runtime services table has the same C ABI structure as boot services — writable function pointers in a C struct. The table must survive into the OS runtime, so there is no opportunity to make it read-only at the DXE/OS boundary.

### Impact

Persistent OS-level compromise via runtime service hijacking. The malicious code runs in kernel context whenever the OS calls GetVariable, SetVariable, or ResetSystem.

---

## C1. HIGH — Event Callback Function Pointer Hijacking

### The Problem

The UEFI event system stores callback function pointers (`EFI_EVENT_NOTIFY`) and context pointers (`*mut c_void`) in the event database. In Patina, this is a global `SpinLockedEventDb` with interior mutability via spin locks.

Events are identified by opaque `EFI_EVENT` handles. When an event is signaled, the stored callback function pointer is invoked with the stored context pointer.

### The Attack

A driver that can locate the event database in memory (by scanning Patina's heap, which is in the same address space) can:

1. Find an event structure belonging to a security-critical driver
2. Replace the `notify_function` pointer with its own code
3. Replace the `notify_context` pointer with attacker-controlled data
4. Wait for the event to be signaled — the attacker's code runs in the context of the DXE core's event dispatcher

### Why Rust Does Not Help

The event database stores `Option<efi::EventNotify>` — which is essentially `Option<extern "efiapi" fn(efi::Event, *mut c_void)>`, a raw function pointer. This must be a raw function pointer because callbacks come from C-compiled drivers through the UEFI ABI. Rust's `Spin<Mutex>` protects against concurrent access from within Patina's own code, but a malicious driver operating through raw memory access bypasses the mutex entirely.

### Impact

Code execution in the DXE core's event processing context. Enables transparent interception of timer events, protocol notifications, and signal events.

---

## D1. CRITICAL — No Cryptographic Verification of Loaded Images

### The Problem

The DXE dispatcher loads PE/COFF images from firmware volumes and executes them. In the standard EDK2 flow, image verification depends on optional security architecture protocols (`EFI_SECURITY_ARCH_PROTOCOL`, `EFI_SECURITY2_ARCH_PROTOCOL`) which are themselves DXE drivers that must be loaded first.

This creates a bootstrap problem: the drivers that enforce image verification are loaded *by the same dispatcher* that should be checking them. Until those security drivers are loaded, all images are loaded without verification.

Patina loads images using the `goblin` crate for PE parsing and does not include built-in cryptographic signature verification. It relies on the same optional security architecture protocol pattern.

### The Attack

1. A compromised firmware volume includes a malicious DXE driver with a satisfied DEPEX (dependency expression) that causes it to load early — before any security verification driver
2. The DXE dispatcher loads and executes it without any signature check
3. The malicious driver can now hook `InstallProtocolInterface` to intercept the security architecture protocol installation and neuter it, ensuring no subsequent images are ever rejected

### Why Rust Does Not Help

This is an architectural ordering problem, not a memory safety issue. Rust cannot enforce that "security driver loads before all other drivers" because the DXE dispatcher uses DEPEX evaluation to determine load order, and DEPEX expressions are untrusted data from the firmware volume.

### Impact

Complete secure boot bypass. All subsequent image verification is controlled by the attacker.

---

## E1. HIGH — No Memory Isolation Between DXE Drivers

### The Problem

All DXE drivers share a single flat address space with no hardware-enforced isolation. The MMU page tables during DXE phase typically map all of physical memory as readable and writable. Patina uses `patina_paging` for page table management but still operates in a single-address-space model required by the UEFI specification.

The `linked_list_allocator` manages the DXE heap as a single pool. Any driver can:

- Read any other driver's code and data
- Write to any other driver's code and data (unless page protections are applied, which is optional and not enforced by the UEFI spec during boot services)
- Scan the entire heap to find protocol databases, event tables, and system tables

### The Attack

A malicious driver doesn't need to use UEFI APIs to hijack protocols. It can simply scan memory for known signatures (like the `EFI_BOOT_SERVICES_SIGNATURE` = `0x56524553544f4f42`) and overwrite function pointers directly.

### Why Rust Does Not Help

Rust's memory safety model assumes a **cooperative** environment — it prevents bugs in code that opts into the safety system. A DXE driver loaded as a separate PE image is outside Rust's compilation unit. It has unrestricted memory access via its own instructions. No amount of Rust safety in the DXE core prevents a loaded C driver from executing `*(uint64_t*)0xDEADBEEF = malicious_addr`.

### Impact

All other vulnerabilities in this section can be exploited without using any UEFI API — just raw memory access.

---

## F1. HIGH — DEPEX Spoofing and Driver Load Order Manipulation

### The Problem

The DXE dispatcher evaluates Dependency Expressions (DEPEX) to determine which drivers can be loaded. DEPEX evaluates to TRUE when all referenced protocol GUIDs are already installed. Patina uses `patina_internal_depex` (v20.1.3) for this evaluation.

DEPEX data comes from the firmware volume, which is the same untrusted source as the driver images themselves. A malicious firmware volume can craft a driver with:

- A `TRUE` constant DEPEX (always satisfied — loads immediately)
- Or a DEPEX that depends only on protocols installed by the DXE core itself (which are available before any third-party driver)

### The Attack

The attacker's driver loads before security-critical drivers and:

1. Hooks `InstallProtocolInterface` to intercept all future protocol registrations
2. Installs a compromised `EFI_SECURITY_ARCH_PROTOCOL` that approves all images
3. All subsequent drivers pass "verification"

### Why Rust Does Not Help

DEPEX evaluation is a logical operation on GUID presence. Rust cannot validate whether a DEPEX expression is "legitimate" — that requires out-of-band policy that the UEFI specification does not define.

### Impact

Attacker achieves first-mover advantage in the DXE environment.

---

## G1. CRITICAL — Configuration Table Injection

### The Problem

The `EFI_SYSTEM_TABLE` contains a `ConfigurationTable` array — a set of GUID-tagged pointers to arbitrary data structures. These are visible to every driver and to the OS after `ExitBootServices()`.

Configuration tables include critical structures:

- ACPI tables (`EFI_ACPI_TABLE_GUID`)
- SMBIOS tables (`SMBIOS_TABLE_GUID`)
- HOB list (`EFI_HOB_LIST_GUID`)
- DXE services table (`DXE_SERVICES_TABLE_GUID`)

Any DXE driver can call `InstallConfigurationTable()` to add, replace, or remove entries. There is no authentication.

### The Attack

A malicious driver calls `InstallConfigurationTable()` with `EFI_ACPI_TABLE_GUID` pointing to crafted ACPI tables. The OS consumes these tables and:

- Executes attacker's AML bytecode in kernel context
- Loads attacker's SSDT tables defining malicious device methods
- Processes crafted DSDT that triggers kernel vulnerabilities

### Why Rust Does Not Help

`InstallConfigurationTable()` is a standard boot service. Patina must implement it per the UEFI specification. The function takes a GUID and a `*mut c_void` — there is no type safety or authentication possible. Rust cannot validate what the pointer points to or whether the caller should be allowed to install that GUID.

### Impact

OS-level compromise via ACPI table injection. Standard technique in UEFI rootkits.

---

## H1. HIGH — HOB List from PEI Is Consumed Without Authentication

### The Problem

The DXE core receives the Hand-Off Block (HOB) list from the PEI phase as its primary initialization input. The HOB list describes:

- Available memory regions
- Firmware volume locations
- CPU configuration
- Platform-specific data

In both the C DxeMain and Patina, the HOB list pointer is received as the sole argument to the entry point. In Patina (`src/main.rs`, line 111):

```rust
pub extern "efiapi" fn _start(physical_hob_list: *const c_void) -> ! {
    // ...
    CORE.entry_point(physical_hob_list);
}
```

The HOB list is a linked structure in memory. Its contents are parsed and used to initialize the memory map, locate firmware volumes, and set up the configuration table. There is no cryptographic signature or MAC on the HOB list.

### The Attack

If the PEI phase is compromised (or if a physical attacker can modify the HOB list in memory between PEI and DXE hand-off), the attacker can:

1. Add a fake firmware volume HOB pointing to a malicious FV in memory
2. The DXE dispatcher scans this FV and loads the attacker's drivers
3. Modify memory descriptor HOBs to hide or expose memory regions
4. Inject configuration HOBs that change platform behavior

### Why Rust Does Not Help

The HOB list is a raw memory structure passed through a C ABI pointer. Rust's type system doesn't extend backward in time to the PEI phase. The `physical_hob_list: *const c_void` parameter is inherently untrusted — Rust cannot verify that the memory it points to hasn't been tampered with.

### Impact

Complete DXE environment compromise from a compromised PEI phase or physical DRAM attack.

---

## Architectural Summary Table

| # | Component | Vulnerability | Severity | Root Cause |
|---|-----------|---|---|---|
| A1 | Protocol Database | Interface pointer hijacking | **CRITICAL** | Protocols return writable raw pointers per UEFI spec |
| A2 | Handle Database | Handle enumeration and protocol spoofing | **HIGH** | No handle ownership or access control in UEFI spec |
| B1 | Boot Services Table | Function pointer overwrite | **CRITICAL** | C-struct of function pointers in writable memory |
| B2 | Runtime Services Table | Persistent function pointer hijack | **HIGH** | Runtime table survives into OS with writable fn ptrs |
| C1 | Event System | Callback function pointer replacement | **HIGH** | Events store raw function pointers in writable global state |
| D1 | Image Loading | No cryptographic verification | **CRITICAL** | Security drivers loaded by same dispatcher they protect |
| E1 | Memory Model | No inter-driver isolation | **HIGH** | Single address space, flat memory model |
| F1 | DXE Dispatcher | DEPEX spoofing for early load | **HIGH** | DEPEX data is untrusted, no load-order policy |
| G1 | Configuration Table | ACPI/SMBIOS table injection | **CRITICAL** | Any driver can install any configuration table |
| H1 | HOB List | Unauthenticated PEI→DXE hand-off | **HIGH** | No cryptographic integrity on HOB list |

---

## Why These Vulnerabilities Exist

These are not bugs — they are **design properties** of the UEFI DXE architecture. The DXE phase was designed as a cooperative environment where all code is trusted. The security model assumes:

1. All firmware volumes are authenticated before DXE (by PEI or ROM verification)
2. All DXE drivers are produced by the platform vendor
3. Physical access to the platform implies full trust

These assumptions break down in modern threat models:

- Supply chain attacks can inject malicious drivers into firmware updates
- Physical attacks on DRAM (cold boot, bus probing) can modify HOB lists
- Third-party option ROMs and UEFI applications run as DXE drivers with full access
- UEFI rootkits persist by modifying SPI flash contents

**Rust protects the DXE core from being compromised by its own bugs (Part 1). It does not protect the DXE core from being compromised by drivers it loads and trusts (Part 2).** The UEFI specification's flat trust model is the root cause, and it cannot be solved by changing the implementation language alone.

---

## Potential Mitigations (Beyond Scope of Rust Language)

These architectural issues would require changes beyond just the DXE core implementation:

| Mitigation | Addresses | Feasibility |
|---|---|---|
| Hardware-enforced memory isolation (e.g., ARM Realm Management Extension) | E1 | Requires hardware + major spec changes |
| Protocol interface copy-on-read with integrity checks | A1, C1 | Breaks UEFI spec compatibility |
| Read-only page protection for system tables after initialization | B1, B2 | Partially possible; breaks late-binding protocols |
| Mandatory image signing before dispatch | D1 | Requires solving bootstrap ordering problem |
| DEPEX allow-listing / signed DEPEX | F1 | Requires firmware build toolchain changes |
| Authenticated configuration table installation | G1 | Requires UEFI spec amendment |
| Cryptographic MAC on HOB list | H1 | Requires PEI-DXE interface changes |
| UEFI Secure Boot (when fully enabled) | D1 partially | Only covers images, not protocol/table attacks |

---
---

# Part 3: Hardening the Patina DXE Core Within UEFI Design Boundaries

Parts 1 and 2 identified what Rust fixes and what it cannot fix. This section defines the **practical hardening work** required to make the Patina DXE core as secure as the UEFI architecture allows — without breaking spec compatibility or requiring hardware changes.

The key realization is that the UEFI specification already defines several hardening mechanisms, and the EDK2 reference implementation provides proven implementations of them. The current Sky1/O6 platform configuration **enables none of them**. Additionally, Patina's architecture creates unique hardening opportunities that the C DxeMain cannot offer due to its monolithic nature.

---

## Current State Assessment

Before defining work items, the current security posture:

### What the Platform Has Today

| Mechanism | Status | Evidence |
|---|---|---|
| UEFI Secure Boot | **ENABLED** | `SECURE_BOOT_ENABLE = TRUE` in O6.dsc |
| SecurityStubDxe | **LOADED** | Present in Sky1Common.fdf.inc |
| W^X Image Protection (`PcdImageProtectionPolicy`) | **DISABLED** (default 0x2, but not set in platform DSC) | No override in any Sky1/O6 DSC include |
| NX Memory Protection (`PcdDxeNxMemoryProtectionPolicy`) | **DISABLED** (default 0x0) | Not set in platform DSC |
| Heap Guard (`PcdHeapGuardPropertyMask`) | **DISABLED** (default 0x0) | Not set in platform DSC |
| NULL Pointer Detection (`PcdNullPointerDetectionPropertyMask`) | **DISABLED** (default 0x0) | Not set in platform DSC |
| Patina built-in W^X enforcement | **[Unverified]** | `patina_paging v11.0.4` is a dependency; unclear if W^X is automatically applied to loaded images |
| Patina built-in NX for data | **[Unverified]** | Same — depends on `patina_dxe_core` internal behavior |
| Boot Services Table protection | **NONE** | Tables are in writable heap memory |
| Image signature verification in DXE dispatch | **PARTIAL** | SecurityStubDxe delegates to SecurityManagementLib; effectiveness depends on platform library instance |
| TPM measurement of loaded images | **NOT CONFIGURED** for DXE dispatch path | Tcg2Dxe is conditionally included but not linked to dispatch |

### What Other ARM64 Platforms Enable

For comparison, here are the settings used by other EDK2 ARM64 platforms (ArmVirtPkg, Ampere Altra, Socionext DeveloperBox):

```
gEfiMdeModulePkgTokenSpaceGuid.PcdImageProtectionPolicy|0x3
gEfiMdeModulePkgTokenSpaceGuid.PcdDxeNxMemoryProtectionPolicy|0xC000000000007FD1
```

The value `0x3` for `PcdImageProtectionPolicy` means: protect **both** IMAGE_FROM_FV (bit 1) and IMAGE_UNKNOWN (bit 0) — i.e., all loaded images get W^X enforcement.

The value `0xC000000000007FD1` for `PcdDxeNxMemoryProtectionPolicy` marks the following memory types as NX:

- EfiReservedMemoryType (bit 0)
- EfiLoaderData (bit 4)
- EfiBootServicesCode (bit 5) — [Note: code is handled by image protection, this is for non-image code regions]
- EfiBootServicesData (bit 6)
- EfiRuntimeServicesData (bit 7)
- EfiConventionalMemory (bit 8)
- EfiACPIReclaimMemory (bit 9)
- EfiACPIMemoryNVS (bit 10)
- EfiPersistentMemory (bit 14)
- Plus reserved/OEM types in upper bits

---

## Hardening Work Items

### H1. Enable W^X (Write XOR Execute) for All Loaded Images

**What**: Set `PcdImageProtectionPolicy` to `0x3` in the platform DSC.

**How it works**: When a PE/COFF image is loaded, the DXE core (or Patina equivalent) parses the PE section headers and:

- Marks `.text` sections as **Read-Only + Executable** (EFI_MEMORY_RO)
- Marks `.data`, `.rdata`, `.bss` sections as **Read-Write + Non-Executable** (EFI_MEMORY_XP)

This is enforced via the `EFI_CPU_ARCH_PROTOCOL.SetMemoryAttributes()` function, which modifies MMU page table entries.

**What it prevents**:

- **Protocol vtable overwrite → code execution (A1)**: Even if an attacker overwrites a function pointer in a protocol interface, if the target address is in a data region (heap, stack, .data), the CPU will fault on execution because the page is marked NX. The attacker can redirect the pointer but cannot point it to injected shellcode in data memory.
- **Boot Services table hijacking (B1)**: Same — replacing a function pointer with an address in writable data memory causes an NX fault when called.
- **ROP gadget reduction**: With code sections read-only, the attacker cannot modify existing code to create new gadgets.

**What it does NOT prevent**: Code-reuse attacks (ROP/JOP) where the attacker chains existing executable code gadgets. The attacker can still point a hijacked function pointer at a legitimate function in an executable region.

**Patina-specific consideration**: Patina provides its own CpuDxe support internally (the original `ArmPkg/Drivers/CpuDxe/CpuDxe.inf` is commented out in the FDF). Patina must expose `EFI_CPU_ARCH_PROTOCOL.SetMemoryAttributes()` for EDK2's MemoryProtection.c to call, OR Patina must implement its own W^X enforcement using `patina_paging`. **This is the first item to investigate**: does `patina_dxe_core` apply W^X to loaded images automatically?

**Prerequisite**: All PE images in the firmware volume must be page-aligned (section alignment >= 4K). Images that are not page-aligned will be allowed to load but will NOT receive W^X protection (per the `PROTECT_IF_ALIGNED_ELSE_ALLOW` policy). The EDK2 build tools produce page-aligned images when `/ALIGN:4096` is passed to the linker.

**Priority**: **CRITICAL** — This is the single highest-impact hardening change.

---

### H2. Enable NX (No-Execute) for Data Memory Types

**What**: Set `PcdDxeNxMemoryProtectionPolicy` to `0xC000000000007FD1` in the platform DSC.

**How it works**: When memory is allocated via `AllocatePages()` or `AllocatePool()`, the DXE core applies NX attributes to pages based on their `EFI_MEMORY_TYPE`. Data types (EfiBootServicesData, EfiRuntimeServicesData, EfiConventionalMemory, etc.) are marked non-executable at the page table level.

**What it prevents**:

- **Heap spray → code execution**: An attacker that fills the heap with shellcode cannot execute it because all heap memory is NX.
- **Stack-based code execution**: Stack memory (allocated from EfiBootServicesData) is NX.
- **Event callback hijack (C1)**: Even if the event database's function pointer is overwritten to point to attacker-controlled data, executing that data faults.

**What it does NOT prevent**: The attacker can still overwrite function pointers to redirect to existing executable code (code-reuse attacks).

**Patina-specific consideration**: Since Patina subsumes the CpuDxe and manages its own page tables via `patina_paging`, it must either:

1. Honor the NX memory policy internally when servicing `AllocatePages`/`AllocatePool`, OR
2. Expose the `EFI_CPU_ARCH_PROTOCOL` so EDK2's MemoryProtection.c (if loaded as a separate module) can apply NX, OR
3. Implement equivalent functionality natively

**Priority**: **CRITICAL** — Second highest-impact change after W^X.

---

### H3. Enable NULL Pointer Detection

**What**: Set `PcdNullPointerDetectionPropertyMask` to `0x01` (or `0x41` for non-stop mode) in the platform DSC.

**How it works**: The DXE core unmaps the first 4KB of virtual memory (page 0) by clearing its page table entry. Any dereference of a NULL pointer triggers a synchronous page fault (data abort on AArch64).

**What it prevents**:

- **NULL pointer dereference exploitation**: In the C DxeMain, many functions use `ASSERT(ptr != NULL)` which compiles to nothing in RELEASE builds. With NULL detection, dereferencing a NULL pointer from any driver — including the DXE core itself — causes a CPU exception instead of silently reading/writing address 0.
- **NULL function pointer calls**: If a vtable entry is not initialized (remains 0), calling it faults immediately instead of executing whatever code happens to be mapped at address 0.

**Patina-specific consideration**: Patina's Rust code eliminates NULL dereferences internally (Part 1, item 3), but loaded C drivers can still have NULL pointer bugs. NULL detection protects the system from those drivers.

**Compatibility note**: Some legacy Option ROMs access the interrupt vector table (IVT) at address 0. The `BIT7` flag in the PCD disables NULL detection after EndOfDxe to accommodate these. On AArch64, this is less of a concern since there is no x86 IVT.

**Priority**: **HIGH** — Low effort, high value, minimal compatibility risk on AArch64.

---

### H4. Enable Heap Guard Pages

**What**: Set `PcdHeapGuardPropertyMask` to `0x03` (page guard + pool guard) and `PcdHeapGuardPageType`/`PcdHeapGuardPoolType` to cover security-critical memory types.

**How it works**: The allocator places **guard pages** (unmapped pages) before and/or after every allocation. Any buffer overflow or underflow into the guard page triggers a page fault. For pool allocations, each pool allocation gets its own page(s) with guards, eliminating pool metadata corruption.

**What it prevents**:

- **Heap buffer overflow → metadata corruption (Part 1, item 10)**: Guard pages catch overflows before they can corrupt adjacent allocations.
- **Pool use-after-free**: With `BIT4` (freed-memory guard), freed pool memory is marked as a guard page. Any subsequent access faults.

**Trade-off**: Heap guard significantly increases memory consumption (each allocation consumes at least one extra 4KB page for the guard). For production firmware with limited memory, a selective approach is recommended — guard only `EfiBootServicesData` and `EfiRuntimeServicesData`.

**Patina-specific consideration**: Patina uses `linked_list_allocator` for its heap. Heap guards as implemented in EDK2's HeapGuard.c are tightly integrated with the C DxeMain's allocator. Patina would need to implement equivalent guard functionality in its own allocator, OR expose allocator hooks that MemoryProtection.c can call.

**Priority**: **MEDIUM** — Significant memory overhead; recommended for debug/validation builds. Consider selective enabling for production.

---

### H5. Boot Services Table Write Protection After Initialization

**What**: After all architectural protocols are installed and the boot services table is fully populated, remap the page(s) containing `EFI_BOOT_SERVICES` as read-only.

**How it works**: The DXE core knows when all architectural protocols have been installed (it tracks this via `CoreAllEfiServicesAvailable()`). At that point, the boot services table is complete. The page(s) containing the table can be remapped as RO via `SetMemoryAttributes()`.

To handle late-binding protocols that legitimately need to update the table (e.g., `CalculateCrc32` is installed late), the DXE core temporarily unlocks the page, makes the update, re-checksums, and re-locks.

**What it prevents**:

- **Boot Services table function pointer overwrite (B1)**: A malicious driver cannot modify the boot services table because the memory page faults on write.
- **This is the most impactful mitigation for the architectural vulnerabilities identified in Part 2.**

**UEFI spec compatibility**: The UEFI spec does not require the boot services table to be writable after initialization. It only requires that the table be valid and its CRC32 be correct. Making it read-only is fully spec-compliant.

**Patina advantage**: Since Patina owns the page tables (via `patina_paging`) AND owns the boot services table (it allocates and populates it), it can implement this entirely within its own codebase without depending on external drivers. The C DxeMain cannot easily do this because `SetMemoryAttributes` requires the CpuArch protocol, which is a separate driver.

**Implementation approach**:

1. After all architectural protocols install, mark the boot services table page(s) as RO
2. When the DXE core itself needs to update the table (e.g., installing the CRC32 function), temporarily:
   a. Remap the page as RW
   b. Make the update
   c. Recalculate CRC32
   d. Remap the page as RO
3. Expose no API for external drivers to request write access

**Priority**: **CRITICAL** — High impact, Patina-unique advantage, no spec compatibility issues.

---

### H6. Runtime Services Table Write Protection Before ExitBootServices

**What**: Same as H5, but for the `EFI_RUNTIME_SERVICES` table. Mark it read-only before `ExitBootServices()` is called.

**How it works**: Runtime services function pointers are set by runtime drivers (Variable, ResetSystem, RealTimeClock, etc.). Once all runtime drivers are loaded and `EndOfDxe` is signaled, the table should be stable. Mark it RO at the `EndOfDxe` event.

**Complication**: `SetVirtualAddressMap()` must update runtime service function pointers during the virtual address map transition. The DXE core must temporarily unlock the table during this operation.

**What it prevents**:

- **Runtime Services hijacking (B2)**: A malicious DXE driver loaded after EndOfDxe cannot modify runtime service function pointers.

**Priority**: **HIGH** — Important for preventing persistent OS-level compromise.

---

### H7. Protocol Interface Integrity Monitoring

**What**: Implement a shadow copy / hash registry of installed protocol interfaces that the DXE core can check on each `LocateProtocol` / `HandleProtocol` call.

**How it works**:

1. When a driver calls `InstallProtocolInterface(handle, guid, interface_ptr)`, the DXE core records a hash (e.g., CRC32 or xxHash) of the first N bytes of the interface structure at `interface_ptr`.
2. When another driver calls `LocateProtocol()` or `HandleProtocol()`, before returning the pointer, the DXE core re-hashes the interface and compares against the stored hash.
3. If the hash mismatches, the DXE core logs an alert (and optionally returns `EFI_SECURITY_VIOLATION` or halts).

**What it prevents**:

- **Protocol vtable hijacking (A1)**: Detects that a protocol interface's function pointers have been modified since installation.

**Limitations**:

- **Detection, not prevention**: By the time LocateProtocol is called, the damage is done. But detection enables logging and response.
- **False positives**: Some protocols legitimately modify their interface after installation (e.g., Reinstall flow). The monitor must whitelist `ReinstallProtocolInterface` as a legitimate update path.
- **Performance cost**: Hashing on every Locate/Handle call adds latency. Can be mitigated by only checking security-critical protocol GUIDs (SecurityArch, LoadedImage, BlockIo, SimpleFileSystem).

**UEFI spec compatibility**: Fully compatible. The spec says `LocateProtocol` returns the interface pointer; adding a pre-return integrity check is an internal implementation detail.

**Patina advantage**: The protocol database is implemented within `patina_dxe_core` in Rust. Adding a hash field to the protocol instance struct and a verification step is straightforward. In the C DxeMain, this would require modifying the `PROTOCOL_INTERFACE` struct and all functions that touch it.

**Priority**: **MEDIUM** — Novel defense not present in any UEFI implementation. Good detection capability.

---

### H8. Configuration Table Installation Restrictions

**What**: Implement a policy that restricts which drivers can install configuration tables with security-sensitive GUIDs.

**How it works**:

1. Define a built-in allow-list of GUIDs → expected installer identities. For example:
   - `EFI_ACPI_TABLE_GUID` → may only be installed by a driver loaded from the platform's primary firmware volume
   - `SMBIOS_TABLE_GUID` → same restriction
   - `EFI_HOB_LIST_GUID` → may only be installed by the DXE core itself
2. When `InstallConfigurationTable()` is called, check the calling driver's loaded image device path to determine if it came from a trusted FV.
3. If the caller is not authorized for that GUID, reject the call with `EFI_ACCESS_DENIED`.

**What it prevents**:

- **ACPI table injection (G1)**: A malicious or compromised third-party driver cannot replace the ACPI tables.
- **HOB list tampering**: Only the DXE core can set the HOB list configuration table entry.

**UEFI spec compatibility**: The spec says `InstallConfigurationTable` shall "add, update, or remove a configuration table entry." It does not say the implementation must accept all callers. An access control policy is an implementation decision.

**Patina advantage**: Since Patina owns both the configuration table implementation and the image loading path, it can correlate the caller's identity (which PE image is currently executing) with the requested GUID. The C DxeMain would need significant refactoring to thread caller identity through `CoreInstallConfigurationTable`.

**Priority**: **HIGH** — Prevents a critical attack vector with minimal compatibility impact.

---

### H9. Image Authentication Before DXE Dispatch

**What**: Ensure that image signature verification is active before the first non-core driver is dispatched.

**Current problem**: The DXE dispatcher loads drivers in DEPEX order. The security architecture protocol (which performs signature verification) is itself a DXE driver that must be loaded by the dispatcher. This creates a window where drivers load without verification.

**How to fix within the UEFI design**:

**Option A — Built-in Authenticode verification in Patina**: Embed a minimal Authenticode signature verifier directly in the `patina_dxe_core` crate. Before dispatching any image from a firmware volume, verify its PE signature against a built-in public key. This eliminates the bootstrap problem because the verifier is part of the DXE core itself, not a loadable driver.

**Option B — FV-level authentication**: Verify the entire firmware volume's signature at DXE core initialization (before scanning it for drivers). If the FV signature is valid, all images within it are trusted. Third-party images (non-FV) are deferred until the full SecurityArch protocol is available.

**Option C — Strict DEPEX ordering with allow-list**: Hardcode that `SecurityStubDxe` (and its dependency chain) must load before any other driver. The DXE dispatcher checks each driver's GUID against an allow-list of "pre-security" drivers. All other drivers are held until SecurityArch is installed.

**What it prevents**:

- **DEPEX spoofing (F1)**: A malicious driver cannot load before the security verifier.
- **No-verification window (D1)**: Eliminates the bootstrap gap.

**Patina advantage**: Options A and B are uniquely feasible in Patina because the DXE core is a Rust binary that can include additional crate dependencies. Adding an Authenticode verifier (such as the `authenticode` or `cms` Rust crate) is a dependency addition, not a fundamental architecture change. The C DxeMain cannot easily embed additional verification logic without modifying the EDK2 build system.

**Priority**: **CRITICAL** — Closes the most dangerous architectural gap.

---

### H10. Event Callback Origin Tracking

**What**: Record which loaded image registered each event callback, and validate that the callback function pointer is within that image's code range.

**How it works**:

1. When `CreateEvent()` or `CreateEventEx()` is called with a notify function, record the calling image's base address and size range (from LoadedImageProtocol).
2. Verify that the `notify_function` pointer falls within the caller's `.text` section.
3. Periodically (or on each `SignalEvent`), re-verify that the stored `notify_function` still points within the original image's code range.

**What it prevents**:

- **Event callback hijacking (C1)**: If an attacker overwrites an event's function pointer to point outside the original registrant's code, the verification catches it.
- **Cross-image callback injection**: A driver cannot register a callback that points into another driver's code (which would be suspicious).

**UEFI spec compatibility**: Compatible. The spec defines the callback prototype but does not restrict where the DXE core validates the pointer.

**Priority**: **MEDIUM** — Good defense-in-depth. Requires maintaining a mapping of loaded images to their address ranges.

---

### H11. Patina Internal — Reduce `unsafe` Surface at FFI Boundaries

**What**: Audit and minimize the `unsafe` code in Patina's UEFI ABI boundary functions. Add runtime validation to all `extern "efiapi"` entry points.

**How it works**: Every `extern "efiapi"` function in Patina is a trust boundary. These functions receive raw pointers from C drivers. Currently, many of these functions dereference pointers with minimal validation. Hardening means:

1. **Validate all pointer arguments**: Check non-null, check alignment, check that the pointer is within a valid memory range (from the GCD memory map).
2. **Validate GUID arguments**: Check that GUID pointers point to readable memory before dereferencing.
3. **Validate buffer sizes**: For functions that take buffer + size pairs, verify size is consistent with the buffer's allocation.
4. **Validate handle arguments**: Beyond the existing handle database lookup, verify that the handle value hasn't been corrupted.

**What it prevents**:

- **Confused deputy attacks**: A malicious driver passing crafted pointers to boot services cannot cause Patina to read/write arbitrary memory.
- **NULL pointer dereference via API**: Catches cases where a driver passes NULL for a non-optional parameter.

**Patina advantage**: Rust's type system can enforce these checks at the boundary with `Option`, `NonNull`, and custom validation wrappers. The C DxeMain uses manual `if (ptr == NULL) return EFI_INVALID_PARAMETER` checks that are inconsistently applied.

**Priority**: **HIGH** — Directly hardens the most exposed attack surface.

---

### H12. Leveraging Patina's Subsumed Drivers for Reduced Attack Surface

**What**: Document and verify the security benefit of Patina subsuming multiple architectural protocol drivers.

**Current state**: Patina replaces these separate drivers (all commented out with ODP tags in Sky1Common.fdf.inc):

- `CpuDxe` — CPU architectural protocol
- `ArmGicDxe` — Interrupt controller
- `RuntimeDxe` — Runtime services
- `TimerDxe` — Timer
- `GenericWatchdogDxe` — Watchdog
- `PCD/Dxe/Pcd.inf` — PCD database
- `NorFlashDxe` / `NorFlashStmmRuntimeDxe` — Flash access
- `VariableRuntimeDxe` / `VariableSmmRuntimeDxe` — Variable services
- `FaultTolerantWriteDxe` — FTW
- `ResetDxe` — System reset
- `PowerDxe` / `ClockDxe` — Power and clock management
- `ArmScmiDxe` — SCMI
- `SocDxe` / `PlatformDxe` — Platform init
- `MmCommunicationDxe` — MM communication

**Security benefit**: Each subsumed driver is one fewer separately loaded PE image that could be hijacked, spoofed, or have its protocol interface overwritten. When CpuDxe is part of the DXE core, the `EFI_CPU_ARCH_PROTOCOL` interface is in the core's own memory — it doesn't need to be passed through the protocol database where it could be intercepted.

**Quantified attack surface reduction**: ~15 fewer protocol install/locate cycles that cross the untrusted protocol database. ~15 fewer PE images that need signature verification. ~15 fewer driver entry points that could be exploited.

**What to verify**: Ensure that the subsumed protocol interfaces are stored in memory that is protected by the DXE core's own page table controls (ideally RO after initialization), not in general heap memory accessible to other drivers.

**Priority**: **HIGH** — This is an existing advantage that should be formally documented and verified.

---

## Implementation Priority Matrix

| Priority | Item | Effort | Impact | Notes |
|---|---|---|---|---|
| **P0** | H1 — W^X for loaded images | Low (PCD setting) or Medium (Patina internal) | Blocks data→code execution | Must verify Patina's SetMemoryAttributes support |
| **P0** | H2 — NX for data memory | Low (PCD setting) or Medium (Patina internal) | Blocks heap/stack execution | Same dependency as H1 |
| **P0** | H5 — Boot Services table RO | Medium | Blocks the #1 architectural attack | Patina-unique advantage |
| **P0** | H9 — Image auth before dispatch | High | Closes bootstrap verification gap | May require new Patina crate dependency |
| **P1** | H3 — NULL pointer detection | Low | Catches NULL derefs from C drivers | Minimal risk on AArch64 |
| **P1** | H6 — Runtime Services table RO | Medium | Blocks persistent OS compromise | Needs SetVirtualAddressMap unlock |
| **P1** | H8 — Config table restrictions | Medium | Blocks ACPI injection | Policy definition needed |
| **P1** | H11 — FFI boundary validation | Medium | Hardens Patina's exposed API | Ongoing engineering discipline |
| **P1** | H12 — Verify subsumed driver protections | Low | Documents existing advantage | Audit task |
| **P2** | H7 — Protocol integrity monitoring | Medium | Detection, not prevention | Novel; no precedent in UEFI |
| **P2** | H10 — Event callback validation | Medium | Defense-in-depth | Requires image range tracking |
| **P2** | H4 — Heap guard pages | Low (PCD) or Medium (Patina) | Catches buffer overflows | High memory cost for production |

---

## Open Questions Requiring Investigation

These are items that cannot be answered from the source code available in this repository. They require examining the `patina_dxe_core` library internals (which is distributed as a compiled crate from crates.io):

1. **Does `patina_dxe_core` already apply W^X to loaded PE images?** If yes, H1 is already partially addressed. If no, Patina needs to implement the equivalent of EDK2's `MemoryProtection.c::ProtectUefiImage()`.

2. **Does `patina_dxe_core` expose `EFI_CPU_ARCH_PROTOCOL.SetMemoryAttributes()`?** Since Patina subsumes CpuDxe, it must expose this protocol for other EDK2 drivers (like MemoryProtection.c, if loaded separately) to use.

3. **Does `patina_dxe_core` apply NX to allocated data memory?** If yes, H2 is partially addressed. If no, the `linked_list_allocator` needs to be augmented with page table attribute management.

4. **Where does `patina_dxe_core` store the Boot Services table in memory?** If it's in a separate page that can be isolated, H5 is straightforward. If it's in the middle of a large heap allocation, it requires refactoring.

5. **Does the `compatibility_mode_allowed` feature flag affect security?** This feature is enabled by default in the Cargo.toml. Its purpose and security implications need to be documented.

6. **Does `goblin` (PE parser) validate PE section characteristics?** Specifically, does it verify that code sections have the `IMAGE_SCN_MEM_EXECUTE` flag and data sections do not? This affects W^X enforcement accuracy.

7. **How does Patina handle `ExitBootServices()` with respect to page table protections?** Does it produce an `EFI_MEMORY_ATTRIBUTES_TABLE` configuration table for the OS to consume?
