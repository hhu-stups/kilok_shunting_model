MACHINE Control
EXTENDS Vision
VARIABLES
   CTR_allow_forw, CTR_allow_back
INVARIANT
   CTR_allow_forw : NATURAL &
   CTR_allow_back : NATURAL
INITIALISATION
   CTR_allow_forw := VIS_max_detect_dist ||
   CTR_allow_back := VIS_max_detect_dist
OPERATIONS
   CTR_SetAllowFront =
      IF VIS_detected_stops_front /= {}
         THEN CTR_allow_forw := min({min(ran(dom(VIS_detected_stops_front))), VIS_max_detect_dist})
         ELSE CTR_allow_forw := VIS_max_detect_dist
      END;
   CTR_SetAllowBack =
      IF VIS_detected_stops_back /= {}
         THEN CTR_allow_back := min({min(ran(dom(VIS_detected_stops_back))), VIS_max_detect_dist})
         ELSE CTR_allow_back := VIS_max_detect_dist
      END
END