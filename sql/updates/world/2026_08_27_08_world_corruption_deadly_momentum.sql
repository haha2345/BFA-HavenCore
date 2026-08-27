-- 837 blizzlike: Deadly Momentum (致命之势). 318219 DBC BP is 0; script fills
-- per-stack crit rating from the rank Dummy. Crit-only filter is C++ CheckProc.
-- Do NOT write spell_proc.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (318218, 318219);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(318218, 'spell_deadly_momentum_proc'),
(318219, 'spell_deadly_momentum_buff');
