shader_type spatial;

//Made by Yni
//Inspired by bsubard 's shader
//License - MIT License

const float UV_SCALE = 4.0;

uniform sampler2D ground_albedo;
uniform sampler2D ground_roughness;
//uniform sampler2D ground_normal;

uniform sampler2D sand_albedo;
uniform sampler2D sand_roughness;
//uniform sampler2D sand_normal;
uniform float sand_fade_start = -0.5;
uniform float sand_fade_end = -1.0;

//uniform sampler2D rock_tex;
//uniform sampler2D snow_tex;

varying vec3 vertex_world_pos;

void vertex() {
	vertex_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 ground_a = texture(ground_albedo, UV * UV_SCALE).rgb;
	float ground_r = texture(ground_roughness, UV * UV_SCALE).r;
	//vec3 ground_n = texture(ground_normal, UV * UV_SCALE).rgb;
	vec3 sand_a = texture(sand_albedo, UV * UV_SCALE).rgb;
	float sand_r = texture(sand_roughness, UV * UV_SCALE).r;
	//vec3 sand_n = texture(sand_normal, UV * UV_SCALE).rgb;
	vec3 final_a = ground_a;
	float final_r = ground_r;
	//vec3 final_n = ground_n;
	if (vertex_world_pos.y < sand_fade_start) {
		float sand_mix = smoothstep(sand_fade_start, sand_fade_end, vertex_world_pos.y);
		final_a = mix(final_a, sand_a, sand_mix);
		final_r = mix(final_r, sand_r, sand_mix);
		//final_n = mix(final_n, sand_n, sand_mix);
	}
	ALBEDO = final_a;
	ROUGHNESS = final_r;
	//NORMAL = final_n;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
