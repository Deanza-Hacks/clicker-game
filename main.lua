-- Simple Clicker Game using Love2D

local score = 0
local button = {
    x = 300,
    y = 200,
    width = 200,
    height = 100,
    text = "Click Me!"
}

function love.load()
    love.window.setTitle("Clicker Game")
    love.window.setMode(800, 600)
    font = love.graphics.newFont(32)
    love.graphics.setFont(font)
end

function love.draw()
    -- Draw score
    love.graphics.printf("Score: " .. score, 0, 50, love.graphics.getWidth(), "center")

    -- Draw button
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)

    -- Draw button text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(button.text, button.x, button.y + 30, button.width, "center")
end

function love.mousepressed(x, y, buttonType, isTouch, presses)
    if buttonType == 1 then -- left click
        if x > button.x and x < button.x + button.width and
           y > button.y and y < button.y + button.height then
            score = score + 1
        end
    end
end

