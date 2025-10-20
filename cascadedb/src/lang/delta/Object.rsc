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
//Base objects are List, Set and Map.
//Note: extend Object for each DSL.

module lang::delta::Object

import Type;
import Map;
import Set;
import Node;
import String;

public alias UUID = int;

public data Heap = heap(UUID cur_id = 0, map[UUID, Object] space = ());

//todo: separate DSL objects from base types
data Object
  = null()
  | List(str class, list[value] l) // loc src = |unknown:://|)
  | Set(str class, set[value] s) //loc src = |unknown:://|)
  | Map(str class, map[value, value] m) //loc src = |unknown:://|)
  ;

public Object create(str class) {
  //todo: check class exists
  //todo: create objects in a more generic manner
  if(startsWith(class, "List")) {
    return List(class, []);
  } else if(startsWith(class, "Set")) {
    return Set(class, {});
  } else if(startsWith(class, "Map")) {
    return Map(class, ());
  }
  throw "Delta cannot create object <class>, expected List, Set or Map.";
}

public Heap claim(Heap heap, UUID id) {
  if(id > heap.cur_id){
    heap.cur_id = id;
  } else {
    throw "Error claiming <id>. Current id <heap.cur_id>.";
  }
  return heap;
}

//Returns the first unused object id.
//Note: make sure to use it only once in object creations.
//Note: works for the editor because object creations are mutually exclusive.
public tuple[UUID, Heap] getNextId(Heap heap) {
  set[UUID] keys = domain(heap.space) + {heap.cur_id};
  UUID id = max(keys)+1;
  heap.cur_id = id;
  return <id, heap>;
}