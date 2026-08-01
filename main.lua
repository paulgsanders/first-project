-- File: main.lua

function _config()
    return {
        name = "Ball Catcher",
        pixel_perfect = true
    }
end

function _init()
    math.randomseed(os.time())

    -- State tracks overall game settings AND scene state
    State = {
        current_scene = "title", -- Options: "title", "gameplay", "gameover"
        score = 0,
        high_score = 0,
        lives = 3,
        wave_counter = 0,
        player = {
            x = usagi.GAME_W / 2 - 8,
            y = usagi.GAME_H - 24,
            w = 16,
            h = 16,
            speed = 150
        },
        ball = {
            x = math.random(10, usagi.GAME_W - 26),
            y = -16,
            w = 16,
            h = 16,
            speed = 80,
            ball_sprite = math.random(1, 6),
        }
    }

    -- local saved_data = usagi.load()
end

-- Reset gameplay values without touching scene management
function reset_gameplay()
    State.score = 0
    State.lives = 3
    State.player.x = usagi.GAME_W / 2 - 8
    State.ball.speed = 80
    State.wave_counter = 0
    reset_ball()
end

function reset_ball()
    State.ball.y = -16
    State.ball.x = math.random(10, usagi.GAME_W - 26)
    State.ball.ball_sprite = math.random(1, 6)
end

----------------------------------------------------
-- MAIN UPDATE LOOP (State Dispatcher)
----------------------------------------------------
function _update(dt)
    if State.current_scene == "title" then
        update_title(dt)
    elseif State.current_scene == "gameplay" then
        update_gameplay(dt)
    elseif State.current_scene == "gameover" then
        update_gameover(dt)
    end
end

----------------------------------------------------
-- MAIN DRAW LOOP (State Dispatcher)
----------------------------------------------------
function _draw(dt)
    gfx.clear(gfx.COLOR_BLACK)

    if State.current_scene == "title" then
        draw_title(dt)
    elseif State.current_scene == "gameplay" then
        draw_gameplay(dt)
    elseif State.current_scene == "gameover" then
        draw_gameover(dt)
    end
end

----------------------------------------------------
-- SCENE 1: TITLE SCREEN
----------------------------------------------------
function update_title(dt)
    -- Press BTN1 (Z/J/A) to start playing
    if input.pressed(input.BTN1) then
        reset_gameplay()
        State.current_scene = "gameplay"
    end
end

function draw_title(dt)
    local title = "BALL CATCHER"
    local prompt = "Press BTN1 (Z/J) to Start"

    local w1, _ = usagi.measure_text(title)
    local w2, _ = usagi.measure_text(prompt)

    gfx.text(title, (usagi.GAME_W - w1) / 2, usagi.GAME_H / 2 - 16, gfx.COLOR_YELLOW)
    gfx.text(prompt, (usagi.GAME_W - w2) / 2, usagi.GAME_H / 2 + 8, gfx.COLOR_WHITE)
end

----------------------------------------------------
-- SCENE 2: GAMEPLAY
----------------------------------------------------
function update_gameplay(dt)
    local p = State.player
    local c = State.ball

    -- Input
    if input.held(input.LEFT) then
        p.x -= p.speed * dt
    end
    if input.held(input.RIGHT) then
        p.x += p.speed * dt
    end
    p.x = util.clamp(p.x, 0, usagi.GAME_W - p.w)

    -- Movement
    c.y += c.speed * dt

    -- Collisions
    if util.rect_overlap(p, c) then
        State.score += 1
        if State.score > State.high_score then
            State.high_score = State.score
        end
        State.wave_counter += 1
        if State.wave_counter >= 5 then
            State.ball.speed += 15
            State.wave_counter = 0
        end
        effect.screen_shake(0.1, 2)
        reset_ball()
    end

    -- Missed coin
    if c.y > usagi.GAME_H then
        State.lives -= 1
        reset_ball()
        effect.flash(0.1, gfx.COLOR_WHITE)
        -- TRANSITION: Check for Game Over state transition
        if State.lives <= 0 then
            State.current_scene = "gameover"
        end
    end
end

function draw_gameplay(dt)
    local p = State.player
    local c = State.ball

    -- Draw Entities
    gfx.spr(10, p.x, p.y)
    gfx.spr(c.ball_sprite, c.x, c.y)
    -- Draw UI
    gfx.text("Score: " .. State.score, 8, 8, gfx.COLOR_WHITE)

    local sprite_size = 16
    local margin = 8 -- Gap between the screen's right edge and the icons

    local sprite_size = 16
    local margin = 8 -- Gap between the screen's right edge and the icons

    for l = 1, State.lives do
        -- 1. Calculate total width of all active life icons
        local total_width = State.lives * sprite_size

        -- 2. Find starting point on the right edge
        local start_x = usagi.GAME_W - margin - total_width

        -- 3. Offset each icon moving left-to-right
        local x_pos = start_x + ((l - 1) * sprite_size)

        gfx.spr(10, x_pos, 8, gfx.COLOR_WHITE)
    end
end

----------------------------------------------------
-- SCENE 3: GAME OVER
----------------------------------------------------
function update_gameover(dt)
    -- Press BTN1 to return to title or restart
    if input.pressed(input.BTN1) then
        reset_gameplay()
        State.current_scene = "gameplay"
    end
end

function draw_gameover(dt)
    local msg1 = "GAME OVER"
    local msg2 = "Final Score: " .. State.score
    local msg3 = "Press BTN1 (Z/J) to Try Again"

    local w1, _ = usagi.measure_text(msg1)
    local w2, _ = usagi.measure_text(msg2)
    local w3, _ = usagi.measure_text(msg3)

    gfx.text(msg1, (usagi.GAME_W - w1) / 2, usagi.GAME_H / 2 - 20, gfx.COLOR_RED)
    gfx.text(msg2, (usagi.GAME_W - w2) / 2, usagi.GAME_H / 2, gfx.COLOR_WHITE)
    gfx.text(msg3, (usagi.GAME_W - w3) / 2, usagi.GAME_H / 2 + 20, gfx.COLOR_LIGHT_GRAY)
end
