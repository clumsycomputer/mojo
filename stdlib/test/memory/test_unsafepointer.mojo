# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
# RUN: %mojo %s

from memory import UnsafePointer
from test_utils import ExplicitCopyOnly, MoveCounter
from testing import assert_equal, assert_not_equal, assert_true, assert_false


struct MoveOnlyType(Movable):
    # It's a weak reference, we don't want to delete the actions
    # after the struct is deleted, otherwise we can't observe the __del__.
    var actions: UnsafePointer[List[String]]
    var value: Int

    fn __init__(inout self, value: Int, actions: UnsafePointer[List[String]]):
        self.actions = actions
        self.value = value
        self.actions[0].append("__init__")

    fn __moveinit__(inout self, owned existing: Self):
        self.actions = existing.actions
        self.value = existing.value
        self.actions[0].append("__moveinit__")

    fn __del__(owned self):
        self.actions[0].append("__del__")


def test_unsafepointer_of_move_only_type():
    var actions_ptr = UnsafePointer[List[String]].alloc(1)
    actions_ptr.init_pointee_move(List[String]())

    var ptr = UnsafePointer[MoveOnlyType].alloc(1)
    ptr.init_pointee_move(MoveOnlyType(42, actions_ptr))
    assert_equal(len(actions_ptr[0]), 2)
    assert_equal(actions_ptr[0][0], "__init__")
    assert_equal(actions_ptr[0][1], "__moveinit__", msg="emplace_value")
    assert_equal(ptr[0].value, 42)

    var value = ptr.take_pointee()
    assert_equal(len(actions_ptr[0]), 3)
    assert_equal(actions_ptr[0][2], "__moveinit__")
    assert_equal(value.value, 42)

    ptr.free()
    assert_equal(len(actions_ptr[0]), 4)
    assert_equal(actions_ptr[0][3], "__del__")

    actions_ptr.free()


def test_unsafepointer_move_pointee_move_count():
    var ptr = UnsafePointer[MoveCounter[Int]].alloc(1)

    var value = MoveCounter(5)
    assert_equal(0, value.move_count)
    ptr.init_pointee_move(value^)

    # -----
    # Test that `UnsafePointer.move_pointee` performs exactly one move.
    # -----

    assert_equal(1, ptr[].move_count)

    var ptr_2 = UnsafePointer[MoveCounter[Int]].alloc(1)
    ptr.move_pointee_into(ptr_2)

    assert_equal(2, ptr_2[].move_count)


def test_unsafepointer_initialize_pointee_explicit_copy():
    var ptr = UnsafePointer[ExplicitCopyOnly].alloc(1)

    var orig = ExplicitCopyOnly(5)
    assert_equal(orig.copy_count, 0)

    # Test initialize pointee from `ExplicitlyCopyable` type
    ptr.initialize_pointee_explicit_copy(orig)

    assert_equal(ptr[].value, 5)
    assert_equal(ptr[].copy_count, 1)


def test_refitem():
    var ptr = UnsafePointer[Int].alloc(1)
    ptr[0] = 0
    ptr[] += 1
    assert_equal(ptr[], 1)
    ptr.free()


def test_refitem_offset():
    var ptr = UnsafePointer[Int].alloc(5)
    for i in range(5):
        ptr[i] = i
    for i in range(5):
        assert_equal(ptr[i], i)
    ptr.free()


def test_address_of():
    var local = 1
    assert_not_equal(0, int(UnsafePointer[Int].address_of(local)))
    _ = local


def test_explicit_copy_of_pointer_address():
    var local = 1
    var ptr = UnsafePointer[Int].address_of(local)
    var copy = UnsafePointer(other=ptr)
    assert_equal(int(ptr), int(copy))
    _ = local


def test_bitcast():
    var local = 1
    var ptr = UnsafePointer[Int].address_of(local)
    var aliased_ptr = ptr.bitcast[SIMD[DType.uint8, 4]]()

    assert_equal(int(ptr), int(ptr.bitcast[Int]()))

    assert_equal(int(ptr), int(aliased_ptr))
    _ = local


def test_unsafepointer_string():
    var nullptr = UnsafePointer[Int]()
    assert_equal(str(nullptr), "0x0")

    var ptr = UnsafePointer[Int].alloc(1)
    assert_true(str(ptr).startswith("0x"))
    assert_not_equal(str(ptr), "0x0")
    ptr.free()


def test_eq():
    var local = 1
    var p1 = UnsafePointer[Int].address_of(local)
    var p2 = p1
    assert_equal(p1, p2)

    var other_local = 2
    var p3 = UnsafePointer[Int].address_of(other_local)
    assert_not_equal(p1, p3)

    var p4 = UnsafePointer[Int].address_of(local)
    assert_equal(p1, p4)
    _ = local
    _ = other_local


def test_comparisons():
    var p1 = UnsafePointer[Int].alloc(1)

    assert_true((p1 - 1) < p1)
    assert_true((p1 - 1) <= p1)
    assert_true(p1 <= p1)
    assert_true((p1 + 1) > p1)
    assert_true((p1 + 1) >= p1)
    assert_true(p1 >= p1)

    p1.free()


def test_unsafepointer_address_space():
    var p1 = UnsafePointer[Int, AddressSpace(0)].alloc(1)
    p1.free()

    var p2 = UnsafePointer[Int, AddressSpace.GENERIC].alloc(1)
    p2.free()


def test_unsafepointer_aligned_alloc():
    alias alignment_1 = 32
    var ptr = UnsafePointer[UInt8].alloc[alignment=alignment_1](1)
    var ptr_uint64 = UInt64(int(ptr))
    ptr.free()
    assert_equal(ptr_uint64 % alignment_1, 0)

    alias alignment_2 = 64
    var ptr_2 = UnsafePointer[UInt8].alloc[alignment=alignment_2](1)
    var ptr_uint64_2 = UInt64(int(ptr_2))
    ptr_2.free()
    assert_equal(ptr_uint64_2 % alignment_2, 0)

    alias alignment_3 = 128
    var ptr_3 = UnsafePointer[UInt8].alloc[alignment=alignment_3](1)
    var ptr_uint64_3 = UInt64(int(ptr_3))
    ptr_3.free()
    assert_equal(ptr_uint64_3 % alignment_3, 0)


# NOTE: Tests fails due to a `UnsafePointer` size
# and alignment constraint failing to be satisfied.
#
# def test_unsafepointer_zero_size():
#     alias T = SIMD[DType.int32, 0]
#
#     var start_ptr = UnsafePointer[T].alloc(10)
#     var dest_ptr = start_ptr + 5
#
#     assert_true(start_ptr < dest_ptr)
#     assert_true(start_ptr != dest_ptr)


def test_indexing():
    var ptr = UnsafePointer[Int].alloc(4)
    for i in range(4):
        ptr[i] = i

    assert_equal(ptr[False], 0)
    assert_equal(ptr[int(1)], 1)
    assert_equal(ptr[3], 3)


def test_bool():
    var nullptr = UnsafePointer[Int]()
    var ptr = UnsafePointer[Int].alloc(1)

    assert_true(ptr.__bool__())
    assert_false(nullptr.__bool__())
    assert_true(ptr.__as_bool__())
    assert_false(nullptr.__as_bool__())

    ptr.free()


def test_alignment():
    var ptr = UnsafePointer[Int64].alloc[alignment=64](8)
    assert_equal(int(ptr) % 64, 0)
    ptr.free()

    var ptr_2 = UnsafePointer[UInt8].alloc[alignment=32](32)
    assert_equal(int(ptr_2) % 32, 0)
    ptr_2.free()


def main():
    test_address_of()

    test_refitem()
    test_refitem_offset()

    test_unsafepointer_of_move_only_type()
    test_unsafepointer_move_pointee_move_count()
    test_unsafepointer_initialize_pointee_explicit_copy()

    test_explicit_copy_of_pointer_address()
    test_bitcast()
    test_unsafepointer_string()
    test_eq()
    test_comparisons()

    test_unsafepointer_address_space()
    test_indexing()
    test_bool()
    test_alignment()
