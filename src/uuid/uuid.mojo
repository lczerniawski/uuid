struct UUIDVersion(Equatable):
    comptime v1: UInt8 = 1
    comptime v4: UInt8 = 4
    comptime v6: UInt8 = 6
    comptime v7: UInt8 = 7

    var value: UInt8

    @implicit
    def __init__(out self, val: UInt8):
        self.value = val


@fieldwise_init
struct UUIDValidationError(ImplicitlyCopyable, Writable):
    var reason: String


struct UUID(ImplicitlyCopyable, Writable):
    comptime hex_chars = "0123456789abcdef"
    comptime standard_uuid_len = 36
    comptime uuid_len_without_hyphens = 32
    comptime hyphen_uint8 = UInt8(ord("-"))
    comptime urn_prefix = "urn:uuid:"
    comptime validation_indices = [
        0,
        2,
        4,
        6,
        9,
        11,
        14,
        16,
        19,
        21,
        24,
        26,
        28,
        30,
        32,
        34,
    ]

    var bytes: SIMD[DType.uint8, 16]

    def __init__(out self, bytes: SIMD[DType.uint8, 16]):
        self.bytes = bytes

    @staticmethod
    def from_bytes(bytes: SIMD[DType.uint8, 16]) -> UUID:
        return UUID(bytes)

    @staticmethod
    def from_string(s: String) raises -> UUID:
        Self.validate(s)
        var string_as_bytes = s.as_bytes()

        var uuid_length = 0
        var result = SIMD[DType.uint8, 16](0)

        if string_as_bytes[0:9] == Self.urn_prefix.as_bytes():
            string_as_bytes = string_as_bytes[9:]

        for i in range(len(string_as_bytes)):
            if (
                string_as_bytes[i] != UInt8(ord("{"))
                and string_as_bytes[i] != UInt8(ord("}"))
                and string_as_bytes[i] != UInt8(ord("-"))
            ):
                var val = _hex_to_byte(string_as_bytes[i])
                if uuid_length % 2 == 0:
                    result[uuid_length // 2] = val << 4
                else:
                    result[uuid_length // 2] |= val
                uuid_length += 1

        return UUID(result)

    def to_string(self: Self) -> String:
        var result = String()

        for i in range(len(self.bytes)):
            if i == 4 or i == 6 or i == 8 or i == 10:
                result += "-"

            var b = Int(self.bytes[i])
            result += self.hex_chars[b >> 4]
            result += self.hex_chars[b & 0x0F]
        return result

    def urn(self: Self) -> String:
        return self.urn_prefix + self.to_string()

    def version(self: Self) -> UUIDVersion:
        return UUIDVersion(self.bytes[6] >> 4)

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def write_repr_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    @staticmethod
    def validate(s: String) raises:
        """
        Validate raises an error if s is not a properly formatted UUID.
        The passed string needs to be in one of the following formats:
            xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,
            urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,
            xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,
            {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}.

        Args:
            s: The input string to be validated.

        Raises:
            An `UUIDValidationError` error with a reason if validation fails.
        """
        var cleaned = s.as_bytes()
        var string_length = s.byte_length()

        if string_length == Self.standard_uuid_len:
            pass
        elif string_length == Self.standard_uuid_len + 9:
            if cleaned[0:9] != Self.urn_prefix.as_bytes():
                raise UUIDValidationError("Wrong URN Prefix")
            cleaned = cleaned[9:]
        elif string_length == Self.standard_uuid_len + 2:
            if cleaned[0] != UInt8(ord("{")) or cleaned[
                len(cleaned) - 1
            ] != UInt8(ord("}")):
                raise UUIDValidationError("Invalid Brackets Format")
            cleaned = cleaned[1 : len(cleaned) - 1]
        elif string_length == Self.uuid_len_without_hyphens:
            for i in range(0, string_length, 2):
                var char_high = cleaned[i]
                var char_low = cleaned[i + 1]
                try:
                    _ = _hex_to_byte(char_high)
                    _ = _hex_to_byte(char_low)
                except:
                    raise UUIDValidationError("Invalid UUID Format")
        else:
            raise UUIDValidationError("Invalid UUID Format")

        if len(cleaned) == Self.standard_uuid_len:
            if (
                cleaned[8] != Self.hyphen_uint8
                or cleaned[13] != Self.hyphen_uint8
                or cleaned[18] != Self.hyphen_uint8
                or cleaned[23] != Self.hyphen_uint8
            ):
                raise UUIDValidationError("Invalid UUID Format")

            for i in materialize[Self.validation_indices]():
                var char_high = cleaned[i]
                var char_low = cleaned[i + 1]
                try:
                    _ = _hex_to_byte(char_high)
                    _ = _hex_to_byte(char_low)
                except:
                    raise UUIDValidationError("Invalid UUID Format")


def _hex_to_byte(c: UInt8) raises -> UInt8:
    var int_c = Int(c)

    # 0-9
    if 48 <= int_c <= 57:
        return c - 48
    # a-f
    if 97 <= int_c <= 102:
        return c - 87
    # A-F
    if 65 <= int_c <= 70:
        return c - 55

    raise Error("Invalid hex character")
