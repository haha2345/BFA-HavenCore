#include "ScriptMgr.h"
#include "temple_of_sethraliss.h"
#include "ScriptedGossip.h"
#include "ObjectMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Util.h"

enum Misc
{
    ENCOUNTER_ID = 2127,
};

enum Texts
{
    SAY_OBJECTIVE = 0,
    SAY_EFFECTIVE_HEAL = 1,
    SAY_INTRO = 5,
    SAY_RESTORE = 6,
    SAY_THANK_YOU = 4,
    SAY_JOIN_COMBAT = 3,
};

enum Spells
{
    SPELL_EMPOWERMENT = 269670,
    SPELL_LIFE_FORCE = 274149,
    SPELL_LIFE_FORCE_HEAL = 274149,
    SPELL_JOLT = 279000,
    SPELL_TAINT_DEBUFF = 267944,
  
    SPELL_TAINT_CHANNEL = 273677,
    SPELL_TAINT_VISUAL = 267759,
  
    SPELL_PULSE = 268024,
    SPELL_PLAGUE = 269686,
};

enum Events
{
    EVENT_PLAGUE_DOCTOR = 1,
    EVENT_HEART_GUARDIAN,
    EVENT_TOAD,
    EVENT_JOLT,
    EVENT_CHECK_PLAYERS
};

const Position universal_spawn_pos = { 4140.0f, 3659.0f, -43.0f, 0.59f };
const Position middle_of_room_pos = { 4161.0f, 3673.0f, -34.0f, 3.69f };

//133392
struct boss_avatar_of_sethraliss : public BossAI
{
    boss_avatar_of_sethraliss(Creature* creature) : BossAI(creature, DATA_AVATAR_OF_SETHRALISS) { }

    void Reset() override
    {
        BossAI::Reset();
        _JustReachedHome();
        instance->SetBossState(DATA_AVATAR_OF_SETHRALISS, NOT_STARTED);
        this->wavecount = 0;
        victoryHandled = false;
        me->RestoreFaction();
        std::list<Creature*> c_li;
        me->GetCreatureListWithEntryInGrid(c_li, NPC_HOODOO_HEXER, 150.0f);
        for (auto & hoodoo : c_li)
        {
            if (hoodoo->IsAlive())
            {
                instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, hoodoo);
            }
            else
            {
                hoodoo->Respawn(true);
                hoodoo->AI()->Reset();
            }
        }
        me->DespawnCreaturesInArea(NPC_HEART_GUARDIAN);
        me->DespawnCreaturesInArea(NPC_PLAGUE_TOAD);
        me->DespawnCreaturesInArea(NPC_PLAGUE_DOCTOR);
        me->RemoveUnitFlag(UNIT_FLAG_IMMUNE_TO_PC);       
    }

    void EnterCombat(Unit* /*unit*/) override
    {
        instance->SetBossState(DATA_AVATAR_OF_SETHRALISS, IN_PROGRESS);
        events.ScheduleEvent(EVENT_CHECK_PLAYERS, 1s);
        events.ScheduleEvent(EVENT_HEART_GUARDIAN, 5s);
        events.ScheduleEvent(EVENT_TOAD, 25s);
        if (IsSethralissHeroicPlus(me->GetMap()))
            events.ScheduleEvent(EVENT_PLAGUE_DOCTOR, 10s);
    }

    void HealReceived(Unit* /*done_by*/, uint32& addhealth) override
    {
        if (AuraEffect const* aurEff = me->GetAuraEffect(SPELL_TAINT_CHANNEL, EFFECT_0))
            AddPct(addhealth, aurEff->GetAmount());
    }

    void JustDied(Unit* /*killer*/) override
    {
        _JustDied();
        me->ForcedDespawn(0, 5s);
        me->DespawnCreaturesInArea(NPC_HEART_GUARDIAN);
        me->DespawnCreaturesInArea(NPC_PLAGUE_TOAD);
        me->DespawnCreaturesInArea(NPC_PLAGUE_DOCTOR);        
    }

    void DamageTaken(Unit* /*done_by*/, uint32& dmg) override
    {
        if (me->HealthBelowPctDamaged(80, dmg) && (this->wavecount == 0))
        {
            wavecount = 1;
            std::list<Creature*> c_li;
            me->GetCreatureListWithEntryInGrid(c_li, NPC_HOODOO_HEXER, 150.0f);
            for (auto& hoodoo : c_li)
            {
                if (hoodoo->IsAlive())
                {
                    return;
                }
                else
                {
                    hoodoo->Respawn(true);
                    hoodoo->AI()->Reset();
                }
            }
        }

        if (me->HealthBelowPctDamaged(70, dmg) && (this->wavecount == 1))
        {
            wavecount = 2;
            std::list<Creature*> c_li;
            me->GetCreatureListWithEntryInGrid(c_li, NPC_HOODOO_HEXER, 150.0f);
            for (auto& hoodoo : c_li)
            {
                if (hoodoo->IsAlive())
                {
                    return;
                }
                else
                {
                    hoodoo->Respawn(true);
                    hoodoo->AI()->Reset();
                }
            }
        }

        if (me->HealthBelowPctDamaged(40, dmg) && (this->wavecount == 2))
        {
            wavecount = 3;
            std::list<Creature*> c_li;
            me->GetCreatureListWithEntryInGrid(c_li, NPC_HOODOO_HEXER, 150.0f);
            for (auto & hoodoo : c_li)
            {
                if (hoodoo->IsAlive())
                {
                    return;
                }
                else
                {
                    hoodoo->Respawn(true);
                    hoodoo->AI()->Reset();
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, hoodoo);
                    std::list<Creature*> c_li;
                    me->GetCreatureListWithEntryInGrid(c_li, NPC_AVATAR_OF_SETHRALISS, 100.0f);
                    for (auto& avatar : c_li)
                    if (avatar->IsAlive())
                    {    
                        me->CastSpell(avatar, SPELL_TAINT_CHANNEL);
                        me->CastSpell(avatar, SPELL_TAINT_VISUAL);
                    }
                }
            }
        }
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);

        if (instance && instance->GetBossState(DATA_AVATAR_OF_SETHRALISS) == IN_PROGRESS && me->HealthAbovePct(99) && !victoryHandled)
        {
            victoryHandled = true;
            me->CastStop();
            instance->SetBossState(DATA_AVATAR_OF_SETHRALISS, DONE);
            _JustReachedHome();
            me->AddUnitFlag(UNIT_FLAG_IMMUNE_TO_NPC);
            instance->SendBossKillCredit(ENCOUNTER_ID);
            std::list<Player*> p_li;
            me->GetPlayerListInGrid(p_li, 150.0f);
            for (auto & players : p_li)
            {
                players->KilledMonsterCredit(me->GetEntry());
                players->ClearInCombat();
            }
            Talk(SAY_THANK_YOU);
            me->SummonGameObject(GO_SETHRALISS_TREASURE, 4149.73f, 3665.59f, -43.0365f, 3.68391f, QuaternionData(0, 0, -0.963461f, 0.267849f), false);
            if (IsMythic() && instance->IsChallengeModeStarted())
            {
                me->SummonGameObject(GO_CHALLENGERS_CACHE_SETHRALISS, 4185.0f, 3688.0f, -43.0f, 3.84f, QuaternionData(), false);
            }
            me->DespawnCreaturesInArea(NPC_HOODOO_HEXER, 125.0f);
            me->DespawnCreaturesInArea(NPC_HEART_GUARDIAN, 125.0f);
            me->DespawnCreaturesInArea(NPC_PLAGUE_TOAD, 125.0f);
            me->DespawnCreaturesInArea(NPC_PLAGUE_DOCTOR, 125.0f);
            return;
        }

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
            ExecuteEvent(eventId);
    }

    void ExecuteEvent(uint32 eventId) override
    {
        switch (eventId)
        {
        case EVENT_JOLT:
        {
            std::list<Creature*> c_li;
            me->GetCreatureListWithEntryInGrid(c_li, NPC_HOODOO_HEXER, 150.0f);
            for (auto& hoodoo : c_li)
            me->AI()->DoCast(hoodoo, SPELL_JOLT);
            events.Repeat(3s);
            break;
        }

        case EVENT_CHECK_PLAYERS:
        {
            std::list<Player*> p_li;
            me->GetPlayerListInGrid(p_li, 150.0f);
            bool anyAlive = false;
            for (auto & players : p_li)
            {
                if (players->IsAlive())
                {
                    anyAlive = true;
                    break;
                }
            }
            if (anyAlive)
            {
                events.Repeat(3s);
                break;
            }
            BossAI::Reset();
            break;
        }

        case EVENT_HEART_GUARDIAN:
             me->SummonCreature(NPC_HEART_GUARDIAN, universal_spawn_pos, TEMPSUMMON_MANUAL_DESPAWN);
             events.Repeat(15s);
             break;

        case EVENT_PLAGUE_DOCTOR:
             me->SummonCreature(NPC_PLAGUE_DOCTOR, universal_spawn_pos, TEMPSUMMON_MANUAL_DESPAWN);
             events.Repeat(20s);
             break;

        case EVENT_TOAD:
            for (uint8 i = 0; i < 6; i++)
            {
                me->SummonCreature(NPC_PLAGUE_TOAD, me->GetRandomPoint(middle_of_room_pos, 30.0f));
            }
            events.Repeat(25s);
            break;
        }        
    }

    void JustSummoned(Creature* summon)
    {
        switch (summon->GetEntry())
        {
        case NPC_PLAGUE_TOAD:
            if (Unit* tar = SelectTarget(SELECT_TARGET_RANDOM, 0, 100.0f, true))
            {
                summon->AI()->AttackStart(tar);
            }      
            break;

        case NPC_HEART_GUARDIAN:
            summon->RemoveAura(274609);
            summon->RemoveAura(231201);
            summon->RemoveAura(274603);  
            summon->RemoveUnitFlag(UNIT_FLAG_IMMUNE_TO_PC);
            summon->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            summon->SetFaction(14);
            summon->AI()->DoZoneInCombat();
            break;

        default:
            break;
        }
    }

    void sGossipSelect(Player* player, uint32 /*menuId*/, uint32 gossipListId) override
    {
        if (gossipListId == 1)
        {
            CloseGossipMenuFor(player);
            if (WorldSafeLocsEntry const* loc = sObjectMgr->GetWorldSafeLoc(6419))
                player->TeleportTo(loc->Loc);
            return;
        }

        if (gossipListId != 0)
            return;

        if (instance->GetBossState(DATA_AVATAR_OF_SETHRALISS) == NOT_STARTED)
        {
            instance->SetBossState(DATA_AVATAR_OF_SETHRALISS, IN_PROGRESS);
            me->AddUnitState(UNIT_STATE_ROOT);
            me->RemoveNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            me->SetHealth(me->GetMaxHealth() * 0.10f);
            me->SetFaction(FACTION_MASK_PLAYER);
            events.ScheduleEvent(EVENT_JOLT, 100ms);

            std::list<Creature*> c_li;
            me->GetCreatureListWithEntryInGrid(c_li, NPC_HOODOO_HEXER, 150.0f);
            for (auto & hoodoo : c_li)
            {
                if (hoodoo->IsAlive())
                {
                    hoodoo->SetVisible(true);
                    hoodoo->SetReactState(REACT_DEFENSIVE);
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, hoodoo);
                }
            }

            Talk(SAY_INTRO);
            _EnterCombat();

            me->GetScheduler().Schedule(6s, [this] (TaskContext /*context*/)
            {
                Talk(SAY_OBJECTIVE);
            });

            me->GetScheduler().Schedule(8s, [this] (TaskContext /*context*/)
            {
                Talk(SAY_RESTORE);
            });

            EnterCombat(player);
        }
    }

private:
    uint8 wavecount;
    uint8 encouter_done;
    bool victoryHandled = false;
};

enum HoodooHexerSpells
{
    SPELL_LAVA_BURST = 274642,
    SPELL_FLAME_SHOCK = 268013
};

enum HoodooHexerEvents
{
    EVENT_LAVA_BURST = 1,
    EVENT_FLAME_SHOCK
};

//135552
struct npc_hoodoo_hexer : public ScriptedAI
{
    npc_hoodoo_hexer(Creature* c) : ScriptedAI(c) { }

    void Reset() override
    {
        ScriptedAI::Reset();
        me->SetReactState(REACT_PASSIVE);
        std::list<Creature*> c_li;
        me->GetCreatureListWithEntryInGrid(c_li, NPC_AVATAR_OF_SETHRALISS, 100.0f);
        for (auto & avatar : c_li)
        if (avatar->IsAlive())
        {            
            me->CastSpell(avatar, SPELL_TAINT_CHANNEL);
            me->CastSpell(avatar, SPELL_TAINT_VISUAL);
        }
        me->SetVisible(false);
    }

    void EnterCombat(Unit* /*unit*/) override
    {        
        if (IsSethralissHeroicPlus(me->GetMap()))
        {
            events.ScheduleEvent(EVENT_FLAME_SHOCK, 1s);
        }
        events.ScheduleEvent(EVENT_LAVA_BURST, 3s);
    }

    void JustDied(Unit* /*killer*/) override
    {
        instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
    }

    void ExecuteEvent(uint32 eventId) override
    {
        switch (eventId)
        {
        case EVENT_FLAME_SHOCK:
            if (Unit* tar = SelectTarget(SELECT_TARGET_RANDOM, 0, 100.0f, true))
            {
                DoCast(tar, SPELL_FLAME_SHOCK);
            }
            events.Repeat(15s);
            break;

        case EVENT_LAVA_BURST:
            if (Unit* tar = SelectTarget(SELECT_TARGET_RANDOM, 0, 30.0f, true))
            {
                DoCast(tar, SPELL_LAVA_BURST);
            }
            events.Repeat(3s);
            break;

        default:
            break;
        }
    }
};

//137233
struct npc_plague_toad_137233 : public ScriptedAI
{
    npc_plague_toad_137233(Creature* c) : ScriptedAI(c) { }

    void Reset() override
    {
        ScriptedAI::Reset();
    }

    void EnterCombat(Unit* /*unit*/) override
    {
       DoCastVictim(SPELL_PLAGUE);
    }
};

//142929
struct npc_energy_fragment : public ScriptedAI
{
    npc_energy_fragment(Creature* c) : ScriptedAI(c) { }

    void Reset() override
    {
        ScriptedAI::Reset();
        me->AddNpcFlag(UNIT_NPC_FLAG_GOSSIP);
    }

    void sGossipHello(Player* player) 
    { 
        CloseGossipMenuFor(player);
        if (Creature* avatar = me->FindNearestCreature(NPC_AVATAR_OF_SETHRALISS, 100.0f, true))
        {
            avatar->RemoveAura(SPELL_TAINT_DEBUFF);
            avatar->AddAura(SPELL_LIFE_FORCE);
            me->CastSpell(avatar, SPELL_LIFE_FORCE_HEAL);
            avatar->AI()->Talk(SAY_EFFECTIVE_HEAL);            
            me->DespawnOrUnsummon();
        }
    }
};

// 273677 Taint Dummy: apply difficulty BasePoints as healing reduction.
class spell_sethraliss_taint : public AuraScript
{
    PrepareAuraScript(spell_sethraliss_taint);

    void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = false;

        Unit* owner = GetUnitOwner();
        Map const* map = owner ? owner->GetMap() : nullptr;
        Difficulty const difficulty = map ? map->GetDifficultyID() : DIFFICULTY_NONE;

        int32 fallback = -20;
        if (difficulty == DIFFICULTY_HEROIC)
            fallback = -30;
        else if (difficulty == DIFFICULTY_MYTHIC)
            fallback = -50;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(SPELL_TAINT_CHANNEL);
        SpellEffectInfo const* effect = info ? info->GetEffect(uint32(difficulty), EFFECT_0) : nullptr;
        if (!effect || effect->BasePoints <= -100)
        {
            amount = fallback;
            return;
        }

        amount = effect->BasePoints;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_sethraliss_taint::CalculateAmount, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

void AddSC_boss_avatar_of_sethraliss()
{
    RegisterCreatureAI(boss_avatar_of_sethraliss);
    RegisterCreatureAI(npc_hoodoo_hexer);
    RegisterCreatureAI(npc_plague_toad_137233);
    RegisterCreatureAI(npc_energy_fragment);
    RegisterAuraScript(spell_sethraliss_taint);
}
