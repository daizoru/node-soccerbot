#!/usr/bin/env coffee
# STANDARD LIB
{inspect}        = require 'util'

# THIRD PARTIES
{Petri, common} = require 'petri'
execSync        = require 'execSync'
spawn           = require('child_process').spawn
eyes            = require 'eyes'
ROOT            = "#{require('./player')}"

{pretty, repeat, every, pick, sha1} = common
log = console.log 

config =

  players: 1 # 5

  server: 
    host: 'localhost'
    port: 3100

  scene: 'rsg/agent/nao/nao.rsg'

  robot:
    effectors: [
      #      No.   Description          Hinge Joint Perceptor name  Effector name
      'he1'  # 0   Neck Yaw             [0][0]      hj1             he1
      'h2'   # 1   Neck Pitch           [0][1]      hj2             he2

      'lae1' # 2   Left Shoulder Pitch  [1][0]      laj1            lae1
      'lae2' # 3   Left Shoulder Yaw    [1][1]      laj2            lae2
      'lae3' # 4   Left Arm Roll        [1][2]      laj3            lae3
      'lae4' # 5   Left Arm Yaw         [1][3]      laj4            lae4
      'lle1' # 6   Left Hip YawPitch    [2][0]      llj1            lle1
      'lle2' # 7   Left Hip Roll        [2][1]      llj2            lle2
      'lle3' # 8   Left Hip Pitch       [2][2]      llj3            lle3
      'lle4' # 9   Left Knee Pitch      [2][3]      llj4            lle4
      'lle5' # 10  Left Foot Pitch      [2][4]      llj5            lle5
      'lle6' # 11  Left Foot Roll       [2][5]      llj6            lle6

      'rle1' # 12  Right Hip YawPitch   [3][0]      rlj1            rle1
      'rle2' # 13  Right Hip Roll       [3][1]      rlj2            rle2
      'rle3' # 14  Right Hip Pitch      [3][2]      rlj3            rle3
      'rle4' # 15  Right Knee Pitch     [3][3]      rlj4            rle4
      'rle5' # 16  Right Foot Pitch     [3][4]      rlj5            rle5
      'rle6' # 17  Right Foot Roll      [3][5]      rlj6            rle6
      'rae1' # 18  Right Shoulder Pitch [4][0]      raj1            rae1
      'rae2' # 19  Right Shoulder Yaw   [4][1]      raj2            rae2
      'rae3' # 20  Right Arm Roll       [4][2]      raj3            rae3
      'rae4' # 21  Right Arm Yaw        [4][3]      raj4            rae4
    ]

log """\n\t   ____                           ___        __ 
\t  / __/___  ____ ____ ___  ____  / _ ) ___  / /_
\t _\\ \\ / _ \\/ __// __// -_)/ __/ / _  |/ _ \\/ __/
\t/___/ \\___/\\__/ \\__/ \\__//_/   /____/ \\___/\\__/
\n\t               Robotic Soccer Training Program\n\n"""

start = -> Petri ->

  log "Spawning team members.."
  # storage for trading models
  team = {}
  team[ROOT.toString()] = 1
  playing = 0

  # Initialization of the team
  @spawn() for i in [0...config.players]

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

log "Checking is SimSpark is running.."
psaux = execSync.exec('ps aux | grep rcssserver3d | grep -v grep | wc -l; exit 1');
instances = ((Number) psaux.stdout) 
if instances is 0
  log "SimSpark is not running, starting it.."
  startSimSpark (server) ->
    log "simspark is started, connecting to it.."
    start()
else
  log "SimSpark is already running, connecting to it.."
  start()
