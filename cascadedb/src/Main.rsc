module Main

import lang::cascade::IDE;
import lang::delta::Language;
import lang::delta::Object;
import lang::delta::Engine;
import lang::delta::Effect;
import lang::delta::Debugger;

import IO;
import Node;
import lang::sml::Language;

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
  'sml.StateDelete(14, \"locked\", 1)";
  //'sml.MachDelete(1, \"doors\")";

int main() {
  lang::cascade::IDE::register();
  map[str, Language] languages = ("sml": SML_Language);
  Heap heap = heap(cur_id=0, space=());
  <heap, thepast> = lang::delta::Engine::run(languages, heap, myEditScript1);
  print(heap); //heap is built

  Debugger db = debugger(heap, thepast, [], done());
  db = rewind(db);
  print(db.heap); //heap is emptied

  db = play(db);
  print(db.heap); //heap rebuilt

  return 0;
}