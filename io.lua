function loadGame()
    if love.filesystem.getInfo(SAVENAME) then
        local contents, size = love.filesystem.read(SAVENAME)
        if contents then
            loaded = Tserial.unpack(contents)
        end
    end
    highscore = loaded and loaded[1] or 0
    coins = loaded and loaded[2] or 0
    player.movespeed = loaded and loaded[3] or player.movespeed
end

function saveGame()
    local data = Tserial.pack({highscore, coins, player.movespeed})
    love.filesystem.write(SAVENAME, data)
end
