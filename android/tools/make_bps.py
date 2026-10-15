#!/usr/bin/env python3
"""Create (or apply) a BPS patch between a clean HeartGold ROM and an hg-engine build.

    make_bps.py create rom.nds test.nds hg-engine.bps
    make_bps.py apply  rom.nds hg-engine.bps out.nds

The Android app bundles the patch instead of a ROM, so the APK contains no
Nintendo data: players pick their own ROM and the app patches it on-device.
BPS patches also work with Floating IPS, ROM Patcher JS, etc.

Requires numpy (already pulled in by hg-engine's requirements via pandas).
"""

import argparse
import sys
import time
import zlib

import numpy as np

MIN_MATCH = 24          # shortest copy worth emitting
KEY_BYTES = 8           # index key length
SOURCE_STRIDE = 4       # source positions indexed every N bytes
WINDOW = 1 << 22        # target bytes scanned per vectorised lookup


def encode_number(n, out):
    while True:
        x = n & 0x7F
        n >>= 7
        if n == 0:
            out.append(0x80 | x)
            return
        out.append(x)
        n -= 1


def encode_signed(n, out):
    encode_number((abs(n) << 1) | (1 if n < 0 else 0), out)


def match_length(a, ai, b, bi, limit):
    """Length of the common prefix of a[ai:] and b[bi:], capped at limit."""
    if ai < 0:
        return 0
    limit = min(limit, len(a) - ai, len(b) - bi)
    n = 0
    step = 64
    grow = True
    while n < limit:
        k = min(step, limit - n)
        if a[ai + n:ai + n + k] == b[bi + n:bi + n + k]:
            n += k
            if grow:
                step = min(step * 2, 1 << 20)
        else:
            if k == 1:
                break
            step = max(k // 2, 1)
            grow = False
    return n


def keys_at(data, start, count):
    """Little-endian u64 keys of data[p:p+8] for every p in [start, start+count)."""
    keys = np.empty(count, dtype=np.uint64)
    for o in range(KEY_BYTES):
        first = start + o
        n = (count - o + KEY_BYTES - 1) // KEY_BYTES
        if n <= 0:
            continue
        chunk = np.frombuffer(data, dtype='<u8', count=n, offset=first)
        keys[o::KEY_BYTES] = chunk
    return keys


def build_index(source):
    usable = len(source) - KEY_BYTES
    positions = np.arange(0, usable + 1, SOURCE_STRIDE, dtype=np.int64)
    raw = np.frombuffer(source, dtype=np.uint8)
    keys = np.zeros(len(positions), dtype=np.uint64)
    for i in range(KEY_BYTES):
        keys |= raw[positions + i].astype(np.uint64) << np.uint64(8 * i)
    order = np.argsort(keys, kind='stable')
    return keys[order], positions[order]


def create(source, target):
    out = bytearray(b'BPS1')
    encode_number(len(source), out)
    encode_number(len(target), out)
    encode_number(0, out)  # no metadata

    sorted_keys, sorted_pos = build_index(source)

    literal_start = 0
    t = 0
    source_rel = 0
    last_delta = 0
    n = len(target)

    def flush_literal(end):
        nonlocal literal_start
        if end > literal_start:
            encode_number(((end - literal_start - 1) << 2) | 1, out)
            out.extend(target[literal_start:end])
        literal_start = end

    window_start = -1
    candidates = None
    has_candidate = None

    while t < n:
        if t + KEY_BYTES > n:
            break

        if not (window_start <= t < window_start + len(has_candidate if has_candidate is not None else ())):
            window_start = t
            count = min(WINDOW, n - KEY_BYTES + 1 - t)
            keys = keys_at(target, t, count)
            idx = np.searchsorted(sorted_keys, keys)
            np.minimum(idx, len(sorted_keys) - 1, out=idx)
            has_candidate = sorted_keys[idx] == keys
            candidates = sorted_pos[idx]

        rel = t - window_start
        if not has_candidate[rel]:
            # Skip ahead to the next position that has an index hit.
            hits = np.flatnonzero(has_candidate[rel:])
            if len(hits) == 0:
                t = window_start + len(has_candidate)
                continue
            t += int(hits[0])
            rel = t - window_start

        best_len, best_src = 0, 0
        for src in (t, t + last_delta, int(candidates[rel])):
            length = match_length(source, src, target, t, n - t)
            if length > best_len:
                best_len, best_src = length, src

        if best_len < MIN_MATCH:
            t += 1
            continue

        # Grow the match backwards into the pending literal.
        back = 0
        while (t - back > literal_start and best_src - back > 0
               and source[best_src - back - 1] == target[t - back - 1]):
            back += 1
        t -= back
        best_src -= back
        best_len += back

        flush_literal(t)
        if best_src == t:
            encode_number((best_len - 1) << 2, out)
        else:
            encode_number(((best_len - 1) << 2) | 2, out)
            encode_signed(best_src - source_rel, out)
            source_rel = best_src + best_len
        last_delta = best_src - t
        t += best_len
        literal_start = t

    flush_literal(n)

    out += zlib.crc32(source).to_bytes(4, 'little')
    out += zlib.crc32(target).to_bytes(4, 'little')
    out += zlib.crc32(out).to_bytes(4, 'little')
    return bytes(out)


def decode_number(data, pos):
    value, shift = 0, 1
    while True:
        b = data[pos]
        pos += 1
        value += (b & 0x7F) * shift
        if b & 0x80:
            return value, pos
        shift <<= 7
        value += shift


def apply(source, patch):
    if patch[:4] != b'BPS1':
        raise ValueError('not a BPS patch')
    if zlib.crc32(patch[:-4]) != int.from_bytes(patch[-4:], 'little'):
        raise ValueError('patch checksum mismatch')
    if zlib.crc32(source) != int.from_bytes(patch[-12:-8], 'little'):
        raise ValueError('source ROM does not match the patch')
    pos = 4
    source_size, pos = decode_number(patch, pos)
    target_size, pos = decode_number(patch, pos)
    meta, pos = decode_number(patch, pos)
    pos += meta
    if source_size != len(source):
        raise ValueError('source size mismatch')

    target = bytearray(target_size)
    out = source_rel = target_rel = 0
    end = len(patch) - 12
    while pos < end:
        cmd, pos = decode_number(patch, pos)
        length = (cmd >> 2) + 1
        action = cmd & 3
        if action == 0:
            target[out:out + length] = source[out:out + length]
        elif action == 1:
            target[out:out + length] = patch[pos:pos + length]
            pos += length
        else:
            delta, pos = decode_number(patch, pos)
            delta = -(delta >> 1) if delta & 1 else delta >> 1
            if action == 2:
                source_rel += delta
                target[out:out + length] = source[source_rel:source_rel + length]
                source_rel += length
            else:
                target_rel += delta
                for i in range(length):
                    target[out + i] = target[target_rel + i]
                target_rel += length
        out += length

    if zlib.crc32(target) != int.from_bytes(patch[-8:-4], 'little'):
        raise ValueError('patched output checksum mismatch')
    return bytes(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='command', required=True)
    c = sub.add_parser('create', help='create a patch')
    c.add_argument('source')
    c.add_argument('target')
    c.add_argument('patch')
    a = sub.add_parser('apply', help='apply a patch')
    a.add_argument('source')
    a.add_argument('patch')
    a.add_argument('output')
    args = parser.parse_args()

    if args.command == 'create':
        source = open(args.source, 'rb').read()
        target = open(args.target, 'rb').read()
        start = time.time()
        patch = create(source, target)
        if apply(source, patch) != target:
            sys.exit('internal error: patch does not reproduce the target')
        with open(args.patch, 'wb') as f:
            f.write(patch)
        print(f'wrote {args.patch}: {len(patch):,} bytes ({time.time() - start:.1f}s)')
    else:
        source = open(args.source, 'rb').read()
        patch = open(args.patch, 'rb').read()
        with open(args.output, 'wb') as f:
            f.write(apply(source, patch))
        print(f'wrote {args.output}')


if __name__ == '__main__':
    main()
