def _rotl32(value: UInt32, shift: Int) -> UInt32:
    var amount = UInt32(shift)
    return (value << amount) | (value >> UInt32(32 - shift))


def _md5_round_constant(index: Int) -> UInt32:
    if index < 16:
        return [
            UInt32(0xD76AA478),
            UInt32(0xE8C7B756),
            UInt32(0x242070DB),
            UInt32(0xC1BDCEEE),
            UInt32(0xF57C0FAF),
            UInt32(0x4787C62A),
            UInt32(0xA8304613),
            UInt32(0xFD469501),
            UInt32(0x698098D8),
            UInt32(0x8B44F7AF),
            UInt32(0xFFFF5BB1),
            UInt32(0x895CD7BE),
            UInt32(0x6B901122),
            UInt32(0xFD987193),
            UInt32(0xA679438E),
            UInt32(0x49B40821),
        ][index]
    if index < 32:
        return [
            UInt32(0xF61E2562),
            UInt32(0xC040B340),
            UInt32(0x265E5A51),
            UInt32(0xE9B6C7AA),
            UInt32(0xD62F105D),
            UInt32(0x02441453),
            UInt32(0xD8A1E681),
            UInt32(0xE7D3FBC8),
            UInt32(0x21E1CDE6),
            UInt32(0xC33707D6),
            UInt32(0xF4D50D87),
            UInt32(0x455A14ED),
            UInt32(0xA9E3E905),
            UInt32(0xFCEFA3F8),
            UInt32(0x676F02D9),
            UInt32(0x8D2A4C8A),
        ][index - 16]
    if index < 48:
        return [
            UInt32(0xFFFA3942),
            UInt32(0x8771F681),
            UInt32(0x6D9D6122),
            UInt32(0xFDE5380C),
            UInt32(0xA4BEEA44),
            UInt32(0x4BDECFA9),
            UInt32(0xF6BB4B60),
            UInt32(0xBEBFBC70),
            UInt32(0x289B7EC6),
            UInt32(0xEAA127FA),
            UInt32(0xD4EF3085),
            UInt32(0x04881D05),
            UInt32(0xD9D4D039),
            UInt32(0xE6DB99E5),
            UInt32(0x1FA27CF8),
            UInt32(0xC4AC5665),
        ][index - 32]
    return [
        UInt32(0xF4292244),
        UInt32(0x432AFF97),
        UInt32(0xAB9423A7),
        UInt32(0xFC93A039),
        UInt32(0x655B59C3),
        UInt32(0x8F0CCC92),
        UInt32(0xFFEFF47D),
        UInt32(0x85845DD1),
        UInt32(0x6FA87E4F),
        UInt32(0xFE2CE6E0),
        UInt32(0xA3014314),
        UInt32(0x4E0811A1),
        UInt32(0xF7537E82),
        UInt32(0xBD3AF235),
        UInt32(0x2AD7D2BB),
        UInt32(0xEB86D391),
    ][index - 48]


def _md5_shift_amount(index: Int) -> Int:
    if index < 16:
        return [7, 12, 17, 22][index % 4]
    if index < 32:
        return [5, 9, 14, 20][index % 4]
    if index < 48:
        return [4, 11, 16, 23][index % 4]
    return [6, 10, 15, 21][index % 4]


def _md5_message_index(index: Int) -> Int:
    if index < 16:
        return index
    if index < 32:
        return (5 * index + 1) % 16
    if index < 48:
        return (3 * index + 5) % 16
    return (7 * index) % 16


def _md5_digest(data: Span[UInt8, ...]) -> SIMD[DType.uint8, 16]:
    var a = UInt32(0x67452301)
    var b = UInt32(0xEFCDAB89)
    var c = UInt32(0x98BADCFE)
    var d = UInt32(0x10325476)

    var message = List[UInt8]()
    for byte in data:
        message.append(byte)

    var original_length = len(message)
    message.append(UInt8(0x80))
    while (len(message) % 64) != 56:
        message.append(UInt8(0))

    var bit_length = UInt64(original_length) * UInt64(8)
    for i in range(8):
        message.append(UInt8((bit_length >> UInt64(i * 8)) & UInt64(0xFF)))

    var offset = 0
    while offset < len(message):
        var m = List[UInt32]()
        for i in range(16):
            var base = offset + (i * 4)
            var word = UInt32(message[base])
            word |= UInt32(message[base + 1]) << UInt32(8)
            word |= UInt32(message[base + 2]) << UInt32(16)
            word |= UInt32(message[base + 3]) << UInt32(24)
            m.append(word)

        var aa = a
        var bb = b
        var cc = c
        var dd = d

        for i in range(64):
            var g = _md5_message_index(i)
            var f: UInt32

            if i < 16:
                f = (bb & cc) | ((~bb) & dd)
            elif i < 32:
                f = (dd & bb) | ((~dd) & cc)
            elif i < 48:
                f = bb ^ cc ^ dd
            else:
                f = cc ^ (bb | (~dd))

            var temp = dd
            dd = cc
            cc = bb
            bb = bb + _rotl32(
                aa + f + _md5_round_constant(i) + m[g],
                _md5_shift_amount(i),
            )
            aa = temp

        a = a + aa
        b = b + bb
        c = c + cc
        d = d + dd

        offset += 64

    var result = SIMD[DType.uint8, 16](0)
    result[0] = UInt8(a & UInt32(0xFF))
    result[1] = UInt8((a >> UInt32(8)) & UInt32(0xFF))
    result[2] = UInt8((a >> UInt32(16)) & UInt32(0xFF))
    result[3] = UInt8((a >> UInt32(24)) & UInt32(0xFF))
    result[4] = UInt8(b & UInt32(0xFF))
    result[5] = UInt8((b >> UInt32(8)) & UInt32(0xFF))
    result[6] = UInt8((b >> UInt32(16)) & UInt32(0xFF))
    result[7] = UInt8((b >> UInt32(24)) & UInt32(0xFF))
    result[8] = UInt8(c & UInt32(0xFF))
    result[9] = UInt8((c >> UInt32(8)) & UInt32(0xFF))
    result[10] = UInt8((c >> UInt32(16)) & UInt32(0xFF))
    result[11] = UInt8((c >> UInt32(24)) & UInt32(0xFF))
    result[12] = UInt8(d & UInt32(0xFF))
    result[13] = UInt8((d >> UInt32(8)) & UInt32(0xFF))
    result[14] = UInt8((d >> UInt32(16)) & UInt32(0xFF))
    result[15] = UInt8((d >> UInt32(24)) & UInt32(0xFF))
    return result


def _sha1_digest(data: Span[UInt8, ...]) -> SIMD[DType.uint8, 20]:
    var h0 = UInt32(0x67452301)
    var h1 = UInt32(0xEFCDAB89)
    var h2 = UInt32(0x98BADCFE)
    var h3 = UInt32(0x10325476)
    var h4 = UInt32(0xC3D2E1F0)

    var message = List[UInt8]()
    for byte in data:
        message.append(byte)

    var original_length = len(message)
    message.append(UInt8(0x80))
    while (len(message) % 64) != 56:
        message.append(UInt8(0))

    var bit_length = UInt64(original_length) * UInt64(8)
    for i in range(8):
        var shift = UInt64((7 - i) * 8)
        message.append(UInt8((bit_length >> shift) & UInt64(0xFF)))

    var offset = 0
    while offset < len(message):
        var w = List[UInt32]()
        for i in range(16):
            var base = offset + (i * 4)
            var word = UInt32(message[base]) << UInt32(24)
            word |= UInt32(message[base + 1]) << UInt32(16)
            word |= UInt32(message[base + 2]) << UInt32(8)
            word |= UInt32(message[base + 3])
            w.append(word)

        for i in range(16, 80):
            w.append(_rotl32(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1))

        var a = h0
        var b = h1
        var c = h2
        var d = h3
        var e = h4

        for i in range(80):
            if i < 20:
                var temp = (
                    _rotl32(a, 5)
                    + ((b & c) | ((UInt32(0xFFFFFFFF) ^ b) & d))
                    + e
                    + UInt32(0x5A827999)
                    + w[i]
                )
                e = d
                d = c
                c = _rotl32(b, 30)
                b = a
                a = temp
            elif i < 40:
                var temp = (
                    _rotl32(a, 5) + (b ^ c ^ d) + e + UInt32(0x6ED9EBA1) + w[i]
                )
                e = d
                d = c
                c = _rotl32(b, 30)
                b = a
                a = temp
            elif i < 60:
                var temp = (
                    _rotl32(a, 5)
                    + ((b & c) | (b & d) | (c & d))
                    + e
                    + UInt32(0x8F1BBCDC)
                    + w[i]
                )
                e = d
                d = c
                c = _rotl32(b, 30)
                b = a
                a = temp
            else:
                var temp = (
                    _rotl32(a, 5) + (b ^ c ^ d) + e + UInt32(0xCA62C1D6) + w[i]
                )
                e = d
                d = c
                c = _rotl32(b, 30)
                b = a
                a = temp

        h0 = h0 + a
        h1 = h1 + b
        h2 = h2 + c
        h3 = h3 + d
        h4 = h4 + e

        offset += 64

    var result = SIMD[DType.uint8, 20](0)
    result[0] = UInt8((h0 >> UInt32(24)) & UInt32(0xFF))
    result[1] = UInt8((h0 >> UInt32(16)) & UInt32(0xFF))
    result[2] = UInt8((h0 >> UInt32(8)) & UInt32(0xFF))
    result[3] = UInt8(h0 & UInt32(0xFF))
    result[4] = UInt8((h1 >> UInt32(24)) & UInt32(0xFF))
    result[5] = UInt8((h1 >> UInt32(16)) & UInt32(0xFF))
    result[6] = UInt8((h1 >> UInt32(8)) & UInt32(0xFF))
    result[7] = UInt8(h1 & UInt32(0xFF))
    result[8] = UInt8((h2 >> UInt32(24)) & UInt32(0xFF))
    result[9] = UInt8((h2 >> UInt32(16)) & UInt32(0xFF))
    result[10] = UInt8((h2 >> UInt32(8)) & UInt32(0xFF))
    result[11] = UInt8(h2 & UInt32(0xFF))
    result[12] = UInt8((h3 >> UInt32(24)) & UInt32(0xFF))
    result[13] = UInt8((h3 >> UInt32(16)) & UInt32(0xFF))
    result[14] = UInt8((h3 >> UInt32(8)) & UInt32(0xFF))
    result[15] = UInt8(h3 & UInt32(0xFF))
    result[16] = UInt8((h4 >> UInt32(24)) & UInt32(0xFF))
    result[17] = UInt8((h4 >> UInt32(16)) & UInt32(0xFF))
    result[18] = UInt8((h4 >> UInt32(8)) & UInt32(0xFF))
    result[19] = UInt8(h4 & UInt32(0xFF))
    return result


def compute_md5(data: Span[UInt8, ...]) -> SIMD[DType.uint8, 16]:
    """
    Compute MD5 hash of input string.

    Args:
        data: Input data to hash as a byte span.

    Returns:
        `SIMD[DType.uint8, 16]`: 16-byte MD5 hash.
    """
    return _md5_digest(data)


def compute_sha1(data: Span[UInt8, ...]) -> SIMD[DType.uint8, 20]:
    """
    Compute SHA-1 hash of input string.

    Args:
        data: Input data to hash as a byte span.

    Returns:
        `SIMD[DType.uint8, 20]`: 20-byte SHA-1.
    """
    return _sha1_digest(data)
