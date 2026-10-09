Union commit: 85e572c5712029e08fea34f473c23b9d9bcf59e8
Date: 2026-10-09
Compiler: MSVC 18.4, C++20, x64
Configuration: RelWithDebInfo, TOOLS=0, SCRIPTS=minimal-static, SCRIPTS_CUSTOM=static
Command: cmake --build build-corruption --config RelWithDebInfo --target worldserver -- /m:2
Result: exit 0; linked worldserver.exe
Worldserver SHA256: ee5f1aefd2aed96a31dc7ef509ec44ac2718bd8963c168d640238f956e202993
Scope: all game/core code and Spells, Commands, Custom script modules.
Excluded: other legacy content modules, per-PR isolated builds, server startup,
client packets/gameplay and live database migrations.

The first union build found an empty if left after stripping a notification.
The submitted procs branch fixes it; the final union build passed.

Method harnesses (MSVC /std:c++20 /EHsc):
rank-sum-before: exit 1, 8/10 fail; rank-sum-after: exit 0, 10/10 pass.
charge-rescale-before: exit 1, 5/7 fail; charge-rescale-after: exit 0, 7/7 pass.
inventory-boundaries: exit 0 (20 locations, missing owner, extended backpack).
Production methods are embedded in the C++ sources; collaborators are mocked.
Compile each source as a standalone executable; no server/database needed.
These methods do not validate client data, proc probabilities or full gameplay.
