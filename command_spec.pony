"""
This package implements command line parsing with the notion of commands that are specified as a hierarchy.
See RFC-xxx for more details.

The general EBNF of the command line looks like:
  command_line ::= root_command (flag* command*)* (flag | arg)*
  command ::= alphanum_word
  alphanum_word ::= alphachar(alphachar | numchar | '_' | '-')*
  flag ::= longflag | shortflagset
  longflag ::= '--'alphanum_word['='arg | ' 'arg]
  shortflagset := '-'alphachar[alphachar]...['='arg | ' 'arg]
  arg := boolarg | intarg | floatarg | stringarg
  boolarg := 'true' | 'false'
  intarg> := ['-'] numchar...
  floatarg ::= ['-'] numchar... ['.' numchar...]
  stringarg ::= anychar

Some Examples:
  usage: chat [<flags>] <command> [<flags>] [<args> ...]
"""
use col = "collections"


class CommandSpec
  """
  CommandSpec describes the specification of a root or child command. Each
  command has the following attributes:

  - a name: a simple string token that identifies the command.
  - a fullname: for child commands this name includes the /-separated path from the root.
  - a description: used in the syntax message.
  - a map of flags: the valid flags for this command.
  - a Map of child commands.
  - or
  - an Array of arguments.
  """
  let name: String
  let fullname: String
  let descr: String
  let flags: col.Map[String, FlagSpec box] = flags.create()

  // A command can have sub-commands or args, but not both.
  let commands: col.Map[String, CommandSpec box] = commands.create()
  let args: Array[ArgSpec box] = args.create()

  new create(name': String, descr': String) =>
    name = name'
    fullname = name'
    descr = descr'
    // TODO: error of name is not alpha_num?

  new _subcommand(parent: CommandSpec, name': String, descr': String) =>
    name = name'
    fullname = parent.name + "/" + name'
    descr = descr'
    // TODO: error if name is not alpha_num?

  fun ref command(name': String, descr': String = ""): CommandSpec ? =>
    if args.size() > 0 then error end
    let c = _subcommand(this, name', descr')
    commands.update(c.name, c)
    c

  fun ref flag(name': String, typ': ValueType, descr': String = "",
    short: (U8 | None) = None, default: (Value|None) = None) ?
  =>
    let f = FlagSpec(name', typ', descr', short, default)
    flags.update(f.name, f)

  fun ref arg(name': String, typ': ValueType, descr': String="", default: (Value|None) = None) ? =>
    if commands.size() > 0 then error end
    let a = ArgSpec(name', typ', descr', default)
    args.push(a)

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
  """
  FlagSpec describes the specification of a flag.
  """
  let name: String
  let typ: ValueType
  let descr: String
  let short: (U8 | None)
  let default: Value
  let required: Bool

  new create(name': String, typ': ValueType, descr': String,
    short': (U8 | None), default': (Value | None)) ?
  =>
    name = name'
    typ = typ'
    descr = descr'
    short = short'
    match default'
      | None =>
        default = typ.default()
        required = true
    else
      if not (Type.of(default') is typ') then error end
      default = default' as Value
      required = false
    end

  // Other than bools, all flags require args.
  fun box requires_arg(): Bool =>
    match typ |(let b: BoolType) => false else true end
    // TODO: why can't we match on just type? |BoolType=>...

  // Used for bool flags to get the true arg when flag is present w/o arg
  fun default_arg(): Value =>
    match typ |(let b: BoolType) => true else false end

  fun box has_name(nm: String): Bool =>
    nm == name

  fun box has_short(sh: U8): Bool =>
    match short
    | let ss: U8 => sh == ss
    else
      false
    end

  fun string(): String =>
    "--" + name + "[" + typ.string() + "]"


class ArgSpec
  """
  ArgSpec describes the specification of a positional argument.
  """
  let name: String
  let typ: ValueType
  let descr: String
  let default: Value
  let required: Bool

  new create(name': String, typ': ValueType, descr': String, default': (Value|None)) ? =>
    name = name'
    typ = typ'
    descr = descr'
    match default'
      | None =>
        default = typ.default() // Has the right type, but won't be used.
        required = true
    else
      if not (Type.of(default') is typ') then error end
      default = default' as Value
      required = false
    end

  fun string(): String =>
    name + "[" + typ.string() + "]"


primitive BoolType
  fun string(): String => "Bool"
  fun default(): Value => false

primitive StringType
  fun string(): String => "String"
  fun default(): Value => ""

primitive I64Type
  fun string(): String => "I64"
  fun default(): Value => I64(0)

primitive F64Type
  fun string(): String => "F64"
  fun default(): Value => F64(0.0)

type ValueType is
  ( BoolType
  | StringType
  | I64Type
  | F64Type)

primitive Type
  fun of(v: (Value|None)): (ValueType|None) =>
    match v
    | let b: Bool => BoolType
    | let s: String => StringType
    | let i: I64 => I64Type
    | let f: F64 => F64Type
    | None => None
    else
      // TODO: Pony shouldn't hit this
      BoolType // None?
    end
