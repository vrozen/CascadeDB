module lang::sml::Generator

import List;
import IO;
import ValueIO;

import lang::delta::Object;
import lang::delta::Effect;
import lang::delta::Operation;

import lang::sml::Command;

tuple[Heap, Event] runGenerate(Heap heap, Event evt) = 
  generate(heap, evt, ValueIO::readTextValueString(#Command, evt.command.name));

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachCreate(UUID m, str name)) {  
  heap = claim(heap, m);
  <states, heap> = getNextId(heap);
  <instances, heap> = getNextId(heap);

  evt.operations = [
    o_new(m, "Mach"),
    o_set(m, "name", name, ""),
    o_new(states, "List[State]"),
    o_set(m, "states", states, 0),
    o_new(instances, "Set[MachInst]"),
    o_set(m, "instances", instances, 0)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachDelete(UUID m, str name)) {
  Object mach = heap.space[m];

  evt.operations = [
    o_set(m, "instances", 0, mach.instances),
    o_delete(mach.instances, "Set[MachInst]"),
    o_set(m, "states", 0, mach.states),
    o_delete(mach.states, "List[State]"),
    o_set(m, "name", "", mach.name),
    o_delete(m, "Mach")
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachAddState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  evt.operations = [l_push(mach.states, s)];
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachRemoveState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  
  //todo: reduce complexity in obtaining list position
  //note: if the patcher inserts the position instead.
  //      it would probably by much easier to generate this code 
  Object states = heap.space[mach.states];
  int pos = indexOf(states.l, s);
  evt.operations = [l_remove(mach.states, pos, s)];
  println("bingo!");
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachAddMachInst(UUID m, UUID mi)) {
  Object mach = heap.space[m];
  evt.operations = [s_add(mach.instances, mi)];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachRemoveMachInst(UUID m, UUID mi)) {
  Object mach = heap.space[m];
  evt.operations = [s_remove(mach.instances, mi)];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateCreate(UUID s, str name, UUID m)) {
  heap = claim(heap, s);
  <input, heap> = getNextId(heap);
  <output, heap> = getNextId(heap);

  evt.operations = [
    o_new(s, "State"),
    o_set(s, "name", name, ""),
    o_new(input, "Set[Trans]"),
    o_set(s, "input", input, 0),
    o_new(output, "Set[Trans]"),
    o_set(s, "output", output, 0)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateDelete(UUID s, str name, UUID m)) {
  Object state = heap.space[s];

  evt.operations = [
    o_set(s, "output", 0, state.output),
    o_delete(state.output, "Set[Trans]"),
    o_set(s, "input", 0, state.input),
    o_delete(state.input, "Set[Trans]"),
    o_set(s, "name", "", state.name),
    o_delete(s, "State")
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateAddIn(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [s_add(state.input, t)];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateRemoveIn(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [s_remove(state.input, t)];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateAddOut(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [s_add(state.output, t)];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateRemoveOut(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [s_remove(state.output, t)];
  evt.typ = t_effect();   
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: TransCreate(UUID t, UUID source, str trigger, UUID target)) {
  heap = claim(heap, t);
  evt.operations = [
    o_new(t, "Trans"),
    o_set(t, "source", source, 0),
    o_set(t, "target", target, 0)
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: TransDelete(UUID t, UUID source, str trigger, UUID target)) {
  evt.operations = [
    o_set(t, "target", 0, target),
    o_set(t, "source", 0, source),
    o_delete(t, "Trans")
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstCreate(UUID mi, UUID def)) {
  heap = claim(heap, mi);
  <sis, heap> = getNextId(heap);

  evt.operations = [
    o_new(mi, "MachInst"),
    o_new(sis, "Map[State,StateInst]"),
    o_set(mi, "sis", sis, 0),
    o_set(mi, "def", def, 0),
    o_set(mi, "cur", 0, 0)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstDelete(UUID mi, UUID def)) {
  Object machInst = heap.space[mi];

  evt.operations = [
    o_set(mi, "def", 0, machInst.def),
    o_set(mi, "cur", 0, machInst.cur),
    o_set(mi, "sis", 0, machInst.sis),
    o_delete(machInst.sis, "Map[State,StateInst]"),
    o_delete(mi, "MachInst")
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstAddStateInst(UUID mi, UUID si, UUID s)) {
  Object machInst = heap.space[mi]; 
  evt.operations = [
    m_insert(machInst.sis, s),
    m_set(machInst.sis, s, si, 0)
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstRemoveStateInst(UUID mi, UUID si, UUID s)) {
  Object machInst = heap.space[mi];
  evt.operations = [
    m_set(machInst.sis, s, 0, si),
    m_remove(machInst.sis, s)
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstInitialize(UUID mi)) {
  //no operations
  evt.typ = t_trigger();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstMissingCurrentState(UUID mi)) {
  //no operations
  evt.typ = t_signal();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstQuiescence(UUID mi)) {
  //no operations
  evt.typ = t_signal();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstSetCurState(UUID mi, UUID cur)) {
  Object machInst = heap.space[mi];
  evt.operations = [o_set(mi, "cur", cur, machInst.cur)];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstTrigger(UUID mi, str trigger)) {
  //no operations
  evt.typ = t_trigger();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateInstCreate(UUID si, UUID def)) {
  //heap = claim(heap, si); (already claimed by postmigrator)
  evt.operations = [
    o_new(si, "StateInst"),
    o_set(si, "def", def, 0),
    o_set(si, "count", 0, 0)
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateInstDelete(UUID si, UUID def)) {
  Object stateInst = heap.space[si];
  evt.operations = [
    o_set(si, "def", 0, stateInst.def),
    o_set(si, "count", 0, stateInst.count),
    o_delete(si, "StateInst")
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateInstSetCount(UUID si, int count, int oldCount)) {
  Object stateInst = heap.space[si];
  if(oldCount != stateInst.count) {
    throw "Expected StateInst old count <statInst.count>, found <oldCount>.";
  }
  evt.operations = [o_set(si, "count", count, stateInst.count)];
  evt.typ = t_effect();
  return <heap, evt>;
}