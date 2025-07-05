local script = require('scriptcomponent'):derive()
local config = require('config')
local game_state = require('game_state')

function script:on_init()
	-- Register self in game state
	game_state.paddle_script = self
	
	-- Set initial position
	local transform = getcomponent(self.entity, "transform")
	if transform then
		transform.translation = vec3(0, config.paddle.y_position, 0)
	end
	
	-- Cache input button IDs
	self.input_keys = {
		left = Input.getbuttonidforname("LEFT"),
		right = Input.getbuttonidforname("RIGHT"),
		a = Input.getbuttonidforname("A"),
		d = Input.getbuttonidforname("D")
	}
	
	-- Paddle position
	self.x = 0
end

function script:on_update()
	-- Handle input
	local move_left = Input.getbutton(self.input_keys.left) > 0 or Input.getbutton(self.input_keys.a) > 0
	local move_right = Input.getbutton(self.input_keys.right) > 0 or Input.getbutton(self.input_keys.d) > 0
	
	local dt = Time.deltaTime
	if move_left then
		self.x = self.x - config.paddle.speed * dt
	end
	if move_right then
		self.x = self.x + config.paddle.speed * dt
	end
	
	-- Clamp position
	local half_width = config.paddle.width / 2
	self.x = math.max(config.PLAY_AREA.left + half_width, 
	                 math.min(config.PLAY_AREA.right - half_width, self.x))
	
	-- Update transform
	local transform = getcomponent(self.entity, "transform")
	if transform then
		transform.translation = vec3(self.x, config.paddle.y_position, 0)
	end
end

return script