local score = 0
local add = 1
local addpersec = 1
local combo = 0
local combo_timer = 0
local combo_max_time = 2
local cps_timer = 0

local font, font_large, font_huge
local buttons = {}
local clicker_radius = 80
local clicker_x, clicker_y = 600, 350  -- Moved clicker to the right
local laundry_images = {}
local bike_images = {}
local car_images = {}
local current_clicker = 1
local background_image
local background2_image
local background3_image
local button_image
local sock_image
local game_phase = 1  -- 1 for laundry, 2 for bike, 3 for car

-- Character animation variables
local character_images = {}
local character_x = 100
local character_y = 600
local character_speed = 200
local character_direction = 1
local character_frame = 1
local character_frame_timer = 0
local character_frame_duration = 0.2

-- Clicker animation variables
local clicker_scale = 1
local clicker_tilt = 0
local clicker_tilt_amount = 0
local clicker_tilt_decay = 0.9

-- Particle systems for floating numbers and laundry
local floating_numbers = {}
local laundry_particles = {}

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
        scale = 2.0,  -- Made pop-out numbers larger
        rotation = 0,
        lifetime = 1.5
    })
end

function createLaundryParticle(x, y)
    local angle = math.random() * math.pi * 2
    local speed = math.random(100, 200)
    local size = math.random(30, 60)  -- Made particles larger
    table.insert(laundry_particles, {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = -speed,
        size = size,
        rotation = 0,
        rotation_speed = (math.random() - 0.5) * 10,
        lifetime = 1,
        image = laundry_images[math.random(1, 3)]
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
    love.window.setMode(1200, 800)
    love.window.setTitle("Clicker Game with UI Upgrades")

    font = love.graphics.newFont(18)
    font_large = love.graphics.newFont(28)
    font_huge = love.graphics.newFont(48)  -- Added huge font for SOCKS
    love.graphics.setFont(font)

    -- Load background
    background_image = love.graphics.newImage("background.png")
    background2_image = love.graphics.newImage("background2.png")
    background3_image = love.graphics.newImage("background3.png")
    button_image = love.graphics.newImage("button1.jpg")
    sock_image = love.graphics.newImage("sock.png")

    -- Load character images
    character_images[1] = love.graphics.newImage("MainChar1.png")
    character_images[2] = love.graphics.newImage("MainChar2.png")

    -- Load laundry images
    for i = 1, 3 do
        laundry_images[i] = love.graphics.newImage("laundry" .. i .. ".png")
    end

    -- Load bike images
    for i = 1, 3 do
        bike_images[i] = love.graphics.newImage("Bike" .. i .. ".png")
    end

    -- Load car images
    for i = 1, 2 do
        car_images[i] = love.graphics.newImage("Car" .. i .. ".png")
    end

    -- CPC and CPS buttons
    local cpc_names = {
        "Laundry Machine",
        "Bike Taxi",
        "Van Taxi",
        "Plane Taxi",
        "Slipper Factory Owner"
    }
    
    local cps_names = {
        "Laundromat Worker",
        "Bike Taxi Driver",
        "Van Taxi Driver",
        "Plane Taxi Driver",
        "Slipper Factory Owner"
    }

    for i, level in ipairs(upgrade_levels) do
        local y = 300 + (i - 1) * 70  -- Moved buttons further down
        createButton(cpc_names[i], 50, y, 300, 40, nil, "cpc", i)
        createButton(cps_names[i], 800, y, 300, 40, nil, "cps", i)  -- Moved right buttons further right
    end
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()

    -- Update character position and animation
    character_x = character_x + character_speed * character_direction * dt
    
    -- Bounce off screen edges
    if character_x <= 0 then
        character_x = 0
        character_direction = 1
    elseif character_x >= 800 then  -- Assuming character width is ~100px
        character_x = 800
        character_direction = -1
    end
    
    -- Update character animation
    character_frame_timer = character_frame_timer + dt
    if character_frame_timer >= character_frame_duration then
        character_frame_timer = 0
        character_frame = character_frame == 1 and 2 or 1
    end

    -- Update clicker animation
    clicker_scale = 1 + (clicker_scale - 1) * 0.9  -- Smoothly return to normal size
    clicker_tilt = clicker_tilt * clicker_tilt_decay  -- Decay tilt effect

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

    -- Update laundry particles
    for i = #laundry_particles, 1, -1 do
        local p = laundry_particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 500 * dt -- gravity
        p.rotation = p.rotation + p.rotation_speed * dt
        p.lifetime = p.lifetime - dt
        if p.lifetime <= 0 then
            table.remove(laundry_particles, i)
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
    -- Draw background with reduced saturation
    love.graphics.setColor(0.8, 0.8, 0.8)  -- Reduced color intensity to 80%
    local current_background = game_phase == 1 and background_image or game_phase == 2 and background2_image or background3_image
    love.graphics.draw(current_background, 0, 0, 0, 1200/current_background:getWidth(), 800/current_background:getHeight())
    
    -- Reset color for other elements
    love.graphics.setColor(1, 1, 1)
    
    -- Draw character
    local scale = 4.0
    local img = character_images[character_frame]
    love.graphics.draw(img, character_x, character_y, 0, 
        character_direction * scale, scale,
        img:getWidth()/2, img:getHeight()/2)
    
    -- Draw laundry particles
    for _, p in ipairs(laundry_particles) do
        love.graphics.setColor(1, 1, 1, p.lifetime)
        local scale = p.size / p.image:getWidth()
        love.graphics.draw(p.image, p.x, p.y, p.rotation, scale, scale, p.image:getWidth()/2, p.image:getHeight()/2)
    end

    -- Draw floating numbers
    love.graphics.setFont(font_large)
    for _, num in ipairs(floating_numbers) do
        love.graphics.setColor(1, 1, 0, num.alpha)
        love.graphics.printf("+" .. num.amount, num.x - 150, num.y, 300, "center", 0, num.scale, num.scale)
    end

    -- Draw SOCKS score with sock icon
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font_huge)
    local sock_size = 60
    local sock_scale = sock_size / sock_image:getWidth()
    local score_text = "SOCKS: " .. score
    local text_width = font_huge:getWidth(score_text)
    local total_width = text_width + sock_size + 20
    
    -- Draw sock icon
    love.graphics.draw(sock_image, 
        600 - total_width/2,
        20,
        0, sock_scale, sock_scale)
    
    -- Draw score text
    love.graphics.printf(score_text, 
        600 - total_width/2 + sock_size + 20,
        20,
        text_width, "left")

    -- Draw the laundry clicker
    local mx, my = love.mouse.getPosition()
    local distance = math.sqrt((mx - clicker_x)^2 + (my - clicker_y)^2)
    local hover = distance <= clicker_radius
    
    -- Draw drop shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    local img = game_phase == 1 and laundry_images[current_clicker] or game_phase == 2 and bike_images[current_clicker] or car_images[current_clicker]
    local base_scale = (clicker_radius * 2) / math.max(img:getWidth(), img:getHeight())
    local final_scale = base_scale * clicker_scale
    love.graphics.draw(img, 
        clicker_x + 5, 
        clicker_y + 5, 
        clicker_tilt * 0.08,
        final_scale, 
        final_scale, 
        img:getWidth()/2, 
        img:getHeight()/2)
    
    -- Draw clicker
    love.graphics.setColor(1, 1, 1)
    if hover then
        love.graphics.setColor(1.2, 1.2, 1.2)
    end
    love.graphics.draw(img, 
        clicker_x, 
        clicker_y, 
        clicker_tilt * 0.08,
        final_scale, 
        final_scale, 
        img:getWidth()/2, 
        img:getHeight()/2)

    -- Draw upgrade buttons
    for _, btn in ipairs(buttons) do
        -- Draw button background
        love.graphics.setColor(0.8, 0.7, 1)  -- Light purple color
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 20, 20)
        
        -- Draw icon next to button
        love.graphics.setColor(1, 1, 1)
        local icon_size = btn.h * 1.2
        local icon_image = btn.level == 1 and laundry_images[3] or btn.level == 2 and bike_images[1] or car_images[1]
        love.graphics.draw(icon_image, 
            btn.x - icon_size - 5,
            btn.y + (btn.h - icon_size)/2,
            0, icon_size/icon_image:getWidth(), icon_size/icon_image:getHeight())

        -- Draw button text
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.setFont(font)
        love.graphics.printf(btn.label, btn.x, btn.y + 10, btn.w, "center")
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check if clicker was pressed
        local distance = math.sqrt((x - clicker_x)^2 + (y - clicker_y)^2)
        if distance <= clicker_radius then
            -- Trigger clicker animations
            clicker_scale = 0.7  -- More dramatic shrink
            clicker_tilt = 8    -- More dramatic tilt
            
            -- Cycle to next image
            local max_images = game_phase == 1 and 3 or game_phase == 2 and 3 or 2
            current_clicker = current_clicker % max_images + 1
            
            -- Calculate points earned
            local points_earned = combo > 10 and math.floor(add * (combo / 10)) or add
            
            -- Create floating number
            createFloatingNumber(x, y, points_earned)
            
            -- Create particles
            for i = 1, 5 do  -- Increased particle count
                createLaundryParticle(x, y)
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
                    -- Check if this is the second upgrade of either type
                    if btn.level == 2 then
                        game_phase = 2  -- Changed to phase 2 instead of 3
                    elseif btn.level == 3 then
                        game_phase = 3  -- Move to phase 3 on third upgrade
                    end
                end
            end
        end
    end
end

