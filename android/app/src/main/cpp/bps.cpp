#include "bps.h"

#include <algorithm>
#include <array>

namespace hge
{

static const std::array<uint32_t, 256>& CrcTable()
{
    static const std::array<uint32_t, 256> table = []
    {
        std::array<uint32_t, 256> t{};
        for (uint32_t i = 0; i < 256; i++)
        {
            uint32_t c = i;
            for (int k = 0; k < 8; k++)
                c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
            t[i] = c;
        }
        return t;
    }();
    return table;
}

uint32_t Crc32(const uint8_t* data, size_t len, uint32_t crc)
{
    const auto& table = CrcTable();
    crc = ~crc;
    for (size_t i = 0; i < len; i++)
        crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >> 8);
    return ~crc;
}

namespace
{

struct Reader
{
    const std::vector<uint8_t>& data;
    size_t pos = 0;
    size_t end;

    bool ReadByte(uint8_t& out)
    {
        if (pos >= end)
            return false;
        out = data[pos++];
        return true;
    }

    bool ReadNumber(uint64_t& out)
    {
        uint64_t value = 0, shift = 1;
        for (int i = 0; i < 10; i++)
        {
            uint8_t b;
            if (!ReadByte(b))
                return false;
            value += (b & 0x7F) * shift;
            if (b & 0x80)
            {
                out = value;
                return true;
            }
            shift <<= 7;
            value += shift;
        }
        return false;
    }

    bool ReadSigned(int64_t& out)
    {
        uint64_t n;
        if (!ReadNumber(n))
            return false;
        out = static_cast<int64_t>(n >> 1);
        if (n & 1)
            out = -out;
        return true;
    }
};

uint32_t ReadLE32(const std::vector<uint8_t>& data, size_t pos)
{
    return data[pos] | (data[pos + 1] << 8) | (data[pos + 2] << 16) | (static_cast<uint32_t>(data[pos + 3]) << 24);
}

}

bool ApplyBps(const std::vector<uint8_t>& source,
              const std::vector<uint8_t>& patch,
              std::vector<uint8_t>& target,
              std::string& error)
{
    if (patch.size() < 4 + 12 || patch[0] != 'B' || patch[1] != 'P' || patch[2] != 'S' || patch[3] != '1')
    {
        error = "Not a BPS patch.";
        return false;
    }

    const size_t footer = patch.size() - 12;
    const uint32_t sourceCrc = ReadLE32(patch, footer);
    const uint32_t targetCrc = ReadLE32(patch, footer + 4);
    const uint32_t patchCrc = ReadLE32(patch, footer + 8);

    if (Crc32(patch.data(), patch.size() - 4) != patchCrc)
    {
        error = "The patch file is corrupt (checksum mismatch).";
        return false;
    }

    Reader r{patch, 4, footer};
    uint64_t sourceSize, targetSize, metadataSize;
    if (!r.ReadNumber(sourceSize) || !r.ReadNumber(targetSize) || !r.ReadNumber(metadataSize))
    {
        error = "Malformed BPS header.";
        return false;
    }
    if (metadataSize > footer - r.pos)
    {
        error = "Malformed BPS metadata.";
        return false;
    }
    r.pos += metadataSize;

    if (source.size() != sourceSize || Crc32(source.data(), source.size()) != sourceCrc)
    {
        error = "This ROM doesn't match the one the patch was made for. "
                "Use a clean English (USA) Pokémon HeartGold ROM.";
        return false;
    }
    if (targetSize > (1ull << 31))
    {
        error = "Patched ROM would be too large.";
        return false;
    }

    target.assign(targetSize, 0);
    size_t out = 0;
    int64_t sourceRel = 0, targetRel = 0;

    while (r.pos < footer)
    {
        uint64_t cmd;
        if (!r.ReadNumber(cmd))
            break;
        const uint64_t length = (cmd >> 2) + 1;
        if (length > targetSize - out)
        {
            error = "Patch writes past the end of the ROM.";
            return false;
        }

        switch (cmd & 3)
        {
        case 0: // SourceRead
            if (out + length > source.size())
            {
                error = "Patch reads past the end of the source ROM.";
                return false;
            }
            std::copy_n(source.begin() + out, length, target.begin() + out);
            out += length;
            break;

        case 1: // TargetRead
            if (length > footer - r.pos)
            {
                error = "Truncated patch data.";
                return false;
            }
            std::copy_n(patch.begin() + r.pos, length, target.begin() + out);
            r.pos += length;
            out += length;
            break;

        case 2: // SourceCopy
        {
            int64_t delta;
            if (!r.ReadSigned(delta))
            {
                error = "Truncated patch data.";
                return false;
            }
            sourceRel += delta;
            if (sourceRel < 0 || static_cast<uint64_t>(sourceRel) + length > source.size())
            {
                error = "Patch copies from outside the source ROM.";
                return false;
            }
            std::copy_n(source.begin() + sourceRel, length, target.begin() + out);
            sourceRel += length;
            out += length;
            break;
        }

        case 3: // TargetCopy (may overlap, so copy byte by byte)
        {
            int64_t delta;
            if (!r.ReadSigned(delta))
            {
                error = "Truncated patch data.";
                return false;
            }
            targetRel += delta;
            if (targetRel < 0 || static_cast<uint64_t>(targetRel) >= out)
            {
                error = "Patch copies from outside the written ROM.";
                return false;
            }
            for (uint64_t i = 0; i < length; i++)
                target[out++] = target[targetRel++];
            break;
        }
        }
    }

    if (out != targetSize || r.pos != footer)
    {
        error = "Patch ended unexpectedly.";
        return false;
    }
    if (Crc32(target.data(), target.size()) != targetCrc)
    {
        error = "Patched ROM failed verification.";
        return false;
    }
    return true;
}

}
