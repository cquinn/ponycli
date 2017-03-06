use col = "collections"

class box Command
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
  let spec: FlagSpec box
  let value: Value

  new create(spec': FlagSpec box, value': Value) =>
    spec = spec'
    value = value'

  fun string(): String =>
    spec.string() + "=" + value.string()


class box Arg
  let spec: ArgSpec box
  let value: Value

  new create(spec': ArgSpec box, value': Value) =>
    spec = spec'
    value = value'

  fun string(): String =>
    "(" + spec.string() + "=)" + value.string()
