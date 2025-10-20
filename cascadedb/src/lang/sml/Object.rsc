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
//Object extends delta Object with SML abstractions.
//Note: create was added to ensure all keyword parameters are set.

module lang::sml::Object

import Type;
import Map;
import Set;
import Node;
import String;

import lang::delta::Object;

data Object
  = Mach(str name = "", /*List<State>*/ UUID states = 0, /*Set<MachInst>*/ UUID instances = 0)  // loc src = |unknown:://|)
  | State(str name = "", /*Set<Trans>*/ UUID input = 0, /*Set<Trans>*/ UUID output = 0) // loc src = |unknown:://|)
  | Trans(str evt = "", /*State*/ UUID source = 0, /*State*/ UUID target = 0) //loc src = |unknown:://|)
  | MachInst(/*Mach*/ UUID def = 0, /*StateInst*/ UUID cur = 0, /*Map<State,StateInst>*/ UUID sis = 0) // loc src = |unknown:://|)
  | StateInst(/*State*/ UUID def = 0, int count = 0)
  ;

public Object create(str class) {
  //todo: check class exists
  Object object = make(#Object, class, [], ());
  //Hack: ensure all keyword parameters appear inside the object
  map[str, value] defaultParams = getAllKeywordParameters(object);
  object = make(#Object, class, [], defaultParams);
  return object;
}

public map[str, value] getAllKeywordParameters(node n) {
  map[str, value] params = getKeywordParameters(n); 

  switch(getName(n)){
    case "Mach": {
      if("name" notin params) {
        params = params + ("name": "");
      }
      if("states" notin params) {
        params = params + ("states": 0);
      }
      if("instances" notin params) {
        params = params + ("instances": 0);
      }
    }
    case "State": {
      if("name" notin params) { 
        params = params + ("name": "");
      }
      if("input" notin params) {
        params = params + ("input": 0);
      }
      if("output" notin params) {
        params = params + ("output": 0);
      }
    }
    case "Trans": {
      if("evt" notin params) {
        params = params + ("evt": "");
      }
      if("source" notin params) {
        params = params + ("source": 0);
      }
      if("target" notin params) {
        params = params + ("target": 0);
      }
    }
    case "MachInst": {
      if("def" notin params) {
        params = params + ("def": 0);
      }
      if("cur" notin params) {
        params = params + ("cur": 0);
      }
      if("sis" notin params) {
        params = params + ("sis": 0);
      }
    }
    case "StateInst": {
      if("def" notin params) {
        params = params + ("def": 0);
      }
      if("count" notin params) {
        params = params + ("count": 0);
      }
    }
  }
  return params;
}