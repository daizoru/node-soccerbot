

module.exports = (options={}) ->

  {failure, warn, success, info, debug}  = @logger
  emit = @emit
  src = @src

  #console.log "src: #{src}"
  {mutable, clone} = require 'evolve'
  petri            = require 'petri'
  {common} = petri
  {P, copy, pretty, round2, round3, randInt, every, after} = common

  simspark         = require 'simspark'

  # Errors have a cost, and impact the motivation of the player
  # a player not motivated might declare forfeit the game -> death!
  motivation = 10000
  ERR = petri.errors (value, msg) -> motivation -= value ; msg

  #############
  # VARIABLES #s
  #############
  number = options.number ? 0
  team   = options.team
  side   = 'Left'
  state = 'connecting'
  playmode = ''
  t = 0

  robot =
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



  warn "connecting.."
  sim = new simspark.Agent()

  sim.on 'close', ->  
    state = 'disconnected'
  
  sim.on 'error', (er) ->
    warn "simspark error: " + pretty er
    state = 'disconnected'

  sim.on 'connect', ->
    state = 'waiting'
    success "connected to server"
    sim.send [
      [ "scene", options.scene ]
      [ "init", [[ "unum", number ],[ "teamname", team ]]]
    ]


    # keep track of what we sent in last, to save badnwidth and calls
    alreadySet = []
    buffer = []
    
    # flush changes, by sending a batch of events to the webserver
    # this is an optimized batch, aiming at saving the number of packets, and packet size
    flush = ->
      batch = for i in [0...buffer.length]
        continue unless buffer[i]? # when writing to random array position, the first may be empty
        continue if isNaN buffer[i]
        buffer[i] = round3 buffer[i] # round the value to 2 decimals
        continue if buffer[i] is alreadySet[i]
        # if value changed, we updated SPEEDS and sned an update message
        alreadySet[i] = buffer[i]
        [ robot.effectors[i], buffer[i] ]
      buffer = []
      sim.send batch
      batch

    sim.on 'gs', (args) ->
      #debug 'game state'
      for nfo in args
        switch nfo[0]
          when 't'  then t = nfo[1]
          when 'pm' then playmode = nfo[1]
          else
            warn "unknow GS attribute: " + pretty nfo

    sim.on 'time', (args) ->
      # timestamp

    sim.on 'agentstate', (args) ->
      temperature = args[0][1]
      battery     = args[1][1]
      #debug "temperature: #{temperature}, battery: #{battery}"


    sim.on 'frp', (args) ->
      #debug "Sensor: Force-resistance: " + pretty args

    sim.on 'gyr', (args) ->
      #debug "Sensor: Gyroscope: " + pretty args

    sim.on 'acc', (args) ->
      #debug "Sensor: Acceleration: " + pretty args
            
    sim.on 'see', (args) ->
      #debug "Sensor: Simplified vision"


    sim.on 'hj', (args) ->
      #debug "Sensor: Hinge Joint"
      # do something with the value
      # 
      # t is important, it tells the player if he should hurry or not
      # we should keep an history of effectors and sensors,
      # and game state - this is important for overall dynamic gameplay
      buffer[0]   = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[1]   = mutable  - 0.8 * Math.random() + 0.05 * Math.cos t 
      buffer[2]   = mutable   0.8 * Math.random() + 0.5 * Math.cos t
      buffer[3]   = mutable   0.8 * Math.random() + 0.05 * Math.sin t
      buffer[4]   = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[5]   = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[6]   = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[7]   = mutable  - 0.8 * Math.random() + 0.05 * Math.cos t
      buffer[8]   = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[9]   = mutable   0.8 * Math.random() + 0.05 * Math.sin t
      buffer[10]  = mutable  - 0.8 * Math.random() + 0.05 * Math.cos t
      buffer[11]  = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[12]  = mutable   0.8 * Math.random() + 0.05 * Math.sin t
      buffer[13]  = mutable  - 0.8 * Math.random() + 0.05 * Math.cos t
      buffer[14]  = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[15]  = mutable  - 0.8 * Math.random() + 0.5 * Math.cos t
      buffer[16]  = mutable  - 0.8 * Math.random() + 0.5 * Math.cos t
      buffer[17]  = mutable   0.8 * Math.random() + 0.05 * Math.cos t
      buffer[18]  = mutable  - 0.8 * Math.random() + 0.05 * Math.sin t
      buffer[19]  = mutable   0.8 * Math.random() + 0.5 * Math.cos t
      buffer[20]  = mutable   0.8 * Math.random() + 0.5 * Math.cos t
      buffer[21]  = mutable   0.8 * Math.random() + 0.05 * Math.cos t

    ################
    # SELF-CLONING #
    ################
    after 3.sec -> clone 
      src       : src
      ratio     : mutable 0.002
      iterations:  3
      debug: no
      onComplete: (new_src, nb_mutations) ->
        success "cloned with #{nb_mutations} mutations"
        if nb_mutations
          emit cmd: 'fork', src: new_src
        process.exit()


    #############
    # MAIN LOOP #
    #############
    do iterate = ->

      # http://simspark.sourceforge.net/wiki/index.php/Play_Modes
  
      # debug all msg?
      if no
        switch playmode
          when 'BeforeKickOff'
            debug "Before Kick Off"
            #warn "Waiting for kick off.."

          when 'KickOff_Left'
            debug "Kick Off Left"

          when 'KickOff_Right'
            debug "Kick Off Right"

          when 'PlayOn'
            debug "Play On"

          when 'KickIn_Left'
            debug "Kick In Left"

          when 'KickIn_Right'
            debug "Kick In Right"

          when 'corner_kick_left'
            debug "Corner Kick Left"

          when 'corner_kick_right'
            debug "Corner Kick Right"

          when 'goal_kick_left'
            debug "Goal Kick Left"

          when 'goal_kick_right'
            debug "Goal Kick Right"

          when 'offside_left'
            debug "Offside Left"

          when 'offside_right'
            debug "Offside Right"

          when 'GameOver'
            debug "Game Over"
            state = 'ended'

          when 'Goal_Left'
            debug "Goal Left"

          when 'Goal_Right'
            debug "Goal Right"

          when 'free_kick_left'
            debug "Free Kick Left"

          when 'free_kick_right'
            debug "Free Kick Right"


      switch state
        when 'play'
          flushed = flush()
          #if flushed.length
          #  debug "flushed: " + pretty flushed

        when 'connecting'
          warn "connecting to the server.."

        when 'waiting'
          #debug "waiting.."
          if playmode is 'KickOff_Left' or playmode is 'PlayOn'
            success "we can play"
            state = 'play'

        when 'ended', 'disconnected'
          process.exit()
      
      after 150.ms iterate
