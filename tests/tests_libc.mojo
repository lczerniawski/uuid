from uuid.libc import (
    get_real_time_ns,
    get_secure_random_u16,
    get_secure_random_u64,
)
from std.collections import Set
from std.testing import (
    assert_true,
    TestSuite,
)


def test_get_real_time_ns_returns_non_zero_value() raises:
    var now = get_real_time_ns()
    assert_true(now != 0)


def test_get_real_time_ns_is_plausible_unix_timestamp() raises:
    # 2020-01-01T00:00:00Z in nanoseconds.
    comptime min_expected = UInt64(1_577_836_800_000_000_000)

    var now = get_real_time_ns()
    assert_true(now >= min_expected)


def test_get_real_time_ns_stays_valid_over_many_calls() raises:
    for _ in range(1000):
        var now = get_real_time_ns()
        assert_true(now != 0)


def test_get_real_time_ns_eventually_changes() raises:
    var first = get_real_time_ns()
    var changed = False

    for _ in range(10_000):
        var current = get_real_time_ns()
        if current != first:
            changed = True
            break

    assert_true(changed)


def test_get_real_time_ns_delta_is_reasonable() raises:
    var t1 = get_real_time_ns()

    # Burn a tiny amount of CPU time between reads.
    var sink: UInt64 = 0
    for i in range(50_000):
        sink = sink + UInt64(i)

    var t2 = get_real_time_ns()

    # Accept either direction to avoid flakiness from rare wall-clock adjustments.
    comptime max_drift_ns = UInt64(5_000_000_000)  # 5 seconds
    if t2 >= t1:
        assert_true((t2 - t1) <= max_drift_ns)
    else:
        assert_true((t1 - t2) <= max_drift_ns)

    # Ensure the optimizer keeps the loop.
    assert_true(sink > 0)


def test_get_real_time_ns_tv_nsec_range() raises:
    var now = get_real_time_ns()
    var nsec = now % UInt64(1_000_000_000)
    assert_true(nsec < UInt64(1_000_000_000))


def test_get_real_time_ns_increases_short_loop() raises:
    var t1 = get_real_time_ns()
    var increased = False
    for _ in range(100_000):
        if get_real_time_ns() > t1:
            increased = True
            break
    assert_true(increased)


def test_get_secure_random_u16_returns_non_zero_value() raises:
    var result = get_secure_random_u16()
    assert_true(result != 0)


def test_get_secure_random_u16_returns_non_zero_value_over_many_calls() raises:
    for _ in range(1000):
        var result = get_secure_random_u16()
        assert_true(result != 0)


def test_get_secure_random_u16_within_bounds() raises:
    var v = get_secure_random_u16()
    assert_true(v <= UInt16(65_535))


def test_get_secure_random_u16_diversity() raises:
    var seen = Set[UInt16]()
    for _ in range(256):
        seen.add(get_secure_random_u16())
    assert_true(len(seen) >= 200)


def test_secure_random_many_quick_calls() raises:
    for _ in range(10_000):
        _ = get_secure_random_u16()
    assert_true(True)


def test_get_secure_random_u64_returns_non_zero_value() raises:
    var result = get_secure_random_u64()
    assert_true(result != 0)


def test_get_secure_random_u64_returns_non_zero_value_over_many_calls() raises:
    for _ in range(1000):
        var result = get_secure_random_u64()
        assert_true(result != 0)


def test_get_secure_random_u64_within_bounds() raises:
    var v = get_secure_random_u64()
    assert_true(v <= UInt64(18_446_744_073_709_551_615))


def test_get_secure_random_u64_diversity() raises:
    var seen = Set[UInt64]()
    for _ in range(256):
        seen.add(get_secure_random_u64())
    assert_true(len(seen) >= 250)


def test_secure_random_u64_consecutive_calls_differ() raises:
    var a = get_secure_random_u64()
    var different = False
    for _ in range(10):
        if get_secure_random_u64() != a:
            different = True
            break
    assert_true(different)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
