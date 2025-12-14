#include "src/game/envfx_snow.h"

const GeoLayout ash_pile_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_ASM(0, geo_update_layer_transparency),
		GEO_SWITCH_CASE(2, geo_switch_anim_state),
		GEO_OPEN_NODE(),
			GEO_DISPLAY_LIST(LAYER_OPAQUE, model_Ash_mesh_layer_1),
			GEO_DISPLAY_LIST(LAYER_TRANSPARENT, model_Ash_mesh_layer_5),
		GEO_CLOSE_NODE(),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
