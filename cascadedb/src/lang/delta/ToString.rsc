module lang::delta::ToString

public str toString(Event evt: Trigger(str name, map[str, value] params, list[Event] post)) =
  "trigger <name>(<toString(params)>) { //source <evt.src>
  '  //post events
  '  <for(Event e <- post){>
  '    <toString(e)>
  '  <}>
  '}";

public str toString(Event evt: Signal(str name, map[str, value] params)) =
  "signal <name>(<toString(params)>); //source <evt.src>";

public str toString(Event evt: Effect(str name, map[str, value] params, list[Operation] operations, list[Event] pre, list[Event] post)) =
  "effect <name>(<toString(params)>) { //source <evt.src>
  '  //pre events
  '  <for(Event e <- pre){>
  '    <toString(e)>
  '  <}>
  '  //operations
  '  <for(Operation op <- operations){>
  '    <toString(op)>
  '  <}>
  '  //post events
  '  <for(Event e <- post){>
  '    <toString(e)>
  '  <}>
  '}";

