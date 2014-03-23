require 'Tserial'
function love.conf(t)
    t.window.width = 500
    t.window.height = 500
end

function love.load()
    SAVENAME = 'scores.save'
    font = love.graphics.newFont('high_scores.ttf', 48)
    music = love.audio.newSource('hexagon-force.mp3')
    music:play()
    width = love.graphics.getWidth()
    height = love.graphics.getWidth()
    player = {x = (width - 25)/2, y = 0, speed = 0, size = 25, canmove = true, movespeed=20}
    base_speed = 5
    obstacles_speed = base_speed
    bonus_size = 20
    time_to_next = 0
    hole_size = 50
    obstacles = {}
    bonuses = {}
    score = 0
    highscore = 0
    if love.filesystem.exists(SAVENAME) then
        highscore = Tserial.unpack(love.filesystem.read(SAVENAME))[1]
    end
end

function love.draw()
    -- background
    love.graphics.setColor(50, 40, 30)
    love.graphics.rectangle('fill', 0, 0, width, height)
    
    -- scores
    love.graphics.setFont(font)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print(score, 5, 0)
    love.graphics.print(highscore, 105, 0)

    -- player
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle('fill', player.x, player.y, player.size, player.size)

    -- obstacles
    love.graphics.setColor(255, 255, 255)
    for _, o in pairs(obstacles) do -- FIXME?
        love.graphics.rectangle('fill', o.x, o.y, o.length, o.height)
    end
end

function love.update()
    if time_to_next <= 0 then
        time_to_next = 100
        createObstacle()
    end

    time_to_next = time_to_next - obstacles_speed

    if player.canmove then
        if love.keyboard.isDown('left') then
            player.x = player.x - player.movespeed
        elseif love.keyboard.isDown('right') then
            player.x = player.x + player.movespeed
        end
    end

    player.speed = player.speed + 1 
    player.canmove = true

    for k, o in pairs(obstacles) do
        correction = math.max(0, player.y - height + 200 + player.size)/30
        obstacles_speed = base_speed + correction + score^0.4/10
        obstacles[k].y = o.y - obstacles_speed 
        --print(correction)

        --print(player.y, o.y)
        if checkCollision(player.x, player.y, player.size, player.size,
                          o.x, o.y, o.length, o.height) then
            if player.y + o.height - player.speed <= o.y then
                player.speed = 0
                player.y = o.y - o.height - player.speed - obstacles_speed
            else
                player.canmove = false 
                if player.x > o.x then
                    player.x = o.x + o.length
                elseif player.x < o.x then
                    player.x = o.x - player.size
                else
                    print('Something is going wrong (player.x)')
                end
            end
        end

        if o.y < -o.height then
            obstacles[k] = nil
            score = score + 0.5
        end
    end

    if not (player.y >= height - player.size) then
        player.y = player.y + player.speed 
    end
    
    if player.y < 0 then
        print('Game over!')
        highscore = math.max(score, highscore)
        saveGame()
        player.y = 0
        score = 0
        bonuses = {}
        obstacles = {}
        time_to_next = 0
        love.timer.sleep(1)
    end

    player.x = math.max(0, player.x)
    player.x = math.min(width-player.size, player.x)
end

function createObstacle()
    hole_position = hole_size + math.ceil(math.random()*(width-hole_size*2)+0.5) 
    --print(hole_position)
    obstacle1 = {x = hole_position+hole_size, y = height, length = width, height = 20}
    obstacle2 = {x = -width+hole_position-hole_size, y = height, length = width, height = 20}
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
    love.filesystem.write(SAVENAME, Tserial.pack({highscore}))
end
