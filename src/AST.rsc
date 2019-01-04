module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 
  
data AQuestion(loc src = |tmp:///|)
  = question(str label, str id, AType typeName)
  | computedQuestion(str label, str id, AType typeName, AExpr expression)
  | ifThen(AExpr expression, list[AQuestion] questions)
  | ifThenElse(AExpr expression, list[AQuestion] questions1, list[AQuestion] questions2)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | boolean(bool b)
  | integer(int i)
  | string(str s)
  | not(AExpr expression)
  | parentheses(AExpr expression)
  | multiply(AExpr a, AExpr b)
  | divide(AExpr a, AExpr b)
  | add(AExpr a, AExpr b)
  | subtract(AExpr a, AExpr b)
  | greater(AExpr a, AExpr b)
  | less(AExpr a, AExpr b)
  | greaterEqual(AExpr a, AExpr b)
  | lessEqual(AExpr a, AExpr b)
  | equal(AExpr a, AExpr b)
  | notEqual(AExpr a, AExpr b)
  | and(AExpr a, AExpr b)
  | or(AExpr a, AExpr b)
  ;

data AType(loc src = |tmp:///|)
  = boolean()
  | integer()
  | string();
