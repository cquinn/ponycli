use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMinimal)
    test(_TestFlags)
    test(_TestShortsAdj)
    test(_TestShortsEq)
    test(_TestShortsNext)
    test(_TestLongsEq)
    test(_TestLongsNext)
    test(_TestChatEmpty)
    test(_TestChatAll)

class iso _TestMinimal is UnitTest
  fun name(): String => "ponycli/minimal"

  fun apply(h: TestHelper) ? =>
    let cs = CommandSpec("minimal")
    cs.flag("aflag", BoolType)
    h.assert_eq[String]("minimal", cs.name)

    let args: Array[String] = ["ignored", "--aflag=true"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let cmd: Command => cmd else error end

    let f = cmd.flags("aflag")
    h.assert_eq[Bool](true, f.value as Bool)

class iso _TestFlags is UnitTest
  fun name(): String => "ponycli/flags"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.flags_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "-abc"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let cmd: Command => cmd else error end

    let af = cmd.flags("a")
    h.assert_eq[Bool](true, af.value as Bool)
    let bf = cmd.flags("b")
    h.assert_eq[Bool](true, bf.value as Bool)
    let cf = cmd.flags("c")
    h.assert_eq[Bool](true, cf.value as Bool)
    try
        cmd.flags("d")
        h.fail("There should not be a d")
    end

class iso _TestShortsAdj is UnitTest
  fun name(): String => "ponycli/shorts_adjacent"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.shorts_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "-BSastring", "-I42", "-F42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let cmd: Command => cmd else error end

    let bfr = cmd.flags("boolr")
    h.assert_eq[Bool](true, bfr.value as Bool)
    let sfr = cmd.flags("stringr")
    h.assert_eq[String]("astring", sfr.value as String)
    let ifr = cmd.flags("intr")
    h.assert_eq[I64](42, ifr.value as I64)
    let ffr = cmd.flags("floatr")
    h.assert_eq[F64](42.0, ffr.value as F64)

class iso _TestShortsEq is UnitTest
  fun name(): String => "ponycli/shorts_eq"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.shorts_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "-BS=astring", "-I=42", "-F=42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let cmd: Command => cmd else error end

    let bfr = cmd.flags("boolr")
    h.assert_eq[Bool](true, bfr.value as Bool)
    let sfr = cmd.flags("stringr")
    h.assert_eq[String]("astring", sfr.value as String)
    let ifr = cmd.flags("intr")
    h.assert_eq[I64](42, ifr.value as I64)
    let ffr = cmd.flags("floatr")
    h.assert_eq[F64](42.0, ffr.value as F64)

class iso _TestShortsNext is UnitTest
  fun name(): String => "ponycli/shorts_next"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.shorts_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "-BS", "astring", "-I", "42", "-F", "42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let cmd: Command => cmd else error end

    let bfr = cmd.flags("boolr")
    h.assert_eq[Bool](true, bfr.value as Bool)
    let sfr = cmd.flags("stringr")
    h.assert_eq[String]("astring", sfr.value as String)
    let ifr = cmd.flags("intr")
    h.assert_eq[I64](42, ifr.value as I64)
    let ffr = cmd.flags("floatr")
    h.assert_eq[F64](42.0, ffr.value as F64)

class iso _TestLongsEq is UnitTest
  fun name(): String => "ponycli/shorts_eq"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.shorts_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "--boolr=true", "--stringr=astring", "--intr=42", "--floatr=42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let cmd: Command => cmd else error end

    let bfr = cmd.flags("boolr")
    h.assert_eq[Bool](true, bfr.value as Bool)
    let sfr = cmd.flags("stringr")
    h.assert_eq[String]("astring", sfr.value as String)
    let ifr = cmd.flags("intr")
    h.assert_eq[I64](42, ifr.value as I64)
    let ffr = cmd.flags("floatr")
    h.assert_eq[F64](42.0, ffr.value as F64)

class iso _TestLongsNext is UnitTest
  fun name(): String => "ponycli/shorts_next"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.shorts_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "--stringr", "astring", "--intr", "42", "--floatr", "42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let cmd: Command => cmd else error end

    let sfr = cmd.flags("stringr")
    h.assert_eq[String]("astring", sfr.value as String)
    let ifr = cmd.flags("intr")
    h.assert_eq[I64](42, ifr.value as I64)
    let ffr = cmd.flags("floatr")
    h.assert_eq[F64](42.0, ffr.value as F64)

class iso _TestChatEmpty is UnitTest
  fun name(): String => "ponycli/chat_empty"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.chat_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored"]
    let vars: Array[String] = [""]

    let cmdErr = CommandParser(cs).parse(args, vars)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr
    | let cmd: Command => cmd
    else
      error
    end
    h.assert_eq[String]("chat", cs.name)

class iso _TestChatAll is UnitTest
  fun name(): String => "ponycli/chat_all"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.chat_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "--admin", "--name=carl", "say", "-v80", "hello"]
    let vars: Array[String] = [""]

    let cmdErr = CommandParser(cs).parse(args, vars)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr
    | let cmd: Command => cmd
    else
      error
    end

    h.assert_eq[String]("say", cmd.spec.name)
    h.assert_eq[String]("chat/say", cmd.spec.fullname())

    let f1 = cmd.flags("admin")
    h.assert_eq[String]("admin", f1.spec.name)
    h.assert_eq[Bool](true, f1.value as Bool)

    let f2 = cmd.flags("name")
    h.assert_eq[String]("name", f2.spec.name)
    h.assert_eq[String]("carl", f2.value as String)

    let f3 = cmd.flags("volume")
    h.assert_eq[String]("volume", f3.spec.name)
    h.assert_eq[F64](80.0, f3.value as F64)

    let a1 = cmd.args("words")
    h.assert_eq[String]("words", a1.spec.name)
    h.assert_eq[String]("hello", a1.value as String)

primitive _Fixtures

  fun flags_cli_spec(): CommandSpec box =>
    """
    Builds and returns the spec for an app with bool flags.
    """
    let cs = CommandSpec("shorts", "a sample program with bool flags")
    cs.flag("a", BoolType).short('a')
    cs.flag("b", BoolType).short('b')
    cs.flag("c", BoolType).short('c')
    cs.flag("d", BoolType).short('d')
    cs

  fun shorts_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for an app with short flags of each type.
    """
    let cs = CommandSpec("shorts", "a sample program with various short flags")
    cs.flag("boolr", BoolType).short('B')
    cs.flag("boolo", BoolType).short('b').optional(true)
    cs.flag("stringr", StringType).short('S')
    cs.flag("stringo", StringType).short('s').optional("astring")
    cs.flag("intr", I64Type).short('I')
    cs.flag("into", I64Type).short('i').optional(I64(42))
    cs.flag("floatr", F64Type).short('F')
    cs.flag("floato", F64Type).short('f').optional(F64(42.0))
    cs

  fun chat_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a sample chat client's CLI
    """
    let cs = CommandSpec("chat", "a sample chat program")
    cs.flag("admin", BoolType, "chat as admin").optional(false)
    cs.flag("name", StringType, "your name").short('n')
    cs.flag("volume", F64Type, "chat volume").short('v')

    let say = cs.command("say", "say something")
    say.arg("words", StringType)

    let emote = cs.command("emote")
    emote.arg("emotion", StringType, "emotion to send")
    emote.flag("speed", F64Type, "how fast to play emotion").optional(F64(1.0))

    cs
