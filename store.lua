function buySpeed()
    if player.movespeed <= maxspeed then
        if coins >= speed_price() then
            coins = coins - speed_price()
            player.movespeed = player.movespeed + 1
            storeMessage('Your new speed is ' .. player.movespeed .. '!')
            saveGame()
        else
            storeMessage('Not enough money.')
        end
    else
        storeMessage('You are too fast already.')
    end
end

function storeMessage(str)
    if not justpressed then
        message = str
    end
    justpressed = true
    local function pm() message = '' justpressed = false end
    message_clock = cron.after(0.1, pm)
end

function drawStore()
    OSSpecificStore()
    love.graphics.setColor(191, 255, 0)
    love.graphics.print('Highscore:'  .. highscore, 0, 0)
    love.graphics.print('Money:    '  .. coins, 0, 30)
    love.graphics.print('Movespeed:'  .. player.movespeed, 0, 60)
end
