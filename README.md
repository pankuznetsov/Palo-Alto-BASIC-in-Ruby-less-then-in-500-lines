# PaloAlto BASIC in Ruby less then in 500 lines
PaloAlto BASIC (also known as Tiny BASIC) interpreter less than in 500 lines.
The original program takes only 3KB or ROM and runs on Intel 8080, Motorola 6800 and MOS Technology 6502 processors.

This BASIC understands a few statements and all variables there are 16 or 32-bit integers.

[Take a look on Wikipedia page](https://en.wikipedia.org/wiki/Tiny_BASIC).

The grammer is also very simple and can be described in ABNF just in a few lines:


CR  _stands for Carret Return (`\r\n` or `\n`, depends on OS)_

__empty__ _stands for nothing._

__space__ _stands for any white space _ASCII_ symbol._

(__...__)*  _means that ... may be repeated zero or more times._


__digit__ ::= _0_ | _1_ | _2_ | _3_ | _4_ | _5_ | _6_ | _7_ | _8_ | _9_

__lowercase__ ::= _a_ | _b_ | _c_ ... _x_ | _y_ | _z_

__uppercase__ ::= _A_ | _B_ | _C_ ... _X_ | _Y_ | _Z_

__letter__  ::= __lowercase__ | __uppercase__

__number__  ::= __digit__ (__digit__)*

__string__  ::= _"_ (__letter__ | __digit__ | __space__)* _"_

__var__ ::= __uppercase__

__var-list__  ::= __var__ (_,_ __var__)*

__factor__  ::= __var__ | __number__ | _(_ __expression__ _)_

__term__  ::= __factor__ ((_*_ | _/_) __factor__)*

__expression__  ::= (_+_ | _-_ | __empty__) __term__ ((_+_ | _-_) __term__)*

__expression-list__ ::= (__expression__ | __string__) (_,_ __expression__ | __string__)*

__ralational-operator__ ::= (_<_ (_>_ | _=_ | __empty__)) | (_>_ (_<_ | _=_ | __empty__)) | _=_

__statement__ ::= _PRINT_ __expression-list__
                  | _INPUT_ __var-list__ 
                  | _LET_ __var__ _=_ __expression__
                  | _GOTO_ __expression__
                  | _GOSUB_ __expression__
                  | _RETURN_
                  | _IF_ __expression__ __relational-operator__ _THEN_ __statement__
                  | _END_

__line__  ::= (__number__ __statement__) | (__statement__) CR
