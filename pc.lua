function input()
    if state=='game' then
        if love.keyboard.isDown('left') then
            movePlayer('left')
        elseif love.keyboard.isDown('right') then
            movePlayer('right')
        end
    elseif state=='store' then
        if love.keyboard.isDown('1') then
            buySpeed()
        elseif love.keyboard.isDown('0') then
            state = 'game'
            music:play()
        end
    end
end

function OSSpecificStore()
    love.graphics.setColor(255, 191, 0)
    love.graphics.print('Press 1 to buy a speed upgrade ($' ..
                         speed_price() .. ')',0, 200)
    love.graphics.print('Press 0 to start new game', 0, 300)
    love.graphics.setColor(250, 245, 191)
    love.graphics.print(message, 50, 400)
end
