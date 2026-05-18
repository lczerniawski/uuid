from uuid.crypto import (
    compute_md5,
    compute_sha1,
)
from std.testing import (
    assert_true,
    assert_equal,
    TestSuite,
)

comptime md5_empty = SIMD[DType.uint8, 16](
    0xD4,
    0x1D,
    0x8C,
    0xD9,
    0x8F,
    0x00,
    0xB2,
    0x04,
    0xE9,
    0x80,
    0x09,
    0x98,
    0xEC,
    0xF8,
    0x42,
    0x7E,
)

comptime md5_abc = SIMD[DType.uint8, 16](
    0x90,
    0x01,
    0x50,
    0x98,
    0x3C,
    0xD2,
    0x4F,
    0xB0,
    0xD6,
    0x96,
    0x3F,
    0x7D,
    0x28,
    0xE1,
    0x7F,
    0x72,
)

comptime md5_quick_brown_fox = SIMD[DType.uint8, 16](
    0x9E,
    0x10,
    0x7D,
    0x9D,
    0x37,
    0x2B,
    0xB6,
    0x82,
    0x6B,
    0xD8,
    0x1D,
    0x35,
    0x42,
    0xA4,
    0x19,
    0xD6,
)

comptime md5_long_message = SIMD[DType.uint8, 16](
    0x36,
    0xA9,
    0x2C,
    0xC9,
    0x4A,
    0x9E,
    0x0F,
    0xA2,
    0x1F,
    0x62,
    0x5F,
    0x8B,
    0xFB,
    0x00,
    0x7A,
    0xDF,
)


def test_compute_md5_empty_string() raises:
    var result = compute_md5("".as_bytes())
    assert_equal(result, md5_empty)


def test_compute_md5_abc() raises:
    var result = compute_md5("abc".as_bytes())
    assert_equal(result, md5_abc)


def test_compute_md5_quick_brown_fox() raises:
    var result = compute_md5(
        "The quick brown fox jumps over the lazy dog".as_bytes()
    )
    assert_equal(result, md5_quick_brown_fox)


def test_compute_md5_is_deterministic() raises:
    var first = compute_md5("hello world".as_bytes())
    var second = compute_md5("hello world".as_bytes())
    assert_equal(first, second)


def test_compute_md5_changes_for_different_inputs() raises:
    var first = compute_md5("hello".as_bytes())
    var second = compute_md5("world".as_bytes())
    assert_true(first != second)


def test_compute_md5_long_input_spans_multiple_blocks() raises:
    var result = compute_md5(("a" * 100).as_bytes())
    assert_equal(result, md5_long_message)


comptime sha1_empty = SIMD[DType.uint8, 20](
    0xDA,
    0x39,
    0xA3,
    0xEE,
    0x5E,
    0x6B,
    0x4B,
    0x0D,
    0x32,
    0x55,
    0xBF,
    0xEF,
    0x95,
    0x60,
    0x18,
    0x90,
    0xAF,
    0xD8,
    0x07,
    0x09,
)

comptime sha1_abc = SIMD[DType.uint8, 20](
    0xA9,
    0x99,
    0x3E,
    0x36,
    0x47,
    0x06,
    0x81,
    0x6A,
    0xBA,
    0x3E,
    0x25,
    0x71,
    0x78,
    0x50,
    0xC2,
    0x6C,
    0x9C,
    0xD0,
    0xD8,
    0x9D,
)

comptime sha1_quick_brown_fox = SIMD[DType.uint8, 20](
    0x2F,
    0xD4,
    0xE1,
    0xC6,
    0x7A,
    0x2D,
    0x28,
    0xFC,
    0xED,
    0x84,
    0x9E,
    0xE1,
    0xBB,
    0x76,
    0xE7,
    0x39,
    0x1B,
    0x93,
    0xEB,
    0x12,
)


def test_compute_sha1_empty_string() raises:
    var result = compute_sha1("".as_bytes())
    assert_equal(result, sha1_empty)


def test_compute_sha1_abc() raises:
    var result = compute_sha1("abc".as_bytes())
    assert_equal(result, sha1_abc)


def test_compute_sha1_quick_brown_fox() raises:
    var result = compute_sha1(
        "The quick brown fox jumps over the lazy dog".as_bytes()
    )
    assert_equal(result, sha1_quick_brown_fox)


def test_compute_sha1_is_deterministic() raises:
    var first = compute_sha1("hello world".as_bytes())
    var second = compute_sha1("hello world".as_bytes())
    assert_equal(first, second)


def test_compute_sha1_changes_for_different_inputs() raises:
    var first = compute_sha1("hello".as_bytes())
    var second = compute_sha1("world".as_bytes())
    assert_true(first != second)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
