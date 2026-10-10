# Corruption contribution consolidation — 2026-10-10

[Hextv requested one corruption PR](https://github.com/HavenWoW/BFA-HavenCore/pull/665#issuecomment-6089849327).
The existing [#665](https://github.com/HavenWoW/BFA-HavenCore/pull/665) is expanded to include all ten classified contributions; the original discussion stays there.
The other nine drafts will close after the combined remote head and description are verified. Branches and original authorship remain preserved.

## Combined branch

- Branch: `contrib/corruption-loot` (existing #665 head branch).
- Final head: `6b89d71013771fa6fca0bec43ae8e6c5d2ffa415`.
- Upstream: `c9fca55311d75b282200f8ed5ed8b0a64ec7e74b`.
- Diff: 81 files changed, 5635 insertions(+), 30 deletions(-).
- All ten original submission heads are ancestors; no force-push or history rewrite.
- Original user integration remains `1839496`; pre-consolidation refs are saved locally.

## Historical mapping

| Module | Original PR | Original head | Current review |
|---|---|---|---|
| Item instance effects | [#657](https://github.com/HavenWoW/BFA-HavenCore/pull/657) | `fc5bc962cacb` | #665 |
| Avoidant | [#658](https://github.com/HavenWoW/BFA-HavenCore/pull/658) | `e7af774e0dda` | #665 |
| Lifesteal | [#659](https://github.com/HavenWoW/BFA-HavenCore/pull/659) | `2f8f84e8c256` | #665 |
| LINKED_2 procs | [#660](https://github.com/HavenWoW/BFA-HavenCore/pull/660) | `b28e516133ce` | #665 |
| Positive effects and equipped ranks | [#661](https://github.com/HavenWoW/BFA-HavenCore/pull/661) | `22835358b6d0` | #665 |
| Cooldown effects | [#662](https://github.com/HavenWoW/BFA-HavenCore/pull/662) | `772132413c00` | #665 |
| Drawbacks | [#663](https://github.com/HavenWoW/BFA-HavenCore/pull/663) | `c10959ddc864` | #665 |
| Ny'alotha weapons | [#664](https://github.com/HavenWoW/BFA-HavenCore/pull/664) | `9537e24875a5` | #665 |
| Loot and bonus groups | [#665](https://github.com/HavenWoW/BFA-HavenCore/pull/665) | `7c9e5ce12eb0` | #665 |
| MOTHER application/purification | [#666](https://github.com/HavenWoW/BFA-HavenCore/pull/666) | `a20113a509f2` | #665 |

## Comparison requested by the maintainer

The current #75 and #81 patches were read for comparison; no code was copied or merged from them.
#75 covers three drawback tiers and associated groundwork; this contribution additionally includes positive effects, weapon procs and the item pipeline.
The Eye damage/radius model, the pursuer contact/repeat-strike behavior and speed/clone model differ.
#81 supplies coalesced resynchronization and area/resurrection handling which this branch does not add.
Both sets of drawback bindings/AI must be reconciled before enabling competing implementations together.
These differences are documented in #665 for the maintainer to choose an integration path; no model is claimed newly retail-verified.

## Generic prerequisite

The branch includes #640 through its existing commits. #640 remains an independently reviewed generic absorb-recipient fix.
Its diff will drop out of #665 once merged upstream. #75/#81 are unchanged.

## Verification

The final combined head built worldserver successfully on MSVC 18.4, C++20, x64 RelWithDebInfo.
All core code and Spells/Commands/Custom were compiled together; other legacy content modules were excluded.
No server startup, database migration execution, packet capture or in-game test was performed.
Production method regressions from the original submission remain applicable because consolidation did not change their code:
rank sums 10/10, charge queues 7/7, plus inventory boundaries. [Original sources/results](corruption-evidence-2026-10-09/README.txt).
[Build and branch records](corruption-evidence-2026-10-10/build.json).

## Preserved limitations

#665 stays a draft. Draft CI compiler jobs are skipped; a changes-filter success is not a build pass.
Pending work includes comparison/integration of #75/#81, client DB2/community hotfix availability, proc/scaling checks, dual-wield Lash, MOTHER packet/charging/consumption/persistence and random-loot source eligibility.
Historical approximations and observations remain documented in the PR. Random corruption defaults to zero.
HavenLab/probes, QA vendor overrides, fixed spawn/guessed coordinates, global event deletion, forced Chinese locales and full local DB dumps remain excluded.
The full 52-item/eight-window MOTHER rotation remains a non-executable manual reference outside the updater.

## Attribution

Original haha2345/bathfire authorship and historical Cursor credit are preserved.
OpenAI Codex (GPT-6 family) assisted extraction, review, method repairs and consolidation; the historical Cursor model is unknown.
