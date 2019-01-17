module Transform

import Syntax;
import Resolve;
import AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  return form(f.name, flatten(f.questions, boolean(true)));
}

list[AQuestion] flatten(list[AQuestion] questions, AExpr expression) {
  list[AQuestion] transformedQuestions = [];
  for (/AQuestion question := questions) {
    transformedQuestions += flatten(question, expression);
  }
  return transformedQuestions;
}

list[AQuestion] flatten(AQuestion question, AExpr expression) {
  switch (question) {
    case ifThen(AExpr condition, list[AQuestion] questions):
      return flatten(question, and(expression, condition));
    case ifThenElse(AExpr condition, list[AQuestion] questions1, list[AQuestion] questions2):
      return flatten(questions1, and(expression, condition)) + flatten(questions2, and(expression, not(condition)));
    default: 
      return [ifThen(expression, [question])];
  }
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 
 
 
 

