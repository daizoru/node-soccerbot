#!/usr/bin/env coffee
# STANDARD LIB
{inspect}        = require 'util'

# THIRD PARTIES
{Petri, common} = require 'petri'
execSync        = require 'execSync'
spawn           = require('child_process').spawn
eyes            = require 'eyes'

{pretty, repeat, every, pick, sha1} = common
log = console.log 

# WARNING all workers will execute code which is outside Petri callback
Petri ->

  main = => 

    log "Spawning team members.."
    # storage for trading models
    team = {}
    team["#{require('./player')}"] = 1
    playing = 0

    # Initialization of the team
    for i in [0...1]
      @spawn()

    @on 'exit', =>
      log "Player exited"
      playing--
      @spawn()

    @on 'ready', (onComplete) ->
      log "Configuring player, assigning number #{playing}.."
      onComplete
        src: pick team                   # pick a random program
        scene: 'rsg/agent/nao/nao.rsg'   # robot model
        score: 0                         # default individual score
        team  : 'Daizoru'                # soccer team / side
        number: playing++                # soccer player number

    @on 'data', (reply, src, msg) ->
      id = sha1 src
      name = id[-4..] + id[..4]
      switch msg.cmd
        when 'log'
          console.log "Player (#{name}): #{msg.msg}"
        when 'score'
          team[src] = msg.score
        else
          console.log "Player (#{name}): unknow cmd #{pretty msg}"
      #agent.source = source
      # store the agent
      # if fork: do something



  #############################################
  # LAUNCHING EXTERNAL PROGRAM / DEPENDENCIES #
  #############################################

  startSimSpark = (onReady) ->
    server = spawn "rcssserver3d", []

    isReady = no
    server.stdout.on 'data', (data)  -> 
      #log "rcssserver3d: #{data}"
      unless isReady
        isReady = yes
        onReady server

    server.stderr.on 'data', (data)  ->  #log "rcssserver3d: error: #{data}"
    server.on 'close', (code, signal) -> log "rcssserver3D: exited"
    server.stdin.end()

  log "Checking if SimSpark is running.."
  psaux = execSync.exec('ps aux | grep rcssserver3d | grep -v grep | wc -l; exit 1');
  instances = ((Number) psaux.stdout) 
  if instances is 0
    log "SimSpark is not running, starting it.."
    startSimSpark (server) ->
      log "simspark is now started, connecting to it.."
      main()
  else
    log "SimSpark is already running, connecting to it.."
    main()
