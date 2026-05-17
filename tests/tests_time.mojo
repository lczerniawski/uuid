from uuid.time import (
    TimeGenerator,
    TimeSource,
    SystemTimeSource,
    gregorian_offset_ticks,
)
from uuid.libc import get_real_time_ns
from std.testing import (
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
    TestSuite,
)


struct MockTimeSource(TimeSource):
    var manual_time: UInt64

    def __init__(out self, time: UInt64):
        self.manual_time = time

    def now(self) -> UInt64:
        return self.manual_time


def test_time_generator_sets_clock_sequence_if_not_provided_in_constructor() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)

    assert_true(generator.clock_sequence != 0)


def test_time_generator_sets_clock_sequence_provided_in_constructor() raises:
    var expected = UInt16(12345 & 0x3FFF) | 0x8000
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(mock)
    generator.set_clock_sequence(12345)

    assert_true(generator.clock_sequence == expected)


def test_time_generator_set_clock_sequence_method_with_provided_sequence() raises:
    var expected = UInt16(12345 & 0x3FFF) | 0x8000
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)
    generator.set_clock_sequence(12345)

    assert_true(generator.clock_sequence == expected)


def test_time_generator_set_last_time_to_zero_when_new_sequence_is_provided() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)
    generator.last_time = 10
    generator.set_clock_sequence(12345)

    assert_true(generator.last_time == 0)


def test_get_clock_sequence_returns_provided_value_without_variant_bits() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(mock)
    generator.set_clock_sequence(12345)

    assert_equal(generator.get_clock_sequence(), 12345)


def test_get_clock_sequence_masks_input_to_14_bits() raises:
    # 0x7FFF -> low 14 bits are 0x3FFF (16383)
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(mock)
    generator.set_clock_sequence(0x7FFF)

    assert_equal(generator.get_clock_sequence(), 0x3FFF)


def test_get_clock_sequence_after_set_clock_sequence_with_value() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)
    generator.set_clock_sequence(42)

    assert_equal(generator.get_clock_sequence(), 42)


def test_next_uses_gregorian_offset_and_rfc_sequence_bits() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)
    generator.set_clock_sequence(0x1234)

    var result = generator.next()

    assert_equal(result.timestamp, 1000 + gregorian_offset_ticks)
    assert_equal(result.sequence, UInt16(0x9234))


def test_get_clock_sequence_constructor_random_is_in_range() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)

    var seq = generator.get_clock_sequence()
    assert_true(seq >= 0)
    assert_true(seq <= 0x3FFF)


def test_next_generates_time_structure_with_non_zero_values() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)

    var result = generator.next()
    assert_true(result.timestamp > 0)
    assert_true(result.sequence > 0)


def test_next_generates_unique_timestamp_when_time_changes() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)

    var first_result = generator.next()

    mock = MockTimeSource(1001)
    generator = TimeGenerator(time_source=mock)

    var second_result = generator.next()
    assert_true(first_result.timestamp != second_result.timestamp)


def test_next_generates_unique_sequence_when_time_changes() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)

    var first_result = generator.next()

    mock = MockTimeSource(1001)
    generator = TimeGenerator(time_source=mock)

    var second_result = generator.next()
    assert_true(first_result.sequence != second_result.sequence)


def test_next_generates_not_unique_timestamp_when_time_not_changes() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)

    var first_result = generator.next()
    var second_result = generator.next()

    assert_true(first_result.timestamp == second_result.timestamp)


def test_next_generates_unique_sequence_when_time_not_changes() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)

    var first_result = generator.next()
    var second_result = generator.next()

    assert_true(first_result.sequence != second_result.sequence)


def test_next_wraps_clock_sequence_properly() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(mock)
    generator.set_clock_sequence(0x3FFF)  # Max allowed clock sequence

    _ = generator.next()  # Sets last_time to 1000 + offset
    var second_result = (
        generator.next()
    )  # Time hasn't changed, sequence increments

    # Needs to wrap around correctly returning to 0x8000 (0 sequence with variant)
    assert_true(second_result.sequence == 0x8000)


def test_next_handles_time_moving_backward() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(time_source=mock)
    var first_result = generator.next()

    # Move clock backwards
    mock = MockTimeSource(900)
    generator = TimeGenerator(time_source=mock)
    var second_result = generator.next()

    assert_true(first_result.timestamp > second_result.timestamp)
    assert_true(first_result.sequence != second_result.sequence)


def test_time_generator_handles_zero_sequence() raises:
    var mock = MockTimeSource(1000)
    var generator = TimeGenerator(mock)
    generator.set_clock_sequence(0)

    assert_equal(generator.get_clock_sequence(), 0)
    assert_equal(generator.clock_sequence, 0x8000)  # 0 | variant bits


def test_system_time_source_returns_valid_time() raises:
    var source = SystemTimeSource()
    var t1 = source.now()
    var t2 = source.now()

    assert_true(t1 > 0)
    assert_true(t2 >= t1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
