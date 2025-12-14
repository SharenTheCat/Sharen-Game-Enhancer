#include "src/game/envfx_snow.h"

const GeoLayout light_shine_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_ANIMATED_PART(LAYER_TRANSPARENT, 0, 0, 0, model_Bone_mesh_layer_5),
		GEO_OPEN_NODE(),
			GEO_ASM(0, geo_update_layer_transparency),
			GEO_ANIMATED_PART(LAYER_TRANSPARENT, 0, 0, -22, model_Ring_mesh_layer_5),
		GEO_CLOSE_NODE(),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
