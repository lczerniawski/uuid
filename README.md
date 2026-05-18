# UUID for Mojo

A high-performance Mojo library for generating, parsing, validating, and formatting UUID values in RFC-9562 compatible string forms.

## Overview

### Features

- **Multiple UUID Versions**: Supports UUID v1, v3, v4, v5, v6, v7, and v8 generation
- **RFC-9562 Compliant**: Full compliance with the latest UUID specification
- **String Parsing**: Parse UUIDs from multiple string formats (canonical, URN, hex, braced)
- **Format Support**: Convert between binary, canonical string, and URN representations
- **Validation**: Comprehensive validation for UUID strings before parsing
- **Cross-Platform**: Support for macOS (arm64), Linux (x86_64, aarch64)
- **Secure Random**: Uses platform-specific secure random sources (arc4random on macOS, getrandom on Linux)
- **Zero Dependencies**: No external dependencies beyond Mojo standard library

### Supported UUID Versions

| Version | Type                 | Use Case                                          |
| ------- | -------------------- | ------------------------------------------------- |
| **v1**  | Time-based           | Timestamp + secure random node ID + clock sequence |
| **v3**  | Name-based (MD5)     | Consistent generation from namespace + name       |
| **v4**  | Random               | Secure random generation                          |
| **v5**  | Name-based (SHA-1)   | Consistent generation from namespace + name       |
| **v6**  | Time-based (sorted)  | Timestamp + random clock sequence + node ID       |
| **v7**  | Time-based (Unix ms) | Unix timestamp (milliseconds) + random bytes      |
| **v8**  | Custom               | User-defined fields with RFC version/variant bits |

## Installation

### Package Manager

UUID is available in the modular-community package repository. To install, add it to your channels in `pixi.toml`:

```toml
channels = ["https://conda.modular.com/max", "https://repo.prefix.dev/modular-community", "conda-forge"]
```

Then, install using the Pixi CLI:

```bash
pixi add uuid
```

This fetches the latest version and makes it immediately available for import.

## Quick Start

### Basic Usage

```mojo
from uuid import Generator

def main() raises:
    # Create a generator instance
    var generator = Generator()

    # Generate a random UUID (v4)
    var uuid_v4 = generator.v4()
    print("UUID v4:", uuid_v4.to_string())

    # Generate a time-based UUID (v7 - recommended for modern applications)
    var uuid_v7 = generator.v7()
    print("UUID v7:", uuid_v7.to_string())

    # Access raw bytes
    print("Raw bytes:", uuid_v4.bytes)

    # Parse a UUID string
    var parsed = UUID.from_string("67e55044-10b1-426f-9247-bb680e5fe0c8")
    print("Parsed UUID:", parsed.to_string())

    # Get version and variant information
    print("Version:", parsed.version().value)  # 4 for v4 UUIDs
    print("Variant:", parsed.variant().value)   # 2 for RFC-9562
```

### Generating Different UUID Versions

```mojo
from uuid import Generator

def main() raises:
    var generator = Generator()

    # UUID v1: Time-based with node identifier
    # Note: Keep the generator as a singleton for v1 due to state management
    var uuid_v1 = generator.v1()
    print("UUID v1:", uuid_v1.to_string())

    # UUID v3: Name-based using MD5
    var namespace = UUID.from_string("6ba7b810-9dad-11d1-80b4-00c04fd430c8")  # DNS namespace
    var uuid_v3 = generator.v3(namespace, "example.com")
    print("UUID v3:", uuid_v3.to_string())

    # UUID v4: Random
    var uuid_v4 = generator.v4()
    print("UUID v4:", uuid_v4.to_string())

    # UUID v5: Name-based using SHA-1
    var uuid_v5 = generator.v5(namespace, "example.com")
    print("UUID v5:", uuid_v5.to_string())

    # UUID v6: Time-based (sortable)
    var uuid_v6 = generator.v6()
    print("UUID v6:", uuid_v6.to_string())

    # UUID v7: Time-based with Unix timestamp (recommended)
    var uuid_v7 = generator.v7()
    print("UUID v7:", uuid_v7.to_string())

    # UUID v8: Custom fields
    var custom_a = SIMD[DType.uint8, 6](1, 2, 3, 4, 5, 6)
    var custom_b = SIMD[DType.uint8, 2](7, 8)
    var custom_c = SIMD[DType.uint8, 8](9, 10, 11, 12, 13, 14, 15, 16)
    var uuid_v8 = generator.v8(custom_a, custom_b, custom_c)
    print("UUID v8:", uuid_v8.to_string())
```

### String Parsing and Validation

```mojo
from uuid import UUID

def main() raises:
    # Parse UUID from standard format
    var uuid1 = UUID.from_string("67e55044-10b1-426f-9247-bb680e5fe0c8")
    print("Parsed:", uuid1.to_string())

    # Parse from URN format
    var uuid2 = UUID.from_string("urn:uuid:67e55044-10b1-426f-9247-bb680e5fe0c8")
    print("From URN:", uuid2.to_string())

    # Parse from hex format (no hyphens)
    var uuid3 = UUID.from_string("67e5504410b1426f9247bb680e5fe0c8")
    print("From hex:", uuid3.to_string())

    # Parse from braced format
    var uuid4 = UUID.from_string("{67e55044-10b1-426f-9247-bb680e5fe0c8}")
    print("From braced:", uuid4.to_string())

    # Validate without parsing
    try:
        UUID.validate("67e55044-10b1-426f-9247-bb680e5fe0c8")
        print("Valid UUID!")
    except e:
        print("Invalid UUID:", e)
```

### UUID Representations

```mojo
from uuid import UUID

def main() raises:
    var uuid = UUID.from_string("67e55044-10b1-426f-9247-bb680e5fe0c8")

    # Canonical string representation
    print("String:", uuid.to_string())

    # URN representation
    print("URN:", uuid.urn())

    # Raw bytes
    print("Bytes:", uuid.bytes)

    # Version and variant inspection
    print("Version:", uuid.version().value)
    print("Variant:", uuid.variant().value)
```

### Namespace UUIDs

For name-based UUID generation (v3 and v5), you can use standard namespace UUIDs:

```mojo
# DNS namespace
var dns_namespace = UUID.from_string("6ba7b810-9dad-11d1-80b4-00c04fd430c8")

# URL namespace
var url_namespace = UUID.from_string("6ba7b811-9dad-11d1-80b4-00c04fd430c8")

# ISO OID namespace
var oid_namespace = UUID.from_string("6ba7b814-9dad-11d1-80b4-00c04fd430c8")

# X.500 DN namespace
var x500_namespace = UUID.from_string("6ba7b814-9dad-11d1-80b4-00c04fd430c8")
```

### Comparing UUID Versions

Choose the right UUID version for your use case:

| Version | Type | Pros | Cons | Best For |
|---------|------|------|------|----------|
| **v1** | Time-based | Unique, sortable | MAC address in UUID | Legacy systems |
| **v3** | Name-based (MD5) | Deterministic, fast | Weak hash (MD5) | Namespace-based consistent IDs |
| **v4** | Random | Simple, random | Non-sortable | Most applications |
| **v5** | Name-based (SHA-1) | Deterministic, better hash | Non-sortable | Namespace-based IDs needing security |
| **v6** | Time-based (sorted) | Sortable, fast | Larger timestamp | Databases, sorting requirements |
| **v7** | Time-based (Unix ms) | Sortable, modern, Unix ms | RFC-9562 new | Modern applications, databases |
| **v8** | Custom | Flexible | RFC compliance needed | Custom domain-specific IDs |

### State Considerations

It is advised to initialize the `Generator` once during application startup and reuse it throughout the lifetime of your application. This approach provides better resource management and consistent behavior across all UUID versions.

#### Stateful Versions (v1)

Keep the `Generator` instance as a singleton application-wide for UUID v1 generation to maintain proper clock sequence state:

```mojo
# GOOD: Reuse the same generator
var gen = Generator()
var uuid1 = gen.v1()
var uuid2 = gen.v1()

# AVOID: Creating new generators for v1
# Each new generator resets the clock sequence
```

#### Stateless Versions (v4, v6, v7)

While these versions don't maintain state, it's still recommended to reuse a single generator instance for the lifetime of your application:

```mojo
# GOOD: Initialize once and reuse
var gen = Generator()
var uuid_a = gen.v4()
var uuid_b = gen.v4()
var uuid_c = gen.v4()

# ACCEPTABLE but not recommended: Creating new generators each time
var uuid_x = Generator().v4()
var uuid_y = Generator().v4()
```

## API Reference

### Core Types

#### `UUID`

Represents a 16-byte UUID value.

**Methods:**

- `__init__(bytes: SIMD[DType.uint8, 16])` - Initialize from raw bytes
- `from_bytes(bytes: SIMD[DType.uint8, 16]) -> UUID` - Create from bytes
- `from_string(s: String) -> UUID` - Parse from string (raises `ValidationError` on invalid input)
- `to_string() -> String` - Get canonical hyphenated form (e.g., `67e55044-10b1-426f-9247-bb680e5fe0c8`)
- `to_bytes() -> SIMD[DType.uint8, 16]` - Get raw bytes
- `urn() -> String` - Get URN representation (e.g., `urn:uuid:67e55044-10b1-426f-9247-bb680e5fe0c8`)
- `version() -> Version` - Get UUID version (1-8)
- `variant() -> Variant` - Get UUID variant (NCS, RFC9562, Microsoft, Future)
- `validate(s: String)` - Static method to validate UUID string (raises `ValidationError` on invalid)

**Constants:**

- `Nil` - Nil UUID (all zeros)
- `Max` - Max UUID (all 0xFF)

#### `Version`

UUID version discriminator.

**Constants:**

- `v1` - Time-based UUID
- `v2` - DCE Security UUID
- `v3` - Name-based using MD5 hashing
- `v4` - Random
- `v5` - Name-based using SHA-1 hashing
- `v6` - Time-based (sortable)
- `v7` - Time-based with Unix millisecond timestamp
- `v8` - Custom

#### `Variant`

UUID variant discriminator.

**Constants:**

- `NCS` - Reserved for NCS compatibility
- `RFC9562` - RFC-9562 variant (most common)
- `Microsoft` - Reserved for Microsoft compatibility
- `Future` - Reserved for future use

#### `Generator`

High-level UUID generator with state management.

**Methods:**

- `__init__()` - Initialize with default time and node providers
- `v1() -> UUID` - Generate time-based UUID (stateful for clock sequence)
- `v3(namespace: UUID, name: String) -> UUID` - Generate name-based UUID using MD5
- `v4() -> UUID` - Generate random UUID
- `v5(namespace: UUID, name: String) -> UUID` - Generate name-based UUID using SHA-1
- `v6() -> UUID` - Generate sortable time-based UUID
- `v7() -> UUID` - Generate time-based UUID with Unix millisecond timestamp
- `v8(custom_a, custom_b, custom_c) -> UUID` - Generate custom UUID with RFC bits set
- `get_clock_sequence() -> Int` - Get current clock sequence
- `set_clock_sequence(sequence: Int)` - Update clock sequence

#### `ValidationError`

Error type raised when UUID validation or parsing fails.

**Properties:**

- `reason: String` - Description of the validation error

### Supported String Formats

The library supports parsing UUIDs from the following formats:

1. **Canonical (Standard)**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Example: `67e55044-10b1-426f-9247-bb680e5fe0c8`

2. **URN**: `urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Example: `urn:uuid:67e55044-10b1-426f-9247-bb680e5fe0c8`

3. **Hex (no hyphens)**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - Example: `67e5504410b1426f9247bb680e5fe0c8`

4. **Braced**: `{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}`
   - Example: `{67e55044-10b1-426f-9247-bb680e5fe0c8}`

## Platform Support

The library is tested and supported on:

- **macOS**: arm64 (Apple Silicon)
- **Linux**: x86_64 (Intel/AMD)
- **Linux**: aarch64 (ARM)

Secure random number generation uses:

- **macOS**: `arc4random()` from libc
- **Linux**: `getrandom()` system call


## Package Structure

- **`uuid.mojo`** - Core UUID type, parsing, formatting, and validation
- **`generator.mojo`** - High-level UUID generator with support for v1-v8
- **`time.mojo`** - Time source abstractions and timestamp management for time-based UUIDs
- **`node.mojo`** - Node identifier management for v1 UUID generation
- **`libc.mojo`** - FFI bindings to platform-specific system calls for random number generation and time retrieval
- **`__init__.mojo`** - Public API exports

## Development

### Running Tests

Execute the full test suite:

```bash
pixi run test
```

Or manually run individual test files:

```bash
mojo run -I src tests/tests_uuid.mojo
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## References

- [RFC 9562 - UUID Format](https://datatracker.ietf.org/doc/html/rfc9562)
- [Mojo Documentation](https://docs.modular.com/mojo/)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the library.
