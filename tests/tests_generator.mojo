from uuid import Generator, UUID, Version, Variant
from std.collections import Set
from std.testing import (
    assert_true,
    assert_equal,
    assert_not_equal,
    TestSuite,
)

comptime dns_uuid = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
comptime url_uuid = "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
comptime example_name = "example.com"
comptime rfc_v3_name = "www.widgets.com"
comptime rfc_v3_expected = "3d813cbb-47fb-32ba-91df-831e1593ac29"


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


def test_generator_generates_non_zero_v3_uuid() raises:
    var zero = UUID(SIMD[DType.uint8, 16](0))
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_not_equal(uuid, zero)


def test_generator_generates_same_v3_uuid_with_the_same_input() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var first_uuid = generator.v3(starter_uuid, example_name)
    var second_uuid = generator.v3(starter_uuid, example_name)

    assert_equal(first_uuid, second_uuid)


def test_generator_generates_different_v3_uuid_with_different_input() raises:
    var first_starter_uuid = UUID.from_string(dns_uuid)
    var second_starter_uuid = UUID.from_string(
        "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
    )

    var generator = Generator()
    var first_uuid = generator.v3(first_starter_uuid, example_name)
    var second_uuid = generator.v3(second_starter_uuid, "example.eu")

    assert_not_equal(first_uuid, second_uuid)


def test_generated_v3_uuid_is_correct_uuid_created_from_string() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_generated_v3_uuid_is_correct_uuid_created_from_bytes() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    var new_uuid = UUID.from_bytes(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_generated_v3_uuid_has_correct_version() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_equal(uuid.version(), Version.v3)


def test_generated_v3_uuid_has_correct_variant() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_generated_v3_uuid_matches_rfc_known_vector() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, rfc_v3_name)

    assert_equal(String(uuid), rfc_v3_expected)


def test_generated_v3_uuid_with_empty_name_is_stable_and_valid() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var first_uuid = generator.v3(starter_uuid, "")
    var second_uuid = generator.v3(starter_uuid, "")

    assert_equal(first_uuid, second_uuid)
    assert_equal(first_uuid.version(), Version.v3)
    assert_equal(first_uuid.variant(), Variant.RFC9562)


def test_generated_v3_uuid_is_case_sensitive_for_name() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var lower = generator.v3(starter_uuid, "example.com")
    var upper = generator.v3(starter_uuid, "Example.com")

    assert_not_equal(lower, upper)


def test_generated_v3_uuid_is_whitespace_sensitive_for_name() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var no_trailing = generator.v3(starter_uuid, "example.com")
    var with_trailing = generator.v3(starter_uuid, "example.com ")

    assert_not_equal(no_trailing, with_trailing)


def test_generated_v3_uuid_differs_for_standard_dns_vs_url_namespaces() raises:
    var dns_namespace = UUID.from_string(dns_uuid)
    var url_namespace = UUID.from_string(url_uuid)

    var generator = Generator()
    var dns_result = generator.v3(dns_namespace, example_name)
    var url_result = generator.v3(url_namespace, example_name)

    assert_not_equal(dns_result, url_result)


def test_generated_v3_uuid_sets_raw_version_and_variant_bits() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_equal(Int(uuid.bytes[6] >> 4), 3)
    assert_equal(Int(uuid.bytes[8] >> 6), 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
