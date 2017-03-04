"""
This package implements command line parsing with the notion of commands that
are specified as a hierarchy.
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
  CommandSpec describes the specification of a parent or leaf command. Each
  command has the following attributes:

  - a name: a simple string token that identifies the command.
  - a description: used in the syntax message.
  - a map of flags: the valid flags for this command.
  - one of:
     - a Map of child commands.
     - an Array of arguments.
  """
  let name: String
  let descr: String
  let flags: col.Map[String, FlagSpec box] = flags.create()

  // A parent commands can have sub-commands; leaf commands can have args.
  let commands: col.Map[String, CommandSpec box] = commands.create()
  let args: Array[ArgSpec box] = args.create()

  new parent(name': String, descr': String = "",
    flags': Array[FlagSpec] box = Array[FlagSpec](),
    commands': Array[CommandSpec] box = Array[CommandSpec]()) ?
  =>
    name = assertName(name')
    descr = descr'
    for f in flags'.values() do
      flags.update(f.name, f)
    end
    for c in commands'.values() do
      commands.update(c.name, c)
    end

  new leaf(name': String, descr': String = "",
    flags': Array[FlagSpec] box = Array[FlagSpec](),
    args': Array[ArgSpec] box = Array[ArgSpec]()) ?
  =>
    name = assertName(name')
    descr = descr'
    for f in flags'.values() do
      flags.update(f.name, f)
    end
    for a in args'.values() do
      args.push(a)
    end

    fun tag assertName(nm: String): String ? =>
      for b in nm.values() do
        if (b != '-') and (b != '_') and
          not ((b >= '0') and (b <= '9')) and
          not ((b >= 'A') and (b <= 'Z')) and
          not ((b >= 'a') and (b <= 'z')) then
          error
        end
      end
      nm

  fun ref command(cmd: CommandSpec) =>
    commands.update(cmd.name, cmd)

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
  let descr: String
  let short: (U8 | None)
  let typ: ValueType
  let default: Value
  let required: Bool

  fun tag init(typ': ValueType, default': (Value | None))
  :
    (ValueType, Value, Bool) ?
  =>
    match default'
      | None =>
        (typ', typ'.default(), true)
    else
      //if not (Type.of(default') is typ') then error end
      (typ', default' as Value, false)
    end

  new boolT(name': String, descr': String = "",
    short': (U8 | None) = None, default': (Bool | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = init(BoolType, default')

  new stringT(name': String, descr': String = "",
    short': (U8 | None) = None, default': (String | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = init(StringType, default')

  new i64T(name': String, descr': String = "",
    short': (U8 | None) = None, default': (I64 | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = init(I64Type, default')

  new f64T(name': String, descr': String = "",
    short': (U8 | None) = None, default': (F64 | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = init(F64Type, default')

  // Other than bools, all flags require args.
  fun box requires_arg(): Bool =>
    match typ |(let b: BoolType) => false else true end
    // TODO: why can't Pony match on just type? |BoolType=>...

  // Used for bool flags to get the true arg when flag is present w/o arg
  fun default_arg(): Value =>
    match typ |(let b: BoolType) => true else false end

  fun box has_short(sh: U8): Bool =>
    match short
    | let ss: U8 => sh == ss
    else
      false
    end

  fun string(): String =>
    "--" + name + "[" + typ.string() + "]" +
      if not required then "(=" + default.string() + ")" else "" end


class ArgSpec
  """
  ArgSpec describes the specification of a positional argument.
  """
  let name: String
  let descr: String
  let typ: ValueType
  let default: Value
  let required: Bool

  fun tag init(typ': ValueType, default': (Value | None))
  :
    (ValueType, Value, Bool) ?
  =>
    match default'
      | None =>
        (typ', typ'.default(), true)
    else
      if not (Type.of(default') is typ') then error end
      (typ', default' as Value, false)
    end

  new boolT(name': String, descr': String="", default': (Bool|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = init(BoolType, default')

  new stringT(name': String, descr': String="", default': (String|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = init(StringType, default')

  new i64T(name': String, descr': String="", default': (I64|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = init(I64Type, default')

  new f64T(name': String, descr': String="", default': (F64|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = init(F64Type, default')

  fun string(): String =>
    name + "[" + typ.string() + "]" +
      if not required then "(=" + default.string() + ")" else "" end


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
