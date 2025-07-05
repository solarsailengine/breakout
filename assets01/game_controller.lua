local script = require('scriptcomponent'):derive()
local config = require('config')
local game_state = require('game_state')

function script:spawn_bricks()
	self.bricks = {}
	
	-- Calculate brick grid layout
	local total_width = config.bricks.cols * config.bricks.width + (config.bricks.cols - 1) * config.bricks.spacing
	local start_x = -total_width / 2 + config.bricks.width / 2
	
	for row = 1, config.bricks.rows do
		for col = 1, config.bricks.cols do
			-- Create brick entity from template
			local brick = instantiateTemplate("brick")
			
			-- Position brick
			local x = start_x + (col - 1) * (config.bricks.width + config.bricks.spacing)
			local y = config.bricks.start_y - (row - 1) * (config.bricks.height + config.bricks.spacing)
			
			local transform = getcomponent(brick, "transform")
			if transform then
				transform.translation = vec3(x, y, 0)
			end
			
			-- Store brick info
			table.insert(self.bricks, {
				entity = brick,
				row = row,
				col = col,
				points = config.bricks.points[row],
				destroyed = false
			})
		end
	end
	
	-- Bricks spawned
end

function script:on_init()
	-- Register self in game state
	game_state.game_controller_script = self
	
	-- Game state
	self.score = 0
	self.lives = 3
	self.bricks_remaining = config.game.initial_bricks
	self.game_over = false
	
	-- Spawn brick grid
	self:spawn_bricks()
	
	-- Cache restart key
	self.r_key = Input.getbuttonidforname("R")
end

function script:on_message(msg, data)
	if msg == "ball_lost" then
		if self.game_over then return end
		
		self.lives = self.lives - 1
		log("Ball lost! Lives remaining: " .. self.lives)
		
		if self.lives <= 0 then
			self.game_over = true
			log("GAME OVER! Final score: " .. self.score)
			log("Press R to restart")
		else
			log("Press SPACE to launch ball")
		end
	end
end

function script:on_update()
	-- Check for restart
	if Input.getbutton(self.r_key) > 0 then
		self:restart_game()
	end
	
	-- Score display would go here in a full game with UI
end

function script:restart_game()
	-- Restarting game
	
	-- Show all bricks again
	for _, brick_info in ipairs(self.bricks) do
		brick_info.destroyed = false
		local renderer = getcomponent(brick_info.entity, "spriterenderer")
		if renderer then
			renderer.visible = true
		end
	end
	
	-- Reset game state
	self.score = 0
	self.lives = 3
	self.bricks_remaining = config.game.initial_bricks
	self.game_over = false
	self.last_displayed_score = nil
	
	-- Reset ball via broadcast
	broadcast("reset_ball", {})
	
	log("Game restarted! Press SPACE to launch ball")
end

return script