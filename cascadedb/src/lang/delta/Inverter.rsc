module lang::delta::Inverter

import lang::delta::Object;
import lang::delta::Operation;

public Operation invert(Operation op: o_new(UUID id, str class)) =
  o_delete(id, class)[src = op.src][pc = op.pc];

public Operation invert(Operation op: o_delete(UUID id, str class)) =
  o_new(id, class)[src = op.src][pc = op.pc];

public Operation invert(Operation op: o_rekey(UUID id, UUID new_id)) =
  o_rekey(new_id, id)[src = op.src][pc = op.pc];

public Operation invert(Operation op: o_set(UUID id, str field, value new_val, value old_val)) =
  o_set(id, field, old_val, new_val)[src = op.src][pc = op.pc];

public Operation invert(Operation op: l_insert(UUID id, int pos, value val)) =
  l_remove(id, pos, val)[src = op.src][pc = op.pc];

public Operation invert(Operation op: l_remove(UUID id, int pos, value val)) =
  l_insert(id, pos, val)[src = op.src][pc = op.pc];

public Operation invert(Operation op: l_push(UUID id, value val)) =
  l_pop(id, val)[src = op.src][pc = op.pc];

public Operation invert(Operation op: l_pop(UUID id, value val)) =
  l_push(id, val)[src = op.src][pc = op.pc];

public Operation invert(Operation op: s_add(UUID id, value val)) =
  s_remove(id, val)[src = op.src][pc = op.pc];

public Operation invert(Operation op: s_remove(UUID id, value val)) =
  s_add(id, val)[src = op.src][pc = op.pc];

public Operation invert(Operation op: m_insert(UUID id, value key)) =
  m_remove(id, key)[src = op.src][pc = op.pc];

public Operation invert(Operation op: m_remove(UUID id, value key)) =
  m_insert(id, key)[src = op.src][pc = op.pc];

public Operation invert(Operation op: m_set(UUID id, value key, value new_val, value old_val)) =
  m_set(id, key, old_val, new_val)[src = op.src][pc = op.pc];