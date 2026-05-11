shader_type spatial;
render_mode cull_disabled, depth_draw_always;

uniform vec4 albedo : source_color = vec4(0.45, 0.6, 0.85, 1.0);

// controls
uniform vec3 gravity = vec3(0.0, 1.0, 0.0); // local-space down
uniform float flow_speed = 1.5;   // how fast the slide moves (time multiplier)
uniform float flow_scale = 17.0;   // spatial frequency along the flow direction
uniform float amplitude = 35.0;   // max tangential slide magnitude
uniform float thickness = 0.00;   // extra offset along normal (optional sheet thickness)
uniform float duty_cycle = 15.00;  // fraction of the repeating cycle during which vertices move (0..1)
uniform float global_time_offset = 0.0; // per-instance offset to desync

// Bias direction parameters
uniform sampler2D bias_direction_texture : filter_linear;
uniform float bias_min_y = 0.0;
uniform float bias_max_y = 10.0;
uniform float bias_direction_strength : hint_range(0.0, 1.0, 0.1) = 1.0; // 0 = use gravity only, 1 = use bias only

uniform bool force_messy = false;

vec3 get_bias_direction(float world_y) {
    // Normalize Y coordinate to 0..1 range
    float t = clamp((world_y - bias_min_y) / (bias_max_y - bias_min_y), 0.0, 1.0);
    
    // Sample from texture (texture coordinate is t, 0.5)
    vec3 color_bias_dir = texture(bias_direction_texture, vec2(t, 0.5)).rgb;
	//convert from color back to dir
	vec3 bias_dir = color_bias_dir * 2.0 - 1.0;
	
	
    // Ensure it's normalized
    float len = length(bias_dir);
	
    if (len > 0.001) {
        return bias_dir / len;
    } else {
        return vec3(0.0, 1.0, 0.0);
    }
}

void vertex() {
    // Get world Y position for this vertex
    vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
    float world_y = world_pos.y;
    
    // normalized local gravity & normal
    vec3 g = normalize(gravity);
    vec3 Nn = normalize(NORMAL);

    // Project gravity onto the tangent plane to get the flow direction
    vec3 proj = g - dot(g, Nn) * Nn;
    float proj_len = length(proj);

    // Fallback tangent if projection is near-zero (flat horizontal case)
    vec3 flow_dir;
    if (proj_len > 1e-5) {
        flow_dir = proj / proj_len;
    } else {
        // pick an arbitrary perpendicular direction
        flow_dir = normalize(cross(Nn, vec3(0.0, 1.0, 0.0)));
        if (length(flow_dir) < 1e-5) {
            flow_dir = normalize(cross(Nn, vec3(1.0, 0.0, 0.0)));
        }
    }

    
    // Get bias direction and mix with gravity-based flow
    vec3 bias_dir = get_bias_direction(world_y);
    
    // Project bias direction onto tangent plane as well
    vec3 bias_proj = bias_dir - dot(bias_dir, Nn) * Nn;
    float bias_proj_len = length(bias_proj);
    
    if (bias_proj_len > 1e-5) {
        bias_proj = bias_proj / bias_proj_len;
		
		if (force_messy){
			bias_dir = bias_proj;
		}
		
		
		
        // Mix the two directions
        flow_dir = normalize(mix(flow_dir, bias_dir, bias_direction_strength));
    }
    
    // Spatial coordinate along the flow direction (per-vertex)
    float flow_coord = dot(VERTEX, flow_dir) * flow_scale;

    // time and phase (sawtooth)
    float t = TIME + global_time_offset;
    float phase = fract(flow_coord -t * flow_speed); // repeating 0..1
	
    phase = clamp(phase, 0.0, 1.0);

    // Only move while phase is in the duty window; otherwise snap back to zero.
    float factor = 0.0;
    if (phase < duty_cycle && duty_cycle > 0.0001) {
        factor = phase / duty_cycle; // ramp 0 -> 1 across the duty window
    } else {
        factor = 0.0;
    }

    // Tangential displacement (along flow_dir) and small normal push for thickness
    vec3 tangential_offset = flow_dir * (factor * amplitude);
    vec3 normal_offset = Nn * (-factor * thickness);

    // Apply displacement
    VERTEX += tangential_offset + normal_offset;
}

void fragment() {
    // same normal vector for every face
    NORMAL = -normalize(cross(dFdx(VERTEX),dFdy(VERTEX)));
    
    ALBEDO = albedo.rgb;
    ALPHA = albedo.a;

    // simple fresnel-ish edge highlight for gloss
    float facing = clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0);
    ALBEDO += vec3(0.08 * pow(facing, 2.0));
    METALLIC = 0.0;
    ROUGHNESS = 0.35;
}