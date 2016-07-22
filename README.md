# ponycli
Ponylang cli package

## The Rules

First some terminology to avoid confusion.
The command line arguments are split (by the shell) into an array of tokens. By this definition argv in C is an array of tokens.
Some tokens are options to be processed, others are just passed on to the program.
Some options can take arguments. These may be interpreted as strings, numbers, bools, etc, but this is irrelevant to the formatting being discussed here.

Rule 1.
A token that starts with a hyphen (but not 2 hyphens) is a set of short options, each of which is a single alphanumeric character.

Rule 2.
Multiple short options may be grouped together in a single token, if those options do not take arguments. So -abc is equivalent to -a -b -c.

Rule 3.
Any given short option may require an argument, such an argument not being present is an error.

Rule 4.
An argument for a short option may be specified as the remainder of the token containing the option. For example in -ofoo the option o has the value foo.
Since there is no way to tell if the f in that example is the start of the argument or the next option, arguments provided in this way cannot be optional.

Rule 5.
A required argument for a short option may be provided as the entire next token following the one containing the option. For example -o foo.
The following token is considered to be the argument for the option even if it starts with one or more hyphens. Thus -o -foo means that option o has the argument -foo.

Rule 7.
A token consisting of a single hyphen only, -, is not an option.

Rule 8.
A token consisting of exactly 2 hyphens, --, ends option processing. All following tokens are arguments.
Note that rule 5 implies that the -- may actually be an argument and hence not end processing. For example, given the tokens -o -- -p, if the option o requires an argument then that argument is -- and -p is processed as the next option. However, if the option o does not require an argument then -- ends option processing and -p is not processed as an option.

Rule 9.
A token that starts with 2 hyphens is a single long option, which must contain only alphanumeric characters and hyphens. [CQ] underscores?

Rule 10. [Not Implemented]
Users do not need to specify the whole of a long option name, as long as what they specify is unique.

Rule 11.
A long option may take an argument, which may be required or optional.

Rule 12.
An argument for a long option may be specified with an = between the option name and the argument. For example in --foo=bar the option foo has the argument bar.

Rule 13.
A required argument for a long option may be provided as the entire next token following the one containing the option. For example --foo bar.

Rule 14.
Options may appear in any order and may appear more than once. Last appearance wins.

Rule 15.
Options and non-option tokens may appear in any order, including intermixed.
