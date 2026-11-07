# Eluna NPC Buffer

**Name:** Eluna NPC Buffer  
**Requires:** AzerothCore (3.3.5a) with Eluna  
**NPC:** Aelthain, Keeper of Blessings (entry `601017`)  
**Files:** `npc_buffer.lua`, `buffs_data.lua`, `npc_buffer.sql`

A gossip-driven buffer NPC that grants the key buffs other classes can cast —
Power Word: Fortitude, Arcane Intellect/Brilliance, Divine Spirit, Shadow
Protection, Mark of the Wild/Gift of the Wild, the Paladin blessings (Might,
Wisdom, Kings, Sanctuary) and Thorns. Buffs are free, instant and triggered,
so no reagents, mana or cast times are involved.

This is the Eluna/Lua sibling of your enchanter mod: same data-driven philosophy
(add buffs in `buffs_data.lua`, no core rebuild), same live re-validation at
apply time, same creature-template SQL style.

## Features

* **Level-gated ranks** — every buff rank carries a minimum level. The NPC
  checks the player's level, so a level 2 never receives a level 80 rank of
  Power Word: Fortitude.
* **Best version of a family** — buffs that share a family resolve to the
  single best rank the player qualifies for. Arcane Intellect and Arcane
  Brilliance share `intellect`; Mark of the Wild and Gift of the Wild share
  `wild`. Clicking either entry casts the best eligible spell in the family.
* **Universal buffs** — all offered buffs can be received by every class and
  spec (the NPC casts them on behalf of the player). Optional per-buff class
  gating is supported via the `classes` field.
* **Already-buffed awareness** — if the player already carries an equal or
  stronger aura from the family, the NPC says so instead of recasting; a
  weaker aura is upgraded.
* **Resurrection sickness** — optionally cured before buffing (config).
* **Combat guard** — optionally refuses to buff players in combat (config).

## Install

1. Copy `npc_buffer.lua` and `buffs_data.lua` into `lua_scripts/`.
2. Run `npc_buffer.sql` against the world database.
3. Restart the worldserver, then `.npc add 601017`.
4. Right-click Aelthain.

Using a different creature entry? Change `NPC_ID` at the top of `npc_buffer.lua`
to match.

## How it works

1. **Main menu** — one row per buff family (Stamina, Intellect, …). Each row
   shows whether the player is ready, already has the buff, needs a higher
   level, or has a weaker aura that will be upgraded. Clicking a ready row
   casts the best version immediately.
2. **Inspect all buffs** — lists every buff entry, the exact spell it resolves
   to, its rank and level requirement. Entries are clickable shortcuts to the
   same family-best cast.

## Configuration

Everything is in the `Config` table at the top of `npc_buffer.lua`:

| Key | Default | Meaning |
|---|---|---|
| `CureResSickness` | `true` | remove aura 15007 before buffing |
| `AllowInCombat` | `false` | refuse to buff players in combat |
| `WhisperAfterBuff` | `true` | broadcast a short line after each buff |
| `WhisperMessages` | 3 lines | templates with `{name}` and `{buff}` placeholders |
| `FamilyOrder` | 10 families | menu order of buff families |
| `FamilyLabels` | — | display name per family |
| `MaxRows` | `32` | gossip row cap |
| `Debug` | `false` | unused placeholder |

## The buff book (`buffs_data.lua`)

One table, `Buffs`, one entry per buff:

| Field | Meaning |
|---|---|
| `key` | unique id |
| `name` | menu name (fallback if the spell name cannot be resolved) |
| `family` | family key; shared = best-version logic applies across entries |
| `icon` | spell icon path for the menu row |
| `source` | flavor: which class normally casts it |
| `classes` | `nil` = all classes/specs; or a list of allowed class ids |
| `spells` | `{ {spellId, minLevel}, ... }` ranks, ascending by power |
| `comment` | free-form note |

Class ids: 1 Warrior, 2 Paladin, 3 Hunter, 4 Rogue, 5 Priest, 6 Death Knight,
7 Shaman, 8 Mage, 9 Warlock, 11 Druid.

Adding a buff is one new entry; changing a rank is one line. No rebuild, no
SQL, no `/reload eluna` strictly required (the book loads on first gossip).

## Spell IDs

Several spell ids in `buffs_data.lua` are marked `(verify)`. Before going live,
check them against your core, e.g. in-game:

```
.lookup spell "Power Word: Fortitude"
```

or by querying your spell DBC/table. Wrong ids are handled gracefully: the NPC
whispers that the blessing could not be applied, and nothing is spent (buffs
are free anyway).

## Design comparison with the enchanter mod

| | Enchanter (`enchanter_npc.lua`) | Buffer (`npc_buffer.lua`) |
|---|---|---|
| Data file | `enchants_data.lua` | `buffs_data.lua` |
| Loading | lazy, session-cached | lazy, session-cached |
| Gates | item level / era / mats / gold | player level per rank |
| Apply | consume reagents + fee, refund on fail | triggered cast, free, instant |
| Best-of | n/a | best rank per buff family |

## License

GNU Affero General Public License v3.0.
