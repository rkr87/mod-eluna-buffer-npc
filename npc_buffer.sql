-- --------------------------------------------------------------------------------------
--  NPC BUFFER - 601017
-- --------------------------------------------------------------------------------------
-- Information
-- Creature ID: 601017
-- Creature Model: 14612 -- Tauren Warmaster (change CreatureDisplayID to taste)
-- Name: Aelthain
-- Subname: Keeper of Blessings
-- Script: pure Eluna gossip (npc_buffer.lua), no ScriptName / core rebuild needed
--
-- Blessing casters: 601018-601021
-- Four invisible caster NPCs pre-placed in the world so each Paladin blessing
-- comes from a unique caster GUID, letting Might, Wisdom, Kings, and Sanctuary
-- all be active at once (game engine limits one blessing per caster).
--
-- Install:
--   1. Copy npc_buffer.lua and buffs_data.lua into lua_scripts/.
--   2. Run this file against the world database.
--   3. Restart the worldserver, then .npc add 601017
--   4. Right-click Aelthain to buff.
--   5. The 4 blessing casters are auto-placed at 0,0,0 (change coordinates if
--      you want them elsewhere). They are invisible and non-interactable.

DELETE FROM `creature_template` WHERE `entry` = 601017;

INSERT INTO `creature_template`
    (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`,
     `npcflag`, `unit_flags`, `type`, `flags_extra`, `VerifiedBuild`)
VALUES
    (601017, 'Aelthain', 'Keeper of Blessings',
     80, 80, 2, 35, 1, 768, 7, 2, 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 601017;

INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
    (601017, 0, 14612, 1, 1, 12340);

-- --------------------------------------------------------------------------------------
--  BLESSING CASTERS - 601018 TO 601021
-- --------------------------------------------------------------------------------------
-- Four invisible caster NPCs. Each Paladin blessing is cast from a different
-- one so all four can be active on the same player simultaneously.
-- Spawned at 0,0,0 by default; adjust coordinates in creature table to taste.

DELETE FROM `creature_template` WHERE `entry` IN (601018, 601019, 601020, 601021);

INSERT INTO `creature_template`
    (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`,
     `npcflag`, `unit_flags`, `type`, `flags_extra`, `VerifiedBuild`)
VALUES
    (601018, 'Blessing Caster', '',
     80, 80, 2, 35, 1, 768, 7, 2, 12340),
    (601019, 'Blessing Caster', '',
     80, 80, 2, 35, 1, 768, 7, 2, 12340),
    (601020, 'Blessing Caster', '',
     80, 80, 2, 35, 1, 768, 7, 2, 12340),
    (601021, 'Blessing Caster', '',
     80, 80, 2, 35, 1, 768, 7, 2, 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (601018, 601019, 601020, 601021);

INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
    (601018, 0, 11686, 0.01, 1, 12340),
    (601019, 0, 11686, 0.01, 1, 12340),
    (601020, 0, 11686, 0.01, 1, 12340),
    (601021, 0, 11686, 0.01, 1, 12340);

-- Place the casters in the world at 0,0,0 (adjust X/Y/Z to your buffer's location).
DELETE FROM `creature` WHERE `id` IN (601018, 601019, 601020, 601021);

INSERT INTO `creature`
    (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
     `orientation`, `spawntimesecs`)
VALUES
    (601018, 0, 1, 1, 0, 0, 0, 0, 300),
    (601019, 0, 1, 1, 0, 0, 0, 0, 300),
    (601020, 0, 1, 1, 0, 0, 0, 0, 300),
    (601021, 0, 1, 1, 0, 0, 0, 0, 300);
