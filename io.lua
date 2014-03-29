function loadGame()
    if love.filesystem.exists(SAVENAME) then
        loaded = Tserial.unpack(love.filesystem.read(SAVENAME))
    end
        highscore = loaded and loaded[1] or 0
        coins = loaded and loaded[2] or 0
        player.movespeed = loaded and loaded[3] or player.movespeed
end


function saveGame()
    love.filesystem.write(SAVENAME, Tserial.pack({highscore, coins,
                                                  player.movespeed}))
end
