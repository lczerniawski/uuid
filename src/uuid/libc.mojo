from std.ffi import external_call
from std.sys.info import CompilationTarget
from std.memory import OwnedPointer

comptime clock_realtime = 0


@fieldwise_init
struct timespec(TrivialRegisterPassable):
    """
    Native `clock_gettime` result container.

    This mirrors the POSIX `timespec` layout used by the platform time
    wrapper.
    """

    var tv_sec: Int
    var tv_nsec: Int


def get_real_time_ns() raises -> UInt64:
    """
    Return the current real time in nanoseconds.

    Returns:
        `UInt64`: Current wall-clock time measured from the Unix epoch.

    Raises:
        `Error`: If the underlying system call fails to retrieve the time.
    """
    var ts = timespec(0, 0)
    var success = external_call["clock_gettime", Int32](
        clock_realtime, Pointer(to=ts)
    )
    if success != 0:
        raise Error("clock_gettime failed")

    return (UInt64(ts.tv_sec) * 1_000_000_000) + UInt64(ts.tv_nsec)


def get_secure_random_u16() raises -> UInt16:
    """
    Return a secure random 16-bit value.

    The implementation uses the platform-appropriate entropy source and
    raises if secure random bytes cannot be obtained.

    Returns:
        `UInt16`: A securely generated random 16-bit integer.

    Raises:
        `Error`: If the underlying system call fails to provide secure random bytes.
    """
    comptime compilation_target = CompilationTarget()
    comptime if compilation_target.is_linux():
        var buf = UInt16(0)
        # Definition: ssize_t getrandom(void *buf, size_t buflen, unsigned int flags);
        # Flags (0): Standard blocking behavior, waits for entropy pool initialization.
        var bytes_read = external_call["getrandom", Int](Pointer(to=buf), 2, 0)
        if bytes_read < 2:
            raise Error("Linux getrandom failed to provide 2 bytes of entropy")
        return buf

    elif compilation_target.is_macos():
        # Definition: uint32_t arc4random(void);
        # Returns: A random 32-bit integer.
        var result = external_call["arc4random", UInt32]()
        return UInt16(result)

    else:
        compilation_target.unsupported_target_error[
            note="Unsupported OS: Secure random not implemented"
        ]()


def get_secure_random_u64() raises -> UInt64:
    """
    Return a secure random 64-bit value.

    The implementation uses the platform-appropriate entropy source and
    raises if secure random bytes cannot be obtained.

    Returns:
        `UInt64`: A securely generated random 64-bit integer.

    Raises:
        `Error`: If the underlying system call fails to provide secure random bytes.
    """
    comptime compilation_target = CompilationTarget()
    comptime if compilation_target.is_linux():
        var buf = UInt64(0)
        # Definition: ssize_t getrandom(void *buf, size_t buflen, unsigned int flags);
        # Flags (0): Standard blocking behavior, waits for entropy pool initialization.
        var bytes_read = external_call["getrandom", Int](Pointer(to=buf), 8, 0)
        if bytes_read < 8:
            raise Error("Linux getrandom failed to provide 8 bytes of entropy")
        return buf

    elif compilation_target.is_macos():
        # Definition: uint32_t arc4random(void);
        # Returns: A random 32-bit integer.
        var hi = UInt64(external_call["arc4random", UInt32]())
        var lo = UInt64(external_call["arc4random", UInt32]())
        return (hi << 32) | lo

    else:
        compilation_target.unsupported_target_error[
            note="Unsupported OS: Secure random not implemented"
        ]()


def compute_md5(
    data: Span[UInt8, ...]
) -> SIMD[DType.uint8, 16]:
    """
    Compute MD5 hash of input string.

    Returns:
        `SIMD[DType.uint8, 16]`: 16-byte MD5 hash.
    """
    comptime compilation_target = CompilationTarget()
    comptime if compilation_target.is_linux():
        # OpenSSL: MD5(data, len, result) - one-shot function.
        var result = SIMD[DType.uint8, 16](0)
        var data_ptr = data.unsafe_ptr()
        var data_len = len(data)

        _ = external_call["MD5", OwnedPointer[UInt8]](
            data_ptr, UInt(data_len), Pointer(to=result)
        )
        return result

    elif compilation_target.is_macos():
        # CommonCrypto: CC_MD5(data, len, result)
        var result = SIMD[DType.uint8, 16](0)
        var data_ptr = data.unsafe_ptr()
        var data_len = len(data)

        external_call["CC_MD5", NoneType](
            data_ptr, UInt32(data_len), Pointer(to=result)
        )
        return result

    else:
        compilation_target.unsupported_target_error[
            note="Unsupported OS: Computing MD5 hash not implemented"
        ]()
