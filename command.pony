use c = "collections"

class box Command
  let spec: CommandSpec box
  let flags: c.Map[String, Flag] = flags.create()
  let args: c.Map[String, Arg] = args.create()

  new create(spec': CommandSpec box, flaga: Array[Flag] box,
    arga: Array[Arg] box)
  =>
    spec = spec'
    for f in flaga.values() do
      try flags.insert(f.spec.name, f) end
    end
    for a in arga.values() do
      try args.insert(a.spec.name, a) end
    end

  fun string(): String =>
    let s: String iso = spec.fullname().clone()
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

type Value is (Bool | String | I64 | F64)
