function loadatlas()
	local atlas = atlas()
	atlas.atlasPath = "atlas.png"
	atlas.atlasHeight = 64
	atlas.atlasWidth = 128

	local sprite
	
	-- Ball sprite
	sprite = addsprite()
	sprite.name = "ball"
	sprite.frame.x = 0
	sprite.frame.y = 0
	sprite.frame.width = 32
	sprite.frame.height = 32
	
	-- Paddle sprite
	sprite = addsprite()
	sprite.name = "paddle"
	sprite.frame.x = 32
	sprite.frame.y = 0
	sprite.frame.width = 64
	sprite.frame.height = 16
	
	-- Brick sprite
	sprite = addsprite()
	sprite.name = "brick"
	sprite.frame.x = 0
	sprite.frame.y = 32
	sprite.frame.width = 48
	sprite.frame.height = 16
	
	-- White pixel for temporary use
	sprite = addsprite()
	sprite.name = "white_pixel"
	sprite.frame.x = 96
	sprite.frame.y = 0
	sprite.frame.width = 1
	sprite.frame.height = 1

	return atlas
end

return loadatlas