module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

// HTML part

HTML5Node form2html(AForm f) {
  return html(
    head(
      title("QL")
    ),
    body(
      div(
        id("app"), 
        questions2html(f.questions)
      ),
      script(src("https://cdn.jsdelivr.net/npm/vue")),
      script(src(f.src[extension="js"].file))
    )
  );
}

HTML5Node questions2html(list[AQuestion] questions) {
  return div(
    div([question2html(question) | question <- questions])
  );
}

HTML5Node question2html(AQuestion question) {
  switch (question) {
    case question(str label, str id, AType typeName): 
      return div(
        p(label),
        input(html5attr("v-model", id), \type(type2htmlStr(typeName)))
      );
    case computedQuestion(str label, str id, AType typeName, AExpr expression): 
      return div(
        p(label),
        input(html5attr("v-model", id), \type(type2htmlStr(typeName)), readonly([]))
      );
    case ifThen(AExpr expression, list[AQuestion] questions):
      return template(
        html5attr("v-if", "if_<expression.src.begin.line>_<expression.src.begin.column>"),
        questions2html(questions)
      );
    case ifThenElse(AExpr expression, list[AQuestion] questions1, list[AQuestion] questions2):
      return div(
        template(
          html5attr("v-if", "if_<expression.src.begin.line>_<expression.src.begin.column>"),
          questions2html(questions1)
        ),
        template(
          html5attr("v-else"),
          questions2html(questions2)
        )
      );
  }
}

str type2htmlStr(AType typeName) {
  switch (typeName) {
    case boolean(): return "checkbox";
    case integer(): return "number";
    case string(): return "text";
  }
}

// JS part

str form2js(AForm f) {
  return "var app = new Vue({
  	     '  el: \'#app\',
  	     '  data: {
  	     '    <for (/AQuestion question := f.questions) {>
  	     '      <if (question has id && !(question has expression)) {>
  	     '        <question.id>: <defaultValue(question.typeName)>,
  	     '      <}>
  	     '    <}>
  	     '  },
  	     '  computed: {
  	     '    <for (/AQuestion question := f.questions) {>
  	     '      <if (question has id && question has expression) {>
  	     '        <question.id>: function() {
  	     '          return <expr2js(question.expression)>;
  	     '        },
  	     '      <}>
  	     '    <}>
  	     '    <for (/AQuestion question := f.questions) {>
  	     '      <if (!(question has id) && question has expression) {>
  	     '        if_<question.expression.src.begin.line>_<question.expression.src.begin.column>: function() {
  	     '          return <expr2js(question.expression)>;
  	     '        },
  	     '      <}>
  	     '    <}>
  	     '  }
  	     '});";
}

str defaultValue(AType typeName) {
  switch (typeName) {
    case boolean(): return "false";
    case integer(): return "0";
    case string(): return "\"\"";
  }
}

str expr2js(AExpr expression) {
  switch (expression) {
    case ref(str name):
      return "this.<name>";
    case boolean(bool b):
      return "<b>";
    case integer(int i):
      return "<i>";
    case string(str s):
      return "<s>";
    case not(AExpr ex):
      return "!<expr2js(ex)>";
    case parentheses(AExpr ex):
      return "(" + expr2js(ex) + ")";
    case multiply(AExpr a, AExpr b):
      return "(<expr2js(a)> * <expr2js(b)>)";
    case divide(AExpr a, AExpr b):
      return "(<expr2js(a)> / <expr2js(b)>)";
    case add(AExpr a, AExpr b):
      return "(<expr2js(a)> + <expr2js(b)>)";
    case subtract(AExpr a, AExpr b):
      return "(<expr2js(a)> - <expr2js(b)>)";
    case greater(AExpr a, AExpr b):
      return "(<expr2js(a)> \> <expr2js(b)>)";
    case less(AExpr a, AExpr b):
      return "(<expr2js(a)> \< <expr2js(b)>)";
    case greaterEqual(AExpr a, AExpr b):
      return "(<expr2js(a)> \>= <expr2js(b)>)";
    case lessEqual(AExpr a, AExpr b):
      return "(<expr2js(a)> \<= <expr2js(b)>)";
    case equal(AExpr a, AExpr b):
      return "(<expr2js(a)> = <expr2js(b)>)";
    case notEqual(AExpr a, AExpr b):
      return "(<expr2js(a)> != <expr2js(b)>)";
    case or(AExpr a, AExpr b):
      return "(<expr2js(a)> || <expr2js(b)>)";
    case and(AExpr a, AExpr b):
      return "(<expr2js(a)> && <expr2js(b)>)";
  }
}
