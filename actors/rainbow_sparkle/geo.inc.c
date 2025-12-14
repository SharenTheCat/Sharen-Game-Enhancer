// 0x17000038
const GeoLayout rainbow_sparkle_geo[] = {
   GEO_NODE_START(),
   GEO_OPEN_NODE(),
      GEO_SWITCH_CASE(8, geo_switch_anim_state),
      GEO_OPEN_NODE(),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_04021718),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_04021730),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_04021748),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_04021760),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_04021778),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_04021790),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_040217A8),
         GEO_DISPLAY_LIST(LAYER_ALPHA, sparkle_dl_040217C0),
      GEO_CLOSE_NODE(),
   GEO_CLOSE_NODE(),
   GEO_END(),
};
