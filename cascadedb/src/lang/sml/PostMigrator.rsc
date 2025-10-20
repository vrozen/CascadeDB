/******************************************************************************
 * Copyright (c) 2025, Riemer van Rozen,
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Contributors:
 *   * Riemer van Rozen
 ******************************************************************************/
//The PostMigrator schedules commands/events after an SML event.

module lang::sml::PostMigrator

import ValueIO;
import Map;
import List;
import String;
import lang::delta::Object;
import lang::delta::Effect;
import lang::sml::Object;
import lang::sml::Command;

public tuple[Heap, Event] runPostMigrate(Heap heap, Event evt) = 
  postMigrate(heap, evt, readTextValueString(#Command, evt.command.name));

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachAddState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  Object instances = heap.space[mach.instances];
  list[Command] cmds = [];

  for(UUID mi <- instances.s) {
    <si, heap> = getNextId(heap);
    cmds = cmds + [
      StateInstCreate(si, s, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2679,24,<66,8>,<66,32>)),
      MachInstAddStateInst(mi, si, s, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2713,33,<67,8>,<67,41>)),
      MachInstInitialize(mi, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(2756,24,<68,8>,<68,32>))
    ];
  }

  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachRemoveState(UUID m, UUID s)) {
  Object mach = heap.space[m];
  Object instances = heap.space[mach.instances];
  list[Command] cmds = [];
  for(UUID mi <- instances.s) {
    cmds = cmds + [
      MachInstInitialize(mi, src = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|(3148,24,<84,8>,<84,32>))
    ];
  }
  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: StateCreate(UUID s, str name, UUID m)) {  
  list[Command] cmds = [MachAddState(m, s, src = |cwd://cascadedb/models/TinyLiveSML/State.cml|(2158,20,<44,11>,<44,31>))];
  evt.post = getSMLEvents(cmds);  
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: TransCreate(UUID t, UUID source, str trigger, UUID target)) {
  list[Command] cmds = [
    StateAddOut(source, t, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2155,24,<45,6>,<45,30>)),
    StateAddIn(target, t, src = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|(2187,23,<46,6>,<46,29>))
  ];
  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachInstCreate(UUID mi, UUID def)) {
  Object machInst = heap.space[mi];
  Object mach = heap.space[machInst.def];
  Object states = heap.space[mach.states];
  list[Command] cmds = [
    MachAddMachInst(machInst.def, mi, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2120,29,<45,6>,<45,35>))
  ];

  for(UUID s <- states.l) {
    <si, heap> = getNextId(heap);
    cmds = cmds + [
      StateInstCreate(si, s, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2230,24,<48,8>,<48,32>)),
      MachInstAddStateInst(mi, si, s, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2263,24,<49,8>,<49,32>))
    ];
  }

  cmds = cmds + [
    MachInstInitialize(mi, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(2306,15,<51,6>,<51,21>))
  ];

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
    cmds = [
      MachInstSetCurState(mi, si, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(3156,27,<85,8>,<85,35>))
    ];
  }

  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachInstSetCurState(UUID mi, UUID cur)) {
  list[Command] cmds = [];  
  if(cur != 0) { 
    Object stateInst = heap.space[cur];
    cmds = [
      StateInstSetCount(cur, stateInst.count + 1, stateInst.count, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(3351,45,<94,8>,<94,53>))
    ];
  }

  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

private tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd: MachInstTrigger(UUID mi, str evt2)) {
  Object machInst = heap.space[mi];
  list[Command] cmds = [];
  if(machInst.cur == 0){ 
    cmds = [
      MachInstMissingCurrentState(mi, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(3494,24,<100,8>,<100,32>))
    ];
  } else {
    Object stateInst = heap.space[machInst.cur];
    Object state = heap.space[stateInst.def];
    Object output = heap.space[state.output];
    for(UUID t <- output.s) {
      Object transition = heap.space[t];
      Object sis = heap.space[machInst.sis];
      if(transition.evt == evt2) {
        UUID nextState = toInt("<sis.m[transition.target]>");
        cmds = [
          MachInstSetCurState(mi, nextState, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(3676,27,<106,10>,<106,37>))
        ];
      }
    }
  }
  if(cmds == []){
    cmds = [MachInstQuiescence(mi, src = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|(3746,15,<110,6>,<110,21>))];
  }
  evt.post = getSMLEvents(cmds);
  return <heap, evt>;
}

public default tuple[Heap, Event] postMigrate(Heap heap, Event evt, Command cmd) = <heap, evt>;