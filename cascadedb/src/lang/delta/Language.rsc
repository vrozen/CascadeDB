module lang::delta::Language

import lang::delta::Object;
import lang::delta::Effect;

data Language = language(str name,
  Component preMigrate,
  Component postMigrate,
  Component generate,
  Create create);
  //Printer print

alias Component = tuple[Heap, Event] (Heap heap, Event evt);

alias Create = Object (str class);

alias Printer = str (Object obj);

//alias Editor = ...some salix type ();
