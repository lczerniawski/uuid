from uuid import UUID, Version, Variant
from std.testing import (
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
    TestSuite,
)

# The UUID "67e55044-10b1-426f-9247-bb680e5fe0c8" in bytes
comptime raw_data = SIMD[DType.uint8, 16](
    0x67,
    0xE5,
    0x50,
    0x44,  # Segment 1: 67e55044
    0x10,
    0xB1,  # Segment 2: 10b1
    0x42,
    0x6F,  # Segment 3: 426f (The '4' indicates Version 4)
    0x92,
    0x47,  # Segment 4: 9247 (The '9' indicates the Variant)
    0xBB,
    0x68,
    0x0E,
    0x5F,
    0xE0,
    0xC8,  # Segment 5: bb680e5fe0c8
)


def _uuid_with_version(version: UInt8) -> UUID:
    var bytes = raw_data
    bytes[6] = (bytes[6] & 0x0F) | (version << 4)
    return UUID(bytes)


def _uuid_with_variant(variant_prefix: UInt8) -> UUID:
    var bytes = raw_data
    bytes[8] = (bytes[8] & 0x1F) | variant_prefix
    return UUID(bytes)


def test_uuid_parses_from_init_to_valid_string() raises:
    comptime expected = "67e55044-10b1-426f-9247-bb680e5fe0c8"

    var uuid = UUID(raw_data)
    var result = uuid.to_string()

    assert_equal(expected, result)


def test_uuid_parses_from_bytes_to_valid_string() raises:
    comptime expected = "67e55044-10b1-426f-9247-bb680e5fe0c8"
    var raw_list = List[UInt8]()
    for i in range(len(raw_data)):
        raw_list.append(raw_data[i])

    var uuid = UUID.from_bytes(raw_list)
    var result = uuid.to_string()

    assert_equal(expected, result)


def test_uuid_parses_from_string_to_valid_bytes() raises:
    comptime expected = raw_data

    var uuid = UUID.from_string("67e55044-10b1-426f-9247-bb680e5fe0c8")
    var result = uuid.bytes

    assert_equal(expected, result)


def test_uuid_parses_from_string_to_valid_string() raises:
    comptime expected = "67e55044-10b1-426f-9247-bb680e5fe0c8"

    var uuid = UUID.from_string(expected)
    var result = uuid.to_string()

    assert_equal(expected, result)


def test_uuid_parses_from_string_with_urn_to_valid_string() raises:
    comptime expected = "67e55044-10b1-426f-9247-bb680e5fe0c8"

    var uuid = UUID.from_string("urn:uuid:67e55044-10b1-426f-9247-bb680e5fe0c8")
    var result = uuid.to_string()

    assert_equal(expected, result)


def test_uuid_parses_from_string_with_braces_to_valid_string() raises:
    comptime expected = "67e55044-10b1-426f-9247-bb680e5fe0c8"

    var uuid = UUID.from_string("{67e55044-10b1-426f-9247-bb680e5fe0c8}")
    var result = uuid.to_string()

    assert_equal(expected, result)


def test_uuid_parses_from_string_without_hyphens_to_valid_string() raises:
    comptime expected = "67e55044-10b1-426f-9247-bb680e5fe0c8"

    var uuid = UUID.from_string("67e5504410b1426f9247bb680e5fe0c8")
    var result = uuid.to_string()

    assert_equal(expected, result)


def test_uuid_parses_from_uppercase_string_to_valid_lowercase_string() raises:
    comptime expected = "67e55044-10b1-426f-9247-bb680e5fe0c8"

    var uuid = UUID.from_string("67E55044-10B1-426F-9247-BB680E5FE0C8")
    var result = uuid.to_string()

    assert_equal(expected, result)


def test_version_is_equal_to_4() raises:
    comptime expected = Version.v4

    var uuid = UUID(raw_data)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_version_is_equal_to_1() raises:
    comptime expected = Version.v1

    var uuid = _uuid_with_version(expected)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_version_is_equal_to_2() raises:
    comptime expected = Version.v2

    var uuid = _uuid_with_version(expected)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_version_is_equal_to_3() raises:
    comptime expected = Version.v3

    var uuid = _uuid_with_version(expected)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_version_is_equal_to_5() raises:
    comptime expected = Version.v5

    var uuid = _uuid_with_version(expected)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_version_is_equal_to_6() raises:
    comptime expected = Version.v6

    var uuid = _uuid_with_version(expected)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_version_is_equal_to_7() raises:
    comptime expected = Version.v7

    var uuid = _uuid_with_version(expected)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_version_is_equal_to_8() raises:
    comptime expected = Version.v8

    var uuid = _uuid_with_version(expected)
    var result = uuid.version()

    assert_equal(expected, result.value)


def test_variant_is_equal_to_RFC9562() raises:
    comptime expected = Variant.RFC9562

    var uuid = UUID(raw_data)
    var result = uuid.variant()

    assert_equal(expected, result.value)


def test_variant_is_equal_to_NCS() raises:
    comptime expected = Variant.NCS

    var uuid = _uuid_with_variant(0x00)
    var result = uuid.variant()

    assert_equal(expected, result.value)


def test_variant_is_equal_to_Microsoft() raises:
    comptime expected = Variant.Microsoft

    var uuid = _uuid_with_variant(0xC0)
    var result = uuid.variant()

    assert_equal(expected, result.value)


def test_variant_is_equal_to_Future() raises:
    comptime expected = Variant.Future

    var uuid = _uuid_with_variant(0xE0)
    var result = uuid.variant()

    assert_equal(expected, result.value)


def test_urn_returns_valid_string_uuid_with_urn_prefix() raises:
    comptime expected = "urn:uuid:67e55044-10b1-426f-9247-bb680e5fe0c8"

    var uuid = UUID(raw_data)
    var result = uuid.urn()

    assert_equal(expected, result)


def test_validate_not_raises_with_correct_uuid_with_hyphens() raises:
    comptime correct_hyphenated = "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
    UUID.validate(correct_hyphenated)


def test_validate_raises_with_incorrect_uuid_with_hyphens() raises:
    comptime correct_hyphenated = "f81d4faz-7dec-11d0-a765-00a0c91e6bf6"
    with assert_raises(contains="Invalid UUID Format"):
        UUID.validate(correct_hyphenated)


def test_validate_raises_with_wrong_hyphen_positions() raises:
    comptime malformed_hyphenated = "f81d4fae7-dec-11d0-a765-00a0c91e6bf6"
    with assert_raises(contains="Invalid UUID Format"):
        UUID.validate(malformed_hyphenated)


def test_validate_not_raises_with_correct_uuid_with_urn_prefix() raises:
    comptime correct_hyphenated = (
        "urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66"
    )
    UUID.validate(correct_hyphenated)


def test_validate_raises_with_correct_uuid_with_too_short_urn_prefix() raises:
    comptime correct_hyphenated = "urn:uid:6e8bc430-9c3a-11d9-9669-0800200c9a66"
    with assert_raises(contains="Invalid UUID Format"):
        UUID.validate(correct_hyphenated)


def test_validate_raises_with_correct_uuid_with_invalid_urn_prefix() raises:
    comptime correct_hyphenated = (
        "urn:uudi:6e8bc430-9c3a-11d9-9669-0800200c9a66"
    )
    with assert_raises(contains="Wrong URN Prefix"):
        UUID.validate(correct_hyphenated)


def test_validate_not_raises_with_correct_uuid_without_hyphens() raises:
    comptime correct_hyphenated = "432b4532a231460699477e382d33454b"
    UUID.validate(correct_hyphenated)


def test_validate_not_raises_with_correct_uuid_with_uppercase_hex() raises:
    comptime correct_hyphenated = "F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6"
    UUID.validate(correct_hyphenated)


def test_validate_raises_with_incorrect_uuid_without_hyphens() raises:
    comptime correct_hyphenated = "432z4532a231460699477e382d33454b"
    with assert_raises(contains="Invalid UUID Format"):
        UUID.validate(correct_hyphenated)


def test_validate_not_raises_with_correct_uuid_with_braces() raises:
    comptime correct_hyphenated = "{550e8400-e29b-41d4-a716-446655440000}"
    UUID.validate(correct_hyphenated)


def test_validate_not_raises_with_correct_uuid_with_wrong_braces() raises:
    comptime correct_hyphenated = "[550e8400-e29b-41d4-a716-446655440000]"
    with assert_raises(contains="Invalid Brackets Format"):
        UUID.validate(correct_hyphenated)


def test_validate_raises_with_mismatched_braces() raises:
    comptime correct_hyphenated = "{550e8400-e29b-41d4-a716-446655440000]"
    with assert_raises(contains="Invalid Brackets Format"):
        UUID.validate(correct_hyphenated)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
