# Eluna NPC Buffer — WotLK 3.3.5a (AzerothCore)

NPC buffer gossip script for WotLK of the Lich King Classic (3.3.5a). Players speak to a buffer NPC and receive all available buffs scaled to their level, with correct spell ranks and target levels.

---

## Files

| File | Purpose |
|---|---|
| `npc_buffer.lua` | Main Eluna gossip script — buff menu, caster resolution, spell application |
| `buffs_data.lua` | Buff spell data — `{ spellId, spellLevel }` per entry, all verified against Spell.dbc |
| `grant_buff_talents.sql` | SQL for caster NPCs via `npc_trainer` |

---

## NPC Caster Assignments

| Family | NPC | Notes |
|---|---|---|
| stamina | **player** | Power Word: Fortitude — cast by player |
| intellect | **player** | Arcane Intellect — cast by player |
| spirit | **player** | Divine Spirit — cast by player |
| shadow_resist | **player** | Shadow Protection — cast by player |
| wild | **player** | Mark of the Wild / Gift of the Wild — cast by player |
| might | **190010** | Blessing of Might — separate might buffer NPC |
| wisdom | **{NEARBY_NPC}** | Blessing of Wisdom — wisdom caster NPC |
| kings | **player** | Blessing of Kings — always cast by player |
| sanctuary | **{NEARBY_NPC}** | Blessing of Sanctuary — buffer NPC casts |
| thorns | **player** | Thorns — cast by player |

All non-listed families default to `"player"` in `BLESSING_CASTERS`. Players cast prayer buffs (Prayer of Fortitude, Arcane Brilliance, Gift of the Wild, etc.) themselves so the AoE centers on them — NPC-cast party buffs only reach the NPC's empty party.

---

## Buff Level Formula

`targetMinLevel = max(1, spellLevel - 10)`

A target cannot receive a buff whose `spellLevel` > target level + 10 (verified from Spell.dbc and WoWpedia buff limit rules). Greater buffs win ties using `>=` comparison, so when standard and greater versions share the same `targetMinLevel`, the greater version is selected.

---

## Data Format (`buffs_data.lua`)

```lua
{
    key   = "blessing_of_might",
    icon  = "spell_holy_fistofjustice",
    spells = {
        { 19740,  4 },
        { 19834, 12 },
        -- ...
    },
}
```

- `key` — unique entry ID (matches `Config.KeyOrder` and `BLESSING_CASTERS` keys)
- `icon` — spell icon name (e.g., `spell_holy_fistofjustice`), rendered as `|TInterface/Icons/<icon>:22:22:-18:0|t` in gossip text
- `spells` — `{ spellId, spellLevel }` pairs only, all verified against Spell.dbc (zero mismatches)

10 entries, 66 active spells (27 ranked-out ranks commented with `--`).

---

## Gossip Menu

- **Buff All** — casts every available buff for the player's level/class
- **Per-buff rows** — one row per family with spell icon, name, and status (green = active/rank, red = inactive)
- **Print All** (Debug only) — whispers `[Spell Link] R:{rank} L:{spell_level}` for every spell in the book

---

## Installation

1. Copy `npc_buffer.lua` and `buffs_data.lua` to your worldserver's `lua_scripts/` directory
2. Ensure the script is loaded by your Eluna/AzerothCore worldserver config
3. Run `grant_buff_talents.sql` against your world database (adjust `SET @BUFFER_NPC`, `@MIGHT_NPC`, `@WISDOM_NPC` as needed)
4. Set creature template entry to `601017` for the buffer NPC, `{NEARBY_NPC}` for the might buffer, `{NEARBY_NPC}` for the wisdom caster
5. Reload or restart the worldserver

---

## Spell Data Source

All spell IDs and levels verified against WotLK 3.3.5a Spell.dbc (BaseLevel = SpellLevel = caster learn level). Buff level formula confirmed from WoWpedia buff limit rules.
