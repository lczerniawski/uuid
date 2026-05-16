from uuid.node import NodeManager
from std.time import sleep
from std.collections import Set
from std.testing import (
    assert_true,
    assert_not_equal,
    TestSuite,
)


def test_init_node_id_is_non_zero() raises:
    var zero = SIMD[DType.uint8, 6](0)

    var manager = NodeManager()
    var id = manager.get_node_id()

    assert_not_equal(id, zero)


def test_init_node_is_id_different_per_manager() raises:
    var first_manager = NodeManager()
    var second_manager = NodeManager()

    var first_result = first_manager.get_node_id()
    var second_result = second_manager.get_node_id()

    assert_not_equal(first_result, second_result)


def test_node_id_stable() raises:
    var manager = NodeManager()
    var a = manager.get_node_id()
    var b = manager.get_node_id()
    assert_true(a == b)


def test_many_managers_unique() raises:
    var seen = Set[SIMD[DType.uint8, 6]]()
    for _ in range(100):
        var manager = NodeManager()
        var id = manager.get_node_id()
        assert_true(not id in seen)
        seen.add(id)


def test_first_octet_flag_set() raises:
    var manager = NodeManager()
    var id0 = manager.get_node_id()[0]
    assert_true((id0 & 1) == 1)


def test_length_and_indexing() raises:
    var manager = NodeManager()
    var id = manager.get_node_id()
    for i in range(6):
        var _ = id[i]


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
