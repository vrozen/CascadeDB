module lang::delta::Effect

import lang::delta::Object;
import lang::delta::Operation;

alias Component = tuple[Heap, Event] (Heap heap, Event evt);

data Language = language(str language, Component preMigrate, Component postMigrate, Component generate);

data Event = event(ID language, ID command, EventType typ, ID target, list[Operation] operations, list[Event] pre, list[Event] post);

data EventType
  = t_unknown()
  | t_trigger()
  | t_signal()
  | t_effect()
  ;

data ID = id(str name, loc src = |loc:///unknown|);
