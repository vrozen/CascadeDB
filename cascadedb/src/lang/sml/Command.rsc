module lang::sml::Command

import lang::delta::Effect;

alias UUID = int;

data Command
  = MachCreate          (UUID m, str name)
  | MachDelete          (UUID m, str name)
  | MachAddState        (UUID m, UUID s)
  | MachRemoveState     (UUID m, UUID s)
  | MachAddMachInst     (UUID m, UUID mi)
  | MachRemoveMachInst  (UUID m, UUID mi)
  | StateCreate         (UUID s, str name, UUID m)
  | StateDelete         (UUID s, str name, UUID m)
  | StateAddIn          (UUID s, UUID t)
  | StateRemoveIn       (UUID s, UUID t)
  | StateAddOut         (UUID s, UUID t)
  | StateRemoveOut      (UUID s, UUID t)
  | TransCreate         (UUID t, UUID source, str evt, UUID target)
  | TransDelete         (UUID t, UUID source, str evt, UUID target)
  | MachInstCreate      (UUID mi, UUID def)
  | MachInstDelete      (UUID mi, UUID def)
  | MachInstAddStateInst(UUID mi, UUID si, UUID s)
  | MachInstRemoveStateInst(UUID mi, UUID si, UUID s)
  | MachInstInitialize  (UUID mi)
  | MachInstMissingCurrentState(UUID mi)
  | MachInstQuiescence  (UUID mi)
  | MachInstSetCurState (UUID mi, UUID cur)
  | MachInstTrigger     (UUID mi, str evt)
  | StateInstCreate     (UUID si, UUID def)
  | StateInstDelete     (UUID si, UUID def)
  | StateInstSetCount   (UUID si, int count, int oldCount)
  ;

list[Event] getSMLEvents(list[Command] cmds) = 
  [event(id("sml"), id("<cmd>"), t_unknown(), id(""), [], [], [])  | cmd <- cmds];