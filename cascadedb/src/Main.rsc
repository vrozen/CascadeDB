module Main

import lang::cascade::IDE;
import lang::cascade::AST;
import lang::cascade::Printer;

import lang::delta::Language;
import lang::delta::Object;
import lang::delta::Engine;
import lang::delta::Effect;
import lang::delta::Debugger;

import IO;
import Node;
import lang::sml::Language;
import lang::sml::PrettyPrinter;

public str myEditScript1 = 
  "sml.MachCreate(1, \"doors\")
  'sml.StateCreate(4, \"closed\", 1)
  'sml.MachInstCreate(7, 1)
  'sml.StateCreate(10, \"opened\", 1)
  'sml.StateCreate(14, \"locked\", 1)
  'sml.TransCreate(18, 4, \"open\", 10)
  'sml.TransCreate(19, 10, \"close\", 4)
  'sml.TransCreate(20, 4, \"lock\", 14)
  'sml.TransCreate(21, 14, \"unlock\", 4)
  'sml.MachInstTrigger(7, \"lock\")
  'sml.StateDelete(14, \"locked\", 1)
  'sml.MachDelete(1, \"doors\")";

void testRewind(){
  map[str, Language] languages = ("sml": SML_Language);
  Heap heap = heap(cur_id=0, space=());
  <heap, thepast> = lang::delta::Engine::run(languages, heap, myEditScript1);
  print(heap); //heap is built

  Debugger db = debugger(heap, thepast, [], done());
  db = rewind(db);
  print(db.heap); //heap is emptied

  db = play(db);
  println(db.heap); //heap rebuilt

  println(prettyPrintMachines(heap));
  println(prettyPrintMachineInstances(heap));
}


void getLocsManually(){
  loc MachLoc = |cwd://cascadedb/models/TinyLiveSML/Mach.cml|;
  loc StateLoc = |cwd://cascadedb/models/TinyLiveSML/State.cml|;
  loc TransLoc = |cwd://cascadedb/models/TinyLiveSML/Trans.cml|;
  loc MachInstLoc = |cwd://cascadedb/models/TinyLiveSML/MachInst.cml|;
  loc StateInstLoc = |cwd://cascadedb/models/TinyLiveSML/StateInst.cml|;

  Package p = cascade_implode(StateInstLoc);

  str prog = prettyPrint(p);

  println(prog);
}

int main() {
  lang::cascade::IDE::register();
  testRewind();
  //getLocsManually();
  return 0;
}