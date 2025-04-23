shader_type spatial;
render_mode unshaded, cull_back;
uniform float how_full;

void fragment() {
	float WIDTH = 0.05;
	float DIST_SQ = WIDTH * WIDTH;

	float ysq = (UV.y - 0.5) * WIDTH * 2.0;
	ysq *= ysq;

	if(UV.x < WIDTH || UV.x > 1.0 - WIDTH)
	{
		float x1 = UV.x - WIDTH;
		float x2 = UV.x - 1.0 + WIDTH;

		float distsq1 = x1 * x1 + ysq;
		float distsq2 = x2 * x2 + ysq;

		if(distsq1 > DIST_SQ && distsq2 > DIST_SQ)
		{
			discard;
		}
	}

	float fullness = how_full * (1.0 - WIDTH - WIDTH) + WIDTH;
	float fx = UV.x - fullness;
	float distsq_full = fx * fx + ysq;

	if(UV.x > fullness && distsq_full > DIST_SQ)
	{
		ALBEDO = vec3(0.1);
	}
	else
	{
		ALBEDO = vec3(1.0);
	}
}
