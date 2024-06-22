function spawnBonus()
    local classes = {
        {'destroy',          {0, 127/255, 1}},
        {'player.movespeed', {200/255, 1, 0}},
        {'hole_size',        {1, 253/255, 208/255}},
        {'base_speed',       {1, 0, 1}}}
    local c = {'coin', {1, 215/255, 0}}
    if math.random() > 0.7 then
        c = classes[math.random(#classes)]
    end
    local bonus = {class = c[1], size = bonus_size, speed = 1, col = c[2], 
             x = math.random(width),
             y = math.random(player.y, height)-bonus_size}
    if not checkCollision(bonus.x,  bonus.y,  bonus_size,  bonus_size,
                          player.x, player.y, player.size, player.size) then
        table.insert(bonuses, bonus)
    end
end

function consumeBonus(b)
    if b.class == 'coin' then
        coins = coins + 1
    elseif b.class  == 'destroy' then
        obstacles = {}
        time_to_next = 0
    else
        local power = b.class == 'base_speed' and -1.2 or
            5 + width/20 * (b.class == 'hole_size' and 1 or 0)
        makeBuff(b.class, power, 5, b.col)
    end
end

function makeBuff(stat, power, time, color)
    local c = stat .. '=' .. stat
    load(c .. '+ ' .. power)()
    local f = function() load(c .. '- ' .. power)() end
    table.insert(buffs, cron.after(time, f))
    table.insert(bars, {5, color})
end

function updateBuffs(dt)
    for i = #buffs, 1, -1 do
        local expired = buffs[i]:update(dt)
        if expired then table.remove(buffs, i) end
    end
end

function updateBars(dt)
    for i = #bars, 1, -1 do
        bars[i][1] = bars[i][1] - dt
        if bars[i][1] <= 0 then
            table.remove(bars, i)
        end
    end
end

function updateBonuses()
    for i = #bonuses, 1, -1 do
        local b = bonuses[i]
        local collide_player = checkCollision(b.x, b.y, b.size, b.size, 
                                 player.x, player.y, player.size, player.size) 
        if collide_player then
            consumeBonus(b)
            table.remove(bonuses, i)
        else
            b.y = b.y + b.speed
            if b.y <= -b.size or b.y > height then
                table.remove(bonuses, i)
            end
        end
    end
end
