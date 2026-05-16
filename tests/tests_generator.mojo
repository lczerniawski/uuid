from uuid import Generator, UUID, Version, Variant
from std.collections import Set
from std.testing import (
    assert_true,
    assert_equal,
    assert_not_equal,
    TestSuite,
)


def _timestamp_from_uuid(u: UUID) -> UInt64:
    var b = u.bytes
    var time_low = UInt64(
        (UInt32(b[0]) << 24)
        | (UInt32(b[1]) << 16)
        | (UInt32(b[2]) << 8)
        | UInt32(b[3])
    )
    var time_mid = UInt64((UInt16(b[4]) << 8) | UInt16(b[5]))
    var time_high_and_version = UInt64((UInt16(b[6]) << 8) | UInt16(b[7]))
    var time_high = time_high_and_version & UInt64(0x0FFF)
    return (time_high << 48) | (time_mid << 32) | time_low


def test_generator_generates_non_zero_v1_uuid() raises:
    var zero = UUID(SIMD[DType.uint8, 16](0))

    var generator = Generator()
    var uuid = generator.v1()

    assert_not_equal(uuid, zero)


def test_generator_generates_different_v1_uuid() raises:
    var generator = Generator()
    var first_uuid = generator.v1()
    var second_uuid = generator.v1()

    assert_not_equal(first_uuid, second_uuid)


def test_generated_v1_uuid_is_correct_uuid_created_from_string() raises:
    var generator = Generator()
    var uuid = generator.v1()

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_generated_v1_uuid_is_correct_uuid_created_from_bytes() raises:
    var generator = Generator()
    var uuid = generator.v1()

    var new_uuid = UUID.from_bytes(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_generated_v1_uuid_has_correct_version() raises:
    var generator = Generator()
    var uuid = generator.v1()

    assert_equal(uuid.version(), Version.v1)


def test_generated_v1_uuid_has_correct_variant() raises:
    var generator = Generator()
    var uuid = generator.v1()

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_v1_timestamps_monotonic() raises:
    var generator = Generator()
    var prev_ts = UInt64(0)
    for _ in range(100):
        var uuid = generator.v1()
        var ts = _timestamp_from_uuid(uuid)
        assert_true(ts >= prev_ts)
        prev_ts = ts


def test_v1_node_multicast_bit_set() raises:
    var generator = Generator()
    var uuid = generator.v1()
    assert_equal(Int(uuid.bytes[10] & UInt8(1)), 1)


def test_v1_clock_sequence_matches_generator() raises:
    var generator = Generator()
    var uuid = generator.v1()
    var stored = (Int(uuid.bytes[8]) << 8) | Int(uuid.bytes[9])
    var stored_masked = stored & 0x3FFF
    assert_equal(generator.get_clock_sequence(), stored_masked)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
