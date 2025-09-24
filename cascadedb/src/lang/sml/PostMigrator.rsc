module lang::sml::PostMigrator

import ValueIO;
import Map;
import List;
import String;
import lang::delta::Effect;
import lang::delta::Object;
import lang::sml::Command;

public tuple[Heap, Event] runPostMigrate(Heap heap, Event evt) = 
  postMigrate(heap, evt, ValueIO::readTextValueString(#Command, evt.command.name));

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachAddState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  Object instances = heap.space[mach.instances];
  list[Command] cmds = [];

  for(UUID mi <- instances.s) {
    <si, heap> = getNextId(heap);
    cmds = cmds + [
      StateInstCreate(si, s),
      MachInstAddStateInst(mi, si, s),
      MachInstInitialize(mi)
    ];
  }

  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachInstCreate(UUID mi, UUID def)) {
  Object machInst = heap.space[mi];
  Object mach = heap.space[machInst.def];
  Object states = heap.space[mach.states];
  list[Command] cmds = [MachAddMachInst(machInst.def, mi)];

  for(UUID s <- states.l) {
    <si, heap> = getNextId(heap);
    cmds = cmds + [
      StateInstCreate(si, s),
      MachInstAddStateInst(mi, si, s)
    ];
  }

  cmds = cmds + [MachInstInitialize(mi)];

  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}


private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachRemoveState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  Object instances = heap.space[mach.instances];
  list[Command] cmds = [];
  for(UUID mi <- instances.s) {
    cmds = cmds + [
      MachInstInitialize(mi)
    ];
  }
  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachInstInitialize(UUID mi)) {
  Object machInst = heap.space[mi];
  Object sis = heap.space[machInst.sis];
  Object mach = heap.space[machInst.def];
  Object states = heap.space[mach.states];
  list[Command] cmds = [];
  if(size(sis.m) > 0 && machInst.cur == 0) {
    UUID s = toInt("<states.l[0]>");
    UUID si = toInt("<sis.m[s]>");
    cmds = [MachInstSetCurState(mi, si)];
  }

  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachInstSetCurState(UUID mi, UUID cur)) {
  list[Command] cmds = [];  
  if(cur != 0) { 
    Object stateInst = heap.space[cur];
    cmds = [StateInstSetCount(cur, stateInst.count + 1, stateInst.count)];
  }

  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachInstTrigger(UUID mi, str trigger)) {
  Object machInst = heap.space[mi];
  list[Command] cmds = [];
  if(machInst.cur == 0){ 
    cmds = [MachInstMissingCurrentState(mi)];
  } else {
    Object stateInst = heap.space[machInst.cur];
    Object state = heap.space[stateInst.def];
    Object output = heap.space[state.output];
    for(UUID t <- output.s) {
      Object transition = heap.space[t];
      Object sis = heap.space[machInst.sis];
      if(transition.trigger == trigger) {
        UUID nextState = sis.m[transition.target];
        cmds = [MachInstSetCurState(mi, nextState)];
      }
    }
  }
  if(cmds == []){
    cmds = [MachInstQuiescence(mi)];
  }
  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: StateCreate(UUID s, str name, UUID m)) {  
  list[Command] cmds = [MachAddState(m, s)];
  evt.post = getSMLEvents(cmds);  
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: TransCreate(UUID t, UUID source, str trigger, UUID target)) {
  list[Command] cmds = [StateAddOut(source, t), StateAddIn(target, t)];
  evt.post = getSMLEvents(cmds);  
  return <heap, evt>;
}

public default tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd) = <heap, evt>;