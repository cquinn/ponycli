use col = "collections"

class CommandParser
  let spec: CommandSpec box
  let parent: (CommandParser box | None)

  new box create(spec': CommandSpec box, parent': (CommandParser box | None) = None) =>
    spec = spec'
    parent = parent'

  fun box parse(
    argv: Array[String] box,
    envs: (Array[String] box | None) = None): (Command | SyntaxError)
  =>
    """
    Parses all of the command line tokens and env vars and returns a Command,
    or the first SyntaxError.
    """
    let flags: col.Map[String,Flag] ref = flags.create()
    let args: col.Map[String,Arg] ref = args.create()
    let tokens = argv.clone()
    try tokens.shift() end  // argv[0] is the program name, so skip it
    _parse_command(tokens, envs, flags, args)

  fun box _parse_command(
    tokens: Array[String] ref,
    envs: (Array[String] box | None),
    flags: col.Map[String,Flag] ref,
    args: col.Map[String,Arg] ref): (Command | SyntaxError)
  =>
    """
    Parses all of the command line tokens and env vars into the given flags
    and args maps. Returns the first SyntaxError, or the Command when OK.
    """
    var arg_pos: USize = 0
    while tokens.size() > 0 do
      let token = try tokens.shift() else "" end
      if token.compare_sub("--", 2, 0) == Equal then
        match _parse_long_flag(token.substring(2), tokens, envs)
        | let f: Flag => flags.update(f.spec.name, f)
        | let se: SyntaxError => return se
        end
      elseif token.compare_sub("-", 1, 0) == Equal then
        match _parse_short_flags(token.substring(1), tokens, envs)
        | let fs: Array[Flag] => for f in fs.values() do flags.update(f.spec.name, f) end
        | let se: SyntaxError => return se
        end
      else // no dashes, must be a command or an arg
        match _child_command(token)
        | let cs: CommandSpec box =>
          match CommandParser(cs, this)._parse_command(tokens, envs, flags, args)
          | let c: Command => return c  // propagate out leaf command
          | let se: SyntaxError => return se
          end
        else
          match _parse_arg(token, arg_pos)
          | let a: Arg => args.update(a.spec.name, a); arg_pos = arg_pos + 1
          | let se: SyntaxError => return se
          end
        end
      end
    end
    // Check for missing flags and args: fill in defaults or error if missing.
    for fs in spec.flags.values() do
      if not flags.contains(fs.name) then
        if fs.required then
          return SyntaxError(fs.name, "missing value for required flag")
        end
        flags.update(fs.name, Flag(fs, fs.default))
      end
    end
    while arg_pos < spec.args.size() do
      try
        let ars = spec.args(arg_pos)
        if ars.required then
          return SyntaxError(ars.name, "missing value for required argument " + arg_pos.string() + " / " + spec.args.size().string())
        end
        args.update(ars.name, Arg(ars, ars.default))
      end
      arg_pos = arg_pos + 1
    end
    Command(spec, flags, args)

  fun box _parse_long_flag(
    token: String,
    args: Array[String] ref,
    vars: (Array[String] box | None) = None): (Flag | SyntaxError)
  =>
    """
    --fopt=foo => --fopt has argument foo
    --fopt foo => --fopt has argument foo, iff arg is required
    """
    let parts = token.split("=")
    let name = try parts(0) else "???" end
    let farg = try parts(1) else None end
    match _flag_with_name(name)
    | let fs: FlagSpec box => FlagParser.parse(fs, farg, args, vars)
    | None => SyntaxError(name, "unknown long flag")
    else
      SyntaxError(name, "Pony: shouldn't allow this")
    end

  fun box _parse_short_flags(
    token: String,
    args: Array[String] ref,
    vars: (Array[String] box | None) = None): (Array[Flag] | SyntaxError)
  =>
    """
    if 'f' requires an argument
      -fFoo => -f has argument Foo
      -f=Foo => -f has argument Foo
      -f Foo => -f has argument Foo
    else
      -f=Foo => -f has argument foo
    -abc => flags a, b, c.
    -abcFoo => flags a, b, c. c has argument Foo iff its arg is required.
    -abc=Foo => flags a, b, c. c has argument Foo.
    -abc Foo => flags a, b, c. c has argument Foo iff its arg is required.
    """
    let parts = token.split("=")
    let shorts = (try parts(0) else "" end).clone()
    var farg = try parts(1) else None end

    let flags: Array[Flag] ref = flags.create()
    while shorts.size() > 0 do
      let c = try shorts.shift() else 0 end  // Should never error since checked
      match _flag_with_short(c)
      | let fs: FlagSpec box =>
        if fs.requires_arg() and (shorts.size() > 0) then
          // flag needs an arg, so consume the remainder of the shorts for farg
          if farg is None then
            farg = shorts.clone()
            shorts.truncate(0)
          else
            return SyntaxError(short_string(c), "ambiguous args for short flag")
          end
        end
        let arg = if shorts.size() == 0 then farg else None end
        match FlagParser.parse(fs, arg, args, vars)
        | let f: Flag => flags.push(f)
        | let se: SyntaxError => return se
        end
      | None => SyntaxError(short_string(c), "unknown short flag")
      else
        return SyntaxError(token, "Pony: shouldn't allow this")
      end
    end
    flags

  fun box _child_command(name: String): (CommandSpec box | None) =>
    for c in spec.commands.values() do
      if c.name == name then
        return c
      end
    end
    None

  fun box _parse_arg(token: String, arg_pos: USize): (Arg | SyntaxError) =>
    try
      let arg_spec = spec.args(arg_pos)
      ArgParser.parse(arg_spec, token)
    else
      return SyntaxError(token, "too many positional arguments")
    end

  fun box _flag_with_name(name: String): (FlagSpec box | None) =>
    // TODO(cq): should be able to look this up by name
    for f in spec.flags.values() do
      if f.name == name then
        return f
      end
    end
    match parent
    | let p: CommandParser box => p._flag_with_name(name)
    else
      None
    end

  fun box _flag_with_short(short: U8): (FlagSpec box | None) =>
    for f in spec.flags.values() do
      if f.has_short(short) then
        return f
      end
    end
    match parent
    | let p: CommandParser box => p._flag_with_short(short)
    else
      None
    end

  fun short_string(c: U8): String => recover String().unshift(c) end


primitive FlagParser
  fun box parse(
    spec: FlagSpec box,
    farg: (String|None),
    args: Array[String] ref,
    vars: (Array[String] box | None) = None): (Flag | SyntaxError)
  =>
    // Grab the flag-arg if provided, else consume an arg if one is required.
    let arg = match farg
      | (let fn: None) if spec.requires_arg() => try args.shift() else None end
      else
        farg
      end
    // Now convert the arg to Type, detecting missing or mis-typed args
    match arg
    | let a: String =>
      match ValueParser.parse(spec.typ, a)
      | let v: Value => Flag(spec, v)
      | let se: SyntaxError => se
      else
          // TODO: Ponyc should know we've covered all match cases above
          SyntaxError(a, "Pony: shouldn't need this")
      end
    else
      if not spec.requires_arg() then
        Flag(spec, spec.default_arg())
      else
        SyntaxError(spec.name, "missing arg for flag")
      end
    end


primitive ArgParser
  fun parse(spec: ArgSpec box, arg: String): (Arg | SyntaxError) =>
    match ValueParser.parse(spec.typ, arg)
    | let v: Value => Arg(spec, v)
    | let se: SyntaxError => se
    else
        // TODO: Ponyc should know we've covered all match cases above
        SyntaxError(arg, "Pony: shouldn't allow this")
    end


primitive ValueParser
  fun box parse(typ: ValueType, arg: String): (Value | SyntaxError) =>
    try
      match typ
      | let b: BoolType => arg.bool()
      | let s: StringType => arg
      | let f: F64Type => arg.f64()
      | let i: I64Type => arg.i64()
      else
        // TODO: Ponyc should know we've covered all match cases above
        SyntaxError(arg, "Pony: shouldn't allow this: unknown value type " + typ.string())
      end
    else
      SyntaxError(arg, "unable to convert '" + arg + "' to " + typ.string())
    end


class val SyntaxError
  let token: String
  let msg: String

  new val create(token': String, msg': String) =>
    token = token'
    msg = msg'

  fun string(): String =>
    "Error: " + msg + " at: '" + token + "'"
