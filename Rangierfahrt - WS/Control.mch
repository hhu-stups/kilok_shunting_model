MACHINE Control
EXTENDS Vision
VARIABLES
   CTR_allow_forw
INVARIANT
   CTR_allow_forw : NATURAL
INITIALISATION
   CTR_allow_forw := VIS_max_detect_dist
OPERATIONS
   CTR_SetAllowFront =
      IF VIS_detected_stops_front /= {}
         THEN CTR_allow_forw := min({min(ran(dom(VIS_detected_stops_front))), VIS_max_detect_dist})
         ELSE CTR_allow_forw := VIS_max_detect_dist
      END
END