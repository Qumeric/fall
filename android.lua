function input()
    local touches = love.touch.getTouches()

    if #touches > 0 and state=='game' then
        local id, tx, ty = love.touch.getPosition(touches[1])

        if tx <= love.graphics.getWidth() / 2 then
            movePlayer('left')
        else
            movePlayer('right')
        end
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if state=='store' then
        if x <= love.graphics.getWidth() / 2 then
            buySpeed()
        else
            state='game'
            music:play()
        end
    end
end

function OSSpecificStore()
    local bigFont = love.graphics.newFont('high_scores.ttf', height)
    love.graphics.setFont(bigFont)
    love.graphics.setColor(150/255, 128/255, 40/255)
    love.graphics.rectangle('fill', 0, 0, width/2, height)
    love.graphics.setColor(40/255, 150/255, 40/255)
    love.graphics.rectangle('fill', width/2, 0, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print('$', width/8, height/10)
    love.graphics.print('>', 5 * width/8, height/10)
    love.graphics.setFont(font)
    love.graphics.print(speed_price(), 0, height-50)
end
