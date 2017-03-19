use "../cli"

actor Main
  new create(env: Env) =>
    try
      let cs = cli_spec()

      let cmdErr = CommandParser(cs).parse(env.args)
      let cmd = match cmdErr
        | let c: Command => c
        | let se: SyntaxError =>
            env.out.print(se.string())
            return
        else
          error  // shouldn't happen
        end

      if cmd.spec.name == "help" then
        let arg = cmd.args("command").value as String
        let chErr = match arg
          | "" => Help.general(cs)
          | let c: String => Help.for_command(cs, [c])
        end
        let ch = match chErr
          | let c: CommandHelp => c
          | let se: SyntaxError =>
              env.out.print(se.string())
              return
          else
            error  // shouldn't happen
          end
        ch.print_help(OutWriter(env.out))
      end
    end

  fun tag cli_spec(): CommandSpec box ? =>
    """
    Builds and returns the spec for a sample chat client's CLI.
    """
    let cs = CommandSpec.parent("chat", "A sample chat program", [
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
    cs.add_help()
    cs

