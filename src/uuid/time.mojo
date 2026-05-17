from .libc import get_secure_random_u16, get_real_time_ns
from std.utils import BlockingSpinLock, BlockingScopedLock

comptime seconds_per_day = 86400
comptime ticks_per_second = 10_000_000  # 100ns intervals
comptime gregorian_epoch_julian_day_number = 2299160  # Julian day of 15 Oct 1582
comptime unix_epoch_julian_day_number = 2440587  # Julian day of 1 Jan 1970
comptime epoch_delta_days = unix_epoch_julian_day_number - gregorian_epoch_julian_day_number  # Days between epochs
comptime gregorian_offset_sec = epoch_delta_days * seconds_per_day  # seconds between epochs
comptime gregorian_offset_ticks = gregorian_offset_sec * ticks_per_second  # 100s of a nanoseconds between epochs


trait TimeSource(TrivialRegisterPassable):
    """
    Time source interface used by the UUID time generator.

    Implementations must return the current time in nanoseconds. 
    """

    def now(self) raises -> UInt64:
        ...


@fieldwise_init
struct SystemTimeSource(TimeSource):
    """
    System-backed `TimeSource` implementation.
    """

    def now(self) raises -> UInt64:
        """
        Return the current system time in nanoseconds.

        Returns:
            `UInt64`: Current system time in nanoseconds since the Unix epoch.

        Raises:
            `Error`: If the underlying system call fails to retrieve the time.
        """
        return get_real_time_ns()


@fieldwise_init
struct Time:
    """
    Timestamp and clock-sequence pair used by the generator.

    `timestamp` is stored as 100 ns ticks since the Gregorian epoch offset.
    `sequence` stores the RFC 4122 clock sequence with variant bits applied.
    """

    var timestamp: UInt64
    var sequence: UInt16


struct TimeGenerator[T: TimeSource]:
    """
    Generate monotonic time values and clock sequences for time-based UUIDs.

    The returned timestamp is converted to Gregorian epoch ticks. If the
    underlying clock stalls or moves backward, the clock sequence advances to
    preserve uniqueness.

    This type is intended to be created once and reused for the lifetime of
    the program.
    """

    var lock: BlockingSpinLock
    var last_time: UInt64  # last time returned by the generator
    var clock_sequence: UInt16  # clock sequence
    var time_source: Self.T  # current time returned by TimeSource, exposed in constructor for easier testing

    def __init__(
        out self,
        time_source: Self.T = SystemTimeSource(),
    ) raises:
        """
        Initialize a time generator.

        The generator uses the provided `time_source` for testability and
        initializes the clock sequence from secure random data.

        Args:
            time_source: Source used to obtain the current time.

        Raises:
            An error if secure random initialization fails.
        """

        self.lock = BlockingSpinLock()
        self.time_source = time_source
        self.last_time = 0

        var random_u16 = get_secure_random_u16()
        self.clock_sequence = (random_u16 & 0x3FFF) | 0x8000

    def set_clock_sequence(mut self, sequence: Int) raises:
        """
        Update the clock sequence used for generated times.

        The provided value is masked into the RFC 4122 clock-sequence range.
        When the value changes, the cached last timestamp is reset so the next
        generated value can advance cleanly.

        Args:
            sequence: Clock sequence value to set.
        """
        with BlockingScopedLock(self.lock):
            var target_sequence = (UInt16(sequence) & 0x3FFF) | 0x8000
            if target_sequence != self.clock_sequence:
                self.clock_sequence = target_sequence
                self.last_time = 0

    def get_clock_sequence(mut self) -> Int:
        """
        Return the current clock sequence.

        Returns:
            `Int`: Current RFC 4122 clock-sequence value.
        """
        with BlockingScopedLock(self.lock):
            return Int(self.clock_sequence & 0x3FFF)

    def next(mut self) raises -> Time:
        """
        Generate the next timestamp and clock-sequence pair used for UUID v1 generation.

        The current time is converted to Gregorian epoch ticks and compared with
        the previous value. If time does not advance, the clock sequence is
        incremented to avoid collisions.

        Returns:
            `Time`: The adjusted timestamp and active clock sequence.
        """
        with BlockingScopedLock(self.lock):
            var now = self.time_source.now() + gregorian_offset_ticks
            if now <= self.last_time:
                self.clock_sequence = (
                    (self.clock_sequence + 1) & 0x3FFF
                ) | 0x8000
            self.last_time = now
            return Time(now, self.clock_sequence)

    def now_gregorian_ticks(self) raises -> UInt64:
        """
        Return the current time in Gregorian epoch ticks.

        This is a convenience method that retrieves the current time from the
        time source and converts it to the format used for UUID timestamps.

        Returns:
            `UInt64`: Current time in 100 ns ticks since the Gregorian epoch offset.
        """
        return self.time_source.now() + gregorian_offset_ticks
    
    def now_unix_ms(self) raises -> UInt64:
        """
        Return the current time in Unix epoch milliseconds.

        This is a convenience method that retrieves the current time from the
        time source and converts it to milliseconds since the Unix epoch.

        Returns:
            `UInt64`: Current time in milliseconds since the Unix epoch.
        """
        return self.time_source.now() / 1_000_000
