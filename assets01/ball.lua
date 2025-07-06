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
	
	log(string.format("Ball initialized at position (%.3f, %.3f)", self.x, self.y))
	
	-- Set initial position
	local transform = getcomponent(self.entity, "transform")
	if transform then
		transform.translation = vec3(self.x, self.y, 0)
		log(string.format("Ball transform set to (%.3f, %.3f, %.3f)", 
			transform.translation.x, transform.translation.y, transform.translation.z))
	end
	
	-- Cache input
	self.space_key = Input.getbuttonidforname("SPACE")
end

-- Custom line-AABB intersection function removed - now using engine aabb:raycast() method

-- Manual line-AABB intersection for reliable collision detection
function script:line_intersects_aabb(x1, y1, x2, y2, aabb_min_x, aabb_min_y, aabb_max_x, aabb_max_y)
	local dx = x2 - x1
	local dy = y2 - y1
	
	if dx == 0 and dy == 0 then return nil end -- No movement
	
	-- Calculate intersection times for each axis
	local t_min = -math.huge
	local t_max = math.huge
	local hit_normal_x, hit_normal_y = 0, 0
	
	-- X axis
	if dx ~= 0 then
		local t1 = (aabb_min_x - x1) / dx
		local t2 = (aabb_max_x - x1) / dx
		
		if t1 > t2 then t1, t2 = t2, t1 end
		
		if t1 > t_min then
			t_min = t1
			hit_normal_x = dx > 0 and -1 or 1
			hit_normal_y = 0
		end
		
		if t2 < t_max then
			t_max = t2
		end
	else
		-- Line is vertical, check if it's within X bounds
		if x1 < aabb_min_x or x1 > aabb_max_x then
			return nil
		end
	end
	
	-- Y axis
	if dy ~= 0 then
		local t1 = (aabb_min_y - y1) / dy
		local t2 = (aabb_max_y - y1) / dy
		
		if t1 > t2 then t1, t2 = t2, t1 end
		
		if t1 > t_min then
			t_min = t1
			hit_normal_x = 0
			hit_normal_y = dy > 0 and -1 or 1
		end
		
		if t2 < t_max then
			t_max = t2
		end
	else
		-- Line is horizontal, check if it's within Y bounds
		if y1 < aabb_min_y or y1 > aabb_max_y then
			return nil
		end
	end
	
	-- Check if intersection exists and is within line segment
	if t_min <= t_max and t_min >= 0 and t_min <= 1 then
		local hit_x = x1 + t_min * dx
		local hit_y = y1 + t_min * dy
		
		return {
			x = hit_x,
			y = hit_y,
			normal_x = hit_normal_x,
			normal_y = hit_normal_y,
			distance = t_min
		}
	end
	
	return nil
end

-- Ray-cast collision detection using manual line-AABB intersection
function script:raycast_brick_collision(old_x, old_y, new_x, new_y)
	-- Get game controller from game state
	local controller_script = game_state.game_controller_script
	if not controller_script or not controller_script.bricks then return nil end
	
	local closest_hit = nil
	local closest_distance = math.huge
	local closest_brick_info = nil
	
	-- Cast ray against all active bricks, find closest intersection
	for _, brick_info in ipairs(controller_script.bricks) do
		if not brick_info.destroyed then
			local brick_transform = getcomponent(brick_info.entity, "transform")
			if brick_transform then
				local brick_x = brick_transform.translation.x
				local brick_y = brick_transform.translation.y
				
				-- Create expanded AABB for brick (includes ball radius for point raycast)
				local min_x = brick_x - config.bricks.width / 2 - config.ball.radius
				local min_y = brick_y - config.bricks.height / 2 - config.ball.radius
				local max_x = brick_x + config.bricks.width / 2 + config.ball.radius
				local max_y = brick_y + config.bricks.height / 2 + config.ball.radius
				
				-- Use manual line-AABB intersection
				local hit = self:line_intersects_aabb(old_x, old_y, new_x, new_y, min_x, min_y, max_x, max_y)
				
				if hit and hit.distance < closest_distance then
					closest_hit = hit
					closest_distance = hit.distance
					closest_brick_info = brick_info
				end
			end
		end
	end
	
	if closest_hit then
		return {
			hit = closest_hit,
			brick_info = closest_brick_info
		}
	end
	
	return nil
end

function script:handle_brick_collision(collision)
	local hit = collision.hit
	local brick_info = collision.brick_info
	
	-- CRITICAL: Position ball at collision point, not beyond it
	-- This prevents tunneling through multiple bricks
	self.x = hit.x
	self.y = hit.y
	
	-- Reflect velocity based on collision normal
	local dot = self.vx * hit.normal_x + self.vy * hit.normal_y
	self.vx = self.vx - 2 * dot * hit.normal_x
	self.vy = self.vy - 2 * dot * hit.normal_y
	
	-- Destroy the brick
	brick_info.destroyed = true
	
	-- Hide the brick
	local renderer = getcomponent(brick_info.entity, "spriterenderer")
	if renderer then
		renderer.visible = false
	end
	
	-- Update game state
	local controller_script = game_state.game_controller_script
	controller_script.score = controller_script.score + brick_info.points
	controller_script.bricks_remaining = controller_script.bricks_remaining - 1
	
	
	-- Update transform immediately
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

function script:check_paddle_collision()
	-- Get paddle script from game state
	local paddle_script = game_state.paddle_script
	if not paddle_script then return end
	
	-- Get paddle position from its script
	local paddle_x = paddle_script.x
	local paddle_y = config.paddle.y_position
	
	-- Create sphere for ball using engine primitives
	local ball_sphere = sphere(vec3(self.x, self.y, 0), config.ball.radius)
	
	-- Create AABB for paddle using engine primitives
	local paddle_aabb = aabb(
		vec3(paddle_x - config.paddle.width / 2, paddle_y - config.paddle.height / 2, 0),
		vec3(paddle_x + config.paddle.width / 2, paddle_y + config.paddle.height / 2, 0)
	)
	
	-- Check collision using engine sphere-AABB intersection
	if ball_sphere:intersects(paddle_aabb) then
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
			self.y = paddle_y + config.paddle.height / 2 + config.ball.radius
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
		log(string.format("Ball reset to position (%.3f, %.3f)", self.x, self.y))
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
		log(string.format("Ball launched! Position: (%.3f, %.3f), Velocity: (%.3f, %.3f)", 
			self.x, self.y, self.vx, self.vy))
	end
	
	if self.active then
		
		local dt = Time.deltaTime
		
		-- Store current position as previous for ray-casting
		local old_x = self.x
		local old_y = self.y
		
		-- Calculate potential new position
		local new_x = self.x + self.vx * dt
		local new_y = self.y + self.vy * dt
		
		-- Check for brick collisions BEFORE moving
		local collision = self:raycast_brick_collision(old_x, old_y, new_x, new_y)
		
		if collision then
			-- Handle brick collision and stop at collision point
			self:handle_brick_collision(collision)
		else
			-- No brick collision, move to new position
			self.x = new_x
			self.y = new_y
			
			-- Wall collisions (after safe movement)
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
		end
		
		-- Paddle collision
		self:check_paddle_collision()
		
		-- Floor (reset)
		if self.y - config.ball.radius <= config.PLAY_AREA.bottom then
			log(string.format("Ball hit floor! Resetting from (%.3f, %.3f)", self.x, self.y))
			self.active = false
			self.x = 0
			self.y = config.paddle.y_position + 0.1
			self.vx = 0
			self.vy = 0
			log(string.format("Ball reset to (%.3f, %.3f)", self.x, self.y))
			
			-- Notify game controller of life lost
			local controller = game_state.game_controller_script
			if controller then
				broadcast("ball_lost", {})
				log("Broadcast ball_lost message")
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