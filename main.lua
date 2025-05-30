local score = 0
local add = 1
local addpersec = 1
local combo = 0
local combo_timer = 0
local combo_max_time = 2
local cps_timer = 0

local font, font_large
local buttons = {}
local clicker_radius = 100
local clicker_x, clicker_y = 450, 350
local coffee_images = {}
local current_coffee = 1
local background_image

-- Particle systems for floating numbers and coffee
local floating_numbers = {}
local coffee_particles = {}

local upgrade_levels = {
    { cpc = 20, cps = 20, cpc_add = 1, cps_add = 1, mult = 1.4 },
    { cpc = 150, cps = 150, cpc_add = 5, cps_add = 5, mult = 1.3 },
    { cpc = 1400, cps = 1400, cpc_add = 20, cps_add = 20, mult = 1.2 },
    { cpc = 12000, cps = 12000, cpc_add = 125, cps_add = 125, mult = 1.1 },
    { cpc = 200000, cps = 200000, cpc_add = 500, cps_add = 500, mult = 1.1 }
}

function createFloatingNumber(x, y, amount)
    table.insert(floating_numbers, {
        x = x,
        y = y,
        amount = amount,
        alpha = 1,
        scale = 1,
        rotation = 0,
        lifetime = 1
    })
end

function createCoffeeParticle(x, y)
    local angle = math.random() * math.pi * 2
    local speed = math.random(100, 200)
    local size = math.random(20, 40)
    table.insert(coffee_particles, {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = -speed,
        size = size,
        rotation = 0,
        rotation_speed = (math.random() - 0.5) * 10,
        lifetime = 1,
        image = coffee_images[math.random(1, 5)]
    })
end

function createButton(label, x, y, w, h, action, type, level)
    table.insert(buttons, {
        label = label,
        x = x, y = y,
        w = w, h = h,
        type = type,
        level = level,
        hover = false,
        action = action
    })
end

function love.load()
    love.window.setMode(900, 700)
    love.window.setTitle("Clicker Game with UI Upgrades")

    font = love.graphics.newFont(18)
    font_large = love.graphics.newFont(28)
    love.graphics.setFont(font)

    -- Load background
    background_image = love.graphics.newImage("background.jpg")

    -- Load coffee images
    for i = 1, 5 do
        coffee_images[i] = love.graphics.newImage("coffee" .. i .. ".png")
    end

    -- CPC and CPS buttons
    for i, level in ipairs(upgrade_levels) do
        local y = 120 + (i - 1) * 60
        createButton("", 50, y, 300, 40, nil, "cpc", i)
        createButton("", 550, y, 300, 40, nil, "cps", i)
    end
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()

    -- Update floating numbers
    for i = #floating_numbers, 1, -1 do
        local num = floating_numbers[i]
        num.y = num.y - 100 * dt
        num.alpha = num.alpha - dt
        num.scale = num.scale + dt * 0.5
        num.lifetime = num.lifetime - dt
        if num.lifetime <= 0 then
            table.remove(floating_numbers, i)
        end
    end

    -- Update coffee particles
    for i = #coffee_particles, 1, -1 do
        local p = coffee_particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 500 * dt -- gravity
        p.rotation = p.rotation + p.rotation_speed * dt
        p.lifetime = p.lifetime - dt
        if p.lifetime <= 0 then
            table.remove(coffee_particles, i)
        end
    end

    for _, btn in ipairs(buttons) do
        btn.hover = mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h

        if btn.type == "cpc" then
            local lvl = upgrade_levels[btn.level]
            btn.label = "+" .. lvl.cpc_add .. " CPC [" .. lvl.cpc .. "]"
            btn.enabled = score >= lvl.cpc
            btn.action = function()
                if score >= lvl.cpc then
                    score = score - lvl.cpc
                    add = add + lvl.cpc_add
                    lvl.cpc = math.floor(lvl.cpc * lvl.mult)
                end
            end
        elseif btn.type == "cps" then
            local lvl = upgrade_levels[btn.level]
            btn.label = "+" .. lvl.cps_add .. " CPS [" .. lvl.cps .. "]"
            btn.enabled = score >= lvl.cps
            btn.action = function()
                if score >= lvl.cps then
                    score = score - lvl.cps
                    addpersec = addpersec + lvl.cps_add
                    lvl.cps = math.floor(lvl.cps * lvl.mult)
                end
            end
        end
    end

    -- Combo + CPS handling
    if combo > 0 then
        combo_timer = combo_timer - dt
        if combo_timer <= 0 then
            combo = 0
        end
    end

    cps_timer = cps_timer + dt
    if cps_timer >= 1 then
        score = score + addpersec
        cps_timer = cps_timer - 1
    end
end

function love.draw()
    -- Draw background
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background_image, 0, 0, 0, 900/background_image:getWidth(), 700/background_image:getHeight())
    
    -- Draw coffee particles
    for _, p in ipairs(coffee_particles) do
        love.graphics.setColor(1, 1, 1, p.lifetime)
        local scale = p.size / p.image:getWidth()
        love.graphics.draw(p.image, p.x, p.y, p.rotation, scale, scale, p.image:getWidth()/2, p.image:getHeight()/2)
    end

    -- Draw floating numbers
    love.graphics.setFont(font_large)
    for _, num in ipairs(floating_numbers) do
        love.graphics.setColor(1, 1, 0, num.alpha)
        love.graphics.printf("+" .. num.amount, num.x - 50, num.y, 100, "center", 0, num.scale, num.scale)
    end
    
    -- Score display
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font_large)
    love.graphics.printf("Score: " .. score, 0, 20, 900, "center")

    -- Stats display
    love.graphics.setFont(font)
    love.graphics.printf("CPC: " .. add .. " | CPS: " .. addpersec .. " | Combo: " .. combo, 0, 60, 900, "center")

    -- Upgrade headers
    love.graphics.setFont(font_large)
    love.graphics.print("CPC Upgrades", 50, 90)
    love.graphics.print("CPS Upgrades", 550, 90)

    -- Draw the coffee clicker
    local mx, my = love.mouse.getPosition()
    local distance = math.sqrt((mx - clicker_x)^2 + (my - clicker_y)^2)
    local hover = distance <= clicker_radius
    
    love.graphics.setColor(1, 1, 1)
    if hover then
        love.graphics.setColor(1.2, 1.2, 1.2)
    end
    
    -- Draw coffee image centered
    local img = coffee_images[current_coffee]
    local scale = (clicker_radius * 2) / math.max(img:getWidth(), img:getHeight())
    love.graphics.draw(img, clicker_x, clicker_y, 0, scale, scale, img:getWidth()/2, img:getHeight()/2)

    -- Draw upgrade buttons
    for _, btn in ipairs(buttons) do
        local bg = {0.3, 0.6, 1}
        if btn.type ~= "click" and not btn.enabled then
            bg = {0.4, 0.4, 0.4}
        elseif btn.hover then
            bg = {0.4, 0.7, 1}
        end

        love.graphics.setColor(bg)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 12, 12)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(font)
        love.graphics.printf(btn.label, btn.x, btn.y + 10, btn.w, "center")
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check if clicker was pressed
        local distance = math.sqrt((x - clicker_x)^2 + (y - clicker_y)^2)
        if distance <= clicker_radius then
            -- Cycle to next coffee image
            current_coffee = current_coffee % 5 + 1
            
            -- Calculate points earned
            local points_earned = combo > 10 and math.floor(add * (combo / 10)) or add
            
            -- Create floating number
            createFloatingNumber(x, y, points_earned)
            
            -- Create coffee particles
            for i = 1, 3 do
                createCoffeeParticle(x, y)
            end
            
            combo = math.min(combo + 1, 25)
            combo_timer = combo_max_time
            if combo > 10 then
                score = score + points_earned
            else
                score = score + add
            end
            return
        end

        -- Check upgrade buttons
        for _, btn in ipairs(buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                if btn.action and (btn.type == "click" or btn.enabled) then
                    btn.action()
                end
            end
        end
    end
end

