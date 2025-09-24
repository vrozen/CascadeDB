module lang::sml::PreMigrator

import Map;
import String;
import ValueIO;
import lang::delta::Effect;
import lang::delta::Object;
import lang::sml::Command;

public tuple[Heap, Event] runPreMigrate(Heap heap, Event evt) = 
  preMigrate(heap, evt, ValueIO::readTextValueString(#Command, evt.command.name));

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: MachDelete(UUID m, str name)) {
  Object mach = heap.space[m];
  Object states = heap.space[mach.states];
  Object instances = heap.space[mach.instances];
  list[Command] cmds = [];

  for(UUID s <- states.l) {
    Object state = heap.space[s];
    cmds = cmds + [StateDelete(s, state.name, m)];
  }

  for(UUID mi <- instances.s) {
    cmds = cmds + [MachInstDelete(mi, m)];
  }

  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: MachRemoveState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  Object instances = heap.space[mach.instances];
  list[Command] cmds = [];
  for(UUID mi <- instances.s) {
    Object machInst = heap.space[mi];
    Object sis = heap.space[machInst.sis];
    UUID si = toInt("<sis.m[s]>");
    cmds = cmds + [
      MachInstRemoveStateInst(mi, si, s),
      StateInstDelete(si, s)
    ];
  }
  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}
    
private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: MachInstDelete(UUID mi, UUID m)) {
  Object machInst = heap.space[mi];
  list[Command] cmds = [MachRemoveMachInst(machInst.def, mi)];
  Object sis = heap.space[machInst.sis];
  for(UUID s <- sis.m) {
    UUID si = toInt("<sis.m[s]>");
    cmds = cmds + [
      MachInstRemoveStateInst(mi, si, s),
      StateInstDelete(si, s)
    ];
  }
  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: MachInstRemoveStateInst(UUID mi, UUID si, UUID s)) {
  Object machInst = heap.space[mi];
  list[Command] cmds = [];
  if(machInst.cur == si){
    cmds = [MachInstSetCurState(mi, 0)];
  }
  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: StateDelete(UUID s, str name, UUID m)) {
  Object state = heap.space[s];
  Object output = heap.space[state.output];
  Object input = heap.space[state.input];
  list[Command] cmds = [];
  
  for(UUID t <- output.s) {
    Object tr = heap.space[t];
    cmds = cmds + [TransDelete(t, tr.source, tr.trigger, tr.target)];
  }
  
  for(UUID t <- input.s) {
    Object tr = heap.space[t];
    cmds = cmds + [TransDelete(t, tr.source, tr.trigger, tr.target)];
  }

  cmds = cmds + [MachRemoveState(m, s)];

  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}
  
private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: TransDelete(UUID t, UUID source, str trigger, UUID target)) {
  list[Command] cmds = [
    StateRemoveOut(source, t),
    StateRemoveIn(target, t)
  ];

  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

public default tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd) = <heap, evt>;