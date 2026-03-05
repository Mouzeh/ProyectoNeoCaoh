shader_type canvas_item;

// --- Parámetros ajustables ---
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.2, 1.0); // Dorado
uniform float shine_speed : hint_range(0.0, 10.0) = 2.0;
uniform float shine_width : hint_range(0.0, 1.0) = 0.2;
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;

void fragment() {
	// 1. Conseguimos el color original de la textura (la carta)
	vec4 old_color = texture(TEXTURE, UV);
	
	// 2. Lógica para crear la franja de brillo diagonal
	// Usamos UV.x - UV.y para que sea diagonal
	float shine = step(1.0 - shine_width, 0.5 + 0.5 * sin(UV.x - UV.y + TIME * shine_speed));
	
	// 3. Mezclamos solo si el píxel original no es transparente (old_color.a)
	vec3 final_rgb = mix(old_color.rgb, glow_color.rgb * glow_intensity, shine * old_color.a);
	
	// 4. Resultado final
	COLOR = vec4(final_rgb, old_color.a);
}