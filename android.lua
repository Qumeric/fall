function input()
    local touches = love.touch.getTouchCount()

    if touches > 0 and state=='game' then
        local id, tx = love.touch.getTouch(touches)

        if tx <= 0.5 then
            movePlayer('left')
        else
            movePlayer('right')
        end
    end
end

function love.touchpressed(id, tx)
    if state=='store' then
        if tx <= 0.5 then
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
    love.graphics.setColor(150, 128, 40)
    love.graphics.rectangle('fill', 0, 0, width/2, height)
    love.graphics.setColor(40, 150, 40)
    love.graphics.rectangle('fill', width/2, 0, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print('$', width/8, height/10)
    love.graphics.print('>', 5 * width/8, height/10)
end
