#Stepping functions and when to use them.

# Stepping in XQuery #

Stepping is definitely one of the most confusing parts of debugging a functional language like XQuery.  Stepping in XQuery is by expression, not lines of code as you would in Java or C#.  If you keep this in mind it will begin to make some sense.

# Descriptions of the stepping functions #

**Step:**
_Step_ will step into a sub-expression or to the end of the current expression.  This is the preferred method of stepping unless you know one of the other methods make more sense.

**Step Out:**
_Step Out_ will step to the end of the current expression… If you look at the stack frame you will see what the current expression is and can gauge where you will step to.  In my code, the current FLOWR expression can sometimes be the entire module.  So use _Step_ to drill down into sub expressions and then _Step Out_ to wind your way back out.  But keep in mind that if you are at the end of the last sub-expression of a parent expression you will _Step Out_ to the end of the parent of all sub expressions that are at their end, which may be the end of your module.

**Next Statement:**
Statements are import, declare and FLOWR statements ... anything that ends with a semicolon.  Think of Next Statement as “I want to jump to the statement after the next semicolon.”

**Step Function:**
_Step Function_ steps to the end of the current function.  If you are not in a function execution will continue until the request completes execution.

**Help in XQDebug 1.0.2**
[Revision 1](https://code.google.com/p/xqdebug/source/detail?r=1).0.2 added some hover tips that should help.  If you hover over the _Step_ link a popup description will say "Step to the beginning or end of current expression." _Step Out_ says something like "Continue evaluation to the End of the Current Expression." Next Statement ...