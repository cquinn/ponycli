"""
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

  new create(name': String, descr': String = "", parent: (CommandSpec | None) = None) =>
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
  var _default: Value // | None
  var _short: (U8 | None) = None

  new create(name': String, typ': ValueType, descr': String) =>
    name = name'
    typ = typ'
    descr = descr'
    _default = Type.default(typ)

  fun ref optional(default: Value): FlagSpec^ ? =>
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

  fun ref optional(default: Value): ArgSpec^ ? =>
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
