use col = "collections"

class box Command
  """
  Command contains all of the information describing a command with its spec
  and given flags and arguments, ready to execute.
  """
  let spec: CommandSpec box
  let flags: col.Map[String, Flag]
  let args: col.Map[String, Arg]

  new create(spec': CommandSpec box, flags': col.Map[String, Flag],
      args': col.Map[String, Arg])
    =>
      spec = spec'
      flags = flags'
      args = args'

  fun string(): String =>
    let s: String iso = spec.name.clone()
    for f in flags.values() do
      s.append(" ")
      s.append(f.string())
    end
    for a in args.values() do
      s.append(" ")
      s.append(a.string())
    end
    s


class box Flag
  """
  Flag contains a spec and a value for a given flag.
  """
  let spec: FlagSpec box
  let value: Value

  new create(spec': FlagSpec, value': Value) =>
    spec = spec'
    value = value'

  fun string(): String =>
    spec.string() + "=" + value.string()


class box Arg
  """
  Arg contains a spec and a value for a given arg.
  """
  let spec: ArgSpec box
  let value: Value

  new create(spec': ArgSpec, value': Value) =>
    spec = spec'
    value = value'

  fun string(): String =>
    "(" + spec.string() + "=)" + value.string()
