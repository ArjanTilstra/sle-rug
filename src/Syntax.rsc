module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

syntax Question
  = Str Id ":" Type // Normal question
  | Str Id ":" Type "=" Expr // Computed question
  | "{" Question* "}" // Block of questions
  | "if" "(" Expr ")" "{" Question* "}" // If-then construction
  | "if" "(" Expr ")" "{" Question* "}" "else" "{" Question* "}"; // If-then-else construction

// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Bool
  | Int
  | Str
  | "(" Expr ")"
  > "!" Expr
  > left ( Expr "*" Expr
  		 | Expr "/" Expr)
  > left ( Expr "+" Expr
  	     | Expr "-" Expr)
  > non-assoc ( Expr "\>" Expr
  			  | Expr "\<" Expr
  			  | Expr "\>=" Expr
  			  | Expr "\<=" Expr)
  > left ( Expr "==" Expr
  		 | Expr "!=" Expr)
  > left Expr "&&" Expr
  > left Expr "||" Expr;
  
syntax Type
  = "string"
  | "integer"
  | "boolean";  
  
lexical Str = "\"" ![\"]* "\"";

lexical Int 
  = [\-]?[1-9][0-9]*
  | [0];

lexical Bool 
  = "true" 
  | "false";



