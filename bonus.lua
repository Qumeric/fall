function spawnBonus()
    local classes = {
        {'destroy',          {000, 127, 255}},
        {'player.movespeed', {200, 255, 0}},
        {'hole_size',        {255, 253, 208}},
        {'base_speed',       {255, 000, 255}}}
    local c = {'coin', {255, 215, 0}}
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
    loadstring(c .. '+ ' .. power)()
    local f = function() loadstring(c .. '- ' .. power)() end
    table.insert(buffs, cron.after(time, f))
    table.insert(bars, {5, color})
end

function updateBuffs(dt)
    for _, buff in pairs(buffs) do
        local expired = buff:update(dt)
        if expired then table.remove(buffs, _) end
    end
end

function updateBars(dt)
    for k, bar in pairs(bars) do
        bars[k][1] = bar[1] - dt
        if bar[1] <= 0 then
            table.remove(bars, k)
        end
    end
end

function updateBonuses()
    for k, b in pairs(bonuses) do
        local collide_player = checkCollision(b.x, b.y, b.size, b.size, 
                                 player.x, player.y, player.size, player.size) 
        if collide_player then
            consumeBonus(b)
            bonuses[k] = nil
        end
        b.y = b.y + b.speed
        if b.y <= -b.size or b.y > height then
            table.remove(bonuses,k)
        end
    end
end

