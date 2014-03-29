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
