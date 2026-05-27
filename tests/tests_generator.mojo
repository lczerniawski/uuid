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
comptime known_v3_name = "www.widgets.com"
comptime known_v3_expected = "3d813cbb-47fb-32ba-91df-831e1593ac29"
comptime known_v5_name = "www.widgets.com"
comptime known_v5_expected = "21f7f8de-8051-5b89-8680-0195ef798b6a"


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


def _timestamp_from_v6_uuid(u: UUID) -> UInt64:
    var b = u.bytes
    var time_high = UInt64(
        (UInt32(b[0]) << 24)
        | (UInt32(b[1]) << 16)
        | (UInt32(b[2]) << 8)
        | UInt32(b[3])
    )
    var time_mid = UInt64((UInt16(b[4]) << 8) | UInt16(b[5]))
    var time_low_and_version = UInt64((UInt16(b[6]) << 8) | UInt16(b[7]))
    var time_low = time_low_and_version & UInt64(0x0FFF)
    return (time_high << 28) | (time_mid << 12) | time_low


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


def test_v1_uuid_is_correct_uuid_created_from_string() raises:
    var generator = Generator()
    var uuid = generator.v1()

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_v1_uuid_is_correct_uuid_created_from_bytes() raises:
    var generator = Generator()
    var uuid = generator.v1()

    var new_uuid = UUID(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_v1_uuid_has_correct_version() raises:
    var generator = Generator()
    var uuid = generator.v1()

    assert_equal(uuid.version(), Version.v1)


def test_v1_uuid_has_correct_variant() raises:
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


def test_v3_uuid_is_correct_uuid_created_from_string() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_v3_uuid_is_correct_uuid_created_from_bytes() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    var new_uuid = UUID(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_v3_uuid_has_correct_version() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_equal(uuid.version(), Version.v3)


def test_v3_uuid_has_correct_variant() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_v3_uuid_matches_known_vector() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, known_v3_name)

    assert_equal(String(uuid), known_v3_expected)


def test_v3_uuid_with_empty_name_is_stable_and_valid() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var first_uuid = generator.v3(starter_uuid, "")
    var second_uuid = generator.v3(starter_uuid, "")

    assert_equal(first_uuid, second_uuid)
    assert_equal(first_uuid.version(), Version.v3)
    assert_equal(first_uuid.variant(), Variant.RFC9562)


def test_v3_uuid_is_case_sensitive_for_name() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var lower = generator.v3(starter_uuid, "example.com")
    var upper = generator.v3(starter_uuid, "Example.com")

    assert_not_equal(lower, upper)


def test_v3_uuid_is_whitespace_sensitive_for_name() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var no_trailing = generator.v3(starter_uuid, "example.com")
    var with_trailing = generator.v3(starter_uuid, "example.com ")

    assert_not_equal(no_trailing, with_trailing)


def test_v3_uuid_differs_for_standard_dns_vs_url_namespaces() raises:
    var dns_namespace = UUID.from_string(dns_uuid)
    var url_namespace = UUID.from_string(url_uuid)

    var generator = Generator()
    var dns_result = generator.v3(dns_namespace, example_name)
    var url_result = generator.v3(url_namespace, example_name)

    assert_not_equal(dns_result, url_result)


def test_v3_uuid_sets_raw_version_and_variant_bits() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_equal(Int(uuid.bytes[6] >> 4), 3)
    assert_equal(Int(uuid.bytes[8] >> 6), 2)


def test_generator_generates_non_zero_v4_uuid() raises:
    var zero = UUID(SIMD[DType.uint8, 16](0))

    var generator = Generator()
    var uuid = generator.v4()

    assert_not_equal(uuid, zero)


def test_generator_generates_different_v4_uuid_each_time() raises:
    var generator = Generator()
    var first_uuid = generator.v4()
    var second_uuid = generator.v4()

    assert_not_equal(first_uuid, second_uuid)


def test_v4_uuid_is_correct_uuid_created_from_string() raises:
    var generator = Generator()
    var uuid = generator.v4()

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_v4_uuid_is_correct_uuid_created_from_bytes() raises:
    var generator = Generator()
    var uuid = generator.v4()

    var new_uuid = UUID(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_v4_uuid_has_correct_version() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v4()

    assert_equal(uuid.version(), Version.v4)


def test_v4_uuid_has_correct_variant() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v4()

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_v4_uuid_sets_raw_version_and_variant_bits() raises:
    var generator = Generator()
    var uuid = generator.v4()

    assert_equal(Int(uuid.bytes[6] >> 4), 4)
    assert_equal(Int(uuid.bytes[8] >> 6), 2)


def test_generator_generates_non_zero_v5_uuid() raises:
    var zero = UUID(SIMD[DType.uint8, 16](0))
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v5(starter_uuid, example_name)

    assert_not_equal(uuid, zero)


def test_generator_generates_same_v5_uuid_with_the_same_input() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var first_uuid = generator.v5(starter_uuid, example_name)
    var second_uuid = generator.v5(starter_uuid, example_name)

    assert_equal(first_uuid, second_uuid)


def test_generator_generates_different_v5_uuid_with_different_input() raises:
    var first_starter_uuid = UUID.from_string(dns_uuid)
    var second_starter_uuid = UUID.from_string(
        "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
    )

    var generator = Generator()
    var first_uuid = generator.v5(first_starter_uuid, example_name)
    var second_uuid = generator.v5(second_starter_uuid, "example.eu")

    assert_not_equal(first_uuid, second_uuid)


def test_v5_uuid_is_correct_uuid_created_from_string() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v5(starter_uuid, example_name)

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_v5_uuid_is_correct_uuid_created_from_bytes() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v5(starter_uuid, example_name)

    var new_uuid = UUID(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_v5_uuid_has_correct_version() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v5(starter_uuid, example_name)

    assert_equal(uuid.version(), Version.v5)


def test_v5_uuid_has_correct_variant() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v3(starter_uuid, example_name)

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_v5_uuid_matches_known_vector() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v5(starter_uuid, known_v5_name)

    assert_equal(String(uuid), known_v5_expected)


def test_v5_uuid_with_empty_name_is_stable_and_valid() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var first_uuid = generator.v5(starter_uuid, "")
    var second_uuid = generator.v5(starter_uuid, "")

    assert_equal(first_uuid, second_uuid)
    assert_equal(first_uuid.version(), Version.v5)
    assert_equal(first_uuid.variant(), Variant.RFC9562)


def test_v5_uuid_is_case_sensitive_for_name() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var lower = generator.v5(starter_uuid, "example.com")
    var upper = generator.v5(starter_uuid, "Example.com")

    assert_not_equal(lower, upper)


def test_v5_uuid_is_whitespace_sensitive_for_name() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var no_trailing = generator.v5(starter_uuid, "example.com")
    var with_trailing = generator.v5(starter_uuid, "example.com ")

    assert_not_equal(no_trailing, with_trailing)


def test_v5_uuid_differs_for_standard_dns_vs_url_namespaces() raises:
    var dns_namespace = UUID.from_string(dns_uuid)
    var url_namespace = UUID.from_string(url_uuid)

    var generator = Generator()
    var dns_result = generator.v5(dns_namespace, example_name)
    var url_result = generator.v5(url_namespace, example_name)

    assert_not_equal(dns_result, url_result)


def test_v5_uuid_sets_raw_version_and_variant_bits() raises:
    var starter_uuid = UUID.from_string(dns_uuid)

    var generator = Generator()
    var uuid = generator.v5(starter_uuid, example_name)

    assert_equal(Int(uuid.bytes[6] >> 4), 5)
    assert_equal(Int(uuid.bytes[8] >> 6), 2)


def test_generator_generates_non_zero_v6_uuid() raises:
    var zero = UUID(SIMD[DType.uint8, 16](0))

    var generator = Generator()
    var uuid = generator.v6()

    assert_not_equal(uuid, zero)


def test_generator_generates_different_v6_uuid() raises:
    var generator = Generator()
    var first_uuid = generator.v6()
    var second_uuid = generator.v6()

    assert_not_equal(first_uuid, second_uuid)


def test_v6_uuid_is_correct_uuid_created_from_string() raises:
    var generator = Generator()
    var uuid = generator.v6()

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_v6_uuid_is_correct_uuid_created_from_bytes() raises:
    var generator = Generator()
    var uuid = generator.v6()

    var new_uuid = UUID(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_v6_uuid_has_correct_version() raises:
    var generator = Generator()
    var uuid = generator.v6()

    assert_equal(uuid.version(), Version.v6)


def test_v6_uuid_has_correct_variant() raises:
    var generator = Generator()
    var uuid = generator.v6()

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_v6_uuid_sets_raw_version_and_variant_bits() raises:
    var generator = Generator()
    var uuid = generator.v6()

    assert_equal(Int(uuid.bytes[6] >> 4), 6)
    assert_equal(Int(uuid.bytes[8] >> 6), 2)


def test_v6_timestamps_monotonic() raises:
    var generator = Generator()
    var prev_ts = UInt64(0)
    for _ in range(100):
        var uuid = generator.v6()
        var ts = _timestamp_from_v6_uuid(uuid)
        assert_true(ts >= prev_ts)
        prev_ts = ts


def test_v6_node_multicast_bit_set() raises:
    var generator = Generator()
    var uuid = generator.v6()
    assert_equal(Int(uuid.bytes[10] & UInt8(1)), 1)


def test_generator_generates_non_zero_v7_uuid() raises:
    var zero = UUID(SIMD[DType.uint8, 16](0))

    var generator = Generator()
    var uuid = generator.v7()

    assert_not_equal(uuid, zero)


def test_generator_generates_different_v7_uuid() raises:
    var generator = Generator()
    var first_uuid = generator.v7()
    var second_uuid = generator.v7()

    assert_not_equal(first_uuid, second_uuid)


def test_v7_uuid_is_correct_uuid_created_from_string() raises:
    var generator = Generator()
    var uuid = generator.v7()

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_v7_uuid_is_correct_uuid_created_from_bytes() raises:
    var generator = Generator()
    var uuid = generator.v7()

    var new_uuid = UUID(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_v7_uuid_has_correct_version() raises:
    var generator = Generator()
    var uuid = generator.v7()

    assert_equal(uuid.version(), Version.v7)


def test_v7_uuid_has_correct_variant() raises:
    var generator = Generator()
    var uuid = generator.v7()

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_v7_uuid_sets_raw_version_and_variant_bits() raises:
    var generator = Generator()
    var uuid = generator.v7()

    assert_equal(Int(uuid.bytes[6] >> 4), 7)
    assert_equal(Int(uuid.bytes[8] >> 6), 2)


def test_v7_timestamp_matches_time_generator() raises:
    var generator = Generator()
    # sample time from the generator and then create a v7 UUID
    var sampled = generator.time_generator.now_unix_ms()
    var uuid = generator.v7()

    # reconstruct 48-bit unix ms from bytes 0..5
    var b = uuid.bytes
    var unix_ms = UInt64(0)
    for i in range(0, 6):
        unix_ms = (unix_ms << 8) | UInt64(b[i])

    assert_true(unix_ms == sampled)


def test_v7_timestamps_monotonic() raises:
    var generator = Generator()
    var prev = UInt64(0)
    for _ in range(100):
        var uuid = generator.v7()
        var b = uuid.bytes
        var ts = UInt64(0)
        for i in range(0, 6):
            ts = (ts << 8) | UInt64(b[i])
        assert_true(ts >= prev)
        prev = ts


def test_generator_generates_non_zero_v8_uuid() raises:
    var zero = UUID(SIMD[DType.uint8, 16](0))

    var a = SIMD[DType.uint8, 6](255, 254, 253, 252, 251, 250)
    var b = SIMD[DType.uint8, 2](249, 248)
    var c = SIMD[DType.uint8, 8](247, 246, 245, 244, 243, 242, 241, 240)

    var generator = Generator()
    var uuid = generator.v8(a, b, c)

    assert_not_equal(uuid, zero)


def test_v8_uuid_is_correct_uuid_created_from_string() raises:
    var a = SIMD[DType.uint8, 6](255, 254, 253, 252, 251, 250)
    var b = SIMD[DType.uint8, 2](249, 248)
    var c = SIMD[DType.uint8, 8](247, 246, 245, 244, 243, 242, 241, 240)

    var generator = Generator()
    var uuid = generator.v8(a, b, c)

    var new_uuid = UUID.from_string(String(uuid))
    assert_equal(uuid, new_uuid)


def test_v8_uuid_is_correct_uuid_created_from_bytes() raises:
    var a = SIMD[DType.uint8, 6](255, 254, 253, 252, 251, 250)
    var b = SIMD[DType.uint8, 2](249, 248)
    var c = SIMD[DType.uint8, 8](247, 246, 245, 244, 243, 242, 241, 240)

    var generator = Generator()
    var uuid = generator.v8(a, b, c)

    var new_uuid = UUID(uuid.bytes)
    assert_equal(uuid, new_uuid)


def test_v8_uuid_has_correct_version() raises:
    var a = SIMD[DType.uint8, 6](255, 254, 253, 252, 251, 250)
    var b = SIMD[DType.uint8, 2](249, 248)
    var c = SIMD[DType.uint8, 8](247, 246, 245, 244, 243, 242, 241, 240)

    var generator = Generator()
    var uuid = generator.v8(a, b, c)

    assert_equal(uuid.version(), Version.v8)


def test_v8_uuid_has_correct_variant() raises:
    var a = SIMD[DType.uint8, 6](255, 254, 253, 252, 251, 250)
    var b = SIMD[DType.uint8, 2](249, 248)
    var c = SIMD[DType.uint8, 8](247, 246, 245, 244, 243, 242, 241, 240)

    var generator = Generator()
    var uuid = generator.v8(a, b, c)

    assert_equal(uuid.variant(), Variant.RFC9562)


def test_v8_uuid_sets_raw_version_and_variant_bits() raises:
    var a = SIMD[DType.uint8, 6](255, 254, 253, 252, 251, 250)
    var b = SIMD[DType.uint8, 2](249, 248)
    var c = SIMD[DType.uint8, 8](247, 246, 245, 244, 243, 242, 241, 240)

    var generator = Generator()
    var uuid = generator.v8(a, b, c)

    assert_equal(Int(uuid.bytes[6] >> 4), 8)
    assert_equal(Int(uuid.bytes[8] >> 6), 2)


def test_v8_uuid_matches_rfc_layout() raises:
    var a = SIMD[DType.uint8, 6](16, 17, 18, 19, 20, 21)
    var b = SIMD[DType.uint8, 2](1, 178)
    var c = SIMD[DType.uint8, 8](195, 196, 197, 198, 199, 200, 201, 202)

    var generator = Generator()
    var uuid = generator.v8(a, b, c)

    assert_equal(Int(uuid.bytes[0]), 16)
    assert_equal(Int(uuid.bytes[1]), 17)
    assert_equal(Int(uuid.bytes[2]), 18)
    assert_equal(Int(uuid.bytes[3]), 19)
    assert_equal(Int(uuid.bytes[4]), 20)
    assert_equal(Int(uuid.bytes[5]), 21)
    assert_equal(Int(uuid.bytes[6]), 129)
    assert_equal(Int(uuid.bytes[7]), 178)
    assert_equal(Int(uuid.bytes[8]), 131)
    assert_equal(Int(uuid.bytes[9]), 196)
    assert_equal(Int(uuid.bytes[10]), 197)
    assert_equal(Int(uuid.bytes[11]), 198)
    assert_equal(Int(uuid.bytes[12]), 199)
    assert_equal(Int(uuid.bytes[13]), 200)
    assert_equal(Int(uuid.bytes[14]), 201)
    assert_equal(Int(uuid.bytes[15]), 202)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
