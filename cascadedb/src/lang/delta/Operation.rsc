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
//Edit operations define changes to objects, lists, sets and maps.

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