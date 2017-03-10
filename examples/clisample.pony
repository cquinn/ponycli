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
      FlagSpec.boolT("admin", "Chat as admin" where default' = false),
      FlagSpec.stringT("name", "Your name" where short' = 'n'),
      FlagSpec.f64T("volume", "Chat volume" where short' = 'v')
    ],[
      CommandSpec.leaf("say", "Say something", Array[FlagSpec](), [
        ArgSpec.stringT("words", "The words to say")
      ]),
      CommandSpec.leaf("emote", "Send an emotion", [
        FlagSpec.f64T("speed", "Emote play speed" where default' = F64(1.0))
      ],[
        ArgSpec.stringT("emotion", "Emote to send")
      ]),
      CommandSpec.parent("config", "Configuration commands", Array[FlagSpec](), [
        CommandSpec.leaf("server", "Server configuration", Array[FlagSpec](), [
          ArgSpec.stringT("address", "Address of the server")
        ])
      ])
    ])
    cs.add_help()
    cs

