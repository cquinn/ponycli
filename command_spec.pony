"""
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

This package adds the notion of commands that are specified as a hierarchy.
Inspired by the Golang Kingpin: https://github.com/alecthomas/kingpin

General CLI form supported:
  <root-command> [[<flags>] [<command>]]... [<flags>] [<args>]
  <command> ::= <alphanum_word>
  <alphanum_word> ::= <alphachar>[<alphachar>|<numchar>|'_'|'-']
  <flags> ::= <flag>...
  <flag> ::= <longflag> | <shortflagset>
  <longflag> ::= '--'<alphanum_word>[=<arg> | ' '<arg>]
  <shortflagset> := '-'<alphachar>[<alphachar>]...[=<arg> | ' '<arg>]
  <args> ::= <arg>...
  <arg> := <boolarg> | <intarg> | <floatarg> | <stringarg>
  <boolarg> := 'true' | 'false'
  <intarg> := ['-'] <numchar>...
  <floatarg> ::= ['-'] <numchar>... ['.' <numchar>...]
  <stringarg> ::= <anychar>

Some Examples:
  usage: chat [<flags>] <command> [<flags>] [<args> ...]
"""

class CommandSpec
  let name: String
  let descr: String
  let flags: Array[FlagSpec box] = flags.create()

  // TODO: maybe enforce at most one of these two:
  let commands: Array[CommandSpec box] = commands.create()
  let args: Array[ArgSpec box] = args.create()

  // Used for fullname rendering only
  let _parent: (CommandSpec box | None)

  new create(name': String, descr': String, parent: (CommandSpec | None) = None) =>
    name = name'
    descr = descr'
    _parent = parent
    // TODO: verify name follows rules?

  fun ref command(name': String, descr': String = ""): CommandSpec =>
    let c = CommandSpec(name', descr', this)
    commands.push(c)
    c

  fun ref flag(name': String, typ': ValueType, descr': String = ""): FlagSpec =>
    let f = FlagSpec(name', typ', descr')
    flags.push(f)
    f

  fun ref arg(name': String, typ': ValueType, descr': String = ""): ArgSpec =>
    let a = ArgSpec(name', typ', descr')
    args.push(a)
    a

  fun box fullname(): String =>
    match _parent
    | let p: CommandSpec box => p.fullname() + "/" + name
    else
      name
    end

  fun box string(): String =>
    let s: String iso = name.clone()
    for f in flags.values() do
      s.append(" ")
      s.append(f.string())
    end
    for a in args.values() do
      s.append(" ")
      s.append(a.string())
    end
    for c in commands.values() do
      s.append(" ")
      s.append(c.string())
    end
    s

class FlagSpec
  let name: String
  let typ: ValueType
  let descr: String
  var _required: Bool = true
  var _default: Value = false
  var _short: (U8 | None) = None

  new create(name': String, typ': ValueType, descr': String) =>
    name = name'
    typ = typ'
    descr = descr'

  fun ref optional(default: Value = false): FlagSpec^ ? =>
    if not (Type.of(default) is typ) then
      error
    end
    _required = false
    _default = default
    this

  fun ref short(sh: U8): FlagSpec^ =>
    _short = sh
    this

  fun box has_name(nm: String): Bool =>
    nm == name

  fun box has_short(sh: U8): Bool =>
    match _short
    | let ss: U8 => sh == ss
    else
      false
    end

  fun string(): String =>
    "--" + name + "[" + typ.string() + "]"

class ArgSpec
  let name: String
  let typ: ValueType
  let descr: String
  var _required: Bool = true
  var _default: Value = false

  new create(name': String, typ': ValueType, descr': String) =>
    name = name'
    typ = typ'
    descr = descr'

  fun ref required(): ArgSpec^ =>
    _required = true
    this

  fun ref optional(default: Value = false): ArgSpec^ ? =>
    if not (Type.of(default) is typ) then
      error
    end
    _required = false
    _default = default
    this

  fun string(): String =>
    name + "[" + typ.string() + "]"


primitive BoolType
  fun string(): String => "Bool"
  fun requires_arg(): Bool => false
  fun default_arg(): String => "true"

primitive StringType
  fun string(): String => "String"
  fun requires_arg(): Bool => true
  fun default_arg(): String => ""

primitive I64Type
  fun string(): String => "I64"
  fun requires_arg(): Bool => true
  fun default_arg(): String => ""

primitive F64Type
  fun string(): String => "F64"
  fun requires_arg(): Bool => true
  fun default_arg(): String => ""

type ValueType is
  ( BoolType
  | StringType
  | I64Type
  | F64Type)

primitive Type
  fun of(v: Value): ValueType =>
    match v
    | let b: Bool => BoolType
    | let s: String => StringType
    | let i: I64 => I64Type
    | let f: F64 => F64Type
    else
      // TODO: Pony shouldn't hit this
      BoolType // None?
    end


