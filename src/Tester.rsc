module Tester

import Syntax;
import AST;
import CST2AST;
import Check;
import Resolve;
import Eval;
import Compile;
import Transform;
import ParseTree;
import Message;

AForm tester() {
  concrete = parse(#start[Form], |project://QL/examples/tax.myql|);
  
  abstract = cst2ast(concrete);
  
  tenv = collect(abstract);
  useDef = resolve(abstract);
  
  set[Message] messages = check(abstract, tenv, useDef);
  
  venv = eval(abstract, input("hasSoldHouse", vbool(true)), initialEnv(abstract));
  
  compile(abstract);
  return abstract;
}