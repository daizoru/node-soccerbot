#!/usr/bin/env coffee
# STANDARD LIB
{inspect}        = require 'util'

# THIRD PARTIES
{Petri, common} = require 'petri'
eyes            = require 'eyes'
simspark        = require 'simspark'

{pretty, after, every, pick, sha1} = common
log = console.log 

Petri ->
  # check if simspark server is running, else run it
  simspark.checkServer =>
    #simspark.checkViewer()
    #sim = new simspark.Monitor()
    log "Spawning team members.."
    team = {}
    team["#{require('./player')}"] = 1

    # Initialization of the team
    @spawn() for i in [0...1]

    @on 'exit', @spawn

    @on 'ready', (onComplete) ->
      log "spawning player (available: #{Object.keys(team).length})"
      onComplete
        src: pick team                   # pick a random program
        scene: 'rsg/agent/nao/nao.rsg'   # robot model
        score: 0                         # default individual score
        team  : 'Daizoru'                # soccer team / side
        number: 0                        # soccer player number

    @on 'data', (reply, src, msg) ->
      id = sha1 src
      name = id[-4..] + id[..4]
      switch msg.cmd
        when 'log'
          0 #log "Player (#{name}): #{msg.msg}"
        when 'score'
          team[src] = msg.score
        when 'fork'
          team[msg.src] = team[msg.src] ? 1
        else
          log "Player (#{name}): unknow cmd #{pretty msg}"
      #agent.source = source
      # store the agent
      # if fork: do something