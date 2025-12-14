static const Vtx sparkle_vertex_0401DE60[] = {
    {{{   -32,      0,      0}, 0, {     0,    992}, {0xff, 0xff, 0xff, 0x64}}},
    {{{    32,      0,      0}, 0, {   992,    992}, {0xff, 0xff, 0xff, 0x64}}},
    {{{    32,     64,      0}, 0, {   992,      0}, {0xff, 0xff, 0xff, 0x64}}},
    {{{   -32,     64,      0}, 0, {     0,      0}, {0xff, 0xff, 0xff, 0x64}}},
};

ALIGNED8 const Texture sparkle_texture_red[] = {
#include "actors/rainbow_sparkle/sparkle_red.rgba16.inc.c"
};

ALIGNED8 const Texture sparkle_texture_orange[] = {
#include "actors/rainbow_sparkle/sparkle_orange.rgba16.inc.c"
};

ALIGNED8 const Texture sparkle_texture_yellow[] = {
#include "actors/rainbow_sparkle/sparkle_yellow.rgba16.inc.c"
};

ALIGNED8 const Texture sparkle_texture_green[] = {
#include "actors/rainbow_sparkle/sparkle_green.rgba16.inc.c"
};

ALIGNED8 const Texture sparkle_texture_teal[] = {
#include "actors/rainbow_sparkle/sparkle_teal.rgba16.inc.c"
};

ALIGNED8 const Texture sparkle_texture_blue[] = {
#include "actors/rainbow_sparkle/sparkle_blue.rgba16.inc.c"
};

ALIGNED8 const Texture sparkle_texture_purple[] = {
#include "actors/rainbow_sparkle/sparkle_purple.rgba16.inc.c"
};

ALIGNED8 const Texture sparkle_texture_magenta[] = {
#include "actors/rainbow_sparkle/sparkle_magenta.rgba16.inc.c"
};

const Gfx sparkle_dl_040216A0[] = {
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsDPSetTile(G_IM_FMT_RGBA, G_IM_SIZ_16b, 0, 0, G_TX_LOADTILE, 0, G_TX_CLAMP, 5, G_TX_NOLOD, G_TX_CLAMP, 5, G_TX_NOLOD),
    gsDPLoadSync(),
    gsDPLoadBlock(G_TX_LOADTILE, 0, 0, 32 * 32 - 1, CALC_DXT(32, G_IM_SIZ_16b_BYTES)),
    gsDPSetTile(G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 0, G_TX_RENDERTILE, 0, G_TX_CLAMP, 5, G_TX_NOLOD, G_TX_CLAMP, 5, G_TX_NOLOD),
    gsDPSetTileSize(0, 0, 0, (32 - 1) << G_TEXTURE_IMAGE_FRAC, (32 - 1) << G_TEXTURE_IMAGE_FRAC),
    gsSPVertex(sparkle_vertex_0401DE60, 4, 0),
    gsSP2Triangles( 0,  1,  2, 0x0,  0,  2,  3, 0x0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPSetCombineMode(G_CC_SHADE, G_CC_SHADE),
    gsSPSetGeometryMode(G_LIGHTING),
    gsSPEndDisplayList(),
};

const Gfx sparkle_dl_04021718[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_red),
    gsSPBranchList(sparkle_dl_040216A0),
};

const Gfx sparkle_dl_04021730[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_orange),
    gsSPBranchList(sparkle_dl_040216A0),
};

const Gfx sparkle_dl_04021748[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_yellow),
    gsSPBranchList(sparkle_dl_040216A0),
};

const Gfx sparkle_dl_04021760[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_green),
    gsSPBranchList(sparkle_dl_040216A0),
};

const Gfx sparkle_dl_04021778[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_teal),
    gsSPBranchList(sparkle_dl_040216A0),
};

const Gfx sparkle_dl_04021790[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_blue),
    gsSPBranchList(sparkle_dl_040216A0),
};

const Gfx sparkle_dl_040217A8[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_purple),
    gsSPBranchList(sparkle_dl_040216A0),
};

const Gfx sparkle_dl_040217C0[] = {
    gsDPPipeSync(),
    gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 1, sparkle_texture_magenta),
    gsSPBranchList(sparkle_dl_040216A0),
};
