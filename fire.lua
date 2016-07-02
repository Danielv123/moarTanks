-- Boring fireutil stuff until line 600

require "util"
local math3d = require "math3d"

local fire_damage_per_tick = 45 / 60
local flamethrower_stream_on_hit_damage = 1

local function make_color(r_,g_,b_,a_)
  return { r = r_ * a_, g = g_ * a_, b = b_ * a_, a = a_ }
end

local fireutil = {}

function fireutil.foreach(table_, fun_)
  for k, tab in pairs(table_) do fun_(tab) end
  return table_
end

function fireutil.flamethrower_turret_extension_animation(shft, opts)
  local m_line_length = 5
  local m_frame_count = 15
  local ret_layers = {
    -- diffuse
    {
      filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-extension.png",
      priority = "medium",
      frame_count = opts and opts.frame_count or m_frame_count,
      line_length = opts and opts.line_length or m_line_length,
      run_mode = opts and opts.run_mode or "forward",
      width = 78,
      height = 65,
      direction_count = 1,
      axially_symmetrical = false,
      shift = {0, -0.796875},
    },
    -- mask
    {
      filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-extension-mask.png",
      flags = { "mask" },
      frame_count = opts and opts.frame_count or m_frame_count,
      line_length = opts and opts.line_length or m_line_length,
      run_mode = opts and opts.run_mode or "forward",
      width = 74,
      height = 61,
      direction_count = 1,
      axially_symmetrical = false,
      shift = {0, -0.796875},
      apply_runtime_tint = true
    },
    -- shadow
    {
      filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-extension-shadow.png",
      frame_count = opts and opts.frame_count or m_frame_count,
      line_length = opts and opts.line_length or m_line_length,
      run_mode = opts and opts.run_mode or "forward",
      width = 91,
      height = 56,
      direction_count = 1,
      axially_symmetrical = false,
      shift = {1.04688, 0},
      draw_as_shadow = true, 
    }
  }
  
  local yoffsets = { north = 0, east = 3, south = 2, west = 1 }
  local m_lines = m_frame_count / m_line_length
  
  return { layers = fireutil.foreach(ret_layers, function(tab)
    if tab.shift then tab.shift = { tab.shift[1] + shft[1], tab.shift[2] + shft[2] } end
    if tab.height then tab.y = tab.height * m_lines * yoffsets[opts.direction] end
  end) }
end

fireutil.turret_gun_shift = {
  north = {0, -0.3125},
  east = {0.625, 0.3125},
  south = {0,  0.625},
  west = { -0.46875, 0.3125},
}

fireutil.turret_model_info = {
  tilt_pivot = { -1.68551, 0, 2.35439 },
  gun_tip_lowered = { 4.27735, 0, 3.97644 },
  gun_tip_raised = { 2.2515, 0, 7.10942 },
  units_per_tile = 4,
}

fireutil.gun_center_base = math3d.vector2.sub({0,  -0.725}, fireutil.turret_gun_shift.south)

function fireutil.flamethrower_turret_preparing_muzzle_animation(opts)
  opts.frame_count = opts.frame_count or 15
  opts.run_mode = opts.run_mode or "forward"
  assert(opts.orientation_count)
  
  local model = fireutil.turret_model_info
  local angle_raised = -math3d.vector3.angle({1, 0, 0}, math3d.vector3.sub(model.gun_tip_raised, model.tilt_pivot))
  local angle_lowered = -math3d.vector3.angle({1, 0, 0}, math3d.vector3.sub(model.gun_tip_lowered, model.tilt_pivot))
  local delta_angle = angle_raised - angle_lowered
  
  local generated_orientations = {}
  for r = 0, opts.orientation_count-1 do
    local phi = (r / opts.orientation_count - 0.25) * math.pi * 2
    local generated_frames = {}
    for i = 0, opts.frame_count-1 do
      local k = opts.run_mode == "backward" and (opts.frame_count - i - 1) or i
      local progress = opts.progress or (k / (opts.frame_count - 1))
      
      local matrix = math3d.matrix4x4
      local mat = matrix.compose({
        matrix.translation_vec3(math3d.vector3.mul(model.tilt_pivot, -1)),
        matrix.rotation_y(progress * delta_angle),
        matrix.translation_vec3(model.tilt_pivot),
        matrix.rotation_z(phi),
        matrix.scale(1 / model.units_per_tile, 1 / model.units_per_tile, -1 / model.units_per_tile)
      })
      
      local vec = math3d.matrix4x4.mul_vec3(mat, model.gun_tip_lowered)
      table.insert(generated_frames, math3d.project_vec3(vec))
    end
    local direction_data = { frames = generated_frames }
    if (opts.layers and opts.layers[r]) then
      direction_data.render_layer = opts.layers[r]
    end
    table.insert(generated_orientations, direction_data)
  end
  
  return 
  {
    rotations = generated_orientations,
    direction_shift = fireutil.turret_gun_shift,
  }
end

function fireutil.flamethrower_turret_extension(opts)
  local set_direction = function (opts, dir)
    opts.direction = dir
    return opts
  end

  return {
    north = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.north, set_direction(opts, "north")),
    east = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.east, set_direction(opts, "east")),
    south = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.south, set_direction(opts, "south")),
    west = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.west, set_direction(opts, "west")),
  } 
end

function fireutil.flamethrower_turret_prepared_animation(shft, opts)
  local diffuse_layer = 
  {
    filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun.png",
    priority = "medium",
    counterclockwise = true,
    line_length = 8,
    width = 78,
    height = 64,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 64,
    shift = {0, -0.75},
  }
  local glow_layer = 
  {
    filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-active.png",
    counterclockwise = true,
    line_length = 8,
    width = 78,
    height = 63,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 64,
    shift = {0, -0.765625},
    tint = make_color(1, 1, 1, 0.5),
    blend_mode = "additive",
  }
  local mask_layer = 
  {
    filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-mask.png",
    flags = { "mask" },
    counterclockwise = true,
    line_length = 8,
    width = 72,
    height = 57,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 64,
    shift = {0, -0.859375},
    apply_runtime_tint = true,
  }
  local shadow_layer = 
  {
    filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-shadow.png",
    counterclockwise = true,
    line_length = 8,
    width = 91,
    height = 57,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 64,
    shift = {0.984375, 0.015625},
    draw_as_shadow = true,
  }
  
  local ret_layers = opts and opts.attacking and { diffuse_layer, glow_layer, mask_layer, shadow_layer }
                                             or  { diffuse_layer, mask_layer, shadow_layer }
  
  return { layers = fireutil.foreach(ret_layers, function(tab)
    if tab.shift then tab.shift = { tab.shift[1] + shft[1], tab.shift[2] + shft[2] } end
  end) }
end

function fireutil.flamethrower_prepared_animation(opts)
  return {
    north = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.north, opts),
    east = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.east, opts),
    south = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.south, opts),
    west = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.west, opts),
  }
end

function fireutil.create_fire_pictures(opts)
  local fire_blend_mode = opts.blend_mode or "additive"
  local fire_animation_speed = opts.animation_speed or 0.5
  local fire_scale =  opts.scale or 1
  local fire_tint = {r=1,g=1,b=1,a=1}
  local fire_flags = { "compressed" }
  local retval = {
    { 
      filename = "__moarTanks__/graphics/fire-flame-13.png",
      line_length = 8,
      width = 60,
      height = 118,
      frame_count = 25,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { -0.0390625, -0.90625 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-12.png",
      line_length = 8,
      width = 63,
      height = 116,
      frame_count = 25,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { -0.015625, -0.914065 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-11.png",
      line_length = 8,
      width = 61,
      height = 122,
      frame_count = 25,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { -0.0078125, -0.90625 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-10.png",
      line_length = 8,
      width = 65,
      height = 108,
      frame_count = 25,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { -0.0625, -0.64844 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-09.png",
      line_length = 8,
      width = 64,
      height = 101,
      frame_count = 25,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { -0.03125, -0.695315 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-08.png",
      line_length = 8,
      width = 50,
      height = 98,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { -0.0546875, -0.77344 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-07.png",
      line_length = 8,
      width = 54,
      height = 84,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { 0.015625, -0.640625 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-06.png",
      line_length = 8,
      width = 65,
      height = 92,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { 0, -0.83594 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-05.png",
      line_length = 8,
      width = 59,
      height = 103,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { 0.03125, -0.882815 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-04.png",
      line_length = 8,
      width = 67,
      height = 130,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { 0.015625, -1.109375 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-03.png",
      line_length = 8,
      width = 74,
      height = 117,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { 0.046875, -0.984375 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-02.png",
      line_length = 8,
      width = 74,
      height = 114,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { 0.0078125, -0.96875 }
    },
    { 
      filename = "__moarTanks__/graphics/fire-flame-01.png",
      line_length = 8,
      width = 66,
      height = 119,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags,
      shift = { -0.0703125, -1.039065 }
    },
  }
  return fireutil.foreach(retval, function(tab)
    if tab.shift and tab.scale then tab.shift = { tab.shift[1] * tab.scale, tab.shift[2] * tab.scale } end
  end)
end

function fireutil.create_small_tree_flame_animations(opts)
  local fire_blend_mode = opts.blend_mode or "additive"
  local fire_animation_speed = opts.animation_speed or 0.5
  local fire_scale =  opts.scale or 1
  local fire_tint = {r=1,g=1,b=1,a=1}
  local fire_flags = { "compressed" }
  local retval = {
    {
      filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-01-a.png",
      line_length = 8,
      width = 38,
      height = 110,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.03125, -1.5},
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags
    },
    {
      filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-01-b.png",
      line_length = 8,
      width = 39,
      height = 111,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.078125, -1.51562},
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags
    },
    {
      filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-01-c.png",
      line_length = 8,
      width = 44,
      height = 108,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.15625, -1.5},
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags
    },
    { 
      filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-03-a.png",
      line_length = 8,
      width = 38,
      height = 110,
      frame_count = 23,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.03125, -1.5},
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags
    },
    { 
      filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-03-b.png",
      line_length = 8,
      width = 34,
      height = 98,
      frame_count = 23,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.03125, -1.34375},
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags
    },
    { 
      filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-03-c.png",
      line_length = 8,
      width = 39,
      height = 111,
      frame_count = 23,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.078125, -1.51562},
      blend_mode = fire_blend_mode,
      animation_speed = fire_animation_speed,
      scale = fire_scale,
      tint = fire_tint,
      flags = fire_flags
    }
  }
  
  return fireutil.foreach(retval, function(tab)
    if tab.shift and tab.scale then tab.shift = { tab.shift[1] * tab.scale, tab.shift[2] * tab.scale } end
  end)
end

function fireutil.flamethrower_turret_pipepictures()
  local tiling_correction = -0.5 / 32
  return {
    north =
    {
      filename = "__base__/graphics/entity/pipe/pipe-straight-vertical.png",
      priority = "extra-high",
      width = 44,
      height = 42,
      shift = {0, 1 + tiling_correction}
    },
    south =
    {
      filename = "__base__/graphics/entity/pipe/pipe-straight-vertical.png",
      priority = "extra-high",
      width = 44,
      height = 42,
      shift = {0, -1 - tiling_correction}
    },
    east =
    {
      filename = "__base__/graphics/entity/pipe/pipe-straight-horizontal.png",
      priority = "extra-high",
      width = 32,
      height = 42,
      shift = {-1 - tiling_correction, 0}
    }, 
    west =
    {
      filename = "__base__/graphics/entity/pipe/pipe-straight-horizontal.png",
      priority = "extra-high",
      width = 32,
      height = 42,
      shift = {1 + tiling_correction, 0}
    },
  }
end

function fireutil.create_burnt_patch_pictures()
  local base = {
    filename = "__base__/graphics/entity/fire-flame/burnt-patch.png",
    line_length = 3,
    width = 115,
    height = 56,
    frame_count = 9,
    axially_symmetrical = false,
    direction_count = 1,
    shift = {-0.09375, 0.125},
  }
  
  local variations = {}
  
  for y=1,(base.frame_count / base.line_length) do
    for x=1,base.line_length do
      table.insert(variations, 
      { 
        filename = base.filename,
        width = base.width,
        height = base.height,
        tint = base.tint,
        shift = base.shift,
        x = (x-1) * base.width,
        y = (y-1) * base.height,
      })
    end
  end

  return variations
end

-- All adding off entities ensues! ////////////////////////////////////////

data:extend(
{
  {
    type = "stream",
    name = "advanced-flamethrower-fire-stream",
    flags = {"not-on-map"},
    working_sound_disabled =
    {
      {
        filename = "__base__/sound/fight/electric-beam.ogg",
        volume = 0.7
      }
    },
    
    smoke_sources =
    {
      {
        name = "soft-fire-smoke",
        frequency = 0.1, --0.25,
        position = {0.0, 0}, -- -0.8},
        starting_frame_deviation = 60
      }
    },
  
    stream_light = {intensity = 1, size = 5 * 0.8},
    ground_light = {intensity = 0.8, size = 4 * 0.8},
  
    particle_buffer_size = 65,
    particle_spawn_interval = 2,
    particle_spawn_timeout = 2,
    particle_vertical_acceleration = 0.005 * 0.6,
    particle_horizontal_speed = 0.45,
    particle_horizontal_speed_deviation = 0.0035,
    particle_start_alpha = 0.5,
    particle_end_alpha = 1,
    particle_start_scale = 0.2,
    particle_loop_frame_count = 3,
    particle_fade_out_threshold = 0.9,
    particle_loop_exit_threshold = 0.25,
    action =
    {
      {
        type = "direct",
        action_delivery =
        {
          type = "instant",
          target_effects =
          {
            {
              type = "create-fire",
              entity_name = "wildfire-flame"
            },
            {
              type = "damage",
              damage = { amount = 1.5, type = "fire" }
            },
          }
        }
      },
      {
        type = "area",
        perimeter = 9,
        action_delivery =
        {
          type = "instant",
          target_effects =
          {
            {
              type = "create-sticker",
              sticker = "fire-sticker"
            },
			{
              type = "create-fire",
              entity_name = "wildfire-flame"
            },
          }
        }
      }
    },
    
    spine_animation = 
    { 
      filename = "__base__/graphics/entity/flamethrower-fire-stream/flamethrower-fire-stream-spine.png",
      blend_mode = "additive",
      --tint = {r=1, g=1, b=1, a=0.5},
      line_length = 4,
      width = 32,
      height = 18,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      animation_speed = 2,
      scale = 0.75,
      shift = {0, 0},
    },
    
    shadow =
    {
      filename = "__base__/graphics/entity/acid-projectile-purple/acid-projectile-purple-shadow.png",
      line_length = 5,
      width = 28,
      height = 16,
      frame_count = 33,
      priority = "high",
      scale = 0.5,
      shift = {-0.09 * 0.5, 0.395 * 0.5}
    },
    
    particle =
    {
      filename = "__base__/graphics/entity/flamethrower-fire-stream/flamethrower-explosion.png",
      priority = "extra-high",
      width = 64,
      height = 64,
      frame_count = 32,
      line_length = 8,
      scale = 0.8,
    },
  },
  {
  type = "fire",
  name = "wildfire-flame",
  flags = {"placeable-off-grid", "not-on-map"},
  duration = 600,
  fade_away_duration = 600,
  spread_duration = 600,
  start_scale = 0.20,
  end_scale = 1.0,
  color = {r=0.7, g=1, b=0, a=1},
  damage_per_tick = {amount = 1.5, type = "fire"},
  
  spawn_entity = "wildfire-flame-on-tree",
  
  spread_delay = 100,
  spread_delay_deviation = 180,
  maximum_spread_count = 200,
  initial_lifetime = 1500,
  
  flame_alpha = 0.35,
  flame_alpha_deviation = 0.05,
  
  emissions_per_tick = 0.1,
  
  add_fuel_cooldown = 50,
  fade_in_duration = 30,
  fade_out_duration = 30,
  
  delay_between_initial_flames = 10,
  burnt_patch_lifetime = 3600,
  
  action =
  {
    type = "direct",
    action_delivery =
    {
      type = "instant",
      target_effects =
      {
        {
          type = "create-smoke",
          entity_name = "fire-smoke-on-adding-fuel",
          -- speed = {-0.03, 0},
          -- speed_multiplier = 0.99,
          -- speed_multiplier_deviation = 1.1,
          offset_deviation = {{-0.5, -0.5}, {0.5, 0.5}},
          speed_from_center = 0.01
        },
      }
    },
  },
  
  pictures = fireutil.create_fire_pictures({ blend_mode = "normal", animation_speed = 1, scale = 0.5}),
  
  smoke_source_pictures = 
  {
    { 
      filename = "__base__/graphics/entity/fire-flame/fire-smoke-source-1.png",
      line_length = 8,
      width = 101,
      height = 138,
      frame_count = 31,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.109375, -1.1875},
      animation_speed = 0.5,
    },
    { 
      filename = "__base__/graphics/entity/fire-flame/fire-smoke-source-2.png",
      line_length = 8,
      width = 99,
      height = 138,
      frame_count = 31,
      axially_symmetrical = false,
      direction_count = 1,
      shift = {-0.203125, -1.21875},
      animation_speed = 0.5,
    },
  },
  
  burnt_patch_pictures = fireutil.create_burnt_patch_pictures(),
  burnt_patch_alpha_default = 0.4,
  burnt_patch_alpha_variations = {
   -- { tile = "grass", alpha = 0.4 },
   -- { tile = "grass-medium", alpha = 0.4 },
    { tile = "grass-dry", alpha = 0.45 },
    { tile = "dirt", alpha = 0.3 },
    { tile = "dirt-dark", alpha = 0.35 },
    { tile = "sand", alpha = 0.24 },
    { tile = "sand-dark", alpha = 0.28 },
    { tile = "stone-path", alpha = 0.26 },
    { tile = "concrete", alpha = 0.24 },
  },

  smoke =
  {
    {
      name = "fire-smoke",
      deviation = {0.5, 0.5},
      frequency = 0.25 / 2,
      position = {0.0, -0.8},
      starting_vertical_speed = 0.05,
      starting_vertical_speed_deviation = 0.005,
      vertical_speed_slowdown = 0.99,
      starting_frame_deviation = 60,
      height = -0.5,
    }
  },
 
  light = {intensity = 1, size = 40},
  
  working_sound =
  {
    sound = { filename = "__base__/sound/furnace.ogg" },
    max_sounds_per_type = 3
  },	
  },
  {
  type = "fire",
  name = "wildfire-flame-on-tree",
  flags = {"placeable-off-grid", "not-on-map"},

  damage_per_tick = {amount = 1.5, type = "fire"}, -- Default 0.75
  
  spawn_entity = "wildfire-flame",
  maximum_spread_count = 200, -- Default 100
  
  spread_delay = 200, -- Default 300
  spread_delay_deviation = 10,
  flame_alpha = 0.35,
  flame_alpha_deviation = 0.05,
  
  tree_dying_factor = 1,
  emissions_per_tick = 0.01, -- Default 0.005
  
  fade_in_duration = 30,
  fade_out_duration = 30,
  smoke_fade_in_duration = 80,
  smoke_fade_out_duration = 100,
  delay_between_initial_flames = 10,
  
  small_tree_fire_pictures = fireutil.create_small_tree_flame_animations({ blend_mode = "additive", animation_speed = 0.5, scale = 0.7 * 0.75 }),
  
  pictures = fireutil.create_fire_pictures({ blend_mode = "additive", animation_speed = 1, scale = 0.5 * 1.25}),
  
  smoke_source_pictures = 
  {
    { 
      filename = "__base__/graphics/entity/fire-flame/fire-smoke-source-1.png",
      line_length = 8,
      width = 101,
      height = 138,
      frame_count = 31,
      axially_symmetrical = false,
      direction_count = 1,
      scale = 0.6,
      shift = {-0.109375 * 0.6, -1.1875 * 0.6},
      animation_speed = 0.5,
      tint = make_color(1,1,1, 0.75),
    },
    { 
      filename = "__base__/graphics/entity/fire-flame/fire-smoke-source-2.png",
      line_length = 8,
      width = 99,
      height = 138,
      frame_count = 31,
      axially_symmetrical = false,
      direction_count = 1,
      scale = 0.6,
      shift = {-0.203125 * 0.6, -1.21875 * 0.6},
      animation_speed = 0.5,
      tint = make_color(1,1,1, 0.75),
    },
  },
  
  smoke =
  {
    {
      name = "fire-smoke-without-glow",
      deviation = {0.5, 0.5},
      frequency = 0.25 / 2,
      position = {0.0, -0.8},
      starting_vertical_speed = 0.008,
      starting_vertical_speed_deviation = 0.05,
      starting_frame_deviation = 60,
      height = -0.5,
    }
  },
   
  light = {intensity = 1, size = 20},

  working_sound =
  {
    sound = { filename = "__base__/sound/furnace.ogg" },
    max_sounds_per_type = 3
  },	
  },
})
