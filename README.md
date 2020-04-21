# PaloAlto BASIC in Ruby less then in 500 lines
__PaloAlto BASIC__ (also known as __Tiny BASIC__) interpreter less than in 500 lines writen in Ruby.
The original program takes only 3KB of ROM and runs on Intel 8080, Motorola 6800 and MOS Technology 6502 processors.

This BASIC understands a few statements and all variables there are 16 or 32-bit integers.

[Take a look on Wikipedia page](https://en.wikipedia.org/wiki/Tiny_BASIC).

# Just take a look on some __code examples__

__Print statement__: `PRINT "HELLO WORLD"`, `PRINT A` or `PRINT "X: ", X, ", Y: ", Y, ", Z: ", Z`

__Input staement__: `INPUT A`, or you can use list of variables: `INPUT A, B, C`

__Variable defenition/assigment__: `LET A = 10`, `LET B = (2 + 6) * 4` or `LET C = (A * B) + (B / A) - 1`

__Goto__: `10 GOTO 10` is endless cycle. `GOTO A * 10 + 230` is also possible.

__If__: `IF A = B THEN PRINT "EQUALITY"`, `IF A > B * 2 THEN LET C = C + (B - A)` or `IF A <> B THEN PRINT "UNEQUALITY"`

__GoSub__: `10  IF A = 1 THEN GOSUB 50` ... `50  LET X = X * X` ... `60  RETURN`

>__*Important Note*__: To run the program just type in `RUN` and hit `<Enter>`!


# EBNF Grammer

The grammer is also pretty simple and can be described in EBNF just in a very few lines:


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

__statement__ ::= (_PRINT_ __expression-list__)
                  | (_INPUT_ __var-list__)
                  | (_LET_ __var__ _=_ __expression__)
                  | (_GOTO_ __expression__)
                  | (_GOSUB_ __expression__)
                  | (_RETURN_)
                  | (_IF_ __expression__ __relational-operator__ __expression__ _THEN_ __statement__)
                  | (_END_)

__line__  ::= ((__number__ __statement__) | (__statement__)) CR


---


To __run the programm__ just download _paloaltobasic.rb_ and run it using `ruby paloaltobasic.rb`. Program works stable on Ruby version __2.6__.

>__Attention!__ Program works unstable under *GIT Bash*. Try using some other terminal (ex. *Windows __CMD__*)


---


Contact me via e-mail `kuznetsovsa_user@protonmail.com`.
