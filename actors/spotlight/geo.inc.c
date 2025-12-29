#include "src/game/envfx_snow.h"

const GeoLayout spotlight_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 43, -1, actor_Handle_mesh_layer_1),
		GEO_OPEN_NODE(),
			GEO_TRANSLATE_ROTATE(LAYER_OPAQUE, 0, -43, 1, 0, -90, -90),
			GEO_OPEN_NODE(),
				GEO_ASM(0, geo_spotlight_rotate)
				GEO_ROTATION_NODE(0x00, 0, 0, 0),
				GEO_OPEN_NODE(),
					GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, actor_Light_mesh_layer_1),
					GEO_ASM(0, geo_spotlight_ray_scale),
					GEO_SCALE(0x00, 65536)
					GEO_OPEN_NODE(),
						GEO_ASM(0, geo_update_layer_transparency),
						GEO_ANIMATED_PART(LAYER_TRANSPARENT, 0, -3, 0, actor_Light_Ray_mesh_layer_5),
					GEO_CLOSE_NODE(),
				GEO_CLOSE_NODE(),
			GEO_CLOSE_NODE(),
		GEO_CLOSE_NODE(),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
