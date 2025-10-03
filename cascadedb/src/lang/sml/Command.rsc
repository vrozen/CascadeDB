module lang::sml::Command

import lang::delta::Effect;

public list[Event] getSMLEvents(list[Command] cmds) = 
  [event(id("sml"), id("<cmd>")[src = cmd.src], t_unknown(), id(""), [], [], [])  | cmd <- cmds];

alias UUID = int;

data Command
  = MachCreate          (UUID m, str name, loc src = |unknown:///|)
  | MachDelete          (UUID m, str name, loc src = |unknown:///|)
  | MachAddState        (UUID m, UUID s, loc src = |unknown:///|)
  | MachRemoveState     (UUID m, UUID s, loc src = |unknown:///|)
  | MachAddMachInst     (UUID m, UUID mi, loc src = |unknown:///|)
  | MachRemoveMachInst  (UUID m, UUID mi, loc src = |unknown:///|)
  | StateCreate         (UUID s, str name, UUID m, loc src = |unknown:///|)
  | StateDelete         (UUID s, str name, UUID m, loc src = |unknown:///|)
  | StateAddIn          (UUID s, UUID t, loc src = |unknown:///|)
  | StateRemoveIn       (UUID s, UUID t, loc src = |unknown:///|)
  | StateAddOut         (UUID s, UUID t, loc src = |unknown:///|)
  | StateRemoveOut      (UUID s, UUID t, loc src = |unknown:///|)
  | TransCreate         (UUID t, UUID source, str event, UUID target, loc src = |unknown:///|)
  | TransDelete         (UUID t, UUID source, str event, UUID target, loc src = |unknown:///|)
  | MachInstCreate      (UUID mi, UUID def, loc src = |unknown:///|)
  | MachInstDelete      (UUID mi, UUID def, loc src = |unknown:///|)
  | MachInstAddStateInst(UUID mi, UUID si, UUID s, loc src = |unknown:///|)
  | MachInstRemoveStateInst(UUID mi, UUID si, UUID s, loc src = |unknown:///|)
  | MachInstInitialize  (UUID mi, loc src = |unknown:///|)
  | MachInstMissingCurrentState(UUID mi, loc src = |unknown:///|)
  | MachInstQuiescence  (UUID mi, loc src = |unknown:///|)
  | MachInstSetCurState (UUID mi, UUID cur, loc src = |unknown:///|)
  | MachInstTrigger     (UUID mi, str event, loc src = |unknown:///|)
  | StateInstCreate     (UUID si, UUID def, loc src = |unknown:///|)
  | StateInstDelete     (UUID si, UUID def, loc src = |unknown:///|)
  | StateInstSetCount   (UUID si, int count, int oldCount, loc src = |unknown:///|)
  ;