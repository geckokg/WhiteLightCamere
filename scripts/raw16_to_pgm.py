from pathlib import Path
import argparse


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert one Python1300 16-bit little-endian raw frame to PGM.")
    parser.add_argument("raw", type=Path, help="Input raw frame: 1280*1024 little-endian uint16 pixels.")
    parser.add_argument("pgm", type=Path, help="Output PGM path.")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=1024)
    parser.add_argument("--shift-left", type=int, default=6, help="Shift 10-bit samples into 16-bit PGM range.")
    args = parser.parse_args()

    expected = args.width * args.height * 2
    data = args.raw.read_bytes()
    if len(data) < expected:
        raise SystemExit(f"raw file is too small: got {len(data)} bytes, expected {expected}")
    data = bytearray(data[:expected])

    if args.shift_left:
        for i in range(0, len(data), 2):
            value = data[i] | (data[i + 1] << 8)
            value = (value & 0x03FF) << args.shift_left
            data[i] = (value >> 8) & 0xFF
            data[i + 1] = value & 0xFF
    else:
        for i in range(0, len(data), 2):
            data[i], data[i + 1] = data[i + 1], data[i]

    header = f"P5\n{args.width} {args.height}\n65535\n".encode("ascii")
    args.pgm.write_bytes(header + bytes(data))


if __name__ == "__main__":
    main()
