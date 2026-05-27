from std.ffi import external_call
from std.sys.info import CompilationTarget

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
    # Definition: int clock_gettime(clockid_t clk_id, struct timespec *tp);
    var success = external_call["clock_gettime", Int32](
        Int32(clock_realtime), Pointer(to=ts)
    )
    if success != 0:
        raise Error("clock_gettime failed")

    return (UInt64(ts.tv_sec) * 1_000_000_000) + UInt64(ts.tv_nsec)
