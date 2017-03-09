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
    """
    Create a command spec that can accept flags and child commands, but not
    arguments.
    """
    name = _assertName(name')
    descr = descr'
    for f in flags'.values() do
      flags.update(f.name, f)
    end
    for c in commands'.values() do
      commands.update(c.name, c)
    end
    // TODO(cq) init args with an immutable empty array?

  new leaf(name': String, descr': String = "",
    flags': Array[FlagSpec] box = Array[FlagSpec](),
    args': Array[ArgSpec] box = Array[ArgSpec]()) ?
  =>
    """
    Create a command spec that can accept flags and arguments, but not child
    commands.
    """
    name = _assertName(name')
    descr = descr'
    for f in flags'.values() do
      flags.update(f.name, f)
    end
    for a in args'.values() do
      args.push(a)
    end
    // TODO(cq) init commands with an immutable empty array?

    fun tag _assertName(nm: String): String ? =>
      for b in nm.values() do
        if (b != '-') and (b != '_') and
          not ((b >= '0') and (b <= '9')) and
          not ((b >= 'A') and (b <= 'Z')) and
          not ((b >= 'a') and (b <= 'z')) then
          error
        end
      end
      nm

  fun ref add_command(cmd: CommandSpec) ? =>
    """
    Add an additional child command to this parent command.
    """
    if args.size() > 0 then error end
    commands.update(cmd.name, cmd)

  fun ref add_help() ? =>
    """
    Add a standard help command to this parent command.
    """
    if args.size() > 0 then error end
    let help = CommandSpec.leaf("help", "", Array[FlagSpec](), [
      ArgSpec.stringT("command" where default'="")
    ])
    commands.update(help.name, help)

  fun help_string(): String =>
    let s = name.clone()
    s.append(" ")
    for a in args.values() do
      s.append(a.help_string())
    end
    s


class /*box*/ FlagSpec
  """
  FlagSpec describes the specification of a flag.
  """
  let name: String
  let descr: String
  let short: (U8 | None)
  let typ: ValueType
  let default: Value
  let required: Bool

  fun tag _init(typ': ValueType, default': (Value | None)) :
    (ValueType, Value, Bool) ?
  =>
    match default'
      | None =>
        (typ', false, true)
    else
      (typ', default' as Value, false)
    end

  new boolT(name': String, descr': String = "",
    short': (U8 | None) = None, default': (Bool | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = _init(BoolType, default')

  new stringT(name': String, descr': String = "",
    short': (U8 | None) = None, default': (String | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = _init(StringType, default')

  new i64T(name': String, descr': String = "",
    short': (U8 | None) = None, default': (I64 | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = _init(I64Type, default')

  new f64T(name': String, descr': String = "",
    short': (U8 | None) = None, default': (F64 | None) = None) ?
  =>
    name = name'
    descr = descr'
    short = short'
    (typ, default, required) = _init(F64Type, default')

  // Other than bools, all flags require args.
  fun _requires_arg(): Bool =>
    match typ |(let b: BoolType) => false else true end
    // TODO: why can't Pony match on just type? |BoolType=>...

  // Used for bool flags to get the true arg when flag is present w/o arg
  fun _default_arg(): Value =>
    match typ |(let b: BoolType) => true else false end

  fun box _has_short(sh: U8): Bool =>
    match short
    | let ss: U8 => sh == ss
    else
      false
    end

  fun string(): String =>
    "--" + name + "[" + typ.string() + "]" +
      if not required then "(=" + default.string() + ")" else "" end

  fun help_string(): String =>
    let s = match short
      | let ss: U8 => "-" + String.from_utf32(ss.u32()) + ", "
      else
        "    "
      end
    let l = "--" + name
    s + l


class /*box*/ ArgSpec
  """
  ArgSpec describes the specification of a positional argument.
  """
  let name: String
  let descr: String
  let typ: ValueType
  let default: Value
  let required: Bool

  fun tag _init(typ': ValueType, default': (Value | None))
  :
    (ValueType, Value, Bool) ?
  =>
    match default'
      | None =>
        (typ', false, true)
    else
      (typ', default' as Value, false)
    end

  new boolT(name': String, descr': String="", default': (Bool|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = _init(BoolType, default')

  new stringT(name': String, descr': String="", default': (String|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = _init(StringType, default')

  new i64T(name': String, descr': String="", default': (I64|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = _init(I64Type, default')

  new f64T(name': String, descr': String="", default': (F64|None)=None) ?
  =>
    name = name'
    descr = descr'
    (typ, default, required) = _init(F64Type, default')

  fun string(): String =>
    name + "[" + typ.string() + "]" +
      if not required then "(=" + default.string() + ")" else "" end

  fun help_string(): String =>
    "<" + name + ">"


type Value is (Bool | String | I64 | F64)

primitive BoolType
  fun string(): String => "Bool"

primitive StringType
  fun string(): String => "String"

primitive I64Type
  fun string(): String => "I64"

primitive F64Type
  fun string(): String => "F64"

type ValueType is
  ( BoolType
  | StringType
  | I64Type
  | F64Type)
