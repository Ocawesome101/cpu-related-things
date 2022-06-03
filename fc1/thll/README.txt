// THLL

THLL is the Terrible High-Level Language.  It uses a somewhat C-like syntax and an entirely custom compiler written in Lua.  Currently it does no optimization.

THLL in its current form could probably run on a machine with two registers - none of its generated code uses more than that.  It's pretty stack-heavy, though.

I may implement a THLL-to-Lua transpiler.  Or, perhaps, THLL-to-C, since they're very similar.

The eventual goal is to get THLL to the point where I can implement a THLL compiler in THLL.

A syntax highlighter for Vim is included in 'syntax/'.  Some code examples are included under 'examples/'.
