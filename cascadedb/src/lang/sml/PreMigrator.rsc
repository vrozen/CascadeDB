module lang::sml::PreMigrator

import IO;
import Map;
import String;
import ValueIO;
import lang::delta::Object;
import lang::delta::Effect;
import lang::sml::Object;
import lang::sml::Command;

public tuple[Heap, Event] runPreMigrate(Heap heap, Event evt) = 
  preMigrate(heap, evt, readTextValueString(#Command, evt.command.name));

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: MachDelete(UUID m, str name)) {
  Object mach = heap.space[m];
  Object states = heap.space[mach.states];
  Object instances = heap.space[mach.instances];
  list[Command] cmds = [];

  for(UUID s <- states.l) {
    Object state = heap.space[s];
    cmds = cmds + [
      StateDelete(s, state.name, m, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2367,27,<53,8>,<53,35>))
    ];
  }

  for(UUID mi <- instances.s) {
    cmds = cmds + [
      MachInstDelete(mi, m, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2458,23,<56,8>,<56,31>))
    ];
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
      MachInstRemoveStateInst(mi, si, s, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2995,36,<78,8>,<78,44>)),
      StateInstDelete(si, s, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(3041,24,<79,8>,<79,32>))
    ];
  }
  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: StateDelete(UUID s, str name, UUID m)) {
  Object state = heap.space[s];
  Object output = heap.space[state.output];
  Object input = heap.space[state.input];
  list[Command] cmds = [];
  
  set[value] trs = output.s + input.s; //note: accounts for reflexive transitions
  println(input.s);
  println(output.s);
  println(trs);  

  for(UUID t <- trs) {
    Object tr = heap.space[t];
    cmds = cmds + [TransDelete(t, tr.source, tr.evt, tr.target, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2407,45,<54,8>,<54,53>))];
  }

  cmds = cmds + [MachRemoveState(m, s, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2582,23,<59,6>,<59,29>))];

  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}
  
private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: TransDelete(UUID t, UUID source, str trigger, UUID target)) {
  list[Command] cmds = [
    StateRemoveOut(source, t, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2446,27,<56,6>,<56,33>)),
    StateRemoveIn(target, t, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2481,26,<57,6>,<57,32>))
  ];

  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: TransSetTarget(UUID t, UUID target)) {
  Object trans = heap.space[t];
  oldTarget = trans.target;

  list[Command] cmds = [
    StateRemoveIn(oldTarget, t),
    StateAddIn(target, t)
  ];

  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: MachInstDelete(UUID mi, UUID m)) {
  Object machInst = heap.space[mi];
  list[Command] cmds = [
    MachRemoveMachInst(machInst.def, mi, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2498,32,<61,6>,<61,38>))
  ];
  Object sis = heap.space[machInst.sis];
  for(UUID s <- sis.m) {
    UUID si = toInt("<sis.m[s]>");
    cmds = cmds + [
      MachInstRemoveStateInst(mi, si, s, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2586,32,<63,8>,<63,40>)),
      StateInstDelete(si, s, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2627,29,<64,8>,<64,37>))
    ];
  }
  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd: MachInstRemoveStateInst(UUID mi, UUID si, UUID s)) {
  Object machInst = heap.space[mi];
  list[Command] cmds = [];
  if(machInst.cur == si){
    cmds = [
      MachInstSetCurState(mi, 0, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2966,22,<78,8>,<78,30>))
    ];
  }
  evt.pre = getSMLEvents(cmds);
  return <heap, evt>;
}

public default tuple[Heap, Event] preMigrate(Heap heap, Event evt, Command cmd) = <heap, evt>;