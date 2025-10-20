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
//The PrettyPrinter generates textual SML representations.

module lang::sml::PrettyPrinter

import lang::delta::Object;
import lang::sml::Object;

public str prettyPrint(Heap heap, UUID id) = print(heap, id);

public str prettyPrintMachines(Heap heap) =
  "<for(UUID id <- heap.space){><if(Mach() := heap.space[id]){><print(heap, id)><}><}>";

public str prettyPrintMachineInstances(Heap heap) =
  "<for(UUID id <- heap.space){><if(MachInst() := heap.space[id]){><print(heap,id)><}><}>";

private str print(Heap heap, UUID id){
  str out = "";
  if(id in heap.space){
    out = print(heap, heap.space[id]);
  }
  return out;
}

private str print(Heap heap, Object m: Mach()) =
  "machine <m.name> {<if(m.states!=0){><for(UUID state <- heap.space[m.states].l){>
  '  <print(heap, state)><}><}>
  '}";

private str print(Heap heap, Object s: State()) =
  "state <s.name> {<for(UUID out <- heap.space[s.output].s){>
  '  <print(heap, out)><}>
  '}";

private str print(Heap heap, Object t: Trans()) = 
  "<t.evt> -\> <heap.space[t.target].name>";

private str print(Heap heap, Object mi: MachInst()){
  str buttons = "";
  str stateInstances = "";
  str name = "";
  if(mi.cur != 0) {
    Object cur = heap.space[mi.cur];
    if(cur.def != 0) {
      Object curDef = heap.space[cur.def];
      buttons = printButtons(heap, curDef);
    }
  }

  if(mi.def != 0) {
    Object m = heap.space[mi.def];
    name = m.name;
    if(m.states != 0) {
      Object states = heap.space[m.states];
      if(mi.sis != 0) {
        Object sis = heap.space[mi.sis];
        for(UUID s <- states.l){
          if(s !=0 && s in sis.m){
            str thisInstance = print(heap, sis.m[s]);
            if(thisInstance != "" && mi.cur==sis.m[s]){
              thisInstance = thisInstance + " *";
            }
            stateInstances = stateInstances + thisInstance + "\n";
          }
        }
      }
    }
  }
  return
    "machine <name>
    '  <buttons>
    '  <stateInstances>
    ";
}

private str printButtons(Heap heap, Object s: State()) = //row of "buttons" active in the current state
  "<for(UUID t <- heap.space[s.output].s){>[ <heap.space[t].evt> ] <}>";

private str print(Heap heap, Object si: StateInst()) =
  "state <heap.space[si.def].name> = <si.count>";