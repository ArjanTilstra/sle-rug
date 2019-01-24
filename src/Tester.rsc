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

start[Form] parseTest(loc filename) {
  return parse(#start[Form], filename);
}

AForm cst2astTest(loc filename) {
  return cst2ast(parseTest(filename));
}

UseDef resolveTest(loc filename) {
  return resolve(cst2astTest(filename));
}

set[Message] checkTest(loc filename) {
  ast = cst2astTest(filename);
  TEnv tenv = collect(ast);
  UseDef useDef = resolve(ast);
  return check(ast, tenv, useDef);
}

VEnv evalTest(loc filename) {
  ast = cst2astTest(filename);
  VEnv venv = initialEnv(ast);
  list[Input] input = [
    input("hasBoughtHouse", vbool(true)),
    input("hasMaintLoan", vbool(false)),
    input("hasSoldHouse", vbool(true)),
    input("sellingPrice", vint(20)),
    input("privateDebt", vint(10))
  ];
  
  for (Input inp <- input) {
    venv = eval(ast, inp, venv);
  }
  return venv;
}

void compileTest(loc filename) {
  ast = cst2astTest(filename);
  compile(ast);
}

AForm flattenTest(loc filename) {
  return flatten(cst2astTest(filename));
}

start[Form] renameTest() {
  concrete = parse(#start[Form], |project://QL/examples/tax.myql|);
  abstract = cst2ast(concrete);
  useDef = resolve(abstract);
  return rename(concrete, |project://QL/examples/tax.myql|(466,12,<20,30>,<20,42>), "testName", useDef);
}