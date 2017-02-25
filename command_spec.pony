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

  new create(name': String, descr': String = "") =>
    name = name'
    fullname = name'
    descr = descr'
    // TODO: verify name follows rules?

  new _create(name': String, fullname': String, descr': String) =>
    name = name'
    fullname = fullname'
    descr = descr'
    // TODO: verify name follows rules?

  fun ref flag(name': String, typ': ValueType, descr': String = ""): FlagSpec =>
    let f = FlagSpec(name', typ', descr')
    flags.update(name', f)
    f

  fun ref command(name': String, descr': String = ""): CommandSpec? =>
    if args.size() > 0 then error end
    let c = CommandSpec._create(name', name + "/" + name', descr')
    commands.update(name', c)
    c

  fun ref arg(name': String, typ': ValueType, descr': String = ""): ArgSpec? =>
    if commands.size() > 0 then error end
    let a = ArgSpec(name', typ', descr')
    args.push(a)
    a

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
  var _required: Bool = true
  var default: Value
  var _short: (U8 | None) = None

  new create(name': String, typ': ValueType, descr': String) =>
    name = name'
    typ = typ'
    descr = descr'
    default = Type.default(typ)

  fun ref optional(default': Value): FlagSpec^ ? =>
    if not (Type.of(default') is typ) then
      error
    end
    _required = false
    default = default'
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
  """
  ArgSpec describes the specification of a positional argument.
  """
  let name: String
  let typ: ValueType
  let descr: String
  var _required: Bool = true
  var _default: Value = false

  new create(name': String, typ': ValueType, descr': String) =>
    name = name'
    typ = typ'
    descr = descr'

  fun ref optional(default: Value): ArgSpec^ ? =>
    if not (Type.of(default) is typ) then
      error
    end
    _required = false
    _default = default
    this

  fun string(): String =>
    name + "[" + typ.string() + "]"


trait ArgRequirer
  fun requires_arg(): Bool => true
  fun default_arg(): String => ""

primitive BoolType
  fun string(): String => "Bool"
  fun requires_arg(): Bool => false
  fun default_arg(): String => "true"

primitive StringType is ArgRequirer
  fun string(): String => "String"

primitive I64Type is ArgRequirer
  fun string(): String => "I64"

primitive F64Type is ArgRequirer
  fun string(): String => "F64"

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

  fun default(typ: ValueType): Value =>
    match typ
    | BoolType => false
    | StringType => ""
    | I64Type => I64(0)
    | F64Type => F64(0.0)
    else
      // TODO: Pony shouldn't hit this
      false // None?
    end
