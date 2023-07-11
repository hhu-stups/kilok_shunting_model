MACHINE Vision
EXTENDS Environment
CONSTANTS
   VIS_max_detect_dist /*@desc "Max. Erkennungsdistanz" */
PROPERTIES
   VIS_max_detect_dist : NATURAL1
VARIABLES
   VIS_detected_track,
   VIS_detected_sig_front,
   VIS_detected_points_front, VIS_detected_obj_front,
   VIS_detected_stops_front
INVARIANT
   VIS_detected_track <: ENV_TRK & VIS_detected_track : ENV_BLOCKS >+> ENV_BLOCKS &

   VIS_detected_sig_front : ENV_SIGNALS +-> ENV_SIGNAL_STATES &
   VIS_detected_points_front : ENV_POINTS +-> ENV_POINT_STATES &
   VIS_detected_obj_front <: ENV_OBJECTS - {lok} &

   VIS_detected_stops_front : (ENV_BLOCKS*NATURAL) <-> ENV_STOP_REASONS &
   VIS_detected_stops_front : FIN(VIS_detected_stops_front)
INITIALISATION
   VIS_detected_track := ENV_TRK |> closure(ENV_next_init)[dom(ENV_object_front_init(lok))] ||
   VIS_detected_sig_front := {} ||
   VIS_detected_points_front := {} ||
   VIS_detected_obj_front := {} ||
   VIS_detected_stops_front := {}
DEFINITIONS
   "definitions.def"
OPERATIONS
   VIS_DetectCorrectObject_Front(reason) =
      ANY
         frnt, B_obj, B_gauge, o, dist
      WHERE
         ENV_derailed(lok) = FALSE
         & front_of_object(lok,frnt)
         & (frnt |-> B_obj : closure(VIS_detected_track) 
               & B_gauge = B_obj)
         & back_of_object(o,B_obj)
         & o /= lok
         & (((frnt /= B_gauge or ENV_object_front(lok)(B_gauge) < ENV_object_back(o)(B_obj))
            & dist = dist_front(frnt,B_gauge,ENV_object_back(o)(B_obj))
            & reason = ENV_object_type(o))
         or (reason : {brake_shoe}
            & dist : ENV_stop_distances_front~[{reason}][{B_obj}]))
         & dist <= VIS_max_detect_dist
         & (B_gauge|->dist) |-> reason /: VIS_detected_stops_front
      THEN 
         IF reason : {human, wagon} THEN VIS_detected_obj_front := VIS_detected_obj_front \/ {o} END ||
         VIS_detected_stops_front := VIS_detected_stops_front \/ {(B_gauge|->dist) |-> reason}
      END;
   VIS_DetectDisappearedStopReason_Front(reason) =
      ANY
         B, dist
      WHERE 
         reason : {human, wagon, brake_shoe}
         & reason : ran(VIS_detected_stops_front)
         & B|->dist : VIS_detected_stops_front~[{reason}]
         & B|->dist /: ENV_stop_distances_front~[{reason}]
         & dist <= VIS_max_detect_dist
      THEN
         //IF reason : {human, wagon} THEN detected_obj_front := detected_obj_front - {o} END || // Bisher kann kein Objekt bis auf den Hemmschuh entfernt werden
         VIS_detected_stops_front := VIS_detected_stops_front - {(B|->dist) |-> reason}
      END;

   VIS_DetectCorrectSignal_Front(B1,B2) =
      ANY
         frnt, dist, st
      WHERE
         ENV_derailed(lok) = FALSE
         & front_of_object(lok,frnt) & frnt |-> B1 : closure(VIS_detected_track) & frnt |-> B2 : closure1(VIS_detected_track)
         & B1 |-> B2: ENV_SIGNALS - ENV_TRK~ & st : ENV_SIGNAL_STATES
         & !s.(s:ENV_SIGNALS & prj1(ENV_BLOCKS,ENV_BLOCKS)(s)=B1 => ENV_signal_states(s) = st)
         & (B1 |-> B2 /: dom(VIS_detected_sig_front) or VIS_detected_sig_front(B1|->B2) /= st)
         & dist = dist_front(frnt,B2,0)
         & dist <= VIS_max_detect_dist
      THEN 
         VIS_detected_sig_front(B1 |-> B2) := st ||
         IF st = Sh0 
            THEN VIS_detected_stops_front := VIS_detected_stops_front \/ {(B2|->dist) |-> signal_without_train_protect}
            ELSE VIS_detected_stops_front := VIS_detected_stops_front - {(B2|->dist) |-> signal_without_train_protect}
         END ||
         IF 
            st = Sh1 // or st = Wn7  // (Wn7 does not give permission to drive)
         THEN 
            ENV_SetSafetyCritical(FALSE) ||
            ENV_SetStopDistancesFront({i | i : ENV_stop_distances_front & prj2(ENV_BLOCKS,INTEGER)(prj1(ENV_BLOCKS*INTEGER,ENV_STOP_REASONS)(i))>=0})
         END
      END;
   VIS_DetectWrongSignal_Front(B,st,dist) = 
      ANY 
         frnt, B2
      WHERE
         ENV_derailed(lok) = FALSE
         & front_of_object(lok,frnt) & frnt |-> B : closure(VIS_detected_track) & frnt |-> B2 : closure1(VIS_detected_track)
         & B |-> B2: ENV_SIGNALS - ENV_TRK~ & st : ENV_SIGNAL_STATES
         & IF st = Sh0 THEN #s.(s:ENV_SIGNALS & prj1(ENV_BLOCKS,ENV_BLOCKS)(s)=B & ENV_signal_states(s) /= st) 
           ELSE !s.(s:ENV_SIGNALS & prj1(ENV_BLOCKS,ENV_BLOCKS)(s)=B => ENV_signal_states(s) /= st) END
         & dist <= VIS_max_detect_dist
         & dist = dist_front(frnt, B2, 0)
      THEN
         VIS_detected_sig_front(B |-> B2) := st ||
         IF st = Sh0 
            THEN VIS_detected_stops_front := VIS_detected_stops_front \/ {(B2|->dist) |-> signal_without_train_protect}
            ELSE VIS_detected_stops_front := VIS_detected_stops_front - {(B2|->dist) |-> signal_without_train_protect}
         END
      END;

   VIS_DetectCorrectPointPosition_Front(B1,B2,B3,st) = 
      ANY
         frnt, dist, old_ENV_next, new_ENV_next, old_detected_stops_front, old_detected_sig_front
      WHERE 
         ENV_derailed(lok) = FALSE 
         & front_of_object(lok,frnt) & B1 : closure(VIS_detected_track)[{frnt}]
         & (B2,B3) : ENV_POINTS[{B1}] 
         & ENV_point_states(B1|->(B2,B3)) = st
         & (B1 |-> (B2,B3) /: dom(VIS_detected_points_front) or VIS_detected_points_front(B1|->(B2,B3)) /= st)
         & B1|->new_ENV_next : ENV_next & ((B2 = old_ENV_next & B3 = new_ENV_next) or (B2 = new_ENV_next & B3 = old_ENV_next))
         & old_detected_stops_front = VIS_detected_stops_front[{(old_ENV_next,dist)}] /\ {signal_with_train_protect,signal_without_train_protect}
         & old_detected_sig_front = VIS_detected_sig_front[{(B1,old_ENV_next)}]
         & dist = dist_front(frnt,B2,0)
         & dist <= VIS_max_detect_dist
      THEN
         VIS_detected_track := ENV_TRK |> (closure(ENV_next)[{frnt}] \/ closure(ENV_next~)[{frnt}]);
         VIS_detected_sig_front := closure(VIS_detected_track) <| VIS_detected_sig_front ||
         VIS_detected_stops_front := (closure(VIS_detected_track)[{frnt}] <| dom(VIS_detected_stops_front)) <| VIS_detected_stops_front ||
	      VIS_detected_points_front := (closure(VIS_detected_track)[{frnt}] <| dom(VIS_detected_points_front)) <| VIS_detected_points_front |>> {undef} ||
         VIS_detected_obj_front := { o | o : VIS_detected_obj_front & #B.(back_of_object(o,B)
                                    & B : closure(VIS_detected_track)[{frnt}] )};
         VIS_detected_points_front(B1 |-> (B2,B3)) := st;
         IF old_detected_stops_front /= {} // For signal at zero position
            THEN VIS_detected_stops_front := (VIS_detected_stops_front \/ {(new_ENV_next,dist)}*old_detected_stops_front) - {(old_ENV_next,dist)}*old_detected_stops_front
         END ||
         IF old_detected_sig_front /= {} & (B1,new_ENV_next) /: dom(VIS_detected_sig_front)
            THEN VIS_detected_sig_front := (VIS_detected_sig_front \/ {(B1,new_ENV_next)}*old_detected_sig_front) - {(B1,old_ENV_next)}*old_detected_sig_front
         END;
         IF st = undef 
            THEN VIS_detected_stops_front := VIS_detected_stops_front \/ {(new_ENV_next|->dist) |-> undef_point}
            ELSE VIS_detected_stops_front := VIS_detected_stops_front - {(new_ENV_next|->dist) |-> undef_point}
         END
      END;
   VIS_DetectWrongPointPosition_Front(B,st,dist) = 
      ANY
         frnt, B2, B3, old_ENV_next, new_ENV_next, old_detected_stops_front, old_detected_sig_front
      WHERE
         ENV_derailed(lok) = FALSE
         & front_of_object(lok,frnt) & B : closure(VIS_detected_track)[{frnt}]
         & (B2,B3) : ENV_POINTS[{B}] 
         & ENV_point_states(B|->(B2,B3)) /= st
         & (B |-> (B2,B3) /: dom(VIS_detected_points_front) or VIS_detected_points_front(B|->(B2,B3)) /= st)
         & B|->new_ENV_next : ENV_next & ((B2 = old_ENV_next & B3 = new_ENV_next) or (B2 = new_ENV_next & B3 = old_ENV_next))
         & old_detected_stops_front = VIS_detected_stops_front[{(old_ENV_next,dist)}] /\ {signal_with_train_protect,signal_without_train_protect}
         & old_detected_sig_front = VIS_detected_sig_front[{(B,old_ENV_next)}]
         & dist = dist_front(frnt,B2,0)
         & dist <= VIS_max_detect_dist
      THEN         
         IF st = undef 
            THEN VIS_detected_stops_front := VIS_detected_stops_front \/ {(B|->dist) |-> undef_point}
            ELSE
               VIS_detected_track := (ENV_TRK |> (closure(ENV_TRK)[{frnt}] \/ closure(ENV_next~)[{frnt}])) |>> closure(ENV_next)[{frnt}] ||
               VIS_detected_stops_front := VIS_detected_stops_front - {(B|->dist) |-> undef_point} //;
         END;
         VIS_detected_sig_front := closure(VIS_detected_track) <| VIS_detected_sig_front ||
         VIS_detected_points_front := (closure(VIS_detected_track)[{B}] <| dom(VIS_detected_points_front)) <| VIS_detected_points_front ||
         VIS_detected_stops_front := {j | j : VIS_detected_stops_front & #B.(B:closure(VIS_detected_track)[{B}] & B=prj1(ENV_BLOCKS,NATURAL)(prj1(ENV_BLOCKS*NATURAL,ENV_STOP_REASONS)(j)))};
         VIS_detected_points_front(B |-> (B2,B3)) := st ||
         IF old_detected_stops_front /= {}
            THEN VIS_detected_stops_front := (VIS_detected_stops_front \/ {(new_ENV_next,dist)}*old_detected_stops_front) - {(old_ENV_next,dist)}*old_detected_stops_front
         END ||
         IF old_detected_sig_front /= {} & (B,new_ENV_next) /: dom(VIS_detected_sig_front)
            THEN VIS_detected_sig_front := (VIS_detected_sig_front \/ {(B,new_ENV_next)}*old_detected_sig_front) - {(B,old_ENV_next)}*old_detected_sig_front
         END
      END;

   VIS_DetectCorrectTrack =
      ANY
         frnt
      WHERE 
         front_of_object(lok,frnt)
         & #B.((B:closure(ENV_next)[{frnt}] or B:closure(ENV_next~)[{frnt}]) & B /: dom(VIS_detected_track) \/ ran(VIS_detected_track) )
      THEN 
         VIS_detected_track := ENV_TRK |> (closure(ENV_next)[{frnt}] \/ closure(ENV_next~)[{frnt}]);
         VIS_detected_sig_front := closure(VIS_detected_track) <| VIS_detected_sig_front ||
         VIS_detected_stops_front := (closure(VIS_detected_track)[{frnt}] <| dom(VIS_detected_stops_front)) <| VIS_detected_stops_front ||
	      VIS_detected_points_front := (closure(VIS_detected_track)[{frnt}] <| dom(VIS_detected_points_front)) <| VIS_detected_points_front |>> {undef}
      END;

   VIS_SetDetectedStopsFront(new) = VIS_detected_stops_front := new;
   VIS_SetDetectedSigFront(new) = VIS_detected_sig_front := new;
   VIS_SetDetectedPointsFront(new) = VIS_detected_points_front := new
END