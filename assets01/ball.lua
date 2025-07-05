local script = require('scriptcomponent'):derive()
local config = require('config')
local game_state = require('game_state')

function script:on_init()
	-- Register self in game state
	game_state.ball_script = self
	
	-- Ball physics state
	self.x = 0
	self.y = config.paddle.y_position + 0.1  -- Start just above paddle
	self.vx = 0
	self.vy = 0
	self.active = false
	
	-- Set initial position
	local transform = getcomponent(self.entity, "transform")
	if transform then
		transform.translation = vec3(self.x, self.y, 0)
	end
	
	-- Cache input
	self.space_key = Input.getbuttonidforname("SPACE")
end

function script:check_brick_collisions()
	-- Get game controller from game state
	local controller_script = game_state.game_controller_script
	if not controller_script or not controller_script.bricks then return end
	
	-- First pass: find all colliding bricks
	local colliding_bricks = {}
	local ball_left = self.x - config.ball.radius
	local ball_right = self.x + config.ball.radius
	local ball_top = self.y + config.ball.radius
	local ball_bottom = self.y - config.ball.radius
	
	for _, brick_info in ipairs(controller_script.bricks) do
		if not brick_info.destroyed then
			local brick_transform = getcomponent(brick_info.entity, "transform")
			if brick_transform then
				local brick_x = brick_transform.translation.x
				local brick_y = brick_transform.translation.y
				
				local brick_left = brick_x - config.bricks.width / 2
				local brick_right = brick_x + config.bricks.width / 2
				local brick_top = brick_y + config.bricks.height / 2
				local brick_bottom = brick_y - config.bricks.height / 2
				
				-- Check collision
				if ball_right >= brick_left and ball_left <= brick_right and
				   ball_bottom <= brick_top and ball_top >= brick_bottom then
					table.insert(colliding_bricks, {
						info = brick_info,
						x = brick_x,
						y = brick_y,
						left = brick_left,
						right = brick_right,
						top = brick_top,
						bottom = brick_bottom
					})
				end
			end
		end
	end
	
	-- Process only the first collision to prevent multi-hit bugs
	
	-- Process only the first collision
	if #colliding_bricks > 0 then
		local brick = colliding_bricks[1]
		local brick_info = brick.info
		
		-- Process collision
		
		-- Mark brick as destroyed and hide it
		brick_info.destroyed = true
		
		-- Hide the brick instead of destroying it
		local renderer = getcomponent(brick_info.entity, "spriterenderer")
		if renderer then
			renderer.visible = false
		end
		
		-- Update game state
		controller_script.score = controller_script.score + brick_info.points
		controller_script.bricks_remaining = controller_script.bricks_remaining - 1
		
		-- Removed verbose logging
		
		-- Determine bounce direction
		local overlap_left = ball_right - brick.left
		local overlap_right = brick.right - ball_left
		local overlap_top = ball_bottom - brick.top
		local overlap_bottom = brick.bottom - ball_top
		
		local min_overlap = math.min(overlap_left, overlap_right, overlap_top, overlap_bottom)
		
		-- Bounce based on smallest overlap
		
		-- Calculate safe repositioning distance considering brick spacing
		local safe_buffer = config.bricks.spacing + config.bricks.height / 2 + 0.01
		
		if min_overlap == overlap_left then
			self.vx = -math.abs(self.vx)
			self.x = brick.left - config.ball.radius - 0.001
			-- Bouncing left
		elseif min_overlap == overlap_right then
			self.vx = math.abs(self.vx)
			self.x = brick.right + config.ball.radius + 0.001
			-- Bouncing right
		elseif min_overlap == overlap_top then
			self.vy = math.abs(self.vy)
			-- Move ball far enough to avoid hitting the brick above
			self.y = brick.top + config.ball.radius + safe_buffer
			-- Bouncing up
		else
			self.vy = -math.abs(self.vy)
			-- Move ball far enough to avoid hitting the brick below
			self.y = brick.bottom - config.ball.radius - safe_buffer
			-- Bouncing down
		end
		
		-- Position and velocity updated
		
		-- Update transform immediately to prevent multiple collisions
		local transform = getcomponent(self.entity, "transform")
		if transform then
			transform.translation = vec3(self.x, self.y, 0)
		end
		
		-- Check for victory
		if controller_script.bricks_remaining == 0 then
			log("Victory! All bricks destroyed!")
			self.active = false
		end
	end
end

function script:check_paddle_collision()
	-- Get paddle script from game state
	local paddle_script = game_state.paddle_script
	if not paddle_script then return end
	
	-- Get paddle position from its script
	local paddle_x = paddle_script.x
	local paddle_y = config.paddle.y_position
	
	-- AABB collision check
	local ball_left = self.x - config.ball.radius
	local ball_right = self.x + config.ball.radius
	local ball_top = self.y + config.ball.radius
	local ball_bottom = self.y - config.ball.radius
	
	local paddle_left = paddle_x - config.paddle.width / 2
	local paddle_right = paddle_x + config.paddle.width / 2
	local paddle_top = paddle_y + config.paddle.height / 2
	local paddle_bottom = paddle_y - config.paddle.height / 2
	
	-- Check collision
	if ball_right >= paddle_left and ball_left <= paddle_right and
	   ball_bottom <= paddle_top and ball_top >= paddle_bottom then
		-- Only bounce if ball is moving downward
		if self.vy < 0 then
			-- Calculate hit position (-1 to 1, where 0 is center)
			local hit_pos = (self.x - paddle_x) / (config.paddle.width / 2)
			hit_pos = math.max(-1, math.min(1, hit_pos))
			
			-- Adjust angle based on hit position
			local bounce_angle = hit_pos * math.pi/3  -- Max 60 degree angle
			
			-- Calculate new velocity
			local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
			speed = math.min(speed * config.ball.speed_increase, config.ball.max_speed)
			
			self.vx = math.sin(bounce_angle) * speed
			self.vy = math.abs(math.cos(bounce_angle)) * speed
			
			-- Move ball above paddle to prevent multiple collisions
			self.y = paddle_top + config.ball.radius
		end
	end
end

function script:on_message(msg, data)
	if msg == "reset_ball" then
		self.active = false
		self.x = 0
		self.y = config.paddle.y_position + 0.1
		self.vx = 0
		self.vy = 0
	end
end

function script:on_update()
	-- Check if game is over
	local game_over = false
	if game_state.game_controller_script and game_state.game_controller_script.game_over then
		game_over = true
	end
	
	-- Launch ball with space (only if game not over)
	if not self.active and not game_over and Input.getbutton(self.space_key) > 0 then
		self.active = true
		-- Random angle upward
		local angle = math.random() * math.pi/3 - math.pi/6
		self.vx = math.sin(angle) * config.ball.initial_speed
		self.vy = math.cos(angle) * config.ball.initial_speed
		log("Ball launched!")
	end
	
	if self.active then
		
		local dt = Time.deltaTime
		
		-- Update position
		self.x = self.x + self.vx * dt
		self.y = self.y + self.vy * dt
		
		-- Wall collisions
		if self.x - config.ball.radius <= config.PLAY_AREA.left then
			self.x = config.PLAY_AREA.left + config.ball.radius
			self.vx = math.abs(self.vx)
		elseif self.x + config.ball.radius >= config.PLAY_AREA.right then
			self.x = config.PLAY_AREA.right - config.ball.radius
			self.vx = -math.abs(self.vx)
		end
		
		-- Ceiling collision
		if self.y + config.ball.radius >= config.PLAY_AREA.top then
			self.y = config.PLAY_AREA.top - config.ball.radius
			self.vy = -math.abs(self.vy)
		end
		
		-- Brick collisions
		self:check_brick_collisions()
		
		-- Paddle collision
		self:check_paddle_collision()
		
		-- Floor (reset)
		if self.y - config.ball.radius <= config.PLAY_AREA.bottom then
			self.active = false
			self.x = 0
			self.y = config.paddle.y_position + 0.1
			self.vx = 0
			self.vy = 0
			
			-- Notify game controller of life lost
			local controller = game_state.game_controller_script
			if controller then
				broadcast("ball_lost", {})
			end
		end
	end
	
	-- Update transform
	local transform = getcomponent(self.entity, "transform")
	if transform then
		transform.translation = vec3(self.x, self.y, 0)
	end
end

return script