require 'Tserial'
function love.conf(t)
    t.window.width = 500
    t.window.height = 500
end

function love.load()
    font = love.graphics.newFont('high_scores.ttf', 48)

    music = love.audio.newSource('hexagon-force.mp3')
    music:play()

    width = love.graphics.getWidth()
    height = love.graphics.getWidth()

    player = {x = (width - 25)/2, y = 0, speed = 0, size = 25, 
              canmove = true, movespeed=20}

    time_to_next = 0
    base_speed = 5
    obstacles_speed = base_speed
    hole_size = 50
    obstacles = {}

    bonus_size = 20
    bonuses = {}

    SAVENAME = 'scores.save'
    score = 0
    highscore = 0
    coins = 0
    if love.filesystem.exists(SAVENAME) then
        loaded = Tserial.unpack(love.filesystem.read(SAVENAME))
        highscore = loaded[1]
        coins = loaded[2]
    end
end

function love.draw()
    -- background
    love.graphics.setColor(50, 40, 30)
    love.graphics.rectangle('fill', 0, 0, width, height)
    
    -- scores
    love.graphics.setFont(font)
    love.graphics.setColor(191, 255, 0)
    love.graphics.print('S:'  .. score, 5, 0)
    love.graphics.print('HS:' .. highscore, 95, 0)
    love.graphics.print('$:'  .. coins, 205, 0)

    -- player
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle('fill', player.x, player.y, player.size, player.size)

    -- bonuses
    love.graphics.setColor(0, 0, 0)
    for _, b in pairs(bonuses) do -- FIXME?
        if b.class == 'coin' then
            love.graphics.setColor(255, 215, 0) -- gold
            love.graphics.rectangle('fill', b.x, b.y+obstacles_speed, b.size, b.size)
        end
    end

    -- obstacles
    love.graphics.setColor(255, 255, 255)
    for _, o in pairs(obstacles) do -- FIXME?
        love.graphics.rectangle('fill', o.x, o.y, o.length, o.height)
    end
end

function love.update()

    -- spawn obstacle if time has come
    if time_to_next <= 0 then
        time_to_next = 100
        createObstacle()
    end

    -- spawn bonus
    if math.random() > 0.99 then
        spawnBonus()
    end

    time_to_next = time_to_next - obstacles_speed

    -- move player only if he doesn't collide obstacle from side he wants move
    if player.canmove then
        if love.keyboard.isDown('left') then
            player.x = player.x - player.movespeed
        elseif love.keyboard.isDown('right') then
            player.x = player.x + player.movespeed
        end
    end

    player.speed = player.speed + 1 
    player.canmove = true

    -- move and remove unneded bonuses
    for k, b in pairs(bonuses) do
        local collide_player = checkCollision(b.x, b.y, b.size, b.size, 
                                 player.x, player.y, player.size, player.size) 
        if collide_player then
            bonuses[k] = nil
            if b.class == 'coin' then
                coins = coins + 1
            end
        end
        b.y = b.y + b.speed
        if b.y < -b.size or b.y > height then
            bonuses[k] = nil
        end
    end

    for k, o in pairs(obstacles) do
        -- move obstacles (y)
        correction = math.max(0, player.y - height + 200 + player.size)/30
        obstacles_speed = base_speed + correction + score^0.4/10
        obstacles[k].y = o.y - obstacles_speed 

        -- move obstacles (x)
        obstacles[k].x = o.x + o.movespeed * o.direction
        if o.x < -o.length then 
            obstacles[k].direction = 1
            obstacles[k-1].direction = 1
        elseif o.x > width then
            obstacles[k].direction = -1
            obstacles[k+1].direction = -1
        end

        -- check collisions with bonuses
        for _, b in pairs(bonuses) do
            local collide_obs = checkCollision(b.x, b.y, b.size, b.size, 
                                 o.x, o.y, o.length, o.height) 
            if collide_obs then
                print(b.y, o.height, o.y)
                if b.y + o.height - obstacles_speed < o.y then
                    print('bonus collides')
                    b.y = o.y - o.height - obstacles_speed
                end
            end
        end

        -- check collisions with player
        collide = checkCollision(player.x, player.y, player.size, player.size, 
                                 o.x, o.y, o.length, o.height) 
        if collide then
            if player.y + o.height - player.speed <= o.y then
                player.speed = 0
                player.y = o.y - o.height - player.speed - obstacles_speed
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
            obstacles[k] = nil
            score = score + 0.5
        end
    end

    -- move player
    if not (player.y >= height - player.size) then
        player.y = player.y + player.speed 
    end
    
    -- game over?
    if player.y < 0 then
        highscore = math.max(score, highscore)
        saveGame()
        player.y = 0
        score = 0
        bonuses = {}
        obstacles = {}
        time_to_next = 0
        love.timer.sleep(1)
        music:rewind()
    end

    -- don't let the player go offscreen
    player.x = math.max(0, player.x)
    player.x = math.min(width-player.size, player.x)
end

function createObstacle()
    hole_position = hole_size + math.ceil(math.random()*(width-hole_size*2)+0.5) -- FIXME?
    local ms = math.max(0, (math.random()-0.5)*10)
    local d = (math.random() > 0.5) and 1 or -1

    obstacle1 = {x = hole_position+hole_size, y = height, direction = d,
                 length = width, height = 20, movespeed = ms}
    obstacle2 = {x = -width+hole_position-hole_size, y = height, direction = d,
                 length = width, height = 20, movespeed = ms}

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
    love.filesystem.write(SAVENAME, Tserial.pack({highscore, coins}))
end

function spawnBonus()
    bonus = {class = 'coin', size = bonus_size, speed = 1,
             x = math.random(width), y = math.random(height/2, height)-bonus_size}
    table.insert(bonuses, bonus)
end
