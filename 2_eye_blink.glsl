/*

	Name: Eye Blink shader
	Description:

	Eye Blink is a screen-spaced post-processing fragment shader written
	in GLSL (OpenGL Shading Language).  Originally intended for use in Shadertoy,
	it can be modified to fit into other rendering pipeline structures.

	The shader is made assuming that the viewport represents a monocular
	vision -- the viewport image is seen as if with one eye.

	Eye Blink can switch between 2 types of animation:


		1. Sharp animation - imitates a quick blink, like someone would normally blink.

		2. Smooth animation - imitates a relaxed blink, like someone would blink
		                      when feeling sleepy or tired.


	It is also possible to switch between 2 types of background:


		1. Textured background - helps to see the effect on a real example
		                         which is not something uniform like a flat color background.

		2. White color background - helps to see the exact intensity of the effect.
		                            Although it should be noted that the resulting effect
		                            is dependant on the original color and should be treated
		                            as a 'mathematically perfect' case example.

	Author: Yaroslav Ilin
	Date: 28 January 2024

	----------------------------

	Copyright 2024 Yaroslav Ilin

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

*/

#define PI 3.1415926535897932

// Controls whether the background is filled with texture or color:
// 1 - Fill with texture.
// 0 - Fill with white color.
#define BACKGROUND_TEXTURE 0

// Controls which blinking function is used:
// 1 - Sharp function, 'quick blink'.
// 0 - Smooth function, 'relaxed blink'.
#define BLINK_QUICK 1

// Used shader inputs from `shadertoy.com`:
// uniform      vec3 iResolution;           // viewport resolution (in pixels)
// uniform     float iTime;                 // shader playback time (in seconds)
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube

void mainImage( out vec4 out_fragment_color, in vec2 in_fragment_coords )
{
	// Normalized viewport pixel coordinates:
	// from: [0, width] x [0, height]
	//   to:     [0, 1] x [0, 1]
	vec2 uv = in_fragment_coords.xy / iResolution.xy;
	float aspect_ratio = iResolution.x / iResolution.y;

	// Fill background...
#if BACKGROUND_TEXTURE
	// ...with texture.

	// Here `texture( sampler2D, vec2 )` returns `vec4` which
	// contains Red, Green, Blue, and Alpha channel values of the texture = RGBA.
	// We do not care about Alpha channel since we do not deal with transparency,
	// so that is why we only take RGB part of the texture.
	vec3 background = texture( iChannel0, uv ).rgb;
#else
	// ...with white color.
	vec3 background = vec3( 1.0 ); // R = G = B = 1.0
#endif

	// Create simple component-based vignette effect.
	//
	// TODO: Update comments below to explain 4.0 -> 3.9 change.
	//
	// The function down below creates a parabola that extends down
	// and intersects perfectly at the viewport bounds -- at 0 and 1 for both X and Y axises.
	// This forms a sort of multiplication mask.
	// The further we move away from the center, the darker the color becomes.

#if 0
	float vignette_horizontal = 4.0 * uv.x * ( 1.0 - uv.x );
	float vignette_vertical   = 4.0 * uv.y * ( 1.0 - uv.y );
#else
	float vignette_horizontal = 3.9 * uv.x * ( 1.0 - uv.x );
	float vignette_vertical   = 3.9 * uv.y * ( 1.0 - uv.y );
#endif

	float vignette = vignette_horizontal * vignette_vertical;

	// TODO: Update 4.0 -> 3.9.
	// These operations could be combined into a single vector one, as:
	//
	// vec2 vignette_xy = 4.0 * uv * ( 1.0 - uv );
	// float vignette = vignette_xy.x * vignette_xy.y;
	//
	// However, the code is left as is for clarity and better understanding.


	// Now we have to create a believable 'blinking' function.
	//
	// First, we have to make a smooth base wave that will get modified later.
	// `sin(x)` is a good candidate, but we cannot use simply that because
	// `sin(x)` has an amplitude with a range of [-1, 1].
	//
	// We do not want the negative part of the function because the aim
	// is to create a some sort of arc that is tightly glued to the
	// value 1 -- to keep the original color values -- that then slowly
	// starts to drift down to eventually collapse at 0 -- turning everything black.
	//
	// The first approach is to use `abs(x)` function to get rid of the negative part.
	// This creates a sharp transition on previously negative parts,
	// resulting in a 'quick blink' similar to a regular human eye blink.
	//
	// The second approach is to multiply `sin(x)` by itself.
	// This will also get rid of the negative part, but transitions will remain equally smooth
	// on all parts. This will result in a more 'relaxed blink' compared to the first approach.
	//
	// Both approaches are valid and should be used considering the desired effect.
	// It should be noted that the second approach function has to have bigger amplitude
	// to compensate for it slowness because of the overall function smoothness.

#if BLINK_QUICK
	// 1st approach, 'quick blink'.
	const float blink_wave_speed     = 1.0;
	const float blink_wave_amplitude = 32.0; // Lower amplitude because of the sharp 0 collapse part in/out transitions.
	float blink_wave = abs( sin( iTime * blink_wave_speed ) ) * blink_wave_amplitude;
#else
	// 2nd approach, 'relaxed blink'.
	const float blink_wave_speed     = 1.0;
	const float blink_wave_amplitude = 64.0; // Higher amplitude because of the overall equally smooth transitions.
	float blink_wave = sin( iTime * blink_wave_speed ) * sin( iTime * blink_wave_speed ) * blink_wave_amplitude;
#endif

	// TODO: Explain.
	vignette = pow( vignette, 1.0 / blink_wave );

	// Output to screen.
	out_fragment_color = vec4( background * vignette, 0.0 );
}