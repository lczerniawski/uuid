from uuid import Generator


def main() raises:
    # Create new Generator object, for UUID v1 Generation this one should be kept as a singleton, due to the need for state.
    # For all the other cases, it can be recreated as needed, but for simplification it is advised to create it once and reuse for whole application lifetime.
    var generator = Generator()

    # Generate a random (version 4) UUID and print it.
    var uuid = generator.v4()

    # Print the canonical string representation and raw bytes
    print("Generated v4 UUID:", uuid.to_string())
    print("Raw bytes:", uuid.bytes)

    # Generate a version 7 UUID and print it.
    var uuid_v7 = generator.v7()

    print("Generated v7 UUID:", uuid_v7.to_string())
    print("Raw bytes:", uuid_v7.bytes)
