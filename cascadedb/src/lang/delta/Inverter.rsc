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
//The Inverter inverts edit operations for obtaining inverse effects.

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