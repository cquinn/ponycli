use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMinimal)
    test(_TestBadName)
    test(_TestHyphenArg)
    test(_TestBools)
    test(_TestDefaults)
    test(_TestShortsAdj)
    test(_TestShortsEq)
    test(_TestShortsNext)
    test(_TestLongsEq)
    test(_TestLongsNext)
    test(_TestEnvs)
    test(_TestOptionStop)
    test(_TestDuplicate)
    test(_TestChatMin)
    test(_TestChatAll)
    test(_TestHelp)


class iso _TestMinimal is UnitTest
  fun name(): String => "ponycli/minimal"

  fun apply(h: TestHelper) ? =>
    let cs = CommandSpec.leaf("minimal", "", [
        OptionSpec.bool("aflag", "")
    ])

    h.assert_eq[String]("minimal", cs.name)

    let args: Array[String] = ["ignored", "--aflag=true"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("aflag").value as Bool)


class iso _TestBadName is UnitTest
  fun name(): String => "ponycli/badname"

  fun apply(h: TestHelper) ? =>
    try
        let cs = CommandSpec.leaf("min imal", "")
    else
        return // error was expected
    end
    error  // lack of error is bad


class iso _TestHyphenArg is UnitTest
  fun name(): String => "ponycli/hyphen"

  // Rule 1
  fun apply(h: TestHelper) ? =>
    let cs = CommandSpec.leaf("minimal" where args' = [
        ArgSpec.string("name", "")
    ])
    let args: Array[String] = ["ignored", "-"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[String]("-", cmd.args("name").value as String)


class iso _TestBools is UnitTest
  fun name(): String => "ponycli/bools"

  // Rules 2, 3, 5, 7 w/ Bools
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.bools_cli_spec()

    let args: Array[String] = ["ignored", "-ab", "-c=true", "-d=false"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("aaa").value as Bool)
    h.assert_eq[Bool](true, cmd.options("bbb").value as Bool)
    h.assert_eq[Bool](true, cmd.options("ccc").value as Bool)
    h.assert_eq[Bool](false, cmd.options("ddd").value as Bool)


class iso _TestDefaults is UnitTest
  fun name(): String => "ponycli/defaults"

  // Rules 2, 3, 5, 6
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = ["ignored", "-B", "-S--", "-I42", "-F42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("boolo").value as Bool)
    h.assert_eq[String]("astring", cmd.options("stringo").value as String)
    h.assert_eq[I64](42, cmd.options("into").value as I64)
    h.assert_eq[F64](42.0, cmd.options("floato").value as F64)


class iso _TestShortsAdj is UnitTest
  fun name(): String => "ponycli/shorts_adjacent"

  // Rules 2, 3, 5, 6, 8
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = ["ignored", "-BS--", "-I42", "-F42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("boolr").value as Bool)
    h.assert_eq[String]("--", cmd.options("stringr").value as String)
    h.assert_eq[I64](42, cmd.options("intr").value as I64)
    h.assert_eq[F64](42.0, cmd.options("floatr").value as F64)


class iso _TestShortsEq is UnitTest
  fun name(): String => "ponycli/shorts_eq"

  // Rules 2, 3, 5, 7
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = ["ignored", "-BS=astring", "-I=42", "-F=42.0"]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("boolr").value as Bool)
    h.assert_eq[String]("astring", cmd.options("stringr").value as String)
    h.assert_eq[I64](42, cmd.options("intr").value as I64)
    h.assert_eq[F64](42.0, cmd.options("floatr").value as F64)


class iso _TestShortsNext is UnitTest
  fun name(): String => "ponycli/shorts_next"

  // Rules 2, 3, 5, 8
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = [
        "ignored", "-BS", "--", "-I", "42", "-F", "42.0"
    ]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("boolr").value as Bool)
    h.assert_eq[String]("--", cmd.options("stringr").value as String)
    h.assert_eq[I64](42, cmd.options("intr").value as I64)
    h.assert_eq[F64](42.0, cmd.options("floatr").value as F64)


class iso _TestLongsEq is UnitTest
  fun name(): String => "ponycli/shorts_eq"

  // Rules 4, 5, 7
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = [
        "ignored",
        "--boolr=true", "--stringr=astring", "--intr=42", "--floatr=42.0"
    ]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("boolr").value as Bool)
    h.assert_eq[String]("astring", cmd.options("stringr").value as String)
    h.assert_eq[I64](42, cmd.options("intr").value as I64)
    h.assert_eq[F64](42.0, cmd.options("floatr").value as F64)


class iso _TestLongsNext is UnitTest
  fun name(): String => "ponycli/longs_next"

  // Rules 4, 5, 8
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = [
        "ignored",
        "--boolr", "--stringr", "--", "--intr", "42", "--floatr", "42.0"
    ]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[String]("--", cmd.options("stringr").value as String)
    h.assert_eq[I64](42, cmd.options("intr").value as I64)
    h.assert_eq[F64](42.0, cmd.options("floatr").value as F64)


class iso _TestEnvs is UnitTest
  fun name(): String => "ponycli/envs"

  // Rules
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = [
      "ignored"
    ]
    let envs: Array[String] = [
      "BOOLR=true",
      "STRINGR=astring",
      "INTR=42",
      "FLOATR=42.0"
    ]
    let cmdErr = CommandParser(cs).parse(args, envs)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[Bool](true, cmd.options("boolr").value as Bool)
    h.assert_eq[String]("astring", cmd.options("stringr").value as String)
    h.assert_eq[I64](42, cmd.options("intr").value as I64)
    h.assert_eq[F64](42.0, cmd.options("floatr").value as F64)


class iso _TestOptionStop is UnitTest
  fun name(): String => "ponycli/option_stop"

  // Rules 2, 3, 5, 7, 9
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = [
      "ignored",
      "-BS=astring", "-I=42", "-F=42.0",
      "--", "-f=1.0"
    ]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[String]("-f=1.0", cmd.args("words").value as String)
    h.assert_eq[F64](42.0, cmd.options("floato").value as F64)


class iso _TestDuplicate is UnitTest
  fun name(): String => "ponycli/duplicate"

  // Rules 4, 5, 7, 10
  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.simple_cli_spec()

    let args: Array[String] = [
        "ignored",
        "--boolr=true", "--stringr=astring", "--intr=42", "--floatr=42.0",
        "--stringr=newstring"
    ]
    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[String]("newstring", cmd.options("stringr").value as String)


class iso _TestChatMin is UnitTest
  fun name(): String => "ponycli/chat_min"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.chat_cli_spec()

    let args: Array[String] = ["ignored", "--name=me", "--volume=42"]

    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end
    h.assert_eq[String]("chat", cs.name)


class iso _TestChatAll is UnitTest
  fun name(): String => "ponycli/chat_all"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.chat_cli_spec()

    let args: Array[String] = [
        "ignored",
        "--admin", "--name=carl", "say", "-v80", "hello"
    ]

    let cmdErr = CommandParser(cs).parse(args)
    h.log("Parsed: " + cmdErr.string())

    let cmd = match cmdErr | let c: Command => c else error end

    h.assert_eq[String]("say", cmd.spec.name)

    let f1 = cmd.options("admin")
    h.assert_eq[String]("admin", f1.spec.name)
    h.assert_eq[Bool](true, f1.value as Bool)

    let f2 = cmd.options("name")
    h.assert_eq[String]("name", f2.spec.name)
    h.assert_eq[String]("carl", f2.value as String)

    let f3 = cmd.options("volume")
    h.assert_eq[String]("volume", f3.spec.name)
    h.assert_eq[F64](80.0, f3.value as F64)

    let a1 = cmd.args("words")
    h.assert_eq[String]("words", a1.spec.name)
    h.assert_eq[String]("hello", a1.value as String)


class iso _TestHelp is UnitTest
  fun name(): String => "ponycli/help"

  fun apply(h: TestHelper) ? =>
    let cs = _Fixtures.chat_cli_spec()

    let chErr = Help.for_command(cs, ["config", "server"])
    let ch = match chErr | let c: CommandHelp => c else error end

    let help = ch.help_string()
    h.log(help)
    h.assert_true(help.contains("Address of the server"))


primitive _Fixtures

  fun bools_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a CLI with four bool options.
    """
    CommandSpec.leaf("bools", "A sample CLI with four bool options", [
      OptionSpec.bool("aaa" where short' = 'a'),
      OptionSpec.bool("bbb" where short' = 'b'),
      OptionSpec.bool("ccc" where short' = 'c'),
      OptionSpec.bool("ddd" where short' = 'd')
    ])

  fun simple_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a CLI with short options of each type.
    """
    CommandSpec.leaf("shorts",
        "A sample program with various short options, optional and required", [
      OptionSpec.bool("boolr" where short' = 'B'),
      OptionSpec.bool("boolo" where short' = 'b', default' = true),
      OptionSpec.string("stringr" where short' = 'S'),
      OptionSpec.string("stringo" where short' = 's', default' = "astring"),
      OptionSpec.i64("intr" where short' = 'I'),
      OptionSpec.i64("into" where short' = 'i', default' = I64(42)),
      OptionSpec.f64("floatr" where short' = 'F'),
      OptionSpec.f64("floato" where short' = 'f', default' = F64(42.0))
    ],[
      ArgSpec.string("words" where default' = "hello")
    ])

  fun chat_cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a sample chat client's CLI.
    """
    CommandSpec.parent("chat", "A sample chat program", [
      OptionSpec.bool("admin", "Chat as admin" where default' = false),
      OptionSpec.string("name", "Your name" where short' = 'n'),
      OptionSpec.f64("volume", "Chat volume" where short' = 'v')
    ],[
      CommandSpec.leaf("say", "Say something", Array[OptionSpec](), [
        ArgSpec.string("words", "The words to say")
      ]),
      CommandSpec.leaf("emote", "Send an emotion", [
        OptionSpec.f64("speed", "Emote play speed" where default' = F64(1.0))
      ],[
        ArgSpec.string("emotion", "Emote to send")
      ]),
      CommandSpec.parent("config", "Configuration commands", Array[OptionSpec](), [
        CommandSpec.leaf("server", "Server configuration", Array[OptionSpec](), [
          ArgSpec.string("address", "Address of the server")
        ])
      ])
    ])
