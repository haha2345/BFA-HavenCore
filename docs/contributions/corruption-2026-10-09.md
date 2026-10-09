# Corruption contribution submission — 2026-10-09

The contributor authorized splitting all corruption fixes into reviewable upstream PRs.
Original integration `1839496` and the `refs/backup/corruption-pre-submission-20261009` snapshot remain preserved.
The contribution branches start from upstream `2c13546197309802d43785a0a1fc9b2cea9211c9`; MOTHER is stacked on loot.

## Submitted scope

| Slice | Branch | Head | Upstream PR |
|---|---|---|---|
| item-effects | `contrib/corruption-item-effects` | `fc5bc962cacb` | [#657](https://github.com/HavenWoW/BFA-HavenCore/pull/657) (draft) |
| avoidance | `contrib/corruption-avoidance` | `e7af774e0dda` | [#658](https://github.com/HavenWoW/BFA-HavenCore/pull/658) (draft) |
| leech | `contrib/corruption-leech` | `2f8f84e8c256` | [#659](https://github.com/HavenWoW/BFA-HavenCore/pull/659) (draft) |
| linked-procs | `contrib/corruption-linked-procs` | `b28e516133ce` | [#660](https://github.com/HavenWoW/BFA-HavenCore/pull/660) (draft) |
| procs | `contrib/corruption-procs` | `22835358b6d0` | [#661](https://github.com/HavenWoW/BFA-HavenCore/pull/661) (draft) |
| cooldowns | `contrib/corruption-cooldowns` | `772132413c00` | [#662](https://github.com/HavenWoW/BFA-HavenCore/pull/662) (draft) |
| drawbacks | `contrib/corruption-drawbacks` | `c10959ddc864` | [#663](https://github.com/HavenWoW/BFA-HavenCore/pull/663) (draft) |
| weapons | `contrib/corruption-weapons` | `9537e24875a5` | [#664](https://github.com/HavenWoW/BFA-HavenCore/pull/664) (draft) |
| loot | `contrib/corruption-loot` | `7c9e5ce12eb0` | [#665](https://github.com/HavenWoW/BFA-HavenCore/pull/665) (draft) |
| mother | `contrib/corruption-mother` | `a20113a509f2` | [#666](https://github.com/HavenWoW/BFA-HavenCore/pull/666) (draft) |

Each script PR includes the same shared header; combine loader declarations/calls when merging.
Merge prerequisites: #657 (instance effects) before scripts/application; #660 (LINKED_2) before #664 (weapons); #661 (equipped rank drivers) before #662 (cooldowns); #665 (loot) before #666 (MOTHER). MOTHER currently includes the loot commits against upstream main; rebase/retarget it once loot merges.
The drawback absorb penalty also depends on [#640](https://github.com/HavenWoW/BFA-HavenCore/pull/640).

## Verification

The union worldserver build passed with all core code, Spells, Commands and Custom enabled; other old content modules were excluded.
No individual-PR build, server startup, client/gameplay check or live SQL migration was performed in this preparation.
The method harnesses reproduce the original failures and verify the new item sum and continuous charge queue.
Inventory location boundary checks passed. See [evidence and standalone sources](corruption-evidence-2026-10-09/README.txt).

## Already covered upstream

- AreaTrigger removal callback fix: [#638](https://github.com/HavenWoW/BFA-HavenCore/pull/638), merged.
- Recipient absorb-taken ownership: [#640](https://github.com/HavenWoW/BFA-HavenCore/pull/640). The maintainer-requested redundant comment was removed in `c34963d`; open; MSVC/Clang passed and GCC remained running at the last check during submission.
- Session-locale hotfix blob delivery (`9be9c7a` locally) already exists upstream through #594; no duplicate PR.

## Preserved in the fork, excluded from upstream patches

- HavenLab addon, server notification/probe hooks, dumps and test packs.
- Obsolete Infinite Stars contaminant AfterCast rank wrapper: the equipped driver supplies the intended effect.
- QA all-rotation vendor/purchase override, fixed MOTHER spawn/guessed floor coordinates, global event deletion.
- Forced Chinese names across all locales, local BroadcastText/hotfix record IDs and related table-hash updates.
- Full local database dumps and machine-specific research/build artifacts.
- The complete 52-item/eight-window rotation remains a non-executable manual template in the MOTHER PR, outside the automatic updater.

## Outstanding validation

All ten PRs are open drafts and allow maintainer edits. Current CI disables compiler jobs for draft PRs; a successful changes filter with skipped builds is not a compiler pass. Historical source comments and build results do not establish official retail correctness.
Avoidant misc masks/base-rating interactions, Lifesteal logs/procs, random-loot source eligibility, dual-wield Lash scaling, and MOTHER packets/currency/consumption/persistence require further checks.
Echoing Void collapse 0.15, Void Ritual solo 5/6, Obsidian Skin 0.15/six-target division, Eye interpolation and pursuer speed/shroud are inherited model approximations. Inevitable Doom's corruption-minus-50 rule comes from historical observations. None were independently revalidated as retail hotfix data here.
Drawbacks require matching 8.3.7 SpellInfo/CorruptionEffects records, especially community-hotfix spells 337612/337816. No new blob data is supplied and no startup loading test was run.

## Attribution

Existing haha2345/bathfire authorship and historical Cursor co-authorship are retained.
OpenAI Codex (GPT-6 family) assisted extraction, review, repairs, method validation and PR preparation; the historical Cursor model is unknown.
