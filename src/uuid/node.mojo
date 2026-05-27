from crypto.random import generate_secure_u64


struct NodeManager:
    """
    Manage the node identifier used by time-based UUID v1 generation.

    The node value is initialized once from secure random bytes and then
    reused so UUIDs can carry a stable node identity.
    """

    var node_id: SIMD[DType.uint8, 6]

    def __init__(out self) raises:
        """
        Initialize the node manager with a fresh node identifier.

        The identifier is generated from secure random data and normalized to
        the UUID node-id format.
        """
        self.node_id = SIMD[DType.uint8, 6](0)
        self._init_node_id()

    def _init_node_id(mut self) raises:
        """
        Fill the node identifier with secure random bytes.

        The multicast bit is set so the value is treated as a random node ID
        rather than a hardware address.

        Raises:
            `Error`: If secure random bytes cannot be obtained for node ID initialization.
        """
        var value = generate_secure_u64() & 0xFFFFFFFFFFFF
        value = value | (UInt64(1) << 40)

        self.node_id[0] = UInt8((value >> 40) & 0xFF)
        self.node_id[1] = UInt8((value >> 32) & 0xFF)
        self.node_id[2] = UInt8((value >> 24) & 0xFF)
        self.node_id[3] = UInt8((value >> 16) & 0xFF)
        self.node_id[4] = UInt8((value >> 8) & 0xFF)
        self.node_id[5] = UInt8(value & 0xFF)

    def get_node_id(self) -> SIMD[DType.uint8, 6]:
        """
        Return the current node identifier.

        Returns:
            `SIMD[DType.uint8, 6]`: The cached node identifier.
        """
        return self.node_id
