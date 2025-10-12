module lang::sml::PrettyPrinter

import lang::delta::Object;
import lang::sml::Object;

//The pretty printer generates textual SML representations

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