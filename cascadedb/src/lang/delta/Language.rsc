module lang::delta::Language

import lang::delta::Object;
import lang::delta::Effect;

data Language = language(str language,
  Component preMigrate,
  Component postMigrate,
  Component generate,
  Create create);

alias Component = tuple[Heap, Event] (Heap heap, Event evt);

alias Create = Object (str class);