module lang::sml::Generator

import List;
import IO;
import ValueIO;

import lang::delta::Operation;
import lang::delta::Object;
import lang::delta::Effect;
import lang::sml::Object;
import lang::sml::Command;

public tuple[Heap, Event] runGenerate(Heap heap, Event evt) = 
  generate(heap, evt, readTextValueString(#Command, evt.command.name));

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachCreate(UUID m, str name)) {  
  heap = claim(heap, m);
  <states, heap> = getNextId(heap);
  <instances, heap> = getNextId(heap);

  evt.operations = [
    o_new(m, "sml.Mach", src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2021,14,<39,6>,<39,20>)),
    o_set(m, "name", name, "", src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2044,13,<40,6>,<40,19>)),
    o_new(states, "List[State]", src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2066,27,<41,6>,<41,33>)),
    o_set(m, "states", states, 0, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2066,27,<41,6>,<41,33>)),
    o_new(instances, "Set[MachInst]", src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2102,33,<42,6>,<42,39>)),
    o_set(m, "instances", instances, 0, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2102,33,<42,6>,<42,39>))
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachDelete(UUID m, str name)) {
  Object mach = heap.space[m];

  evt.operations = [
    o_set(m, "instances", 0, mach.instances, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2221,18,<46,6>,<46,24>)),
    o_delete(mach.instances, "Set[MachInst]", src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2221,18,<46,6>,<46,24>)),
    o_set(m, "states", 0, mach.states, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2248,15,<47,6>,<47,21>)),
    o_delete(mach.states, "List[State]", src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2248,15,<47,6>,<47,21>)),
    o_set(m, "name", "", mach.name, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2272,11,<48,6>,<48,17>)),
    o_delete(m, "sml.Mach", src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2292,8,<49,6>,<49,14>))
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachAddState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  println("<mach>");
  evt.operations = [
    l_push(mach.states, s, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2560,15,<61,6>,<61,21>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachRemoveState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  
  //todo: reduce complexity in obtaining list position
  //note: if the patcher inserts the position instead.
  //      it would be easier to generate this code 
  Object states = heap.space[mach.states];
  int pos = indexOf(states.l, s);
  evt.operations = [
    l_remove(mach.states, pos, s, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2868,18,<73,6>,<73,24>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachAddMachInst(UUID m, UUID mi)) {
  Object mach = heap.space[m];
  evt.operations = [
    s_add(mach.instances, mi, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(3258,19,<89,6>,<89,25>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachRemoveMachInst(UUID m, UUID mi)) {
  Object mach = heap.space[m];
  evt.operations = [
    s_remove(mach.instances, mi, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(3356,22,<92,6>,<92,28>))
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachSetName(UUID m, str name)) {  
  Object mach = heap.space[m];

  evt.operations = [
    o_set(m, "name", name, mach.name)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateCreate(UUID s, str name, UUID m)) {
  heap = claim(heap, s);
  <input, heap> = getNextId(heap);
  <output, heap> = getNextId(heap);

  evt.operations = [
    o_new(s, "sml.State", src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2023,15,<39,6>,<39,21>)),
    o_set(s, "name", name, "", src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2047,13,<40,6>,<40,19>)),
    o_new(input, "Set[Trans]", src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2069,26,<41,6>,<41,32>)),
    o_set(s, "input", input, 0, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2069,26,<41,6>,<41,32>)),
    o_new(output, "Set[Trans]", src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2104,27,<42,6>,<42,33>)),
    o_set(s, "output", output, 0, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2104,27,<42,6>,<42,33>))
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateDelete(UUID s, str name, UUID m)) {
  Object state = heap.space[s];

  evt.operations = [
    o_set(s, "output", 0, state.output, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2265,15,<47,6>,<47,21>)),
    o_delete(state.output, "Set[Trans]", src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2265,15,<47,6>,<47,21>)),
    o_set(s, "input", 0, state.input, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2289,14,<48,6>,<48,20>)),
    o_delete(state.input, "Set[Trans]", src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2289,14,<48,6>,<48,20>)),
    o_set(s, "name", "", state.name, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2312,11,<49,6>,<49,17>)),
    o_delete(s, "sml.State", src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2332,8,<50,6>,<50,14>))
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateAddIn(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [
    s_add(state.input, t, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2667,14,<63,6>,<63,20>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateRemoveIn(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [
    s_remove(state.input, t, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2751,17,<66,6>,<66,23>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateAddOut(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [
    s_add(state.output, t, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2834,15,<70,6>,<70,21>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateRemoveOut(UUID s, UUID t)) {
  Object state = heap.space[s];
  evt.operations = [
    s_remove(state.output, t, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2924,18,<73,6>,<73,24>))
  ];
  evt.typ = t_effect();   
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateSetName(UUID s, str name)) {
  Object state = heap.space[s];

  evt.operations = [
    o_set(s, "name", name, state.name)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: TransCreate(UUID t, UUID source, str evt2, UUID target)) {
  heap = claim(heap, t);
  evt.operations = [
    o_new(t, "sml.Trans", src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2044,15,<39,6>,<39,21>)),
    o_set(t, "source", source, 0, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2068,17,<40,6>,<40,23>)),
    o_set(t, "evt",  evt2, "", src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2092,11,<41,6>,<41,17>)),
    o_set(t, "target", target, 0, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2112,17,<42,6>,<42,23>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: TransDelete(UUID t, UUID source, str evt2, UUID target)) {
  evt.operations = [
    o_set(t, "target", 0, target, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2344,15,<50,6>,<50,21>)),
    o_set(t, "evt", "", evt2, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2368,12,<51,6>,<51,18>)),
    o_set(t, "source", 0, source, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2389,15,<52,6>,<52,21>)),
    o_delete(t, "sml.Trans", src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2413,8,<53,6>,<53,14>))
  ];
  evt.typ = t_effect();  
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: TransSetSource(UUID t, UUID source)) {
  Object trans = heap.space[t];

  evt.operations = [
    o_set(t, "source", source, trans.source)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: TransSetTarget(UUID t, UUID target)) {
  Object trans = heap.space[t];

  evt.operations = [
    o_set(t, "target", target, trans.target)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: TransSetEvent(UUID t, str evt2)) {
  Object trans = heap.space[t];

  evt.operations = [
    o_set(t, "evt", evt2, trans.evt)
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstCreate(UUID mi, UUID def)) {
  heap = claim(heap, mi);
  <sis, heap> = getNextId(heap);

  evt.operations = [
    o_new(mi, "sml.MachInst", src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(1991,19,<39,6>,<39,25>)),
    o_new(sis, "Map[State,StateInst]", src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2018,36,<40,6>,<40,42>)),
    o_set(mi, "sis", sis, 0, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2018,36,<40,6>,<40,42>)),
    o_set(mi, "def", def, 0, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2062,12,<41,6>,<41,18>)),
    o_set(mi, "cur", 0, 0, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2082,13,<42,6>,<42,19>))
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstDelete(UUID mi, UUID def)) {
  Object machInst = heap.space[mi];

  evt.operations = [
    o_set(mi, "cur", 0, machInst.cur, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2402,13,<55,6>,<55,19>)),
    o_set(mi, "def", 0, machInst.def, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2423,13,<56,6>,<56,19>)),
    o_set(mi, "sis", 0, machInst.sis, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2444,13,<57,6>,<57,19>)),
    o_delete(machInst.sis, "Map[State,StateInst]", src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2444,13,<57,6>,<57,19>)),
    o_delete(mi, "sml.MachInst", src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2465,9,<58,6>,<58,15>))
  ];

  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstAddStateInst(UUID mi, UUID si, UUID s)) {
  Object machInst = heap.space[mi]; 
  evt.operations = [
    m_insert(machInst.sis, s, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2791,14,<70,6>,<70,20>)),
    m_set(machInst.sis, s, si, 0, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2791,14,<70,6>,<70,20>))
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: MachInstRemoveStateInst(UUID mi, UUID si, UUID s)) {
  Object machInst = heap.space[mi];
  evt.operations = [
    m_set(machInst.sis, s, 0, si, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2900,16,<74,6>,<74,22>)),
    m_remove(machInst.sis, s, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2900,16,<74,6>,<74,22>))
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
  evt.operations = [
    o_set(mi, "cur", cur, machInst.cur, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(3285,12,<90,6>,<90,18>))
  ];
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
    o_new(si, "sml.StateInst", src = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|(1959,20,<38,6>,<38,26>)),
    o_set(si, "count", 0, 0, src = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|(1987,12,<39,6>,<39,18>)),
    o_set(si, "def", def, 0, src = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|(2007,10,<40,6>,<40,16>))
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateInstDelete(UUID si, UUID def)) {
  Object stateInst = heap.space[si];
  evt.operations = [
    o_set(si, "def", 0, stateInst.def, src = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|(2106,13,<44,6>,<44,19>)),
    o_set(si, "count", 0, stateInst.count, src = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|(2127,12,<45,6>,<45,18>)),
    o_delete(si, "sml.StateInst", src = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|(2147,9,<46,6>,<46,15>))
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}

private tuple[Heap, Event] generate(Heap heap, Event evt, Command cmd: StateInstSetCount(UUID si, int count, int oldCount)) {
  Object stateInst = heap.space[si];
  if(oldCount != stateInst.count) {
    throw "Expected StateInst old count <statInst.count>, found <oldCount>.";
  }
  evt.operations = [
    o_set(si, "count", count, stateInst.count, src = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|(2249,16,<50,6>,<50,22>))
  ];
  evt.typ = t_effect();
  return <heap, evt>;
}