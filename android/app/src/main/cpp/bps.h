#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace hge
{

// Applies a BPS patch (https://www.romhacking.net/documents/746/) to `source`.
// All three CRC32 checksums stored in the patch are verified.
// Returns true on success; on failure `error` describes what went wrong.
bool ApplyBps(const std::vector<uint8_t>& source,
              const std::vector<uint8_t>& patch,
              std::vector<uint8_t>& target,
              std::string& error);

uint32_t Crc32(const uint8_t* data, size_t len, uint32_t crc = 0);

}
