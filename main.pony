use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMinimal)
    test(_TestChatEmpty)
    test(_TestChatAll)

class iso _TestMinimal is UnitTest
  fun name(): String => "commands/empty"

  fun apply(h: TestHelper) =>
    let cs = CommandSpec("test", "a test program")
    h.assert_eq[String]("test", cs.name)
    h.assert_eq[String]("a test program", cs.descr)

class iso _TestChatEmpty is UnitTest
  fun name(): String => "commands/chat"

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
  fun name(): String => "commands/chat"

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

/*
  new create(env: Env) =>
    try
      let cs = _Fixtures.chat_cli_spec()
      env.out.print("Command spec: " + cs.string())

      let cmd = CommandParser(cs).parse(env.args, env.vars())
      env.out.print("Parsed command: " + cmd.string())

      // Handle errors here too.
      // Now use cmd to do our stuff
    else
      env.out.print("Command spec creation failure!")
    end
*/

primitive _Fixtures
  """
  Build and return the spec for our chat program's CLI
  """
  fun chat_cli_spec(): CommandSpec ref ? => // iso?
    let cs = CommandSpec("chat", "a sample chat program")
    cs.flag("admin", BoolType, "chat as admin").optional(false)
    cs.flag("name", StringType, "your name").short('n')
    cs.flag("volume", F64Type, "chat volume").short('v')

    let say = cs.command("say", "say something")
    say.arg("words", StringType)

    let emote = cs.command("emote")
    emote.arg("emotion", StringType, "emotion to send")
    emote.flag("speed", F64Type, "how fast to play emotion").optional(F64(1.0))

    consume cs
