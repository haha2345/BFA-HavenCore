#ifndef MECHAGON_SQUIRT_LIFECYCLE_H
#define MECHAGON_SQUIRT_LIFECYCLE_H

#include <cstdint>
#include <optional>
#include <string>

// Map 2097 static rows only. Not a retail path.
static std::uint64_t const SQUIRT_SPAWN_154741 = 3300000000000910ULL;
static std::uint64_t const SQUIRT_SPAWN_154746 = 3300000000000912ULL;
static std::uint64_t const SQUIRT_SPAWN_154759 = 3300000000000911ULL;
static std::uint32_t const SQUIRT_MAP_ID = 2097;
// Toxic monstrosities. Pair entry with this spawn only.
static std::uint32_t const SQUIRT_ENTRY_150168 = 150168u;
static std::uint64_t const SQUIRT_SPAWN_150168 = 3300000000000722ULL;
static std::uint32_t const SQUIRT_ENTRY_154744 = 154744u;
static std::uint64_t const SQUIRT_SPAWN_154744 = 3300000000000456ULL;
static std::uint32_t const SQUIRT_ENTRY_154758 = 154758u;
static std::uint64_t const SQUIRT_SPAWN_154758 = 3300000000000719ULL;
static std::uint32_t const SQUIRT_POLL_MS = 200;
static std::uint32_t const SQUIRT_FAIL_THROTTLE_MS = 2000;
// Spray presence and pause cleanup. 297821 is goop, not spray.
static std::uint32_t const SQUIRT_SPRAY_SPELLS[] = { 297901u, 298145u, 298216u };
static std::uint32_t const SQUIRT_END_SPELLS[] = { 297821u, 298124u, 298259u };

inline bool SquirtIsSpraySpell(std::uint32_t spellId)
{
    for (std::uint32_t id : SQUIRT_SPRAY_SPELLS)
        if (id == spellId)
            return true;
    return false;
}

inline bool SquirtIsEndSpell(std::uint32_t spellId)
{
    for (std::uint32_t id : SQUIRT_END_SPELLS)
        if (id == spellId)
            return true;
    return false;
}

enum SquirtBossState : std::uint8_t
{
    SQUIRT_NOT_STARTED = 0,
    SQUIRT_IN_PROGRESS = 1,
    SQUIRT_FAIL = 2,
    SQUIRT_DONE = 3
};

enum SquirtAction : std::uint8_t
{
    SQUIRT_ACT_NONE = 0,
    SQUIRT_ACT_BEGIN = 1,
    SQUIRT_ACT_PAUSE = 2,
    SQUIRT_ACT_END = 4
};

inline bool GunkerDoneIsTerminal(std::uint8_t state)
{
    return state == SQUIRT_DONE;
}

// No instance or DONE rejects. IN_PROGRESS keeps the hit. Any other state allows only mask 7.
inline bool GunkerAllowsDamage(bool hasInstance, SquirtBossState bossState, std::uint32_t releaseMask)
{
    if (!hasInstance || bossState == SQUIRT_DONE)
        return false;
    if (bossState == SQUIRT_IN_PROGRESS)
        return true;
    return releaseMask == 7u;
}

inline bool SquirtIsOwnedStatic(std::uint32_t mapId, std::uint32_t entry, std::uint64_t spawnId)
{
    if (mapId != SQUIRT_MAP_ID || spawnId == 0)
        return false;
    if (spawnId == SQUIRT_SPAWN_154741)
        return entry == 154741;
    if (spawnId == SQUIRT_SPAWN_154746)
        return entry == 154746;
    if (spawnId == SQUIRT_SPAWN_154759)
        return entry == 154759;
    return false;
}

// 0, 1, and 2 are hits. nullopt is a miss, so bit 0 stays a real result.
inline std::optional<std::uint8_t> MonstrosityBit(std::uint32_t mapId, std::uint32_t entry, std::uint64_t spawnId)
{
    if (mapId != SQUIRT_MAP_ID)
        return std::nullopt;
    if (entry == SQUIRT_ENTRY_150168 && spawnId == SQUIRT_SPAWN_150168)
        return std::uint8_t{ 0 };
    if (entry == SQUIRT_ENTRY_154744 && spawnId == SQUIRT_SPAWN_154744)
        return std::uint8_t{ 1 };
    if (entry == SQUIRT_ENTRY_154758 && spawnId == SQUIRT_SPAWN_154758)
        return std::uint8_t{ 2 };
    return std::nullopt;
}

// Whole text is one digit 0..7 with whitespace around it. No integer extract, no wrap into 0..7.
enum class SquirtMaskTokenKind : std::uint8_t
{
    Absent = 0,
    Accepted = 1,
    Rejected = 2
};

struct SquirtMaskToken
{
    SquirtMaskTokenKind kind = SquirtMaskTokenKind::Rejected;
    std::uint8_t value = 0;
};

inline bool SquirtMaskCharIsSpace(char c)
{
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' || c == '\f';
}

inline SquirtMaskToken ClassifySquirtMaskToken(std::string const& text)
{
    std::size_t index = 0;
    while (index < text.size() && SquirtMaskCharIsSpace(text[index]))
        ++index;
    if (index == text.size())
        return SquirtMaskToken{ SquirtMaskTokenKind::Absent, 0 };

    char const digit = text[index];
    if (digit < '0' || digit > '7')
        return SquirtMaskToken{ SquirtMaskTokenKind::Rejected, 0 };

    ++index;
    while (index < text.size())
    {
        if (!SquirtMaskCharIsSpace(text[index]))
            return SquirtMaskToken{ SquirtMaskTokenKind::Rejected, 0 };
        ++index;
    }
    return SquirtMaskToken{ SquirtMaskTokenKind::Accepted, static_cast<std::uint8_t>(digit - '0') };
}

// Non-zero respawn time sets bit 0, 1, or 2. Zero does not. No boss-state argument.
inline std::uint8_t MaskFromRespawnTimes(std::int64_t t0, std::int64_t t1, std::int64_t t2)
{
    std::uint8_t mask = 0;
    if (t0 != 0)
        mask |= 1u;
    if (t1 != 0)
        mask |= 2u;
    if (t2 != 0)
        mask |= 4u;
    return mask;
}

struct SquirtReleaseBot
{
    std::uint32_t entry;
    std::uint64_t spawnId;
};

inline std::optional<SquirtReleaseBot> SquirtReleaseBotForBit(std::uint8_t bit)
{
    switch (bit)
    {
        case 0:
            return SquirtReleaseBot{ 154746u, SQUIRT_SPAWN_154746 };
        case 1:
            return SquirtReleaseBot{ 154741u, SQUIRT_SPAWN_154741 };
        case 2:
            return SquirtReleaseBot{ 154759u, SQUIRT_SPAWN_154759 };
        default:
            return std::nullopt;
    }
}

// 154746 already stands on the old pos1. The other two use the old script stations.
inline bool SquirtUsesTemporaryStation(std::uint32_t mapId, std::uint32_t entry, std::uint64_t spawnId)
{
    if (!SquirtIsOwnedStatic(mapId, entry, spawnId))
        return false;
    return spawnId != SQUIRT_SPAWN_154746;
}

struct SquirtLifecycle
{
    bool running = false;
    bool frame = false;
    bool active = false;
    bool gooped = false;
    std::uint32_t pollMs = 0;
    std::uint32_t failThrottleMs = 0;

    bool NeedsEnd() const
    {
        return running || frame || active || gooped;
    }

    // Caller must Apply END before OnEnd. Flags are still intact here.
    std::uint8_t Sync(std::uint8_t bossState, bool goopAura, bool alive)
    {
        if (!alive || bossState != SQUIRT_IN_PROGRESS)
            return NeedsEnd() ? SQUIRT_ACT_END : SQUIRT_ACT_NONE;

        std::uint8_t action = SQUIRT_ACT_NONE;
        if (!running)
            action |= SQUIRT_ACT_BEGIN;
        if (goopAura && !gooped)
            action |= SQUIRT_ACT_PAUSE;
        else if (!goopAura && gooped)
        {
            pollMs = 0;
            failThrottleMs = 0;
        }
        gooped = goopAura;
        return action;
    }

    void OnBegin()
    {
        running = true;
        frame = true;
        active = true;
        gooped = false;
        pollMs = 0;
        failThrottleMs = 0;
    }

    void OnPause()
    {
        gooped = true;
    }

    void OnEnd()
    {
        running = false;
        frame = false;
        active = false;
        gooped = false;
        pollMs = 0;
        failThrottleMs = 0;
    }

    bool WantCast(std::uint32_t diff, bool sprayPresent)
    {
        if (!running)
            return false;

        if (failThrottleMs <= diff)
            failThrottleMs = 0;
        else
            failThrottleMs -= diff;

        if (gooped)
            return false;
        if (sprayPresent)
        {
            pollMs = SQUIRT_POLL_MS;
            return false;
        }
        if (pollMs > diff)
        {
            pollMs -= diff;
            return false;
        }
        pollMs = SQUIRT_POLL_MS;
        return failThrottleMs == 0;
    }

    void NoteCast(bool ok)
    {
        if (!ok)
            failThrottleMs = SQUIRT_FAIL_THROTTLE_MS;
    }
};

#endif
