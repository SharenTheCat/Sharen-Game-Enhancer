Vtx model_Plane_001_mesh_layer_5_vtx_cull[8] = {
	{{ {-60, 0, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
	{{ {-60, 363, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
	{{ {-60, 363, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
	{{ {-60, 0, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
	{{ {60, 0, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
	{{ {60, 363, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
	{{ {60, 363, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
	{{ {60, 0, 0}, 0, {0, 0}, {0, 0, 0, 0} }},
};

Vtx model_Plane_001_mesh_layer_5_vtx_0[3] = {
	{{ {60, 363, 0}, 0, {-16, 1008}, {255, 189, 0, 0} }},
	{{ {-60, 363, 0}, 0, {-16, 1008}, {255, 189, 0, 0} }},
	{{ {0, 0, 0}, 0, {-16, 1008}, {255, 216, 9, 86} }},
};

Gfx model_Plane_001_mesh_layer_5_tri_0[] = {
	gsSPVertex(model_Plane_001_mesh_layer_5_vtx_0 + 0, 3, 0),
	gsSP1Triangle(0, 1, 2, 0),
	gsSPEndDisplayList(),
};


Gfx mat_model_Ray[] = {
	gsSPGeometryMode(G_LIGHTING, 0),
	gsDPPipeSync(),
	gsDPSetCombineLERP(0, 0, 0, SHADE, 0, 0, 0, SHADE, 0, 0, 0, SHADE, 0, 0, 0, SHADE),
	gsSPTexture(65535, 65535, 0, 0, 1),
	gsSPEndDisplayList(),
};

Gfx mat_revert_model_Ray[] = {
	gsSPGeometryMode(0, G_LIGHTING),
	gsDPPipeSync(),
	gsSPEndDisplayList(),
};

Gfx model_Plane_001_mesh_layer_5[] = {
	gsSPClearGeometryMode(G_LIGHTING),
	gsSPVertex(model_Plane_001_mesh_layer_5_vtx_cull + 0, 8, 0),
	gsSPSetGeometryMode(G_LIGHTING),
	gsSPCullDisplayList(0, 7),
	gsSPDisplayList(mat_model_Ray),
	gsSPDisplayList(model_Plane_001_mesh_layer_5_tri_0),
	gsSPDisplayList(mat_revert_model_Ray),
	gsDPPipeSync(),
	gsSPSetGeometryMode(G_LIGHTING),
	gsSPClearGeometryMode(G_TEXTURE_GEN),
	gsDPSetCombineLERP(0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT, 0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT),
	gsSPTexture(65535, 65535, 0, 0, 0),
	gsDPSetEnvColor(255, 255, 255, 255),
	gsDPSetAlphaCompare(G_AC_NONE),
	gsSPEndDisplayList(),
};

