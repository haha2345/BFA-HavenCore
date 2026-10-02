#include "AreaTrigger.h"
#include "AreaTriggerAI.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "SpellAuras.h"
#include "SpellAuraEffects.h"
#include "TemporarySummon.h"
#include "operation_mechagon.h"
#include "squirt_lifecycle.h"
#include "Log.h"
#include "DB2Stores.h"
#include "InstanceScript.h"
#include "Map.h"
#include "MapManager.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "Timer.h"
#include <atomic>
#include <functional>
#include <limits>
#include <map>
#include <memory>
#include <set>
#include <vector>

enum Spells
{
    SPELL_PERIODIC_ENERGY_GAIN = 295065,
    SPELL_GUNKER_VISUAL = 300859,
    SPELL_GOOPED_CREATE_AURA_AT = 297821,
    SPELL_GOOPED_INCAPCITATED = 298124,
    SPELL_GOOPED_MAIN = 298259,
    SPELL_GOOPED_SUMMON = 298125,
    SPELL_TOXIC_FLAMES_TRIGGER = 298228,
    SPELL_SPLATTER_TRIGGER = 297985,
    SPELL_COALESCE = 297835,
    SPELL_SLUDGE_BOLT = 298212,
    SPELL_TOXIC_WAVE = 297834,
    SPELL_SANITIZING_SPRAY = 297901,
    SPELL_SANITIZING_AURA = 298145,
    SPELL_SANITIZING_SPRAY2 = 298216,
};

enum GunkerCreatures
{
    NPC_GUNKER_GOOP = 153377,
};

enum Events
{
    EVENT_COALESCE = 1,
    EVENT_GOOPED,
    EVENT_SLUDGE_BOLT,
    EVENT_SPLATTER,
    EVENT_TOXIC_WAVE,
    EVENT_TOXIC_FLAMES
};

namespace
{
    // Player lifecycle state has one home; instance hooks only forward into this registry.
    char const PlayerGoopRegistryKey[] = "Gunker.PlayerGoop.Registry";
    uint32 constexpr PlayerGoopMapId = 2097;
    uint32 constexpr PlayerGoopPropertiesId = 64;

    struct GunkerPlayerGoopRegistry;
    struct GunkerPlayerGoopLink;
    using PlayerGoopRegistryPtr = std::shared_ptr<GunkerPlayerGoopRegistry>;
    using PlayerGoopLinkPtr = std::shared_ptr<GunkerPlayerGoopLink>;

    enum class PlayerGoopSourceState { Live, Reapplying, Removed, Unknown };
    enum class PlayerGoopLifeState { Alive, Dead, Lost };
    enum class PlayerGoopCleanupState { None, Pending, Complete };
    enum class PlayerGoopCloseReason
    {
        None, SourceRemoved, SourceUnloaded, PlayerLeaving, PlayerDied,
        EncounterReset, RegistryDestroyed, Rescued, MissingContext, ContractFailed
    };

    struct PlayerGoopExecution
    {
        uint64 reservation = 0;
        ObjectGuid castGuid;
        bool reserved = false;
        bool prepareSeen = false;
        bool started = false;
        bool consumed = false;
        bool finished = false;
        bool planKnown = false;
        uint32 plannedCount = 0;
        uint32 successfulCommits = 0; // Cumulative, never derived from the remaining index.
        bool prepareFailed = false;
        bool creationFailed = false;
        bool associationFailed = false;
    };

    struct PlayerGoopRecord
    {
        ObjectGuid guid;
        ObjectGuid summonerGuid;
        uint64 execution = 0;
        PlayerGoopLifeState life = PlayerGoopLifeState::Alive;
        PlayerGoopCleanupState cleanup = PlayerGoopCleanupState::None;
        bool committed = false;
        bool pendingDeath = false;
    };

    struct PlayerGoopCleanupSnapshot
    {
        bool first = false;
        PlayerGoopSourceState sourceState = PlayerGoopSourceState::Unknown;
        PlayerGoopExecution execution;
        std::vector<PlayerGoopRecord> goops;
    };

    struct GunkerPlayerGoopLink
    {
        std::weak_ptr<GunkerPlayerGoopRegistry> registry;
        uint64 lifetime = 0;
        uint32 mapId = PlayerGoopMapId;
        uint32 instanceId = 0;
        uint64 epoch = 0;
        uint64 sequence = 0;
        ObjectGuid playerGuid;
        uint32 sourceSpell = SPELL_GOOPED_MAIN;
        SpellEffIndex sourceEffect = EFFECT_2;
        ObjectGuid sourceCasterGuid;
        ObjectGuid sourceCastGuid;
        PlayerGoopSourceState sourceState = PlayerGoopSourceState::Live;
        bool creationAllowed = true;
        bool terminal = false;
        PlayerGoopCloseReason closeReason = PlayerGoopCloseReason::None;
        bool rescuePending = false;
        uint32 rescueReapplyDepth = 0; // Only defers rescue until the matching refresh Apply halves close.
        PlayerGoopExecution execution;
        // Bound by execution.plannedCount, including unresolved returns; no world pointers.
        std::map<ObjectGuid, PlayerGoopRecord> goops;

        ~GunkerPlayerGoopLink()
        {
            terminal = true;
            creationAllowed = false;
            sourceState = PlayerGoopSourceState::Removed;
        }
    };

    struct PlayerGoopReverseIndex
    {
        std::weak_ptr<GunkerPlayerGoopLink> link;
        uint64 execution = 0;
    };

    PlayerGoopRegistryPtr GetPlayerGoopRegistry(InstanceScript*, bool create);
    bool IsRegisteredPlayerGoopLink(PlayerGoopRegistryPtr const&, PlayerGoopLinkPtr const&);
    bool IsCurrentPlayerGoopLink(PlayerGoopRegistryPtr const&, PlayerGoopLinkPtr const&);
    bool ValidatePlayerGoopDataContract(uint32 difficulty);
    bool CheckPlayerGoopLoadedContract(InstanceScript*);
    Aura* FindLivePlayerGoopSource(PlayerGoopLinkPtr const&, Map*);
    PlayerGoopCleanupSnapshot EndPlayerGoopLink(PlayerGoopLinkPtr, PlayerGoopCloseReason);
    void CleanupConcreteGoops(PlayerGoopLinkPtr const&, PlayerGoopCleanupSnapshot const&, Map*,
        char const* contextFailure = nullptr);
    void ClosePlayerGoopSource(PlayerGoopLinkPtr, Map*, PlayerGoopCloseReason);
    void LogPlayerGoopTransition(GunkerPlayerGoopRegistry*, GunkerPlayerGoopLink const&,
        char const* event, bool summary, ObjectGuid goop = ObjectGuid::Empty,
        ObjectGuid summoner = ObjectGuid::Empty, uint32 effect = EFFECT_2, uint32 mode = 0,
        bool error = false, char const* failureReason = "none", int32 world = -1, int32 dead = -1);
    void LogPlayerGoopTransition(GunkerPlayerGoopRegistry& registry, GunkerPlayerGoopLink const& link,
        char const* event, bool summary, ObjectGuid goop = ObjectGuid::Empty,
        ObjectGuid summoner = ObjectGuid::Empty, uint32 effect = EFFECT_2, uint32 mode = 0)
    {
        LogPlayerGoopTransition(&registry, link, event, summary, goop, summoner, effect, mode);
    }

    struct GunkerPlayerGoopRegistry : std::enable_shared_from_this<GunkerPlayerGoopRegistry>
    {
        GunkerPlayerGoopRegistry(uint64 life, uint32 instance) : lifetime(life), instanceId(instance) { }

        uint64 const lifetime;
        uint32 const mapId = PlayerGoopMapId;
        uint32 const instanceId;
        uint64 epoch = 1;
        uint64 linkSequence = 0;
        uint64 executionSequence = 0;
        uint64 causalSequence = 0;
        bool frozen = false;
        bool exhausted = false;
        std::map<uint64, PlayerGoopLinkPtr> links;
        std::map<ObjectGuid, std::set<uint64>> players;
        std::map<ObjectGuid, PlayerGoopReverseIndex> goops;

        bool Advance(uint64& counter, uint64& result, char const* kind)
        {
            if (counter == std::numeric_limits<uint64>::max())
            {
                frozen = true;
                exhausted = true;
                TC_LOG_ERROR("scripts", "GunkerPlayerGoop contract map %u instance %u life " UI64FMTD
                    " epoch " UI64FMTD " tick %u reason %s-overflow", mapId, instanceId, lifetime, epoch, getMSTime(), kind);
                return false;
            }
            result = ++counter;
            return true;
        }

        bool AdvanceResetEpoch()
        {
            // The reset caller freezes first and retains every first cleanup snapshot.
            uint64 next = 0;
            return Advance(epoch, next, "epoch");
        }

        PlayerGoopLinkPtr CreateLink(ObjectGuid player, ObjectGuid caster, ObjectGuid cast)
        {
            uint64 sequence = 0;
            if (frozen || exhausted || player.IsEmpty() || !Advance(linkSequence, sequence, "link"))
                return nullptr;
            auto link = std::make_shared<GunkerPlayerGoopLink>();
            link->registry = shared_from_this();
            link->lifetime = lifetime;
            link->instanceId = instanceId;
            link->epoch = epoch;
            link->sequence = sequence;
            link->playerGuid = player;
            link->sourceCasterGuid = caster;
            link->sourceCastGuid = cast;
            links.emplace(sequence, link);
            players[player].insert(sequence);
            LogPlayerGoopTransition(*this, *link, "begin", true);
            return link;
        }

        bool ReserveExecution(PlayerGoopLinkPtr const& link, ObjectGuid cast)
        {
            if (frozen || exhausted || !IsCurrentPlayerGoopLink(shared_from_this(), link)
                || link->terminal || !link->creationAllowed || link->execution.reserved || cast.IsEmpty())
                return false;
            uint64 sequence = 0;
            if (!Advance(executionSequence, sequence, "execution"))
                return false;
            link->execution.reservation = sequence;
            link->execution.castGuid = cast;
            link->execution.reserved = true;
            LogPlayerGoopTransition(*this, *link, "reserve", false);
            return true;
        }

        bool IndexGoop(PlayerGoopLinkPtr const& link, PlayerGoopRecord const& record)
        {
            // Task1 must validate the concrete return and AI binding before publishing.
            if (frozen || exhausted || !IsCurrentPlayerGoopLink(shared_from_this(), link)
                || link->terminal || !link->creationAllowed || !link->execution.reserved
                || !link->execution.planKnown || !record.committed || record.guid.IsEmpty()
                || record.summonerGuid != link->playerGuid || record.execution != link->execution.reservation
                || link->goops.size() >= link->execution.plannedCount
                || link->execution.successfulCommits >= link->execution.plannedCount
                || goops.count(record.guid) || link->goops.count(record.guid))
                return false;
            link->goops.emplace(record.guid, record);
            goops.emplace(record.guid, PlayerGoopReverseIndex{ link, record.execution });
            ++link->execution.successfulCommits;
            LogPlayerGoopTransition(*this, *link, "commit", false, record.guid, record.summonerGuid, EFFECT_0);
            return true;
        }

        PlayerGoopCleanupSnapshot TerminalLink(PlayerGoopLinkPtr link, PlayerGoopCloseReason reason)
        {
            PlayerGoopCleanupSnapshot snapshot;
            // Hold a strong value through erasure, including callers using links' own value.
            // Reset may already have advanced epoch; old registered links still need revocation.
            if (!link || link->terminal)
                return snapshot;
            // Data-only revocation, before any future caller accesses the world.
            link->terminal = true;
            link->creationAllowed = false;
            // Terminal does not prove Aura removal; Close may still need to find that live source.
            link->closeReason = reason;
            snapshot.first = true;
            snapshot.sourceState = link->sourceState;
            snapshot.execution = link->execution;
            for (auto const& pair : link->goops)
            {
                PlayerGoopRecord const& record = pair.second;
                snapshot.goops.push_back(record);
                auto reverse = goops.find(pair.first);
                if (reverse != goops.end() && reverse->second.link.lock() == link
                    && reverse->second.execution == record.execution)
                    goops.erase(reverse);
            }
            auto registered = links.find(link->sequence);
            if (registered != links.end() && registered->second == link)
            {
                auto player = players.find(link->playerGuid);
                if (player != players.end())
                {
                    player->second.erase(link->sequence);
                    if (player->second.empty())
                        players.erase(player);
                }
                links.erase(registered); // External Aura/Spell tokens retain their own strong reference.
            }
            LogPlayerGoopTransition(*this, *link, "terminal", true);
            return snapshot; // Not proof of world cleanup. Records remain on the held link.
        }

        ~GunkerPlayerGoopRegistry()
        {
            frozen = true;
            for (auto const& pair : links)
            {
                GunkerPlayerGoopLink& link = *pair.second;
                link.terminal = true;
                link.creationAllowed = false;
                link.sourceState = PlayerGoopSourceState::Unknown;
                link.closeReason = PlayerGoopCloseReason::RegistryDestroyed;
                LogPlayerGoopTransition(*this, link, "terminal", true);
                for (auto& goop : link.goops)
                    if (goop.second.cleanup != PlayerGoopCleanupState::Complete)
                    {
                        TC_LOG_ERROR("scripts", "GunkerPlayerGoop cleanup map %u instance %u life " UI64FMTD
                            " epoch " UI64FMTD " cause_seq " UI64FMTD " tick %u player %s link " UI64FMTD
                            " caster %s cast %s spellcast %s exec " UI64FMTD " G %s rawsummoner %s"
                            " reason registry-destroyed-unresolved",
                            mapId, instanceId, lifetime, link.epoch, causalSequence, getMSTime(), link.playerGuid.ToString().c_str(),
                            link.sequence, link.sourceCasterGuid.ToString().c_str(), link.sourceCastGuid.ToString().c_str(),
                            link.execution.castGuid.ToString().c_str(), goop.second.execution,
                            goop.first.ToString().c_str(), goop.second.summonerGuid.ToString().c_str());
                    }
            }
            goops.clear();
            players.clear();
            links.clear(); // Destruction never resolves GUIDs or calls world objects.
        }
    };

    bool IsRegisteredPlayerGoopLink(PlayerGoopRegistryPtr const& registry, PlayerGoopLinkPtr const& link)
    {
        if (!registry || !link || link->registry.lock() != registry || link->lifetime != registry->lifetime
            || link->mapId != registry->mapId || link->instanceId != registry->instanceId)
            return false;
        auto const current = registry->links.find(link->sequence);
        return current != registry->links.end() && current->second == link;
    }

    PlayerGoopCleanupSnapshot EndPlayerGoopLink(PlayerGoopLinkPtr link, PlayerGoopCloseReason reason)
    {
        if (!link || link->terminal)
            return {};
        if (auto registry = link->registry.lock())
            return registry->TerminalLink(link, reason);
        // Missing world/registry context cannot leave a still-live Spell creation permit behind.
        link->terminal = true;
        link->creationAllowed = false;
        link->closeReason = reason;
        PlayerGoopCleanupSnapshot snapshot;
        snapshot.first = true;
        snapshot.sourceState = link->sourceState;
        snapshot.execution = link->execution;
        for (auto const& pair : link->goops)
            snapshot.goops.push_back(pair.second);
        LogPlayerGoopTransition(nullptr, *link, "terminal", true);
        return snapshot;
    }

    bool IsCurrentPlayerGoopLink(PlayerGoopRegistryPtr const& registry, PlayerGoopLinkPtr const& link)
    {
        return IsRegisteredPlayerGoopLink(registry, link) && link->epoch == registry->epoch;
    }

    PlayerGoopRegistryPtr GetPlayerGoopRegistry(InstanceScript* instance, bool create)
    {
        if (!instance || !instance->instance || instance->instance->GetId() != PlayerGoopMapId)
            return nullptr;
        if (instance->Variables.Exist(PlayerGoopRegistryKey))
        {
            auto registry = instance->Variables.GetValue<PlayerGoopRegistryPtr>(PlayerGoopRegistryKey);
            return registry && registry->mapId == instance->instance->GetId()
                && registry->instanceId == instance->instance->GetInstanceId() ? registry : nullptr;
        }
        if (!create)
            return nullptr;
        // Diagnostic identity only, never a global relationship table. Saturate without fetch_add wrap.
        static std::atomic<uint64> lifetimeSequence{ 0 };
        uint64 current = lifetimeSequence.load(std::memory_order_relaxed);
        do
        {
            if (current == std::numeric_limits<uint64>::max())
            {
                TC_LOG_ERROR("scripts", "GunkerPlayerGoop contract map %u instance %u tick %u reason lifetime-overflow",
                    PlayerGoopMapId, instance->instance->GetInstanceId(), getMSTime());
                return nullptr;
            }
        } while (!lifetimeSequence.compare_exchange_weak(current, current + 1, std::memory_order_relaxed));
        auto registry = std::make_shared<GunkerPlayerGoopRegistry>(current + 1, instance->instance->GetInstanceId());
        instance->Variables.Set<PlayerGoopRegistryPtr>(PlayerGoopRegistryKey, registry);
        return registry;
    }

    void LogPlayerGoopTransition(GunkerPlayerGoopRegistry* registry, GunkerPlayerGoopLink const& link,
        char const* event, bool summary, ObjectGuid goop, ObjectGuid summoner, uint32 effect, uint32 mode,
        bool error, char const* failureReason, int32 world, int32 dead)
    {
        uint64 causal = 0;
        if (registry && !registry->Advance(registry->causalSequence, causal, "causal"))
            return;
        // A missing registry has no allocatable causal sequence; retain the saved link identity.
        std::string const message = Trinity::StringFormat(
            "GunkerPlayerGoop %s map %u instance %u life " UI64FMTD " epoch " UI64FMTD
            " seq " UI64FMTD " tick %u player %s link " UI64FMTD " source %u caster %s cast %s"
            " spellcast %s exec " UI64FMTD " effect %u mode %u G %s rawsummoner %s plan %u success %u"
            " prepareFailed %u creationFailed %u associationFailed %u finished %u reason %u"
            " failureReason %s reserved %u prepareSeen %u started %u consumed %u world %d dead %d registry %u",
            event, registry ? registry->mapId : link.mapId, registry ? registry->instanceId : link.instanceId,
            registry ? registry->lifetime : link.lifetime, link.epoch, causal, getMSTime(),
            link.playerGuid.ToString().c_str(), link.sequence, link.sourceSpell, link.sourceCasterGuid.ToString().c_str(),
            link.sourceCastGuid.ToString().c_str(), link.execution.castGuid.ToString().c_str(), link.execution.reservation,
            effect, mode, goop.ToString().c_str(), summoner.ToString().c_str(), link.execution.plannedCount,
            link.execution.successfulCommits, uint32(link.execution.prepareFailed), uint32(link.execution.creationFailed),
            uint32(link.execution.associationFailed), uint32(link.execution.finished), uint32(link.closeReason), failureReason,
            uint32(link.execution.reserved), uint32(link.execution.prepareSeen), uint32(link.execution.started),
            uint32(link.execution.consumed), world, dead, uint32(registry != nullptr));
        if (error)
            TC_LOG_ERROR("scripts", "%s", message.c_str());
        else if (summary)
            TC_LOG_INFO("scripts", "%s", message.c_str());
        else
            TC_LOG_DEBUG("scripts", "%s", message.c_str());
    }

    bool ValidatePlayerGoopDataContract(uint32 difficulty)
    {
        // Data only: ObjectMgr marks each script enabled AFTER Validate returns.
        auto const fail = [difficulty](char const* reason)
        {
            TC_LOG_ERROR("scripts", "GunkerPlayerGoop contract difficulty %u tick %u reason %s", difficulty, getMSTime(), reason);
            return false;
        };
        if (difficulty != DIFFICULTY_NONE && difficulty != DIFFICULTY_HEROIC
            && difficulty != DIFFICULTY_MYTHIC && difficulty != DIFFICULTY_MYTHIC_KEYSTONE)
            return fail("unsupported-difficulty");
        SpellInfo const* source = sSpellMgr->GetSpellInfo(SPELL_GOOPED_MAIN);
        SpellInfo const* summon = sSpellMgr->GetSpellInfo(SPELL_GOOPED_SUMMON);
        if (!source || !summon)
            return fail("missing-spell-info");
        SpellEffectInfo const* linked = source->GetEffect(difficulty, EFFECT_2);
        if (!linked || linked->Effect != SPELL_EFFECT_APPLY_AURA || linked->ApplyAuraName != SPELL_AURA_LINKED_SUMMON
            || linked->TriggerSpell != SPELL_GOOPED_SUMMON)
            return fail("source-effect2-drift");
        SpellEffectInfo const* effect = summon->GetEffect(difficulty, EFFECT_0);
        if (!effect || effect->Effect != SPELL_EFFECT_SUMMON || effect->MiscValue != NPC_GUNKER_GOOP
            || effect->MiscValueB != PlayerGoopPropertiesId || effect->TargetA.GetTarget() != TARGET_DEST_CASTER
            || effect->TargetB.GetTarget() != 0)
            return fail("summon-effect0-drift");
        if (summon->IsChanneled() || summon->Speed != 0.0f || summon->LaunchDelay != 0.0f
            || summon->HasAttribute(SPELL_ATTR6_CAST_BY_CHARMER))
            return fail("summon-cast-branch-drift");
        if (summon->GetDuration() != 90000)
            return fail("summon-base-duration-drift"); // CalcDuration/mods remain runtime Spell semantics.
        SummonPropertiesEntry const* properties = sSummonPropertiesStore.LookupEntry(PlayerGoopPropertiesId);
        if (!properties || properties->Control != SUMMON_CATEGORY_WILD || properties->Faction != 0
            || properties->Title != int32(SummonTitle::None) || properties->Slot != 0 || properties->Flags != 0)
            return fail("summon-properties64-drift");
        for (SpellEffectInfo const* other : summon->GetEffectsForDifficulty(difficulty))
        {
            if (!other || !other->IsEffect() || other->EffectIndex == EFFECT_0)
                continue;
            // Any new summoning effect is outside the audited single wild branch.
            switch (other->Effect)
            {
                case SPELL_EFFECT_SUMMON:
                case SPELL_EFFECT_SUMMON_CHANGE_ITEM:
                case SPELL_EFFECT_SUMMON_PET:
                case SPELL_EFFECT_SUMMON_OBJECT_WILD:
                case SPELL_EFFECT_SUMMON_PLAYER:
                case SPELL_EFFECT_SUMMON_OBJECT_SLOT1:
                case SPELL_EFFECT_SURVEY:
                case SPELL_EFFECT_SUMMON_RAF_FRIEND:
                case SPELL_EFFECT_SUMMON_OBJECT_PERSONNAL:
                case SPELL_EFFECT_SUMMON_STABLED_PET:
                case SPELL_EFFECT_CALL_PET:
                case SPELL_EFFECT_CREATE_TAMED_PET:
                    return fail("additional-summon-effect");
                default:
                    break; // Unrelated real effects continue to be executed by Spell.
            }
            if (other->ApplyAuraName == SPELL_AURA_LINKED_SUMMON)
                return fail("additional-linked-summon");
        }
        return true;
    }

    bool CheckPlayerGoopLoadedContract(InstanceScript* instance)
    {
        if (!instance || !instance->instance || instance->instance->GetId() != PlayerGoopMapId)
            return false;
        uint32 const difficulty = instance->instance->GetDifficultyID();
        if (!ValidatePlayerGoopDataContract(difficulty))
            return false;
        uint32 const spells[] = { SPELL_GOOPED_MAIN, SPELL_GOOPED_SUMMON };
        char const* const names[] = { "spell_gunker_gooped_player", "spell_gunker_gooped_player_summon" };
        for (uint32 i = 0; i < 2; ++i)
        {
            SpellScriptsBounds bounds = sObjectMgr->GetSpellScriptsBounds(spells[i]);
            auto script = bounds.first;
            bool const single = script != bounds.second && ++script == bounds.second;
            if (!single || !bounds.first->second.second
                || sObjectMgr->GetScriptName(bounds.first->second.first) != names[i]
                || !sScriptMgr->GetSpellScriptLoader(bounds.first->second.first))
            {
                TC_LOG_ERROR("scripts", "GunkerPlayerGoop contract map %u instance %u difficulty %u tick %u"
                    " spell %u expected %s reason binding-not-exact-single-enabled-loader",
                    PlayerGoopMapId, instance->instance->GetInstanceId(), difficulty, getMSTime(), spells[i], names[i]);
                return false;
            }
        }
        // Runtime bounds cannot reconstruct raw negative-rank SQL rows; Task5 supplies that evidence.
        return true;
    }

    InstanceScript* PlayerGoopInstance(Map* map)
    {
        InstanceMap* instance = map ? map->ToInstanceMap() : nullptr;
        return instance ? instance->GetInstanceScript() : nullptr;
    }

    char const PlayerGoopSourceKey[] = "Gunker.PlayerGoop.Source";
    void DispatchLinkedSummonSpell(PlayerGoopLinkPtr const&, Player*, AuraEffect const*);

    PlayerGoopLinkPtr BeginPlayerGoopLink(Aura* aura, Player* player, InstanceScript* instance)
    {
        auto registry = GetPlayerGoopRegistry(instance, true);
        return registry ? registry->CreateLink(player->GetGUID(), aura->GetCasterGUID(), aura->GetCastGUID()) : nullptr;
    }

    void NotifyLinkedGoopDeath(PlayerGoopLinkPtr const&, uint64 exec, Creature* goop);
    void NotifyLinkedGoopRemoved(PlayerGoopLinkPtr const&, uint64 exec, Creature* goop);
    void TryRescueSingleLinkedGoop(PlayerGoopLinkPtr const&);

}

class spell_gunker_gooped_player : public AuraScript
{
    PrepareAuraScript(spell_gunker_gooped_player);
public:
    PlayerGoopLinkPtr const& GetPlayerGoopLink() const { return _link; }
    bool IsManagedLinked() const { return _managedLinked; }
private:
    bool Load() override { return true; }
    bool Validate(SpellInfo const*) override { return ValidatePlayerGoopDataContract(DIFFICULTY_NONE); }
    void HandleApply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Unit* owner = GetUnitOwner();
        Player* player = owner ? owner->ToPlayer() : nullptr;
        AuraApplication const* app = GetTargetApplication();
        Map* map = player ? player->FindMap() : nullptr;
        if (!player || GetAura()->GetOwner() != player || !app || app->GetTarget() != player
            || GetAura()->GetApplicationOfTarget(player->GetGUID()) != app
            || app->GetRemoveMode() != AURA_REMOVE_NONE || !(app->GetEffectMask() & (1u << EFFECT_2))
            || !map || map->GetId() != PlayerGoopMapId || !PlayerGoopInstance(map))
            return;
        bool const firstApply = !_managedLinked;
        _managedLinked = true; // Keep this even when readiness fails, for Task2 Remove.
        PreventDefaultAction();
        if (!firstApply || _link || !CheckPlayerGoopLoadedContract(PlayerGoopInstance(map)))
            return;
        _link = BeginPlayerGoopLink(GetAura(), player, PlayerGoopInstance(map));
        if (_link && !_link->terminal && FindLivePlayerGoopSource(_link, map) == GetAura())
            DispatchLinkedSummonSpell(_link, player, effect);
    }
    void HandleRemove(AuraEffect const*, AuraEffectHandleModes mode)
    {
        if (!(mode & AURA_EFFECT_HANDLE_REAL) || (!_link && !_managedLinked))
            return;
        PreventDefaultAction(); // Managed failures and changed domains never fall back to grid-first.
        Unit* owner = GetUnitOwner();
        Player* player = owner ? owner->ToPlayer() : nullptr;
        Map* map = player ? player->FindMap() : nullptr;
        if (!_link)
        {
            TC_LOG_ERROR("scripts", "GunkerPlayerGoop remove-rejected map %u instance %u tick %u player %s"
                " source %u effect %u mode %u link 0 failureReason managed-without-link",
                map ? map->GetId() : 0, map ? map->GetInstanceId() : 0, getMSTime(),
                owner ? owner->GetGUID().ToString().c_str() : "none", SPELL_GOOPED_MAIN, uint32(EFFECT_2), uint32(mode));
            return;
        }
        PlayerGoopLinkPtr link = _link; // Survives synchronous world callbacks and index erasure.
        char const* failureReason = nullptr;
        if (!owner) failureReason = "remove-owner-missing";
        else if (!player) failureReason = "remove-owner-not-player";
        else if (owner->GetGUID() != link->playerGuid) failureReason = "remove-owner-guid-mismatch";
        else if (GetAura()->GetOwner() != owner
            || GetAura()->GetScript<spell_gunker_gooped_player>("spell_gunker_gooped_player") != this)
            failureReason = "remove-aura-link-identity-mismatch";
        else if (!map) failureReason = "remove-old-map-missing";
        else if (map->GetId() != link->mapId || map->GetInstanceId() != link->instanceId)
            failureReason = "remove-old-context-mismatch";
        AuraApplication const* app = GetTargetApplication();
        bool owned = false;
        if (player)
            for (auto const& pair : player->GetOwnedAuras())
                owned = owned || pair.second == GetAura();
        auto registry = link->registry.lock();
        // Observations only: core already set remove mode, cleared the bit and may have erased owned.
        TC_LOG_DEBUG("scripts", "GunkerPlayerGoop remove-observe map %u instance %u tick %u player %s"
            " link " UI64FMTD " effect %u mode %u ownerworld %d getplayer %d owned %u auraremoved %u"
            " appmask %u removemode %u failureReason %s",
            map ? map->GetId() : 0, map ? map->GetInstanceId() : 0, getMSTime(),
            link->playerGuid.ToString().c_str(), link->sequence, uint32(EFFECT_2), uint32(mode),
            owner ? int32(owner->IsInWorld()) : -1,
            map && !failureReason ? int32(map->GetPlayer(link->playerGuid) != nullptr) : -1,
            uint32(owned), uint32(GetAura()->IsRemoved()), app ? uint32(app->GetEffectMask()) : 0,
            app ? uint32(app->GetRemoveMode()) : 0, failureReason ? failureReason : "none");
        auto snapshot = EndPlayerGoopLink(link, PlayerGoopCloseReason::SourceRemoved);
        link->sourceState = PlayerGoopSourceState::Removed;
        if (failureReason)
            LogPlayerGoopTransition(registry.get(), *link, "remove-rejected", false, ObjectGuid::Empty,
                ObjectGuid::Empty, EFFECT_2, mode, true, failureReason);
        CleanupConcreteGoops(link, snapshot, failureReason ? nullptr : map, failureReason);
        // This Aura is already being removed. Never call RemoveAura here.
    }
    void HandleReapply(AuraEffect const*, AuraEffectHandleModes mode, bool apply)
    {
        if ((mode & AURA_EFFECT_HANDLE_REAL) || !(mode & AURA_EFFECT_HANDLE_REAPPLY))
            return; // A combined mode belongs to the REAL hook exactly once.
        if (!_link && !_managedLinked)
            return;
        PreventDefaultAction();
        if (_link)
        {
            PlayerGoopLinkPtr link = _link; // Rescue may synchronously remove this exact Aura.
            auto registry = link->registry.lock();
            LogPlayerGoopTransition(registry.get(), *link, apply ? "reapply-apply" : "reapply-remove",
                false, ObjectGuid::Empty, ObjectGuid::Empty, EFFECT_2, mode);
            if (!link->terminal)
            {
                if (!apply)
                    ++link->rescueReapplyDepth;
                else
                {
                    if (link->rescueReapplyDepth)
                        --link->rescueReapplyDepth;
                    TryRescueSingleLinkedGoop(link);
                }
            }
        }
        else
            TC_LOG_DEBUG("scripts", "GunkerPlayerGoop reapply effect %u mode %u apply %u link 0 managed %u",
                uint32(EFFECT_2), uint32(mode), uint32(apply), uint32(_managedLinked));
        // Refresh keeps the source, execution, GUIDs and lifetime; only pending death may close it.
    }
    void HandleReapplyApply(AuraEffect const* effect, AuraEffectHandleModes mode) { HandleReapply(effect, mode, true); }
    void HandleReapplyRemove(AuraEffect const* effect, AuraEffectHandleModes mode) { HandleReapply(effect, mode, false); }
    void Unload() override
    {
        PlayerGoopLinkPtr link = _link;
        auto snapshot = EndPlayerGoopLink(link, PlayerGoopCloseReason::SourceUnloaded);
        if (link)
        {
            link->sourceState = PlayerGoopSourceState::Removed;
            auto registry = link->registry.lock();
            for (auto const& record : snapshot.goops)
                if (record.cleanup != PlayerGoopCleanupState::Complete)
                    LogPlayerGoopTransition(registry.get(), *link, "cleanup-unresolved", false, record.guid,
                        record.summonerGuid, EFFECT_2, 0, true, "aura-unload-data-only");
        }
        _link.reset(); // No world resolution or removal from Unload/destruction.
    }
    void Register() override
    {
        OnEffectApply += AuraEffectApplyFn(spell_gunker_gooped_player::HandleApply, EFFECT_2,
            SPELL_AURA_LINKED_SUMMON, AURA_EFFECT_HANDLE_REAL);
        OnEffectRemove += AuraEffectRemoveFn(spell_gunker_gooped_player::HandleRemove, EFFECT_2,
            SPELL_AURA_LINKED_SUMMON, AURA_EFFECT_HANDLE_REAL);
        OnEffectApply += AuraEffectApplyFn(spell_gunker_gooped_player::HandleReapplyApply, EFFECT_2,
            SPELL_AURA_LINKED_SUMMON, AURA_EFFECT_HANDLE_REAPPLY);
        OnEffectRemove += AuraEffectRemoveFn(spell_gunker_gooped_player::HandleReapplyRemove, EFFECT_2,
            SPELL_AURA_LINKED_SUMMON, AURA_EFFECT_HANDLE_REAPPLY);
    }
    bool _managedLinked = false;
    PlayerGoopLinkPtr _link;
};

namespace
{
    Aura* FindLivePlayerGoopSource(PlayerGoopLinkPtr const& link, Map* map)
    {
        // Terminal is deliberately not a finder gate: Close will need this identity too.
        auto registry = link ? link->registry.lock() : nullptr;
        if (!link || !map || map->GetId() != link->mapId || map->GetInstanceId() != link->instanceId
            || !registry || registry->lifetime != link->lifetime
            || GetPlayerGoopRegistry(PlayerGoopInstance(map), false) != registry)
            return nullptr;
        Player* player = map->GetPlayer(link->playerGuid);
        if (!player || !player->IsInWorld() || player->FindMap() != map)
            return nullptr;
        for (auto const& pair : player->GetOwnedAuras())
        {
            Aura* aura = pair.second;
            if (!aura || aura->GetId() != SPELL_GOOPED_MAIN || aura->GetOwner() != player || aura->IsRemoved())
                continue;
            auto script = aura->GetScript<spell_gunker_gooped_player>("spell_gunker_gooped_player");
            AuraApplication const* app = aura->GetApplicationOfTarget(link->playerGuid);
            if (script && script->GetPlayerGoopLink() == link && app && app->GetTarget() == player
                && app->GetRemoveMode() == AURA_REMOVE_NONE && (app->GetEffectMask() & (1u << EFFECT_2)))
                return aura;
        }
        return nullptr;
    }

    bool PlayerGoopExpectedCancellation(PlayerGoopLinkPtr const& link)
    {
        auto registry = link ? link->registry.lock() : nullptr;
        return link && (link->terminal || !link->creationAllowed
            || (registry && (link->epoch != registry->epoch || (registry->frozen && !registry->exhausted))));
    }

    bool PlayerGoopCreationPermitted(PlayerGoopLinkPtr const& link, Player* player, ObjectGuid cast, uint64 exec,
        char const** failureReason = nullptr)
    {
        auto registry = link ? link->registry.lock() : nullptr;
        Map* map = player ? player->FindMap() : nullptr;
        char const* reason = nullptr;
        // Preserve the original short-circuit order, including finder and loaded-contract side effects.
        if (!registry) reason = "registry-missing";
        else if (registry->frozen) reason = "registry-frozen";
        else if (registry->exhausted) reason = "registry-exhausted";
        else if (!IsCurrentPlayerGoopLink(registry, link))
            reason = link->epoch != registry->epoch ? "epoch-revoked" : "link-not-current";
        else if (link->terminal) reason = "terminal-link";
        else if (!link->creationAllowed) reason = "creation-revoked";
        else if (!player) reason = "caster-not-player";
        else if (player->GetGUID() != link->playerGuid) reason = "player-guid-mismatch";
        else if (!link->execution.reserved) reason = "execution-not-reserved";
        else if (link->execution.castGuid != cast) reason = "spellcast-mismatch";
        else if (link->execution.reservation != exec) reason = "execution-mismatch";
        else if (!FindLivePlayerGoopSource(link, map)) reason = "live-source-not-found";
        else if (!CheckPlayerGoopLoadedContract(PlayerGoopInstance(map))) reason = "loaded-contract-rejected";
        if (failureReason)
            *failureReason = reason;
        return !reason;
    }

    void DispatchLinkedSummonSpell(PlayerGoopLinkPtr const& link, Player* player, AuraEffect const* effect)
    {
        auto registry = link->registry.lock();
        SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_GOOPED_SUMMON);
        if (!registry || !info || link->terminal || !link->creationAllowed || link->execution.reserved)
            return;
        Spell* spell = new Spell(player, info, TRIGGERED_FULL_MASK, ObjectGuid::Empty);
        SpellCastTargets targets;
        targets.SetUnitTarget(player);
        spell->m_CastItem = nullptr;
        if (Spell* parent = player->GetCurrentSpell(CURRENT_GENERIC_SPELL))
            spell->CopyCastContextFrom(parent);
        else if (Spell* parent = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
            spell->CopyCastContextFrom(parent);
        if (!registry->ReserveExecution(link, spell->m_castId))
        {
            link->execution.prepareFailed = true;
            delete spell; // Not prepared: no SpellEvent owns this object yet.
            return;
        }
        spell->Variables.Set<PlayerGoopLinkPtr>(PlayerGoopSourceKey, link);
        bool const prepared = spell->prepare(&targets, effect);
        // prepare owns the Spell lifetime. Only the strong link may be used from here.
        if (!prepared)
        {
            link->execution.prepareFailed = true;
            LogPlayerGoopTransition(registry.get(), *link, "prepare-failed", true, ObjectGuid::Empty,
                ObjectGuid::Empty, EFFECT_0, 0, true, "spell-prepare-returned-false");
        }
    }
}

// Former script stations. Not a retail path. 154746 already spawns on pos1.
// 154741 -> pos2 and 154759 -> pos3 are temporary stations near the boss.
const Position squirt_station_154741 = { 595.423f, -325.170f, 1.017f, 4.79f };
const Position squirt_station_154759 = { 577.199f, -359.477f, 0.864f, 0.11f };
const float squirt_home_154741_x = 614.227f;
const float squirt_home_154741_y = -530.915f;
const float squirt_home_154746_x = 626.622f;
const float squirt_home_154746_y = -348.212f;
const float squirt_home_154759_x = 631.387f;
const float squirt_home_154759_y = -411.629f;

static Creature* GetOwnedSquirtSummoner(Creature* goop)
{
    if (!goop || goop->GetEntry() != NPC_GUNKER_GOOP)
        return nullptr;
    TempSummon* summon = goop->ToTempSummon();
    if (!summon)
        return nullptr;
    Unit* summoner = summon->GetSummoner();
    Creature* bot = summoner ? summoner->ToCreature() : nullptr;
    if (!bot || !bot->GetMap() || bot->GetMap() != goop->GetMap())
        return nullptr;
    return SquirtIsOwnedStatic(bot->GetMapId(), bot->GetEntry(), bot->GetSpawnId()) ? bot : nullptr;
}

struct npc_mechagon_squirt_bot;

class spell_gunker_gooped_bot : public AuraScript
{
    PrepareAuraScript(spell_gunker_gooped_bot);

public:
    ObjectGuid GetLinkedGoopGuid() const { return _goopGuid; }
    bool IsLinkedGUID(ObjectGuid guid) const { return !_goopGuid.IsEmpty() && _goopGuid == guid; }
    bool CaptureGoop(Creature* bot, Creature* summon);
    void ClearLinkedGoopIf(ObjectGuid guid)
    {
        if (IsLinkedGUID(guid))
            _goopGuid.Clear();
    }
    void CancelCapture(npc_mechagon_squirt_bot* botAI);

private:
    ObjectGuid _goopGuid = ObjectGuid::Empty;

    bool Validate(SpellInfo const* spellInfo) override
    {
        if (!ValidateSpellInfo({ SPELL_GOOPED_INCAPCITATED, SPELL_GOOPED_SUMMON }) || spellInfo->Id != SPELL_GOOPED_INCAPCITATED)
            return false;
        SpellEffectInfo const* effect = spellInfo->GetEffect(EFFECT_1);
        return effect && effect->ApplyAuraName == SPELL_AURA_LINKED_SUMMON && effect->TriggerSpell == SPELL_GOOPED_SUMMON;
    }

    void HandleApply(AuraEffect const*, AuraEffectHandleModes);
    void HandleAfterApply(AuraEffect const*, AuraEffectHandleModes);
    void HandleRemove(AuraEffect const*, AuraEffectHandleModes);

    void Register() override
    {
        OnEffectApply += AuraEffectApplyFn(spell_gunker_gooped_bot::HandleApply, EFFECT_1, SPELL_AURA_LINKED_SUMMON, AURA_EFFECT_HANDLE_REAL);
        AfterEffectApply += AuraEffectApplyFn(spell_gunker_gooped_bot::HandleAfterApply, EFFECT_1, SPELL_AURA_LINKED_SUMMON, AURA_EFFECT_HANDLE_REAL);
        OnEffectRemove += AuraEffectRemoveFn(spell_gunker_gooped_bot::HandleRemove, EFFECT_1, SPELL_AURA_LINKED_SUMMON, AURA_EFFECT_HANDLE_REAL);
    }
};

struct npc_mechagon_squirt_bot : public ScriptedAI
{
    npc_mechagon_squirt_bot(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _goopCapture = nullptr;
        // End while flags, auras, and the active bit are still intact.
        if (_life.NeedsEnd() || me->isActiveObject() || HasResidual())
            ApplyEnd();
        else
            _life.OnEnd();
        if (!IsOwnedStatic() || !me->IsAlive())
            return;
        Apply(uint8(_life.Sync(BossState(), IsGooped(), true)));
        TryPrepareReleased();
    }

    bool BeginGoopCapture(spell_gunker_gooped_bot* owner)
    {
        if (!owner || owner->GetAura()->IsRemoved() || owner->GetAura()->GetUnitOwner() != me)
            return false;
        if (!_goopCapture)
        {
            _goopCapture = owner;
            return true;
        }

        spell_gunker_gooped_bot* previous = _goopCapture;
        TC_LOG_ERROR("scripts", "GunkerGoop capture-conflict bot %s old-caster %s new-caster %s",
            me->GetGUID().ToString().c_str(), previous->GetAura()->GetCasterGUID().ToString().c_str(), owner->GetAura()->GetCasterGUID().ToString().c_str());
        // Keep a same-owner window; cancel different owners without opening a new one.
        if (previous != owner)
            previous->CancelCapture(this);
        return false;
    }

    void ClearGoopCaptureIf(spell_gunker_gooped_bot* owner)
    {
        if (owner && _goopCapture == owner && owner->GetAura()->GetUnitOwner() == me)
            _goopCapture = nullptr;
    }

    void JustSummoned(Creature* summon) override
    {
        if (!_goopCapture || GetOwnedSquirtSummoner(summon) != me)
            return;
        if (_goopCapture->CaptureGoop(me, summon))
            _goopCapture = nullptr;
    }

    void SummonedCreatureDespawn(Creature* summon) override
    {
        if (GetOwnedSquirtSummoner(summon) != me)
            return;
        Aura* aura = me->GetAura(SPELL_GOOPED_INCAPCITATED);
        if (!aura || aura->IsRemoved())
            return;
        if (spell_gunker_gooped_bot* script = aura->GetScript<spell_gunker_gooped_bot>("spell_gunker_gooped_bot"))
            script->ClearLinkedGoopIf(summon->GetGUID());
    }

    void JustDied(Unit* /*killer*/) override
    {
        ApplyEnd();
    }

    void UpdateAI(uint32 diff) override
    {
        if (!IsOwnedStatic())
            return;
        // END inside Apply finishes before a released bot may take the old station.
        Apply(uint8(_life.Sync(BossState(), IsGooped(), me->IsAlive())));
        TryPrepareReleased();
        if (!_life.WantCast(diff, SprayPresent()))
            return;
        bool ok = me->CastSpell(me, SPELL_SANITIZING_SPRAY, false);
        _life.NoteCast(ok);
    }

    void ForceSync()
    {
        if (!IsOwnedStatic())
            return;
        if (!me->IsAlive())
        {
            ApplyEnd();
            return;
        }
        Apply(uint8(_life.Sync(BossState(), IsGooped(), true)));
    }

private:
    spell_gunker_gooped_bot* _goopCapture = nullptr;
    SquirtLifecycle _life;
    bool _prepared = false;

    uint8 BossState() const
    {
        return instance ? uint8(instance->GetBossState(DATA_GUNKER)) : uint8(SQUIRT_NOT_STARTED);
    }

    bool IsOwnedStatic() const
    {
        uint32 mapId = me->GetMap() ? me->GetMap()->GetId() : 0;
        return SquirtIsOwnedStatic(mapId, me->GetEntry(), me->GetSpawnId());
    }

    bool IsGooped() const
    {
        return me->HasAura(SPELL_GOOPED_INCAPCITATED) || me->HasAura(SPELL_GOOPED_MAIN);
    }

    bool HasSpellUp(uint32 spellId) const
    {
        return me->HasAura(spellId) || me->GetAreaTrigger(spellId);
    }

    bool SprayPresent() const
    {
        for (std::uint32_t spellId : SQUIRT_SPRAY_SPELLS)
            if (HasSpellUp(spellId))
                return true;
        return false;
    }

    bool HasResidual() const
    {
        if (SprayPresent() || IsGooped())
            return true;
        for (std::uint32_t spellId : SQUIRT_END_SPELLS)
            if (HasSpellUp(spellId))
                return true;
        return me->GetDistance(me->GetHomePosition()) > 0.5f;
    }

    void ClearListed(std::uint32_t const* spells, size_t count)
    {
        for (size_t i = 0; i < count; ++i)
        {
            me->RemoveAurasDueToSpell(spells[i]);
            me->RemoveAreaTrigger(spells[i]);
        }
    }

    void ClearSprayOnly()
    {
        me->InterruptNonMeleeSpells(false);
        ClearListed(SQUIRT_SPRAY_SPELLS, sizeof(SQUIRT_SPRAY_SPELLS) / sizeof(SQUIRT_SPRAY_SPELLS[0]));
    }

    void Apply(uint8 action)
    {
        if (action & SQUIRT_ACT_END)
            ApplyEnd();
        if (action & SQUIRT_ACT_BEGIN)
        {
            ApplyBegin();
            _life.OnBegin();
        }
        if (action & SQUIRT_ACT_PAUSE)
        {
            ClearSprayOnly();
            _life.OnPause();
        }
        if ((action & SQUIRT_ACT_END) == 0 && BossState() == SQUIRT_IN_PROGRESS && me->IsAlive())
            _life.gooped = IsGooped();
    }

    void ApplyBegin()
    {
        me->setActive(true);
        uint32 mapId = me->GetMap() ? me->GetMap()->GetId() : 0;
        if (SquirtUsesTemporaryStation(mapId, me->GetEntry(), me->GetSpawnId()))
        {
            Position const* pos = me->GetEntry() == NPC_SQUIRT_BOT_154741 ? &squirt_station_154741 : &squirt_station_154759;
            me->NearTeleportTo(pos->GetPositionX(), pos->GetPositionY(), pos->GetPositionZ(), pos->GetOrientation());
            me->GetMotionMaster()->Clear();
        }
        if (instance && !_life.frame)
            instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, me);
    }

    void ApplyEnd()
    {
        ClearSprayOnly();
        ClearListed(SQUIRT_END_SPELLS, sizeof(SQUIRT_END_SPELLS) / sizeof(SQUIRT_END_SPELLS[0]));
        if (_life.frame && instance)
            instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
        me->GetMotionMaster()->Clear();
        if (me->GetDistance(me->GetHomePosition()) > 0.5f)
        {
            Position const& home = me->GetHomePosition();
            me->NearTeleportTo(home.GetPositionX(), home.GetPositionY(), home.GetPositionZ(), home.GetOrientation());
        }
        if (_life.active || me->isActiveObject())
            me->setActive(false);
        _prepared = false;
        _life.OnEnd();
    }

    void TryPrepareReleased()
    {
        if (!IsOwnedStatic() || !me->IsAlive() || !instance)
            return;

        uint8 const state = BossState();
        if (state == SQUIRT_IN_PROGRESS || state == SQUIRT_DONE || _prepared)
            return;

        uint32 releaseBit = 0;
        uint64 const spawnId = me->GetSpawnId();
        if (spawnId == SQUIRT_SPAWN_154746)
            releaseBit = 1u << 0;
        else if (spawnId == SQUIRT_SPAWN_154741)
            releaseBit = 1u << 1;
        else if (spawnId == SQUIRT_SPAWN_154759)
            releaseBit = 1u << 2;
        else
            return;

        std::uint32_t const releaseMask = instance->GetData(DATA_SQUIRT_RELEASE_MASK);
        if ((releaseMask & releaseBit) == 0)
            return;

        uint32 const mapId = me->GetMap() ? me->GetMap()->GetId() : 0;
        if (SquirtUsesTemporaryStation(mapId, me->GetEntry(), me->GetSpawnId()))
        {
            Position const* pos = me->GetEntry() == NPC_SQUIRT_BOT_154741 ? &squirt_station_154741 : &squirt_station_154759;
            me->NearTeleportTo(pos->GetPositionX(), pos->GetPositionY(), pos->GetPositionZ(), pos->GetOrientation());
            me->GetMotionMaster()->Clear();
        }

        _prepared = true;
    }
};

bool spell_gunker_gooped_bot::CaptureGoop(Creature* bot, Creature* summon)
{
    // JustSummoned runs after the OnApply hook's application/state has been restored.
    Aura* aura = GetAura();
    if (!bot || aura->IsRemoved() || aura->GetUnitOwner() != bot || !_goopGuid.IsEmpty())
        return false;
    if (GetOwnedSquirtSummoner(summon) != bot)
        return false;
    _goopGuid = summon->GetGUID();
    return true;
}

void spell_gunker_gooped_bot::CancelCapture(npc_mechagon_squirt_bot* botAI)
{
    if (botAI)
        botAI->ClearGoopCaptureIf(this);
}

void spell_gunker_gooped_bot::HandleApply(AuraEffect const*, AuraEffectHandleModes)
{
    Creature* bot = GetTarget()->ToCreature();
    if (!bot || !bot->GetMap() || !SquirtIsOwnedStatic(bot->GetMapId(), bot->GetEntry(), bot->GetSpawnId())
        || !bot->IsAIEnabled || GetAura()->IsRemoved() || !_goopGuid.IsEmpty())
        return;
    if (npc_mechagon_squirt_bot* botAI = dynamic_cast<npc_mechagon_squirt_bot*>(bot->AI()))
        botAI->BeginGoopCapture(this);
}

void spell_gunker_gooped_bot::HandleAfterApply(AuraEffect const*, AuraEffectHandleModes)
{
    Creature* bot = GetAura()->GetUnitOwner()->ToCreature();
    if (bot && bot->IsAIEnabled)
        if (npc_mechagon_squirt_bot* botAI = dynamic_cast<npc_mechagon_squirt_bot*>(bot->AI()))
            botAI->ClearGoopCaptureIf(this);
}

void spell_gunker_gooped_bot::HandleRemove(AuraEffect const*, AuraEffectHandleModes)
{
    Creature* bot = GetTarget()->ToCreature();
    bool const owned = bot && bot->GetMap() && SquirtIsOwnedStatic(bot->GetMapId(), bot->GetEntry(), bot->GetSpawnId());
    if (owned)
        PreventDefaultAction();

    // AfterApply can be skipped on removal; release only this Aura's residual window.
    Creature* auraBot = GetAura()->GetUnitOwner()->ToCreature();
    if (auraBot && auraBot->IsAIEnabled)
        if (npc_mechagon_squirt_bot* botAI = dynamic_cast<npc_mechagon_squirt_bot*>(auraBot->AI()))
            botAI->ClearGoopCaptureIf(this);

    ObjectGuid const guid = _goopGuid;
    _goopGuid.Clear();
    if (!owned || guid.IsEmpty())
        return;
    Creature* goop = ObjectAccessor::GetCreature(*bot, guid);
    if (GetOwnedSquirtSummoner(goop) != bot)
        return;
    // UnSummon synchronously notifies the bot; the relationship is already empty.
    goop->DespawnOrUnsummon();
    return;
}

struct npc_mechagon_gunker_goop : public ScriptedAI
{
    npc_mechagon_gunker_goop(Creature* creature) : ScriptedAI(creature) { }

    bool BindPlayerGoop(PlayerGoopLinkPtr const& link, uint64 exec)
    {
        if (!link || !exec)
            return false;
        if (_playerBound)
            return !_playerLink.owner_before(link) && !link.owner_before(_playerLink) && _playerExec == exec;
        _playerBound = true;
        _playerLink = link;
        _playerExec = exec;
        return true;
    }

    bool HasPlayerGoopIdentity(PlayerGoopLinkPtr const& link, uint64 exec) const
    {
        return _playerBound && link && !_playerLink.owner_before(link) && !link.owner_before(_playerLink)
            && _playerExec == exec;
    }

    void ReportPlayerGoopRemoved()
    {
        // Explicit instance forwarding, not a nonexistent Player-owner despawn callback.
        if (_playerBound)
            if (auto link = _playerLink.lock())
                NotifyLinkedGoopRemoved(link, _playerExec, me);
    }

private:
    bool _playerBound = false; // An expired weak pointer still reserves its original identity.
    std::weak_ptr<GunkerPlayerGoopLink> _playerLink;
    uint64 _playerExec = 0;
public:
    void JustDied(Unit* /*killer*/) override
    {
        if (_playerBound)
        {
            // Expired or terminal player ownership cannot fall through to another source.
            if (auto link = _playerLink.lock())
                NotifyLinkedGoopDeath(link, _playerExec, me);
            return;
        }
        Creature* bot = GetOwnedSquirtSummoner(me);
        if (!bot)
            return;
        Aura* aura = bot->GetAura(SPELL_GOOPED_INCAPCITATED);
        if (!aura || aura->IsRemoved())
            return;
        spell_gunker_gooped_bot* script = aura->GetScript<spell_gunker_gooped_bot>("spell_gunker_gooped_bot");
        if (!script || !script->IsLinkedGUID(me->GetGUID()))
            return;
        bot->RemoveAura(aura);
        return;
    }
};

namespace
{
    void MarkLinkedGoopLost(PlayerGoopRegistryPtr const& registry, PlayerGoopLinkPtr const& link,
        ObjectGuid guid, uint64 exec, char const* reason)
    {
        if (!IsRegisteredPlayerGoopLink(registry, link) || link->terminal)
            return;
        auto record = link->goops.find(guid);
        auto reverse = registry->goops.find(guid);
        if (record == link->goops.end() || !record->second.committed || record->second.guid != guid
            || record->second.execution != exec || exec != link->execution.reservation
            || record->second.summonerGuid != link->playerGuid
            || reverse == registry->goops.end() || reverse->second.link.lock() != link
            || reverse->second.execution != exec)
            return;
        registry->goops.erase(reverse);
        if (record->second.life == PlayerGoopLifeState::Alive)
        {
            record->second.life = PlayerGoopLifeState::Lost;
            LogPlayerGoopTransition(registry.get(), *link, "lost", false, guid,
                record->second.summonerGuid, EFFECT_2, 0, false, reason);
        }
        // Previously observed exact death stays Dead/pending. Absence supplies no death or Complete vote.
    }

    void NotifyLinkedGoopRemoved(PlayerGoopLinkPtr const& link, uint64 exec, Creature* goop)
    {
        if (!link || !goop)
            return;
        auto registry = link->registry.lock();
        Map* map = goop->FindMap();
        TempSummon* summon = goop->ToTempSummon();
        auto ai = CAST_AI(npc_mechagon_gunker_goop, goop->AI());
        auto record = link->goops.find(goop->GetGUID());
        if (!map || map->GetId() != link->mapId || map->GetInstanceId() != link->instanceId
            || !registry || registry->lifetime != link->lifetime
            || GetPlayerGoopRegistry(PlayerGoopInstance(map), false) != registry
            || goop->GetEntry() != NPC_GUNKER_GOOP || !summon || summon->GetSummonerGUID() != link->playerGuid
            || !ai || !ai->HasPlayerGoopIdentity(link, exec)
            || record == link->goops.end() || !record->second.committed
            || record->second.guid != goop->GetGUID() || record->second.execution != exec
            || exec != link->execution.reservation || record->second.summonerGuid != link->playerGuid)
            return;
        if (link->terminal)
        {
            // Creature::RemoveFromWorld notifies before Unit/world/store removal. Even an enqueued
            // CleanupsBeforeDelete(false) can notify here: Pending is not completion evidence.
            LogPlayerGoopTransition(registry.get(), *link, "cleanup-remove-notify", false,
                record->second.guid, record->second.summonerGuid, EFFECT_2, 0, false,
                "removal-notification-not-completion", int32(goop->IsInWorld()), int32(goop->isDead()));
            return;
        }
        MarkLinkedGoopLost(registry, link, goop->GetGUID(), exec, "registered-creature-remove");
    }

    void NotifyLinkedGoopDeath(PlayerGoopLinkPtr const& link, uint64 exec, Creature* goop)
    {
        if (!link || link->terminal)
            return;
        auto registry = link->registry.lock();
        Map* map = goop ? goop->FindMap() : nullptr;
        TempSummon* summon = goop ? goop->ToTempSummon() : nullptr;
        ObjectGuid const guid = goop ? goop->GetGUID() : ObjectGuid::Empty;
        ObjectGuid const summoner = summon ? summon->GetSummonerGUID() : ObjectGuid::Empty;
        char const* failureReason = nullptr;
        if (!goop || guid.IsEmpty()) failureReason = "death-guid-missing";
        else if (!goop->isDead()) failureReason = "death-not-dead";
        else if (goop->GetEntry() != NPC_GUNKER_GOOP || !summon) failureReason = "death-not-goop-tempsummon";
        else if (!map || map->GetId() != link->mapId || map->GetInstanceId() != link->instanceId)
            failureReason = "death-old-context-mismatch";
        else if (!IsCurrentPlayerGoopLink(registry, link)
            || GetPlayerGoopRegistry(PlayerGoopInstance(map), false) != registry)
            failureReason = "death-registry-identity-mismatch";
        else if (!exec || !link->execution.reserved || exec != link->execution.reservation)
            failureReason = "death-execution-mismatch";
        else if (summoner != link->playerGuid) failureReason = "death-rawsummoner-mismatch";
        else
        {
            auto ai = CAST_AI(npc_mechagon_gunker_goop, goop->AI());
            auto record = link->goops.find(guid);
            auto reverse = registry->goops.find(guid);
            if (!ai || !ai->HasPlayerGoopIdentity(link, exec)) failureReason = "death-ai-identity-mismatch";
            else if (record == link->goops.end() || !record->second.committed
                || record->second.guid != guid || record->second.execution != exec
                || record->second.summonerGuid != summoner)
                failureReason = "death-record-identity-mismatch";
            else if (reverse == registry->goops.end() || reverse->second.link.lock() != link
                || reverse->second.execution != exec)
                failureReason = "death-reverse-identity-mismatch";
            else
            {
                if (record->second.life != PlayerGoopLifeState::Alive)
                    return; // Duplicate death and lost records never supply another death vote.
                record->second.life = PlayerGoopLifeState::Dead;
                record->second.pendingDeath = true;
                link->rescuePending = true;
                LogPlayerGoopTransition(registry.get(), *link, "dead", false, guid, summoner,
                    EFFECT_2, 0, false, "exact-goop-just-died", int32(goop->IsInWorld()), 1);
                TryRescueSingleLinkedGoop(link); // Unfinished execution/refresh retains this exact pending death.
                return;
            }
        }
        LogPlayerGoopTransition(registry.get(), *link, "dead-rejected", false, guid, summoner,
            EFFECT_2, 0, true, failureReason);
    }

    void TryRescueSingleLinkedGoop(PlayerGoopLinkPtr const& link)
    {
        if (!link || link->terminal || !link->rescuePending || link->rescueReapplyDepth)
            return;
        PlayerGoopExecution const& execution = link->execution;
        if (!execution.planKnown || execution.plannedCount != 1 || !execution.finished
            || !execution.reserved || !execution.prepareSeen || !execution.started || !execution.consumed
            || execution.prepareFailed || execution.creationFailed || execution.associationFailed
            || execution.successfulCommits != 1)
            return;
        PlayerGoopRecord const* dead = nullptr; // Data pointer on this stack only, never a world pointer.
        for (auto const& pair : link->goops)
        {
            PlayerGoopRecord const& record = pair.second;
            if (!record.committed)
                continue;
            if (dead || record.guid.IsEmpty() || record.guid != pair.first
                || record.execution != execution.reservation || record.summonerGuid != link->playerGuid
                || record.life != PlayerGoopLifeState::Dead || !record.pendingDeath)
                return;
            dead = &record;
        }
        if (!dead)
            return;
        auto registry = link->registry.lock();
        if (!IsCurrentPlayerGoopLink(registry, link) || registry->frozen || registry->exhausted)
            return;
        Map* map = sMapMgr->FindMap(link->mapId, link->instanceId);
        if (!FindLivePlayerGoopSource(link, map))
            return; // Missing application/bit is not SourceRemoved; Task4 Update can retry this same link.
        // Local EJ roles 20140/20141/20142 and Spell 298259 support basic single-Goop rescue.
        // Multi-Goop last-death and timeout rescue are unverified. DONE is not a rescue gate.
        LogPlayerGoopTransition(registry.get(), *link, "rescue", true, dead->guid, dead->summonerGuid);
        ClosePlayerGoopSource(link, map, PlayerGoopCloseReason::Rescued);
    }

    void CleanupConcreteGoops(PlayerGoopLinkPtr const& link, PlayerGoopCleanupSnapshot const& snapshot,
        Map* map, char const* contextFailure)
    {
        if (!link || !snapshot.first)
            return; // Only the first caller owns the original cleanup expansion.
        auto registry = link->registry.lock();
        char const* context = contextFailure;
        if (!context)
        {
            if (!map) context = "cleanup-old-map-missing";
            else if (map->GetId() != link->mapId || map->GetInstanceId() != link->instanceId)
                context = "cleanup-old-context-mismatch";
            else if (!registry || registry->lifetime != link->lifetime
                || GetPlayerGoopRegistry(PlayerGoopInstance(map), false) != registry)
                context = "cleanup-registry-identity-mismatch";
        }
        if (context)
            LogPlayerGoopTransition(registry.get(), *link, "cleanup-context-rejected", false,
                ObjectGuid::Empty, ObjectGuid::Empty, EFFECT_2, 0, true, context);
        for (auto const& record : snapshot.goops)
        {
            if (record.cleanup == PlayerGoopCleanupState::Complete)
                continue; // Preserve all snapshot states; never turn absent objects into completion evidence.
            char const* failureReason = context;
            TempSummon* summon = nullptr;
            if (!failureReason)
            {
                // Failed returns and unbound weak identities are not association credentials.
                if (!record.committed) failureReason = "cleanup-uncommitted-return";
                else if (record.guid.IsEmpty()) failureReason = "cleanup-guid-empty";
                else if (record.execution != snapshot.execution.reservation
                    || record.summonerGuid != link->playerGuid)
                    failureReason = "cleanup-record-identity-mismatch";
                else
                {
                    Creature* creature = map->GetCreature(record.guid);
                    if (!creature) failureReason = "cleanup-guid-missing";
                    else if (creature->FindMap() != map || creature->GetMapId() != link->mapId
                        || creature->GetInstanceId() != link->instanceId)
                        failureReason = "cleanup-creature-context-mismatch";
                    else if (creature->GetEntry() != NPC_GUNKER_GOOP)
                        failureReason = "cleanup-entry-mismatch";
                    else if (!(summon = creature->ToTempSummon())) failureReason = "cleanup-not-tempsummon";
                    else if (summon->GetSummonerGUID() != link->playerGuid)
                        failureReason = "cleanup-rawsummoner-mismatch";
                    else
                    {
                        auto ai = CAST_AI(npc_mechagon_gunker_goop, creature->AI());
                        if (!ai || !ai->HasPlayerGoopIdentity(link, record.execution))
                            failureReason = "cleanup-ai-link-execution-mismatch";
                    }
                }
            }
            if (failureReason)
            {
                LogPlayerGoopTransition(registry.get(), *link, "cleanup-unresolved", false, record.guid,
                    record.summonerGuid, EFFECT_2, 0, true, failureReason);
                continue; // Missing is unresolved, never Complete; no grid/neighbor fallback.
            }
            auto current = link->goops.find(record.guid);
            if (current == link->goops.end())
            {
                LogPlayerGoopTransition(registry.get(), *link, "cleanup-unresolved", false, record.guid,
                    record.summonerGuid, EFFECT_2, 0, true, "cleanup-record-missing");
                continue;
            }
            if (current->second.cleanup == PlayerGoopCleanupState::Complete)
                continue;
            if (record.cleanup == PlayerGoopCleanupState::Pending
                || current->second.cleanup == PlayerGoopCleanupState::Pending)
            {
                LogPlayerGoopTransition(registry.get(), *link, "cleanup-already-pending", false,
                    record.guid, record.summonerGuid);
                continue;
            }
            current->second.cleanup = PlayerGoopCleanupState::Pending; // Publish before synchronous callbacks.
            LogPlayerGoopTransition(registry.get(), *link, "cleanup-request", false, record.guid,
                summon->GetSummonerGUID(), EFFECT_2, 0, false, "despawn-enqueued");
            summon->DespawnOrUnsummon();
            // UnSummon enqueues removal; the early CreatureRemove notification is not Complete evidence.
        }
    }

    void ClosePlayerGoopSource(PlayerGoopLinkPtr link, Map* map, PlayerGoopCloseReason reason)
    {
        if (!link || link->terminal)
            return;
        // Find before revocation. Keep these pointers only on this synchronous stack.
        Aura* source = FindLivePlayerGoopSource(link, map);
        Player* player = source && source->GetUnitOwner() ? source->GetUnitOwner()->ToPlayer() : nullptr;
        auto snapshot = EndPlayerGoopLink(link, reason);
        if (source && player)
            player->RemoveAura(source); // Nested REAL Remove sees terminal and cannot own a second snapshot.
        else
        {
            auto registry = link->registry.lock();
            LogPlayerGoopTransition(registry.get(), *link, "close-source-unresolved", false,
                ObjectGuid::Empty, ObjectGuid::Empty, EFFECT_2, 0, true, "close-live-source-not-found");
            // Application/type-list gaps do not prove the source gone; retain its source state.
        }
        CleanupConcreteGoops(link, snapshot, map); // First caller retains responsibility after nested Remove.
    }

    void CommitConcreteGoop(PlayerGoopLinkPtr const& link, uint64 exec, Player* player, TempSummon* goop)
    {
        auto registry = link->registry.lock();
        Map* map = player->FindMap();
        ObjectGuid const guid = goop->GetGUID();
        ObjectGuid const summoner = goop->GetSummonerGUID();
        char const* failureReason = nullptr;
        if (guid.IsEmpty()) failureReason = "return-guid-empty";
        else if (!map) failureReason = "player-map-missing";
        else if (map->GetId() != link->mapId) failureReason = "return-map-id-mismatch";
        else if (map->GetInstanceId() != link->instanceId) failureReason = "return-instance-mismatch";
        else if (goop->FindMap() != map) failureReason = "return-map-mismatch";
        else if (goop->GetEntry() != NPC_GUNKER_GOOP) failureReason = "return-entry-mismatch";
        else if (summoner != link->playerGuid) failureReason = "return-rawsummoner-mismatch";
        bool const concrete = !failureReason;
        bool const dead = goop->isDead();
        bool const stored = concrete && goop->IsInWorld() && map->GetCreature(guid) == goop;
        auto ai = concrete ? CAST_AI(npc_mechagon_gunker_goop, goop->AI()) : nullptr;
        PlayerGoopRecord record;
        record.guid = guid;
        record.summonerGuid = summoner;
        record.execution = exec;
        record.life = dead ? PlayerGoopLifeState::Dead : stored ? PlayerGoopLifeState::Alive : PlayerGoopLifeState::Lost;
        record.pendingDeath = dead;
        bool cancelled = false;
        if (concrete)
        {
            if (!(stored || dead))
                failureReason = "return-lost-without-death";
            else if (!ai)
                failureReason = "return-ai-type-mismatch";
            else if (!PlayerGoopCreationPermitted(link, player, link->execution.castGuid, exec, &failureReason))
                cancelled = PlayerGoopExpectedCancellation(link);
            else if (!ai->BindPlayerGoop(link, exec))
                failureReason = "return-ai-binding-rejected";
            else
            {
                record.committed = true;
                if (registry->IndexGoop(link, record))
                {
                    if (dead)
                        link->rescuePending = true;
                    return;
                }
                failureReason = "return-index-rejected";
            }
        }
        record.committed = false;
        link->execution.associationFailed = true;
        // Keep exact failed/lost returns without publishing a reverse association or cumulative success.
        link->goops.emplace(guid, record);
        LogPlayerGoopTransition(registry.get(), *link, dead ? "return-dead-failed" : stored ? "return-failed" : "return-lost",
            true, guid, summoner, EFFECT_0, SPELL_EFFECT_HANDLE_HIT, !cancelled, failureReason);
        // Only this synchronous concrete return authenticates uncommitted cleanup; never scan neighbors.
        if (!guid.IsEmpty() && goop->GetEntry() == NPC_GUNKER_GOOP
            && summoner == link->playerGuid && goop->IsInWorld())
        {
            link->goops[guid].cleanup = PlayerGoopCleanupState::Pending;
            LogPlayerGoopTransition(registry.get(), *link, "cleanup-concrete-return", false, guid,
                summoner, EFFECT_0, SPELL_EFFECT_HANDLE_HIT, false, "despawn-enqueued");
            goop->DespawnOrUnsummon(); // Enqueued removal is not proof of completed world cleanup.
        }
    }

    std::vector<PlayerGoopLinkPtr> SnapshotPlayerGoopLinks(PlayerGoopRegistryPtr const& registry,
        ObjectGuid playerGuid)
    {
        std::vector<PlayerGoopLinkPtr> snapshot;
        auto player = registry->players.find(playerGuid);
        if (player != registry->players.end())
            for (uint64 sequence : player->second)
            {
                auto link = registry->links.find(sequence);
                if (link != registry->links.end() && link->second->playerGuid == playerGuid)
                    snapshot.push_back(link->second);
            }
        return snapshot;
    }

    void FinishTerminalPlayerGoopSource(PlayerGoopLinkPtr const& link,
        PlayerGoopCleanupSnapshot const& snapshot, Map* map, bool requireLiveSource)
    {
        if (!snapshot.first)
            return;
        // Reset already revoked ALL old links. Identity/liveness lookup deliberately ignores
        // terminal, epoch and registry link indices; no raw source survives between world calls.
        Aura* source = FindLivePlayerGoopSource(link, map);
        Player* player = source && source->GetUnitOwner() ? source->GetUnitOwner()->ToPlayer() : nullptr;
        if (source && player)
            player->RemoveAura(source);
        else if (requireLiveSource && link->sourceState != PlayerGoopSourceState::Removed)
        {
            auto registry = link->registry.lock();
            LogPlayerGoopTransition(registry.get(), *link, "close-source-unresolved", false,
                ObjectGuid::Empty, ObjectGuid::Empty, EFFECT_2, 0, true, "close-live-source-not-found");
        }
        CleanupConcreteGoops(link, snapshot, map); // Original first snapshot, never End again after Remove.
    }
}

void GunkerPlayerGoopPlayerLeaving(InstanceScript* instance, Map* oldMap, Player* player)
{
    auto registry = GetPlayerGoopRegistry(instance, false);
    if (!registry || !player || !oldMap || PlayerGoopInstance(oldMap) != instance
        || oldMap->GetId() != registry->mapId || oldMap->GetInstanceId() != registry->instanceId)
        return;
    ObjectGuid const guid = player->GetGUID();
    bool const lateLeave = !player->IsInWorld();
    auto links = SnapshotPlayerGoopLinks(registry, guid);
    for (auto const& link : links)
    {
        if (!IsRegisteredPlayerGoopLink(registry, link) || link->terminal)
            continue;
        LogPlayerGoopTransition(registry.get(), *link, "leave", true, ObjectGuid::Empty,
            ObjectGuid::Empty, EFFECT_2, 0, false, lateLeave ? "late-leave-residual" : "ordinary-old-map-leave");
        if (!lateLeave)
            ClosePlayerGoopSource(link, oldMap, PlayerGoopCloseReason::PlayerLeaving);
        else
        {
            // Logout's synchronous REAL Remove is primary; this stack only closes old indexed residuals.
            auto snapshot = EndPlayerGoopLink(link, PlayerGoopCloseReason::PlayerLeaving);
            CleanupConcreteGoops(link, snapshot, oldMap);
        }
    }
}

void GunkerPlayerGoopPlayerDied(InstanceScript* instance, Player* player)
{
    auto registry = GetPlayerGoopRegistry(instance, false);
    if (!registry || !player)
        return;
    auto links = SnapshotPlayerGoopLinks(registry, player->GetGUID());
    for (auto const& link : links)
    {
        if (!IsRegisteredPlayerGoopLink(registry, link) || link->terminal)
            continue;
        auto snapshot = EndPlayerGoopLink(link, PlayerGoopCloseReason::PlayerDied);
        // Unit's normal death AuraRemove has already run; only this registered source/residual is closed.
        FinishTerminalPlayerGoopSource(link, snapshot, instance->instance, false);
    }
}

void GunkerPlayerGoopEncounterReset(InstanceScript* instance)
{
    auto registry = GetPlayerGoopRegistry(instance, false);
    if (!registry || registry->frozen)
        return; // Nested accepted reset during world cleanup cannot reopen or own the old snapshots.
    registry->frozen = true;
    struct Unfreeze
    {
        PlayerGoopRegistryPtr registry;
        ~Unfreeze() { registry->frozen = registry->exhausted; }
    } unfreeze{ registry };
    uint64 const oldEpoch = registry->epoch;
    bool const advanced = registry->AdvanceResetEpoch();
    std::vector<PlayerGoopLinkPtr> links;
    for (auto const& pair : registry->links)
        links.push_back(pair.second); // Includes every base-call reentrant old-epoch creation.
    struct Closing
    {
        PlayerGoopLinkPtr link;
        PlayerGoopCleanupSnapshot snapshot;
    };
    std::vector<Closing> closing;
    for (auto const& link : links)
        closing.push_back({ link, EndPlayerGoopLink(link, PlayerGoopCloseReason::EncounterReset) });
    // No world operation until the entire old batch is terminal and detached.
    TC_LOG_INFO("scripts", "GunkerPlayerGoop reset map %u instance %u life " UI64FMTD
        " tick %u oldepoch " UI64FMTD " epoch " UI64FMTD " advanced %u links %u",
        registry->mapId, registry->instanceId, registry->lifetime, getMSTime(), oldEpoch,
        registry->epoch, uint32(advanced), uint32(closing.size()));
    for (auto const& item : closing)
        FinishTerminalPlayerGoopSource(item.link, item.snapshot, instance->instance, true);
}

void GunkerPlayerGoopCreatureRemoved(InstanceScript* instance, Creature* creature)
{
    auto registry = GetPlayerGoopRegistry(instance, false);
    if (!registry || !creature || creature->FindMap() != instance->instance)
        return;
    auto reverse = registry->goops.find(creature->GetGUID());
    if (reverse != registry->goops.end())
    {
        PlayerGoopLinkPtr link = reverse->second.link.lock();
        uint64 const exec = reverse->second.execution;
        NotifyLinkedGoopRemoved(link, exec, creature);
        return;
    }
    if (auto ai = CAST_AI(npc_mechagon_gunker_goop, creature->AI()))
        ai->ReportPlayerGoopRemoved(); // Weak branch also observes terminal pending cleanup without a lost vote.
}

void GunkerPlayerGoopUpdate(InstanceScript* instance)
{
    auto registry = GetPlayerGoopRegistry(instance, false);
    if (!registry || registry->frozen)
        return;
    Map* map = instance->instance; // This synchronous call's old instance only.
    std::vector<PlayerGoopLinkPtr> links;
    for (auto const& pair : registry->links)
        links.push_back(pair.second);
    for (auto const& link : links)
    {
        if (!IsRegisteredPlayerGoopLink(registry, link) || link->terminal)
            continue;
        std::vector<PlayerGoopRecord> goops;
        for (auto const& pair : link->goops)
            goops.push_back(pair.second);
        for (auto const& record : goops)
            if (record.committed && !map->GetCreature(record.guid))
                MarkLinkedGoopLost(registry, link, record.guid, record.execution, "registered-guid-left-store");

        Player* player = map->GetPlayer(link->playerGuid);
        if (!player)
        {
            // Cannot distinguish a missed ordinary leave/new-map Aura from a missing owner here.
            // Never chase a new map or claim removing old G also removed the old source Aura.
            LogPlayerGoopTransition(registry.get(), *link, "close-source-unresolved", false,
                ObjectGuid::Empty, ObjectGuid::Empty, EFFECT_2, 0, true,
                "old-owner-missing-source-unresolved-leave-bridge-unverified");
            auto snapshot = EndPlayerGoopLink(link, PlayerGoopCloseReason::MissingContext);
            CleanupConcreteGoops(link, snapshot, map);
            continue;
        }
        Aura* identity = nullptr;
        for (auto const& pair : player->GetOwnedAuras())
        {
            Aura* aura = pair.second;
            if (!aura || aura->GetId() != SPELL_GOOPED_MAIN || aura->GetOwner() != player)
                continue;
            auto script = aura->GetScript<spell_gunker_gooped_player>("spell_gunker_gooped_player");
            if (script && script->GetPlayerGoopLink() == link)
            {
                identity = aura;
                break;
            }
        }
        if (identity && identity->IsRemoved())
        {
            auto snapshot = EndPlayerGoopLink(link, PlayerGoopCloseReason::SourceRemoved);
            link->sourceState = PlayerGoopSourceState::Removed;
            CleanupConcreteGoops(link, snapshot, map);
            continue;
        }
        // An owned/type/application/linked-bit gap is not proof of REAL removal. Rescue rechecks
        // the same live source and retains pending death through any refresh gap.
        if (link->rescuePending)
            TryRescueSingleLinkedGoop(link);
    }
}

class spell_gunker_gooped_player_summon : public SpellScript
{
    PrepareSpellScript(spell_gunker_gooped_player_summon);
    bool Load() override { return true; }
    bool Validate(SpellInfo const*) override { return ValidatePlayerGoopDataContract(DIFFICULTY_NONE); }
    void LogTokenFailure(char const* event, char const* reason, uint32 effect, uint32 mode, bool capture = true)
    {
        if (capture)
        {
            // No link exists: snapshot only this real Spell's synchronous context, never infer an Aura.
            _tokenCast = GetSpell()->m_castId;
            _tokenSpell = GetSpellInfo()->Id;
            Unit* caster = GetCaster();
            Unit* originalCaster = GetOriginalCaster();
            Map* map = caster ? caster->FindMap() : nullptr;
            _tokenCaster = caster ? caster->GetGUID() : ObjectGuid::Empty;
            _tokenOriginalCaster = originalCaster ? originalCaster->GetGUID() : ObjectGuid::Empty;
            _tokenMap = map ? map->GetId() : 0;
            _tokenInstance = map ? map->GetInstanceId() : 0;
        }
        TC_LOG_ERROR("scripts", "GunkerPlayerGoop %s map %u instance %u tick %u spell %u spellcast %s caster %s"
            " originalcaster %s effect %u mode %u link 0 failureReason %s",
            event, _tokenMap, _tokenInstance, getMSTime(), _tokenSpell, _tokenCast.ToString().c_str(),
            _tokenCaster.ToString().c_str(), _tokenOriginalCaster.ToString().c_str(), effect, mode, reason);
    }
    void HandlePrepare()
    {
        Spell* spell = GetSpell();
        _tokenized = spell->Variables.Exist(PlayerGoopSourceKey);
        if (!_tokenized)
            return;
        try
        {
            _link = spell->Variables.GetValue<PlayerGoopLinkPtr>(PlayerGoopSourceKey);
        }
        catch (boost::bad_any_cast const&)
        {
            _tokenFailureReason = "source-type-mismatch";
            LogTokenFailure("prepare-rejected", _tokenFailureReason, EFFECT_0, 0);
            return;
        }
        if (!_link)
        {
            _tokenFailureReason = "null-source";
            LogTokenFailure("prepare-rejected", _tokenFailureReason, EFFECT_0, 0);
            return;
        }
        _exec = _link->execution.reservation;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        char const* failureReason = "original-caster-mismatch";
        if (GetOriginalCaster() == player
            && PlayerGoopCreationPermitted(_link, player, spell->m_castId, _exec, &failureReason))
        {
            _link->execution.prepareSeen = true;
            if (auto registry = _link->registry.lock())
                LogPlayerGoopTransition(*registry, *_link, "prepare", false);
        }
        else
        {
            _link->execution.prepareFailed = true;
            auto registry = _link->registry.lock();
            LogPlayerGoopTransition(registry.get(), *_link, "prepare-rejected", true, ObjectGuid::Empty,
                ObjectGuid::Empty, EFFECT_0, 0, !PlayerGoopExpectedCancellation(_link), failureReason);
        }
    }
    bool ConsumeLinkedSummonEffect(char const*& failureReason)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        // Same guards and order; the first rejected guard supplies this attempt's reason.
        if (!_link) failureReason = _tokenFailureReason;
        else if (!_link->execution.prepareSeen) failureReason = "prepare-not-seen";
        else if (_link->execution.consumed) failureReason = "already-consumed";
        else if (GetOriginalCaster() != player) failureReason = "original-caster-mismatch";
        else
            PlayerGoopCreationPermitted(_link, player, GetSpell()->m_castId, _exec, &failureReason);
        if (failureReason)
            return false;
        _link->execution.consumed = true;
        _link->execution.started = true;
        return true;
    }
    void HandleSummon(SpellEffIndex index)
    {
        // Presence, including null/invalid values, always suppresses tokenized default execution.
        if (!GetSpell()->Variables.Exist(PlayerGoopSourceKey))
            return;
        _tokenized = true;
        PreventHitDefaultEffect(index);
        char const* failureReason = nullptr;
        if (!ConsumeLinkedSummonEffect(failureReason))
        {
            if (_link)
            {
                if (!_link->execution.consumed)
                    _link->execution.creationFailed = true;
                auto registry = _link->registry.lock();
                LogPlayerGoopTransition(registry.get(), *_link, "hit-rejected", true, ObjectGuid::Empty,
                    ObjectGuid::Empty, index, SPELL_EFFECT_HANDLE_HIT,
                    !_link->execution.consumed && !PlayerGoopExpectedCancellation(_link), failureReason);
            }
            else
                LogTokenFailure("hit-rejected", failureReason, index, SPELL_EFFECT_HANDLE_HIT);
            return;
        }
        if (auto registry = _link->registry.lock())
            LogPlayerGoopTransition(*registry, *_link, "hit", false, ObjectGuid::Empty,
                ObjectGuid::Empty, index, SPELL_EFFECT_HANDLE_HIT);
        struct Finish
        {
            PlayerGoopLinkPtr link;
            ~Finish()
            {
                link->execution.finished = true;
                if (auto registry = link->registry.lock())
                    LogPlayerGoopTransition(*registry, *link, "finish", true);
                TryRescueSingleLinkedGoop(link);
            }
        } finish{ _link };
        Player* player = GetCaster()->ToPlayer();
        SpellEffectInfo const* effect = GetEffectInfo();
        WorldLocation const* dest = GetHitDest();
        SummonPropertiesEntry const* properties = effect ? sSummonPropertiesStore.LookupEntry(effect->MiscValueB) : nullptr;
        if (!dest) failureReason = "hit-destination-missing";
        else if (!effect) failureReason = "hit-effect-missing";
        else if (effect->Effect != SPELL_EFFECT_SUMMON) failureReason = "hit-effect-type-mismatch";
        else if (effect->MiscValue != NPC_GUNKER_GOOP) failureReason = "hit-entry-mismatch";
        else if (effect->MiscValueB != PlayerGoopPropertiesId) failureReason = "hit-properties-id-mismatch";
        else if (!properties) failureReason = "hit-properties-missing";
        else if (!ValidatePlayerGoopDataContract(player->GetMap()->GetDifficultyID())) failureReason = "hit-data-contract-rejected";
        if (failureReason)
        {
            _link->execution.creationFailed = true;
            auto registry = _link->registry.lock();
            LogPlayerGoopTransition(registry.get(), *_link, "hit-rejected", true, ObjectGuid::Empty,
                ObjectGuid::Empty, index, SPELL_EFFECT_HANDLE_HIT, true, failureReason);
            return;
        }
        bool const personalSpawn = (properties->Flags & SUMMON_PROP_FLAG_PERSONAL_SPAWN) != 0;
        int32 const duration = GetSpellInfo()->CalcDuration(GetOriginalCaster());
        uint32 const count = GetEffectValue() > 0 ? GetEffectValue() : 1;
        _link->execution.planKnown = true;
        _link->execution.plannedCount = count;
        TempSummonType const type = duration == 0 ? TEMPSUMMON_DEAD_DESPAWN : TEMPSUMMON_TIMED_DESPAWN;
        float const radius = effect->CalcRadius();
        for (uint32 i = 0; i < count; ++i)
        {
            if (!PlayerGoopCreationPermitted(_link, player, GetSpell()->m_castId, _exec, &failureReason))
            {
                _link->execution.creationFailed = true;
                auto registry = _link->registry.lock();
                LogPlayerGoopTransition(registry.get(), *_link, "creation-cancelled", true, ObjectGuid::Empty,
                    ObjectGuid::Empty, index, SPELL_EFFECT_HANDLE_HIT, !PlayerGoopExpectedCancellation(_link), failureReason);
                break;
            }
            Position pos;
            if (i == 0)
                pos = *dest;
            else
                pos = GetCaster()->GetRandomPoint(*dest, radius);
            TempSummon* goop = GetOriginalCaster()->SummonCreature(effect->MiscValue, pos, type, duration, 0, personalSpawn);
            if (!goop)
            {
                _link->execution.creationFailed = true;
                auto registry = _link->registry.lock();
                LogPlayerGoopTransition(registry.get(), *_link, "return-null", true, ObjectGuid::Empty,
                    ObjectGuid::Empty, index, SPELL_EFFECT_HANDLE_HIT, true, "summon-returned-null");
                continue;
            }
            GetSpell()->ExecuteLogEffectSummonObject(index, goop);
            auto registry = _link->registry.lock();
            LogPlayerGoopTransition(registry.get(), *_link, "return", false, goop->GetGUID(),
                goop->GetSummonerGUID(), index, SPELL_EFFECT_HANDLE_HIT, false, "none",
                int32(goop->IsInWorld()), int32(goop->isDead()));
            CommitConcreteGoop(_link, _exec, player, goop);
        }
    }
    void Unload() override
    {
        if (_tokenized && !_link)
            LogTokenFailure("tokenized-unload", _tokenFailureReason, EFFECT_0, 0, false);
        if (_link && (!_link->execution.reserved || !_link->execution.prepareSeen
            || !_link->execution.consumed || !_link->execution.finished))
        {
            _link->execution.prepareFailed = _link->execution.prepareFailed || !_link->execution.prepareSeen;
            _link->execution.creationFailed = true;
            auto registry = _link->registry.lock();
            bool const cancelled = PlayerGoopExpectedCancellation(_link);
            auto const report = [&](char const* reason)
            {
                LogPlayerGoopTransition(registry.get(), *_link, "unload-incomplete", true, ObjectGuid::Empty,
                    ObjectGuid::Empty, EFFECT_0, 0, !cancelled, reason);
            };
            if (!_link->execution.reserved) report("unload-not-reserved");
            if (!_link->execution.prepareSeen) report("unload-prepare-not-seen");
            if (!_link->execution.consumed) report("unload-not-consumed");
            if (!_link->execution.finished) report("unload-not-finished");
        }
        _link.reset(); // Spell Variables retain the source token until actual Spell destruction.
    }
    void Register() override
    {
        OnPrepare += SpellOnPrepareFn(spell_gunker_gooped_player_summon::HandlePrepare);
        OnEffectHit += SpellEffectFn(spell_gunker_gooped_player_summon::HandleSummon, EFFECT_0, SPELL_EFFECT_SUMMON);
    }
    bool _tokenized = false;
    uint64 _exec = 0;
    PlayerGoopLinkPtr _link;
    char const* _tokenFailureReason = "source-without-prepare";
    ObjectGuid _tokenCast;
    ObjectGuid _tokenCaster;
    ObjectGuid _tokenOriginalCaster;
    uint32 _tokenMap = 0;
    uint32 _tokenInstance = 0;
    uint32 _tokenSpell = 0;
};

//150222
struct boss_gunker : public BossAI
{
    boss_gunker(Creature* creature) : BossAI(creature, DATA_GUNKER) { }

    bool EncounterDone() const
    {
        return instance && GunkerDoneIsTerminal(uint8(instance->GetBossState(DATA_GUNKER)));
    }

    void Reset() override
    {
        // BossAI::_Reset writes NOT_STARTED, and SetBossState allows DONE -> NOT_STARTED.
        if (EncounterDone())
        {
            SetCombatMovement(false);
            me->AddUnitState(UNIT_STATE_ROOT);
            return;
        }

        BossAI::Reset();
        SetCombatMovement(false);
        me->AddUnitState(UNIT_STATE_ROOT);
        me->SetPower(POWER_ENERGY, 0);
        me->AddAura(AURA_OVERRIDE_POWER_COLOR_GREEN);
        RecoverDeadSquirts();
    }

    void ForEachOwnedSquirt(std::function<void(Creature*)> const& fn)
    {
        Map* map = me->GetMap();
        if (!map)
            return;
        uint64 const spawns[] = { SQUIRT_SPAWN_154741, SQUIRT_SPAWN_154746, SQUIRT_SPAWN_154759 };
        for (uint64 spawnId : spawns)
        {
            auto bounds = map->GetCreatureBySpawnIdStore().equal_range(spawnId);
            for (auto it = bounds.first; it != bounds.second; ++it)
            {
                Creature* bot = it->second;
                if (!bot)
                    continue;
                if (!SquirtIsOwnedStatic(bot->GetMapId(), bot->GetEntry(), bot->GetSpawnId()))
                    continue;
                fn(bot);
            }
        }
    }

    void LoadSquirtHomeGrids()
    {
        Map* map = me->GetMap();
        if (!map)
            return;
        map->LoadGrid(squirt_home_154741_x, squirt_home_154741_y);
        map->LoadGrid(squirt_home_154746_x, squirt_home_154746_y);
        map->LoadGrid(squirt_home_154759_x, squirt_home_154759_y);
    }

    // Only 154741, 154746, and 154759 already in the spawn store. Collect, then Respawn(false).
    // No SummonCreature and no new guid. Local compatibility, not a proven reset.
    // DONE returns before any respawn.
    void RecoverDeadSquirts()
    {
        if (EncounterDone())
            return;
        std::vector<Creature*> dead;
        ForEachOwnedSquirt([&dead](Creature* bot)
        {
            if (!bot->IsAlive())
                dead.push_back(bot);
        });
        for (Creature* bot : dead)
            bot->Respawn(false);
    }

    void NotifySquirtBots()
    {
        ForEachOwnedSquirt([](Creature* bot)
        {
            if (!bot->IsAIEnabled)
                return;
            if (npc_mechagon_squirt_bot* ai = dynamic_cast<npc_mechagon_squirt_bot*>(bot->AI()))
                ai->ForceSync();
        });
    }

    void MoveInLineOfSight(Unit* /*unit*/) override
    {
        if (EncounterDone())
            return;
    }

    void JustEngagedWith(Unit* /*unit*/) override
    {
        if (EncounterDone())
            return;
        if (!instance || instance->GetData(DATA_SQUIRT_RELEASE_MASK) != 7u)
        {
            me->CombatStop(true);
            me->GetThreatManager().ClearAllThreat();
            return;
        }
        _JustEngagedWith();
        if (EncounterDone() || !instance || instance->GetBossState(DATA_GUNKER) != IN_PROGRESS)
            return;
        DoCastSelf(SPELL_PERIODIC_ENERGY_GAIN);
        events.ScheduleEvent(EVENT_SLUDGE_BOLT, 1s);
        events.ScheduleEvent(EVENT_SPLATTER, 8s);
        events.ScheduleEvent(EVENT_COALESCE, 20s);
        events.ScheduleEvent(EVENT_GOOPED, 30s);
        events.ScheduleEvent(EVENT_TOXIC_WAVE, 45s);
        events.ScheduleEvent(EVENT_TOXIC_FLAMES, 50s);
        LoadSquirtHomeGrids();
        RecoverDeadSquirts();
        NotifySquirtBots();
    }

    void EnterEvadeMode(EvadeReason /*why*/) override
    {
        if (EncounterDone())
            return;
        _JustReachedHome();
        if (instance)
        {
            instance->SetBossState(DATA_GUNKER, FAIL);
            TC_LOG_INFO("scripts", "GunkerRelease keep map %u mask %u", me->GetMapId(), instance->GetData(DATA_SQUIRT_RELEASE_MASK));
        }
        NotifySquirtBots();
        RecoverDeadSquirts();
        _DespawnAtEvade();
    }

    void ExecuteEvent(uint32 eventid) override
    {
        switch (eventid)
        {
        case EVENT_COALESCE:
            DoCastSelf(SPELL_COALESCE, false);
            events.Repeat(30s);
            break;

        case EVENT_GOOPED:
            DoCastRandom(SPELL_GOOPED_MAIN, 100.0f, false);
            events.Repeat(30s);
            break;

        case EVENT_SLUDGE_BOLT:
            if (Unit* target = SelectTarget(SELECT_TARGET_MAXTHREAT, 0, 10.0f, true))
            {
                if (target->GetDistance2d(me) > 5.0f)
                {
                    me->CastSpell(target, SPELL_SLUDGE_BOLT, false);
                }
            }
            events.Repeat(2s);
            break;

        case EVENT_SPLATTER:
            DoCastSelf(SPELL_SPLATTER_TRIGGER, false);
            events.Repeat(35s);
            break;

        case EVENT_TOXIC_WAVE:
            me->SetPower(POWER_ENERGY, 0);
            DoCastSelf(SPELL_TOXIC_WAVE, false);
            events.Repeat(20s);
            break;

        case EVENT_TOXIC_FLAMES:
            DoCastSelf(SPELL_TOXIC_FLAMES_TRIGGER, true);
            events.Repeat(25s);
            break;
        }
    }

    void DamageTaken(Unit* attacker, uint32& damage) override
    {
        bool const hasInstance = instance != nullptr;
        SquirtBossState bossState = SQUIRT_NOT_STARTED;
        std::uint32_t releaseMask = 0;
        if (hasInstance)
        {
            bossState = SquirtBossState(uint8(instance->GetBossState(DATA_GUNKER)));
            releaseMask = instance->GetData(DATA_SQUIRT_RELEASE_MASK);
        }

        if (!GunkerAllowsDamage(hasInstance, bossState, releaseMask))
            damage = 0;

        BossAI::DamageTaken(attacker, damage);
    }

    void JustDied(Unit* /*killer*/) override
    {
        if (EncounterDone())
            return;
        _JustDied();
        NotifySquirtBots();
        if (instance && instance->GetBossState(DATA_GUNKER) == DONE)
            instance->DoModifyPlayerCurrencies(1553, 35);
    }
};

void AddSC_boss_gunker()
{
    RegisterCreatureAI(boss_gunker);
    RegisterCreatureAI(npc_mechagon_squirt_bot);
    RegisterCreatureAI(npc_mechagon_gunker_goop);
    RegisterAuraScript(spell_gunker_gooped_bot);
    RegisterSpellScript(spell_gunker_gooped_player_summon);
    RegisterAuraScript(spell_gunker_gooped_player);
}
