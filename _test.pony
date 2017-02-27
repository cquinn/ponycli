use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMinimal)
    test(_TestBools)
    test(_TestDefaults)
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
    let cs = CommandSpec("minimal", "")
      .>flag("aflag", BoolType, "")

    h.assert_eq[String]("minimal", cs.name)

    let args: Array[String] = ["ignored", "--aflag=true"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    let f = cmd.flags("aflag")
    h.assert_eq[Bool](true, f.value as Bool)


class iso _TestBools is UnitTest
  fun name(): String => "ponycli/bools"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.bools_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "-abc"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    let af = cmd.flags("a")
    h.assert_eq[Bool](true, af.value as Bool)
    let bf = cmd.flags("b")
    h.assert_eq[Bool](true, bf.value as Bool)
    let cf = cmd.flags("c")
    h.assert_eq[Bool](true, cf.value as Bool)
    let df = cmd.flags("d")
    h.assert_eq[Bool](false, df.value as Bool)


class iso _TestDefaults is UnitTest
  fun name(): String => "ponycli/defaults"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.shorts_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    let bfo = cmd.flags("boolo")
    h.assert_eq[Bool](true, bfo.value as Bool)
    let sfo = cmd.flags("stringo")
    h.assert_eq[String]("astring", sfo.value as String)
    let ifo = cmd.flags("into")
    h.assert_eq[I64](42, ifo.value as I64)
    let ffo = cmd.flags("floato")
    h.assert_eq[F64](42.0, ffo.value as F64)


class iso _TestShortsAdj is UnitTest
  fun name(): String => "ponycli/shorts_adjacent"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.shorts_cli_spec()
    h.log("Command spec: " + cs.string())

    let args: Array[String] = ["ignored", "-BSastring", "-I42", "-F42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed command: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

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

    let cmd = match cmdErr | let c: Command => c else error end

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

    let cmd = match cmdErr | let c: Command => c else error end

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

    let cmd = match cmdErr | let c: Command => c else error end

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

    let cmd = match cmdErr | let c: Command => c else error end

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

    let cmd = match cmdErr | let c: Command => c else error end
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

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[String]("say", cmd.spec.name)
    h.assert_eq[String]("chat/say", cmd.spec.fullname)

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

  fun bools_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a CLI with four bool flags.
    """
    CommandSpec("bools", "a sample CLI with four bool flags")
      .>flag("a", BoolType where short = 'a')
      .>flag("b", BoolType where short = 'b')
      .>flag("c", BoolType where short = 'c')
      .>flag("d", BoolType where short = 'd')

  fun shorts_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a CLI with short flags of each type.
    """
    CommandSpec("shorts", "a sample program with various short flags")
      .>flag("boolr", BoolType where short = 'B')
      .>flag("boolo", BoolType where short = 'b', default=true)
      .>flag("stringr", StringType where short = 'S')
      .>flag("stringo", StringType where short = 's', default="astring")
      .>flag("intr", I64Type where short = 'I')
      .>flag("into", I64Type where short = 'i', default=I64(42))
      .>flag("floatr", F64Type where short = 'F')
      .>flag("floato", F64Type where short = 'f', default=F64(42.0))

  fun chat_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a sample chat client's CLI.
    """
    let cs = CommandSpec("chat", "sample chat program")
      .>flag("admin", BoolType, "chat as admin" where default=false)
      .>flag("name", StringType, "your name" where short='n')
      .>flag("volume", F64Type, "chat volume" where short='v')

    let say = cs.command("say", "say something")
    say.arg("words", StringType)

    let emote = cs.command("emote")
    emote.arg("emotion", StringType, "emotion to send")
    emote.flag("speed", F64Type, "how fast to play emotion" where default=F64(1.0))
    cs
