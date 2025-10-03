module lang::delta::Operation

import lang::delta::Object;

data Operation
  = o_new    (UUID id, str class, int pc = 0, loc src = |unknown:///|)
  | o_delete (UUID id, str class, int pc = 0, loc src = |unknown:///|)
  | o_rekey  (UUID id, UUID new_id, int pc = 0, loc src = |unknown:///|)  
  | o_set    (UUID id, str field, value new_val, value old_val, int pc = 0, loc src = |unknown:///|)
  | l_insert (UUID id, int pos, value val, int pc = 0, loc src = |unknown:///|)
  | l_remove (UUID id, int pos, value val, int pc = 0, loc src = |unknown:///|)
  | l_push   (UUID id, value val, int pc = 0, loc src = |unknown:///|)
  | l_pop    (UUID id, value val, int pc = 0, loc src = |unknown:///|)
  | s_add    (UUID id, value val, int pc = 0, loc src = |unknown:///|)
  | s_remove (UUID id, value val, int pc = 0, loc src = |unknown:///|)
  | m_insert (UUID id, value key, int pc = 0, loc src = |unknown:///|)
  | m_remove (UUID id, value key, int pc = 0, loc src = |unknown:///|)
  | m_set    (UUID id, value key, value new_val, value old_val, int pc = 0, loc src = |unknown:///|)
  ;

/*data OpState = generated() | committed();*/