love.filesystem.load('io.lua')()
love.filesystem.load('bonus.lua')()
love.filesystem.load('store.lua')()
love.filesystem.load(love.touch and 'android.lua' or 'pc.lua')()

require 'Tserial'
cron=require 'cron/cron'

love.filesystem.setIdentity('Fall')
love.window.setMode(0, 0, {fullscreen=true})

function love.load()
    width, height = love.window.getMode()

    -- Start in store with no messages
    state = 'store'
    message = ''

    font = love.graphics.newFont('high_scores.ttf', 48)

    music = love.audio.newSource('hexagon-force.mp3')

    player = {x = (width/(25/24))/2, y = 0, speed = 0, size = height/25, 
              canmove = true, movespeed=width/100, acceleration = height/2500}
    maxspeed = width/40   -- maximum speed on y-axis

    speed_price = function() return math.ceil((player.movespeed-2)^1.8) end

    obstacles = {}
    time_to_next = 0 -- spawn first obstacle immediately
    base_speed = height/250

    correction = function() return math.max(0, player.y - height + height/4 + player.size)/height*50 end
    obstacles_speed = function() return base_speed + score^0.7/height*100 + correction() end
    obstacle_height = height/35
    hole_size = width/10

    bonuses = {}
    bonus_size = height/35
    bonus_freq = 17

    buffs = {}  -- effects on player given by some bonuses
    
    bars = {}   -- represent time for some bonuses
    bar_width = height/30

    SAVENAME = 'scores.save'
    score = 0
    loadGame()
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
        love.graphics.rectangle('fill', player.x, player.y+obstacles_speed(),
                                        player.size, player.size)
        -- bonuses
        for _, b in pairs(bonuses) do
            love.graphics.setColor(b.col[1], b.col[2], b.col[3]) -- gold
            love.graphics.rectangle('fill', b.x, b.y+obstacles_speed(),
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
                                    bar[1]*20, bar_width)   -- FIXME
        end

        --scores
        love.graphics.setColor(191, 255, 0)
        love.graphics.print('Score:' .. math.ceil(score), 0, 0)
        love.graphics.print('Speed:' .. math.ceil(obstacles_speed() * 25), 0, 30)
    elseif state == 'store' then
        drawStore()
    end
end

function love.update(dt)
    input()

    if state =='game' then
        game(dt)
    elseif state =='store' then
        if message_clock then message_clock:update(dt) end
    end
end

function createObstacle()
    hole_position = hole_size + math.random(width-hole_size*2)
    local ms = math.max(0, math.random(-5, 5))
    local d = (math.random() > 0.5) and 1 or -1

    local obstacle1 = {x = hole_position+hole_size, y = height, direction = d,
                 length = width, height = obstacle_height, movespeed = ms}
    local obstacle2 = {x = -width+hole_position-hole_size, y = height, direction = d,
                 length = width, height = obstacle_height, movespeed = ms}

    table.insert(obstacles, obstacle1)
    table.insert(obstacles, obstacle2)
end

function game(dt)
    updateBonuses()
    updateBars(dt)
    updateBuffs(dt)

    -- spawn obstacle if time has come
    if time_to_next <= 0 then
        time_to_next = height/5
        createObstacle()
    end

    time_to_next = time_to_next - obstacles_speed()

    if math.random(0, 1000) < bonus_freq then
        spawnBonus()
    end

    player.speed = player.speed + player.acceleration
    player.canmove = true


    for k, o in pairs(obstacles) do
        -- move obstacles (y)
        obstacles[k].y = o.y - obstacles_speed()

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
                if b.y + b.size - obstacles_speed() - b.speed <= o.y then
                    b.y = o.y - b.size - obstacles_speed() + b.speed
                end
            end
        end

        -- check collisions with player
        collide = checkCollision(player.x, player.y, player.size, player.size, 
                                 o.x, o.y, o.length, o.height) 
        if collide then
            if player.y + player.size - player.speed - obstacles_speed() <= o.y then
                player.y = o.y - player.size - player.speed - obstacles_speed() + 1
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
    
    if player.y < 0 then
        endGame()
    end

    -- don't let the player go offscreen
    player.x = math.max(0, player.x)
    player.x = math.min(width-player.size, player.x)
end

function endGame()
    highscore = math.max(score, highscore)
    saveGame()
    player.y = 0
    score = 0
    obstacles = {}
    time_to_next = 0
    bonuses = {}
    for _, buff in pairs(buffs) do
        buff:update(5)
    end
    buffs = {}
    bars = {}
    state = 'store'
    music:stop()
end

function movePlayer(side)    
    -- move player only if he doesn't collide obstacle from side
    if player.canmove then
        if side == 'left' then
            player.x = player.x - player.movespeed
        elseif side == 'right' then
            player.x = player.x + player.movespeed
        end
    end
end

function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return  x1 < x2+w2 and
            x2 < x1+w1 and
            y1 < y2+h2 and
            y2 < y1+h1
end
