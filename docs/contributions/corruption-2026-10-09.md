# Corruption contribution submission — 2026-10-09

The contributor authorized splitting all corruption fixes into reviewable upstream PRs.
Original integration `1839496` and the `refs/backup/corruption-pre-submission-20261009` snapshot remain preserved.
The contribution branches start from upstream `2c13546197309802d43785a0a1fc9b2cea9211c9`; MOTHER is stacked on loot.

## Submitted scope

| Slice | Branch | Head | Upstream PR |
|---|---|---|---|
| item-effects | `contrib/corruption-item-effects` | `fc5bc962cacb` | Pending creation |
| avoidance | `contrib/corruption-avoidance` | `e7af774e0dda` | Pending creation |
| leech | `contrib/corruption-leech` | `2f8f84e8c256` | Pending creation |
| linked-procs | `contrib/corruption-linked-procs` | `b28e516133ce` | Pending creation |
| procs | `contrib/corruption-procs` | `22835358b6d0` | Pending creation |
| cooldowns | `contrib/corruption-cooldowns` | `772132413c00` | Pending creation |
| drawbacks | `contrib/corruption-drawbacks` | `c10959ddc864` | Pending creation |
| weapons | `contrib/corruption-weapons` | `9537e24875a5` | Pending creation |
| loot | `contrib/corruption-loot` | `7c9e5ce12eb0` | Pending creation |
| mother | `contrib/corruption-mother` | `a20113a509f2` | Pending creation |

Each script PR includes the same shared header; combine loader declarations/calls when merging.
Item effects precede scripts and application/purification; LINKED_2 precedes weapons; positive equipped drivers precede cooldowns; loot precedes MOTHER.
The drawback absorb penalty also depends on [#640](https://github.com/HavenWoW/BFA-HavenCore/pull/640).

## Verification

The union worldserver build passed with all core code, Spells, Commands and Custom enabled; other old content modules were excluded.
No individual-PR build, server startup, client/gameplay check or live SQL migration was performed in this preparation.
The method harnesses reproduce the original failures and verify the new item sum and continuous charge queue.
Inventory location boundary checks passed. See [evidence and standalone sources](corruption-evidence-2026-10-09/README.txt).

## Already covered upstream

- AreaTrigger removal callback fix: [#638](https://github.com/HavenWoW/BFA-HavenCore/pull/638), merged.
- Recipient absorb-taken ownership: [#640](https://github.com/HavenWoW/BFA-HavenCore/pull/640). The maintainer-requested redundant comment was removed in `c34963d`; open, CI pending at audit preparation.
- Session-locale hotfix blob delivery (`9be9c7a` locally) already exists upstream through #594; no duplicate PR.

## Preserved in the fork, excluded from upstream patches

- HavenLab addon, server notification/probe hooks, dumps and test packs.
- Obsolete Infinite Stars contaminant AfterCast rank wrapper: the equipped driver supplies the intended effect.
- QA all-rotation vendor/purchase override, fixed MOTHER spawn/guessed floor coordinates, global event deletion.
- Forced Chinese names across all locales, local BroadcastText/hotfix record IDs and related table-hash updates.
- Full local database dumps and machine-specific research/build artifacts.
- The complete 52-item/eight-window rotation remains a non-executable manual template in the MOTHER PR, outside the automatic updater.

## Outstanding validation

All ten PRs are drafts. Historical source comments and build results do not establish official retail correctness.
Avoidant misc masks/base-rating interactions, Lifesteal logs/procs, random-loot source eligibility, dual-wield Lash scaling, and MOTHER packets/currency/consumption/persistence require further checks.
Eye interpolation, pursuer speed/shroud and other documented approximation/fallback values remain disclosed rather than claimed as newly verified hotfix data.
Drawbacks require matching 8.3.7 SpellInfo/CorruptionEffects records, especially community-hotfix spells 337612/337816. No new blob data is supplied and no startup loading test was run.

## Attribution

Existing haha2345/bathfire authorship and historical Cursor co-authorship are retained.
OpenAI Codex (GPT-6 family) assisted extraction, review, repairs, method validation and PR preparation; the historical Cursor model is unknown.
