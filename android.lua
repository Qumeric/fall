function input()
    local touches = love.touch.getTouchCount()
    if touches > 0 then
        local id, tx, ty = love.touch.getTouch(touches)
        if state=='store' then
            if tx <= 0.5 then
                buySpeed()
            else
                state='game'
                music:play()
            end
       elseif state=='game' then
            if tx <= 0.5 then
                movePlayer('left')
            else
                movePlayer('right')
            end
        end
    end
end
