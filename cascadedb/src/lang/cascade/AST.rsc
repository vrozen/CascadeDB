/******************************************************************************
 * Copyright (c) 2022, Centrum Wiskunde & Informatica (CWI)
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
 *   * Riemer van Rozen - rozen@cwi.nl - CWI
 ******************************************************************************/
/**
 * ASTs express the structure of Cascade programs.
 */
 
module lang::cascade::AST

import IO;
import ParseTree;
import String;

import lang::cascade::Syntax;

data Package
  = package(Using using, Name name, list[Unit] units, loc src = |unknown:///|);

data Using
  = using(list[Name] units, loc src = |unknown:///|);

data Unit
  = evt_class(Vis vis, Imp imp, ID name, Extends extends, list[Attribute] attributes, list[Event] events, loc src = |unknown:///|)
  | class(Vis vis, Imp imp, ID name, Extends extends, list[Attribute] attributes, list[Method] methods, loc src = |unknown:///|)
  | interface(Vis vis, ID name, list[Signature] signatures, loc src = |unknown:///|)
  | enum(Vis vis, ID name, list[ID] values, loc src = |unknown:///|);
  
data Vis
  = vis_default(loc src = |unknown:///|)
  | vis_private(loc src = |unknown:///|)
  | vis_protected(loc src = |unknown:///|)
  | vis_public(loc src = |unknown:///|);

data Imp
  = imp_concrete(loc src = |unknown:///|)
  | imp_abstract(loc src = |unknown:///|);
  
data Extends
  = ext_none(loc src = |unknown:///|)
  | ext_class(list[Name] names, loc src = |unknown:///|);
  
data Store
  = store_dynamic(loc src = |unknown:///|)
  | store_static(loc src = |unknown:///|);
  
data Access
  = a_readwrite(loc src = |unknown:///|)
  | a_readonly(loc src = |unknown:///|);

data Own
  = own_self(loc src = |unknown:///|)
  | own_ref(loc src = |unknown:///|);
  
data Attribute
  = attr(Own own, When when, Vis vis, Store store, Access access, Typ typ, ID name, loc src = |unknown:///|)
  | attr(Own own, When when, Vis vis, Store store, Access access, Typ typ, ID name, Exp val, loc src = |unknown:///|);
  
data Signature
  = signature(Vis vis, Typ rtyp, ID name, list[Param] params, loc src = |unknown:///|);

data Poly
  = poly_none(loc src = |unknown:///|)
  | poly_override(loc src = |unknown:///|);
  
data Method
  = method(Vis vis, Store store, Poly poly, Typ rtyp, ID name, list[Param] params, Body body, loc src = |unknown:///|)
  | abs_method(Vis vis, Poly poly, Typ rtyp, ID name, list[Param] params, loc src = |unknown:///|)
  | constructor(Vis vis, Store store, ID name, list[Param] params, Body body, loc src = |unknown:///|);

data Event
  = effect  (Imp imp, Inverse inverse, bool sideEffect, ID name, list[Param] params, Ops ops, Pre pre, Post post, loc src = |unknown:///|) 
  | trigger (Imp imp, ID name, list[Param] params, TPost tpost, loc src = |unknown:///|)
  | signal  (ID name, list[Param] params, loc src = |unknown:///|)
  | h_method (Vis vis, Store store, Imp imp, Poly poly, Typ rtyp, ID name, list[Param] params, Body body, loc src = |unknown:///|);

data Ops
  = ops_none(loc src = |unknown:///|)
  | ops_body(list[ScriptOperation] ops, loc src = |unknown:///|);

data Inverse
  = inv_none(loc src = |unknown:///|)
  | inv_self(loc src = |unknown:///|)
  | inv_prev(loc src = |unknown:///|);  

//notes:
//1) old values are not included in set operations,
//   these are instead resolved at run time
//2) x_ shorthand operations are rewritten by the specializer
data ScriptOperation
  = o_new    (Name name, Typ typ, loc src = |unknown:///|, Typ typ = t_unknown())   //expands into o_new + o_set
  | o_del    (Name name, loc src = |unknown:///|, Typ typ = t_unknown())            //untyped deletion specializes into deletion with type
  | o_set    (Name name, ID field, Value val, loc src = |unknown:///|, Typ typ = t_unknown())
  | x_assign (Name name, Value val, loc src = |unknown:///|, Typ typ = t_unknown()) //specializes into o_set, l_set or m_add + m_set
  | x_remove (Name name, Value val, loc src = |unknown:///|, Typ typ = t_unknown()) //specializes into l_remove, s_remove or m_set + m_remove
  | l_insert (Name name, Value index, Value val, loc src = |unknown:///|, Typ typ = t_unknown())
  | l_remove (Name name, Value index, loc src = |unknown:///|, Typ typ = t_unknown())
  | l_remove (Name rval, Name name, Value index, loc src = |unknown:///|, Typ typ = t_unknown()) //with return
  | l_set    (Name name, Value index, Value val, loc src = |unknown:///|, Typ typ = t_unknown())
  | l_push   (Name name, Value val, loc src = |unknown:///|, Typ typ = t_unknown())
  | l_pop    (Name name, loc src = |unknown:///|, Typ typ = t_unknown())
  | l_pop    (Name rval, Name name, loc src = |unknown:///|, Typ typ = t_unknown()) //with return
  | m_add    (Name name, Value key, loc src = |unknown:///|, Typ typ = t_unknown())
  | m_remove (Name name, Value key, loc src = |unknown:///|, Typ typ = t_unknown())
  | m_set    (Name name, Value key, Value val, loc src = |unknown:///|, Typ typ = t_unknown())
  | s_add    (Name name, Value val, loc src = |unknown:///|, Typ typ = t_unknown())
  | s_remove (Name name, Value val, loc src = |unknown:///|, Typ typ = t_unknown());

//data MethodParam
//  = m_param(Typ typ, ID name); 

data Param
  = param(When when, Typ typ, ID name, loc src = |unknown:///|)
  | param_change(When when, Typ typ, ID name, Exp val, loc src = |unknown:///|);

data When
  = when_none(loc src = |unknown:///|)
  | when_past(loc src = |unknown:///|)
  | when_future(loc src = |unknown:///|);
  
data Body
  = body_none(loc src = |unknown:///|)
  | body(list[Statement] statements, loc src = |unknown:///|);

data Pre
  = pre_none(loc src = |unknown:///|)
  | pre_body(Body body, loc src = |unknown:///|);
 
data Post
  = post_none(loc src = |unknown:///|)
  | post_body(Body body, loc src = |unknown:///|);
 
data TPost
  = tpost_none(loc src = |unknown:///|)
  | tpost_body(Body body, loc src = |unknown:///|); 
 
data Statement
  = s_call(Name name, list[Exp] operands, loc src = |unknown:///|)
  | s_call_effect(Name name, list[Exp] operands, loc src = |unknown:///|)
  //| s_call_method(Name name, list[Exp] operands)
  | s_declare_assign(Typ typ, ID var, Exp val, loc src = |unknown:///|)
  | s_declare(Typ typ, ID var, loc src = |unknown:///|)
  | s_assign(Name name, Exp val, loc src = |unknown:///|)
  | s_foreach(Typ typ, ID arg, Name name, Body body, loc src = |unknown:///|)
  | s_while(Exp exp, Body body, loc src = |unknown:///|)  
  | s_if(Exp exp, Body tbody, loc src = |unknown:///|)
  | s_if_else(Exp exp, Body tbody, Body fbody, loc src = |unknown:///|)  
  | s_break(loc src = |unknown:///|)
  | s_return(loc src = |unknown:///|)
  | s_return(Exp exp, loc src = |unknown:///|)
  | s_begin(Typ typ, ID var, loc src = |unknown:///|)
  | s_end(Name name, loc src = |unknown:///|)
  | s_comment(str message, loc src = |unknown:///|); //single line comment
    
data Exp
  = e_call(Name name, list[Exp] operands, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_new (Typ typ, list[Exp] operands, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_new (Typ typ, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_cast (Typ typ, Exp exp, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_is(Name name, Typ typ, ID vName, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_val (Value val, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_ovr (Exp exp, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_unm (Exp exp, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_not (Exp exp, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_mul (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_div (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_add (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_sub (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_lt  (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_gt  (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_le  (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_ge  (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_neq (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_eq  (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_and (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown())
  | e_or  (Exp lhs, Exp rhs, loc src = |unknown:///|, Typ typ = t_unknown());

data Value
  = v_unknown(loc src = |unknown:///|, Typ typ = t_unknown())
  | v_true(loc src = |unknown:///|, Typ typ = t_unknown())
  | v_false(loc src = |unknown:///|, Typ typ = t_unknown())
  | v_null(loc src = |unknown:///|, Typ typ = t_unknown())
  | v_int(int ival, loc src = |unknown:///|, Typ typ = t_unknown())
  | v_str(str sval, loc src = |unknown:///|, Typ typ = t_unknown())
  | v_var(Name name, loc src = |unknown:///|, Typ typ = t_unknown())
  | v_enum(ID enum, ID val, loc src = |unknown:///|, Typ typ = t_unknown()) //rewrite v_var into v_enum based on type checking
  | v_array(list[Exp] values, loc src = |unknown:///|, Typ typ = t_unknown());

data Name
  = name(ID head, list[Path] path, loc src = |unknown:///|, Typ typ = t_unknown())
  | name(ID head, loc src = |unknown:///|, Typ typ = t_unknown());

data Path
  = p_field(ID field, loc src = |unknown:///|, Typ typ = t_unknown())
  | p_lookup(Value key, loc src = |unknown:///|, Typ typ = t_unknown());

data Typ
  = t_unknown(loc src = |unknown:///|)
  | t_error(loc src = |unknown:///|)
  | t_int(loc src = |unknown:///|)
  | t_str(loc src = |unknown:///|)
  | t_bool(loc src = |unknown:///|)
  | t_void(loc src = |unknown:///|)
  | t_meta(Typ typ, loc src = |unknown:///|)
  | t_classN(ID name, loc src = |unknown:///|)
  | t_class(Name n, loc src = |unknown:///|) //for disambiguation of generated code
  | t_enum(ID name, loc src = |unknown:///|) //rewrite t_class into t_enum based on type checking
  | t_array(ID name, loc src = |unknown:///|)
  | t_list(Typ typ, loc src = |unknown:///|)
  | t_set(Typ typ, loc src = |unknown:///|)
  | t_map(Typ ktyp, Typ vtyp, loc src = |unknown:///|);

data ID
  = id(str val, loc src = |unknown:///|);
  
public Package cascade_implode(loc file)
  = implode(#Package, cascade_parse(file));