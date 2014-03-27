require 'Tserial'
cron=require 'cron/cron'

function love.load()
    love.filesystem.setIdentity('Fall')

    love.window.setMode(0, 0, {fullscreen=true})
    state = 'store'

    width, height = love.window.getMode()

    message = ''

    font = love.graphics.newFont('high_scores.ttf', 48)

    music = love.audio.newSource('hexagon-force.mp3')

    player = {x = (width/(25/24))/2, y = 0, speed = 0, size = height/25, 
              canmove = true, movespeed=7}
    maxspeed = 20

    speed_price = function() return math.ceil((player.movespeed-2)^1.8) end

    obstacles = {}
    time_to_next = 0
    base_speed = 4
    obstacles_speed = base_speed
    obstacle_height = height/35
    hole_size = 75

    bonuses = {}
    bonus_size = height/35
    bonus_freq = 15
    buffs = {}
    bars = {}
    bar_width = 20

    SAVENAME = 'scores.save'
    score = 0
    highscore = 0
    coins = 0
    if love.filesystem.exists(SAVENAME) then
        loaded = Tserial.unpack(love.filesystem.read(SAVENAME))
        highscore = loaded[1]
        coins = loaded[2]
        player.movespeed = loaded[3]
    end
end

function love.draw()
    -- background
    love.graphics.setColor(55, 42, 25)
    love.graphics.rectangle('fill', 0, 0, width, height)
    
    -- scores
    love.graphics.setFont(font)

    if state=='game' then
        -- player
        love.graphics.setColor(255, 0, 0)
        love.graphics.rectangle('fill', player.x, player.y+obstacles_speed,
                                        player.size, player.size)
        -- bonuses
        for _, b in pairs(bonuses) do
            love.graphics.setColor(b.col[1], b.col[2], b.col[3]) -- gold
            love.graphics.rectangle('fill', b.x, b.y+obstacles_speed,
                                    b.size, b.size)
        end

        -- obstacles
        love.graphics.setColor(255, 255, 255)
        for _, o in pairs(obstacles) do
            love.graphics.rectangle('fill', o.x, o.y, o.length, o.height)
        end

        -- bars
        for y, bar in pairs(bars) do
            love.graphics.setColor(bar[2][1], bar[2][2], bar[2][3])
            love.graphics.rectangle('fill', width-bar[1]*20, (y-1)*bar_width, 
                                    bar[1]*20, bar_width) 
        end

        --scores
        love.graphics.setColor(191, 255, 0)
        love.graphics.print('Score:' .. math.ceil(score), 0, 0)
        love.graphics.print('Speed:' .. math.ceil(obstacles_speed * 25), 0, 30)
    elseif state == 'store' then
        love.graphics.setColor(255, 191, 0)
        love.graphics.print('Press 1 to buy a speed upgrade ($' ..
                             speed_price() .. ')',0, 200)
        love.graphics.print('Press 0 to start new game', 0, 300)
        love.graphics.setColor(250, 245, 191)
        love.graphics.print(message, 50, 400)
        love.graphics.setColor(191, 255, 0)
        love.graphics.print('Highscore:'  .. highscore, 0, 0)
        love.graphics.print('Money:    '  .. coins, 0, 30)
        love.graphics.print('Movespeed:'  .. player.movespeed, 0, 60)
    end
end


function love.update(dt)
    android_control()

    if state =='game' then
        game(dt)
    elseif state =='store' then
        store(dt)
    end
end

function createObstacle()
    hole_position = hole_size + math.random(width-hole_size*2)
    local ms = math.max(0, math.random(-5, 5))
    local d = (math.random() > 0.5) and 1 or -1

    obstacle1 = {x = hole_position+hole_size, y = height, direction = d,
                 length = width, height = obstacle_height, movespeed = ms}
    obstacle2 = {x = -width+hole_position-hole_size, y = height, direction = d,
                 length = width, height = obstacle_height, movespeed = ms}

    table.insert(obstacles, obstacle1)
    table.insert(obstacles, obstacle2)
end

function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return  x1 < x2+w2 and
            x2 < x1+w1 and
            y1 < y2+h2 and
            y2 < y1+h1
end

function saveGame()
    love.filesystem.write(SAVENAME, Tserial.pack({highscore, coins,
                                                  player.movespeed}))
end

function spawnBonus()
    local classes = {
        {'destroy',          {000, 255, 255}},
        {'player.movespeed', {000, 000, 255}},
        {'hole_size',        {000, 255, 000}},
        {'base_speed',       {255, 000, 255}}}
    local c = {'coin', {255, 215, 0}}
    if math.random() > 0.7 then
        c = classes[math.random(#classes)]
    end
    bonus = {class = c[1], size = bonus_size, speed = 1, col = c[2], 
             x = math.random(width),
             y = math.random(player.y, height)-bonus_size}
    table.insert(bonuses, bonus)
end

function consumeBonus(b)
    if b.class == 'coin' then
        coins = coins + 1
    elseif b.class  == 'destroy' then
        obstacles = {}
        time_to_next = 0
    else
        local power = b.class == 'base_speed' and -1.2 or
            5 + 25 * (b.class == 'hole_size' and 1 or 0)
        makeBuff(b.class, power, 5, b.col)
    end
end

function makeBuff(stat, power, time, color)
    local c = stat .. '=' .. stat
    loadstring(c .. '+ ' .. power)()
    local f = function() loadstring(c .. '- ' .. power)() end
    table.insert(buffs, cron.after(time, f))
    table.insert(bars, {5, color})
end

function game(dt)
    for k, bar in pairs(bars) do
        bars[k][1] = bar[1] - dt
        if bar[1] <= 0 then
            table.remove(bars, k)
        end
    end
    -- spawn obstacle if time has come
    if time_to_next <= 0 then
        time_to_next = 110
        createObstacle()
    end

    -- spawn bonus
    if math.random(0, 1000) < bonus_freq then
        spawnBonus()
    end

    time_to_next = time_to_next - obstacles_speed

    if love.keyboard.isDown('left') then
        move_player('left')
    elseif love.keyboard.isDown('right') then
        move_player('right')
    end

    player.speed = player.speed + 0.4
    player.canmove = true

    -- move and remove unneded bonuses
    for k, b in pairs(bonuses) do
        local collide_player = checkCollision(b.x, b.y, b.size, b.size, 
                                 player.x, player.y, player.size, player.size) 
        if collide_player then
            consumeBonus(b)
            bonuses[k] = nil
        end
        b.y = b.y + b.speed
        if b.y <= -b.size or b.y > height then
            table.remove(bonuses,k)
        end
    end

    for k, o in pairs(obstacles) do
        -- move obstacles (y)
        correction = math.max(0, player.y - height + 200 + player.size)/30
        obstacles_speed = base_speed + correction + math.sqrt(score)/10
        obstacles[k].y = o.y - obstacles_speed 

        -- move obstacles (x)
        obstacles[k].x = o.x + o.movespeed * o.direction
        if o.x < -o.length then 
            obstacles[k].direction = 1
            if obstacles[k-1] then obstacles[k-1].direction = 1 end
        elseif o.x > width then
            obstacles[k].direction = -1
            if obstacles[k+1] then obstacles[k+1].direction = -1 end
        end

        -- check collisions with bonuses
        for _, b in pairs(bonuses) do
            local collide_obs = checkCollision(b.x, b.y, b.size, b.size, 
                                 o.x, o.y, o.length, o.height) 
            if collide_obs then
                if b.y + b.size - obstacles_speed - b.speed <= o.y then
                    b.y = o.y - b.size - obstacles_speed
                end
            end
        end

        -- check collisions with player
        collide = checkCollision(player.x, player.y, player.size, player.size, 
                                 o.x, o.y, o.length, o.height) 
        if collide then
            if player.y + player.size - player.speed - obstacles_speed <= o.y then
                player.y = o.y - player.size - player.speed - obstacles_speed + 1
                player.speed = 0
            else
                -- don't let the player fly into collision from sides
                player.canmove = false 
                if player.x > o.x then
                    player.x = o.x + o.length
                elseif player.x < o.x then
                    player.x = o.x - player.size
                else
                    print('Something is going wrong with player [x]!')
                end
            end
        end

        -- remove unneeded obstacles
        if o.y < -o.height then
            table.remove(obstacles, k)
            score = score + 0.5
        end
    end

    -- move player
    if not (player.y >= height - player.size) then
        player.y = player.y + player.speed 
    end
    
    -- game over?
    if player.y < 0 then
        endgame()
    end

    -- don't let the player go offscreen
    player.x = math.max(0, player.x)
    player.x = math.min(width-player.size, player.x)

    -- update buff timers
    for _, buff in pairs(buffs) do
        local expired = buff:update(dt)
        if expired then table.remove(buffs, _) end
    end
end

function store(dt)
    if love.keyboard.isDown('1') then
        buy_speed()
    elseif love.keyboard.isDown('0') then
        state = 'game'
        music:play()
    end
    if message_clock then message_clock:update(dt) end
end

function buy_speed()
    if player.movespeed <= maxspeed then
        if coins >= speed_price() then
            coins = coins - speed_price()
            player.movespeed = player.movespeed + 1
            menumsg('Your new speed is ' .. player.movespeed .. '!')
            saveGame()
        else
            menumsg('Not enough money.')
        end
    else
        menumsg('You are too fast already.')
    end
end

function menumsg(str)
    if not justpressed then
        message = str
    end
    justpressed = true
    local function pm() message = '' justpressed = false end
    message_clock = cron.after(0.1, pm)
end

function endgame()
    highscore = math.max(score, highscore)
    saveGame()
    player.y = 0
    score = 0
    bonuses = {}
    obstacles = {}
    for _, buff in pairs(buffs) do
        buff:update(5)
    end
    buffs = {}
    bars = {}
    time_to_next = 0
    state = 'store'
    music:stop()
end

function move_player(side)    
    -- move player only if he doesn't collide obstacle from side he wants move
    if player.canmove then
        if side == 'left' then
            player.x = player.x - player.movespeed
        elseif side == 'right' then
            player.x = player.x + player.movespeed
        end
    end
end

function android_control()
    local touches = love.touch and love.touch.getTouchCount() or 0
    if touches > 0 then
        local id, tx, ty = love.touch.getTouch(touches)
        if state=='store' then
            if tx <= 0.5 then
                buy_speed()
            else
                state='game'
            end
       elseif state=='game' then
            if tx <= 0.5 then
                move_player('left')
            else
                move_player('right')
            end
        end
    end
end
