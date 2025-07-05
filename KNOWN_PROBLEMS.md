# Known Problems - Breakout Demo

## Multi-Brick Collision Bug

### Description
When the ball hits bricks from certain angles (especially from below), multiple bricks can be destroyed in a single frame. This is most noticeable when the ball is moving quickly upward after a paddle hit.

### Root Cause
The SolarSail engine uses discrete frame-based collision detection without continuous collision detection (CCD). This means:

1. **Position Updates**: The ball position is updated once per frame based on velocity * deltaTime
2. **Collision Checks**: We then check if the ball overlaps any bricks at its new position
3. **Multiple Overlaps**: Fast-moving balls can overlap multiple bricks in a single frame

Example scenario:
```
Frame N:   Ball is below two bricks
Frame N+1: Ball has moved up and is now inside BOTH bricks
```

### Why Current Fixes Don't Work

#### Attempt 1: Process Only First Collision
```lua
if #colliding_bricks > 0 then
    local brick = colliding_bricks[1]  -- Only process first
    -- Handle collision...
end
```
**Problem**: The ball is already inside multiple bricks. Processing only one doesn't prevent the visual glitch.

#### Attempt 2: Safe Buffer Repositioning
```lua
local safe_buffer = config.bricks.spacing + config.bricks.height / 2 + 0.01
self.y = brick.top + config.ball.radius + safe_buffer
```
**Problem**: This causes the ball to "teleport" visually and can still place it inside another brick.

#### Attempt 3: Tighter Brick Spacing
**Problem**: With current brick height (0.06) and ball radius (0.03), even minimal spacing allows multi-collision.

### Engine Limitations

The engine lacks several features needed for proper collision handling:

1. **No Continuous Collision Detection (CCD)**
   - Can't detect collisions between frames
   - No ray/sweep tests along movement path
   - No time-of-impact calculation

2. **No Physics Engine Integration**
   - Manual AABB calculations required
   - No automatic collision response
   - No collision manifolds with penetration depth

3. **No Collision Callbacks**
   - Can't detect collision enter/stay/exit
   - No way to filter or prioritize collisions
   - No collision layers or masks

### Workarounds

Until the engine supports proper collision detection, consider these workarounds:

#### 1. Collision Cooldown (Recommended)
Add a brief cooldown after each brick collision:
```lua
-- Add to ball.lua
function script:on_init()
    self.collision_cooldown = 0
    -- ... other init code
end

function script:check_brick_collisions()
    if self.collision_cooldown > 0 then
        self.collision_cooldown = self.collision_cooldown - Time.deltaTime
        return
    end
    
    -- ... collision detection code
    
    if collision_detected then
        self.collision_cooldown = 0.1  -- 100ms cooldown
    end
end
```

#### 2. Increase Brick Spacing
Make it physically impossible for the ball to touch multiple bricks:
```lua
config.bricks = {
    spacing = 0.08,  -- Larger than ball diameter (0.06)
    -- ...
}
```

#### 3. Reduce Ball Speed
Minimize tunneling by limiting velocity:
```lua
config.ball = {
    initial_speed = 0.5,  -- Slower start
    max_speed = 1.5,      -- Lower maximum
    -- ...
}
```

#### 4. Sub-frame Stepping (Complex)
Manually implement multiple physics steps per frame:
```lua
function script:on_update()
    local steps = 4
    local dt = Time.deltaTime / steps
    
    for i = 1, steps do
        self:update_position(dt)
        if self:check_collisions() then
            break  -- Stop on first collision
        end
    end
end
```

### Impact on Gameplay

- Players may occasionally see multiple bricks disappear at once
- This is especially noticeable when the ball approaches from below
- The bug can make the game easier (more bricks cleared) or feel unfair
- It breaks the expected one-ball-one-brick physics model

### Long-term Solution

See `/engine/docs/proposals/COLLISION_SYSTEM_IMPROVEMENTS.md` for a comprehensive proposal to add proper collision detection to the SolarSail engine. This would eliminate this entire class of bugs.

### Current Status

This bug remains in the demo as an example of engine limitations. The game is still playable and fun despite this issue. Players familiar with classic Breakout games may notice the difference, but casual players often don't mind or even enjoy the occasional "power shot" that clears multiple bricks.