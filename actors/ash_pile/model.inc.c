Gfx model_ash_texture_i8_aligner[] = {gsSPEndDisplayList()};
u8 model_ash_texture_i8[] = {
	#include "ash_pile/ash_texture.i8.inc.c"
};

Vtx model_Ash_mesh_layer_5_vtx_0[10] = {
	{{ {0, 0, -199}, 0, {-16, -262}, {41, 41, 41, 255} }},
	{{ {172, 0, -99}, 0, {1083, 373}, {41, 41, 41, 255} }},
	{{ {172, 0, 99}, 0, {1083, 1643}, {41, 41, 41, 255} }},
	{{ {35, 252, 41}, 0, {206, 1151}, {41, 41, 41, 255} }},
	{{ {0, 183, -45}, 0, {-18, 723}, {41, 41, 41, 255} }},
	{{ {-36, 208, -35}, 0, {-247, 875}, {41, 41, 41, 255} }},
	{{ {-172, 0, -99}, 0, {-1116, 373}, {41, 41, 41, 255} }},
	{{ {-172, 0, 99}, 0, {-1116, 1643}, {41, 41, 41, 255} }},
	{{ {0, 0, 199}, 0, {-16, 2278}, {41, 41, 41, 255} }},
	{{ {0, 172, 45}, 0, {-18, 1294}, {41, 41, 41, 255} }},
};

Gfx model_Ash_mesh_layer_5_tri_0[] = {
	gsSPVertex(model_Ash_mesh_layer_5_vtx_0 + 0, 10, 0),
	gsSP1Triangle(0, 1, 2, 0),
	gsSP1Triangle(1, 0, 3, 0),
	gsSP1Triangle(0, 4, 3, 0),
	gsSP1Triangle(5, 4, 0, 0),
	gsSP1Triangle(0, 6, 5, 0),
	gsSP1Triangle(7, 6, 0, 0),
	gsSP1Triangle(2, 7, 0, 0),
	gsSP1Triangle(2, 8, 7, 0),
	gsSP1Triangle(8, 2, 3, 0),
	gsSP1Triangle(2, 1, 3, 0),
	gsSP1Triangle(8, 3, 9, 0),
	gsSP1Triangle(4, 9, 3, 0),
	gsSP1Triangle(5, 9, 4, 0),
	gsSP1Triangle(8, 9, 5, 0),
	gsSP1Triangle(8, 5, 7, 0),
	gsSP1Triangle(7, 5, 6, 0),
	gsSPEndDisplayList(),
};


Gfx mat_model_Fast3D_Material_layer5[] = {
	gsSPClearGeometryMode(G_LIGHTING | G_SHADING_SMOOTH),
	gsDPPipeSync(),
	gsDPSetCombineLERP(TEXEL0, 0, SHADE, 0, ENVIRONMENT, 0, SHADE, 0, TEXEL0, 0, SHADE, 0, ENVIRONMENT, 0, SHADE, 0),
	gsDPSetAlphaDither(G_AD_NOISE),
	gsDPSetRenderMode(G_RM_AA_ZB_XLU_SURF, G_RM_AA_ZB_XLU_SURF2),
	gsSPTexture(65535, 65535, 0, 0, 1),
	gsDPSetTextureImage(G_IM_FMT_I, G_IM_SIZ_8b_LOAD_BLOCK, 1, model_ash_texture_i8),
	gsDPSetTile(G_IM_FMT_I, G_IM_SIZ_8b_LOAD_BLOCK, 0, 0, 7, 0, G_TX_WRAP | G_TX_NOMIRROR, 0, 0, G_TX_WRAP | G_TX_NOMIRROR, 0, 0),
	gsDPLoadBlock(7, 0, 0, 511, 512),
	gsDPSetTile(G_IM_FMT_I, G_IM_SIZ_8b, 4, 0, 0, 0, G_TX_WRAP | G_TX_NOMIRROR, 5, 0, G_TX_WRAP | G_TX_NOMIRROR, 5, 0),
	gsDPSetTileSize(0, 0, 0, 124, 124),
	gsSPEndDisplayList(),
};

Gfx mat_revert_model_Fast3D_Material_layer5[] = {
	gsSPSetGeometryMode(G_LIGHTING | G_SHADING_SMOOTH),
	gsDPPipeSync(),
	gsDPSetAlphaDither(G_AD_DISABLE),
	gsDPSetRenderMode(G_RM_AA_ZB_XLU_SURF, G_RM_AA_ZB_XLU_SURF2),
	gsSPEndDisplayList(),
};

Gfx model_Ash_mesh_layer_5[] = {
	gsSPDisplayList(mat_model_Fast3D_Material_layer5),
	gsSPDisplayList(model_Ash_mesh_layer_5_tri_0),
	gsSPDisplayList(mat_revert_model_Fast3D_Material_layer5),
	gsDPPipeSync(),
	gsSPSetGeometryMode(G_LIGHTING),
	gsSPClearGeometryMode(G_TEXTURE_GEN),
	gsDPSetCombineLERP(0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT, 0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT),
	gsSPTexture(65535, 65535, 0, 0, 0),
	gsDPSetEnvColor(255, 255, 255, 255),
	gsDPSetAlphaCompare(G_AC_NONE),
	gsSPEndDisplayList(),
};

Gfx mat_model_Fast3D_Material_layer1[] = {
	gsSPClearGeometryMode(G_LIGHTING | G_SHADING_SMOOTH),
	gsDPPipeSync(),
	gsDPSetCombineLERP(TEXEL0, 0, SHADE, 0, ENVIRONMENT, 0, SHADE, 0, TEXEL0, 0, SHADE, 0, ENVIRONMENT, 0, SHADE, 0),
	gsDPSetAlphaDither(G_AD_NOISE),
	gsDPSetRenderMode(G_RM_AA_ZB_OPA_SURF, G_RM_AA_ZB_OPA_SURF2),
	gsSPTexture(65535, 65535, 0, 0, 1),
	gsDPSetTextureImage(G_IM_FMT_I, G_IM_SIZ_8b_LOAD_BLOCK, 1, model_ash_texture_i8),
	gsDPSetTile(G_IM_FMT_I, G_IM_SIZ_8b_LOAD_BLOCK, 0, 0, 7, 0, G_TX_WRAP | G_TX_NOMIRROR, 0, 0, G_TX_WRAP | G_TX_NOMIRROR, 0, 0),
	gsDPLoadBlock(7, 0, 0, 511, 512),
	gsDPSetTile(G_IM_FMT_I, G_IM_SIZ_8b, 4, 0, 0, 0, G_TX_WRAP | G_TX_NOMIRROR, 5, 0, G_TX_WRAP | G_TX_NOMIRROR, 5, 0),
	gsDPSetTileSize(0, 0, 0, 124, 124),
	gsSPEndDisplayList(),
};

Gfx mat_revert_model_Fast3D_Material_layer1[] = {
	gsSPSetGeometryMode(G_LIGHTING | G_SHADING_SMOOTH),
	gsDPPipeSync(),
	gsDPSetAlphaDither(G_AD_DISABLE),
	gsDPSetRenderMode(G_RM_AA_ZB_OPA_SURF, G_RM_AA_ZB_OPA_SURF2),
	gsSPEndDisplayList(),
};

Gfx model_Ash_mesh_layer_1[] = {
	gsSPDisplayList(mat_model_Fast3D_Material_layer1),
	gsSPDisplayList(model_Ash_mesh_layer_5_tri_0),
	gsSPDisplayList(mat_revert_model_Fast3D_Material_layer1),
	gsDPPipeSync(),
	gsSPSetGeometryMode(G_LIGHTING),
	gsSPClearGeometryMode(G_TEXTURE_GEN),
	gsDPSetCombineLERP(0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT, 0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT),
	gsSPTexture(65535, 65535, 0, 0, 0),
	gsDPSetEnvColor(255, 255, 255, 255),
	gsDPSetAlphaCompare(G_AC_NONE),
	gsSPEndDisplayList(),
};