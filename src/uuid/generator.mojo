from .uuid import UUID
from .time import TimeGenerator, SystemTimeSource
from .node import NodeManager
from .libc import compute_md5, get_secure_random_u128


struct Generator:
    """
    High-level UUID generator.
    """

    var time_generator: TimeGenerator[SystemTimeSource]
    var node_manager: NodeManager

    def __init__(out self) raises:
        """
        Initialize a UUID generator with default time and node providers.

        The generator uses the system clock for time values and a secure
        random node identifier.
        """
        self.time_generator = TimeGenerator()
        self.node_manager = NodeManager()

    def get_clock_sequence(mut self) -> Int:
        """
        Return the currently configured clock sequence.

        Returns:
            `Int`: The RFC 4122 clock-sequence value.
        """
        return self.time_generator.get_clock_sequence()

    def set_clock_sequence(mut self, sequence: Int) raises:
        """
        Update the clock sequence used for time-based UUID generation.

        Args:
            sequence: The new clock sequence value to apply.

        Raises:
            `Error`: If the provided sequence value is invalid or if the update process encounters an issue.
        """
        return self.time_generator.set_clock_sequence(sequence)

    def v1(mut self) raises -> UUID:
        """
        Generate a version 1 UUID.

        The UUID is assembled from the current timestamp, the active clock
        sequence, and the node identifier managed by this generator.

        Returns:
            `UUID`: A newly generated version 1 UUID.

        Raises:
            `Error`: If time retrieval or node ID generation fails during UUID creation.
        """
        var time = self.time_generator.next()
        var now = time.timestamp

        var time_low = UInt32(now & 0xFFFFFFFF)
        var time_mid = UInt16((now >> 32) & 0xFFFF)
        var time_high_and_version = UInt16(((now >> 48) & 0x0FFF) | 0x1000)
        var clock_seq = time.sequence
        var node_id = self.node_manager.get_node_id()

        var bytes = SIMD[DType.uint8, 16](0)

        bytes[0] = UInt8((time_low >> 24) & 0xFF)
        bytes[1] = UInt8((time_low >> 16) & 0xFF)
        bytes[2] = UInt8((time_low >> 8) & 0xFF)
        bytes[3] = UInt8(time_low & 0xFF)

        bytes[4] = UInt8((time_mid >> 8) & 0xFF)
        bytes[5] = UInt8(time_mid & 0xFF)

        bytes[6] = UInt8((time_high_and_version >> 8) & 0xFF)
        bytes[7] = UInt8(time_high_and_version & 0xFF)

        bytes[8] = UInt8((clock_seq >> 8) & 0xFF)
        bytes[9] = UInt8(clock_seq & 0xFF)

        bytes[10] = node_id[0]
        bytes[11] = node_id[1]
        bytes[12] = node_id[2]
        bytes[13] = node_id[3]
        bytes[14] = node_id[4]
        bytes[15] = node_id[5]

        return UUID(bytes)

    def v3(mut self, namespace: UUID, name: String) -> UUID:
        """
        Generate a version 3 UUID.

        The UUID is derived from the provided namespace UUID and name using
        an MD5 hash, with the version and variant bits set to RFC values.

        Args:
            namespace: The UUID that defines the namespace for this name-based UUID.
            name: The name from which to generate the UUID, typically a string.

        Returns:
            `UUID`: A newly generated version 3 UUID.
        """
        var namespace_bytes = namespace.to_bytes()
        var name_bytes = name.as_bytes()

        var buf = List[UInt8]()
        for i in range(len(namespace_bytes)):
            buf.append(namespace_bytes[i])

        for byte in name_bytes:
            buf.append(byte)

        var md5_hash = compute_md5(buf)

        md5_hash[6] = UInt8(
            (md5_hash[6] & 0x0F) | 0x30
        )  # Set UUID version to 3
        md5_hash[8] = UInt8(
            (md5_hash[8] & 0x3F) | 0x80
        )  # Set UUID variant to RFC

        return UUID(md5_hash)

    def v4(mut self) raises -> UUID:
        """
        Generate a version 4 UUID.

        The UUID is assembled from secure random bytes, then normalized by
        setting the version and variant bits required by the RFC.

        Returns:
            `UUID`: A newly generated version 4 UUID.

        Raises:
            `Error`: If secure random bytes cannot be obtained.
        """
        var random_bytes = get_secure_random_u128()
        var bytes = SIMD[DType.uint8, 16](0)

        bytes[0] = UInt8((random_bytes >> 120) & 0xFF)
        bytes[1] = UInt8((random_bytes >> 112) & 0xFF)
        bytes[2] = UInt8((random_bytes >> 104) & 0xFF)
        bytes[3] = UInt8((random_bytes >> 96) & 0xFF)
        bytes[4] = UInt8((random_bytes >> 88) & 0xFF)
        bytes[5] = UInt8((random_bytes >> 80) & 0xFF)
        bytes[6] = (
            UInt8((random_bytes >> 72) & 0xFF) & 0x0F
        ) | 0x40  # Set UUID version to 4
        bytes[7] = UInt8((random_bytes >> 64) & 0xFF)
        bytes[8] = (
            UInt8((random_bytes >> 56) & 0xFF) & 0x3F
        ) | 0x80  # Set UUID variant to RFC
        bytes[9] = UInt8((random_bytes >> 48) & 0xFF)
        bytes[10] = UInt8((random_bytes >> 40) & 0xFF)
        bytes[11] = UInt8((random_bytes >> 32) & 0xFF)
        bytes[12] = UInt8((random_bytes >> 24) & 0xFF)
        bytes[13] = UInt8((random_bytes >> 16) & 0xFF)
        bytes[14] = UInt8((random_bytes >> 8) & 0xFF)
        bytes[15] = UInt8(random_bytes & 0xFF)

        return UUID(bytes)
