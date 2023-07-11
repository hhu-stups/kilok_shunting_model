MACHINE Vision
EXTENDS Environment
CONSTANTS
   VIS_max_detect_dist /*@desc "Max. Erkennungsdistanz" */
PROPERTIES
   VIS_max_detect_dist : NATURAL1
VARIABLES
   VIS_detected_track,
   VIS_detected_sig_front, VIS_detected_sig_back, 
   VIS_detected_points_front, VIS_detected_obj_front,
   VIS_detected_stops_front, VIS_detected_stops_back,
   VIS_detected_border_signs_front
INVARIANT
   VIS_detected_track <: ENV_TRK & VIS_detected_track : ENV_BLOCKS >+> ENV_BLOCKS &

   VIS_detected_sig_front : ENV_SIGNALS +-> ENV_SIGNAL_STATES &
   VIS_detected_sig_back : ENV_SIGNALS +-> ENV_SIGNAL_STATES &
   VIS_detected_points_front : ENV_POINTS +-> ENV_POINT_STATES &
   VIS_detected_obj_front <: ENV_OBJECTS - {lok} &

   VIS_detected_stops_front : (ENV_BLOCKS*NATURAL) <-> ENV_STOP_REASONS &
   VIS_detected_stops_front : FIN(VIS_detected_stops_front) &
   VIS_detected_stops_back : (ENV_BLOCKS*NATURAL) <-> ENV_STOP_REASONS &
   VIS_detected_stops_back : FIN(VIS_detected_stops_back) &

   VIS_detected_border_signs_front : (ENV_TRK*NATURAL1) +-> INTEGER // First block: before branching, second block: after branching next to Ra12, NAT1: distance of the border sign to the point (this is unique for each border sign); INT: total distance to Ra12
INITIALISATION
   VIS_detected_track := ENV_TRK |> closure(ENV_next_init)[dom(ENV_object_front_init(lok))] ||
   VIS_detected_sig_front := {} ||
   VIS_detected_sig_back := {} ||
   VIS_detected_points_front := {} ||
   VIS_detected_obj_front := {} ||
   VIS_detected_stops_front := {} ||
   VIS_detected_stops_back := {} ||
   VIS_detected_border_signs_front := {}
DEFINITIONS
   "definitions.def"
OPERATIONS
   VIS_DetectCorrectObject_Front(reason) =
      ANY
         frnt, B0, B_obj, B_gauge, o, dist, P
      WHERE 
         ENV_derailed(lok) = FALSE
         & front_of_object(lok,frnt)
         & ((frnt |-> B_obj : closure(VIS_detected_track) 
               & B_gauge = B_obj) 
            or 
            (frnt |-> B_gauge : closure(VIS_detected_track)
               & P : ENV_POINTS
               & (P = (B0,(B_obj,B_gauge)) or P = (B0,(B_gauge,B_obj)))
               & (B0, B_gauge, ENV_border_signs(P)) : dom(VIS_detected_border_signs_front)
               & dist <= VIS_detected_border_signs_front(B0, B_gauge, ENV_border_signs(P))))
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
         //IF reason : {human, wagon} THEN VIS_detected_obj_front := VIS_detected_obj_front - {o} END || // TODO: Is needed for switching the point (detections only for new branch)
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
         frnt
      WHERE
         ENV_derailed(lok) = FALSE
         & front_of_object(lok,frnt)
         & B : closure(VIS_detected_track)[{frnt}]
         & st : ENV_SIGNAL_STATES
         & dist : NATURAL1 & block_after_distance_forwards(frnt,ENV_object_front(lok)(frnt),dist,B) //ENV_object_front(lok)(B) + dist < ENV_block_length(B)
         & dist <= VIS_max_detect_dist
      THEN
         IF st = Sh0 
            THEN VIS_detected_stops_front := VIS_detected_stops_front \/ {(B|->dist) |-> signal_without_train_protect}
            ELSE VIS_detected_stops_front := VIS_detected_stops_front - {(B|->dist) |-> signal_without_train_protect}
         END
      END;
   VIS_DetectCorrectSignal_Back(B1,B2) =
      ANY
         back, dist, st
      WHERE
         ENV_derailed(lok) = FALSE 
         & back_of_object(lok,back) & back |-> B1 : closure1(VIS_detected_track~) & back |-> B2 : closure(VIS_detected_track~)
         & B2 |-> B1: ENV_SIGNALS - ENV_TRK & st : ENV_SIGNAL_STATES
         & IF st = Sh0 THEN !s.(s:ENV_SIGNALS & prj1(ENV_BLOCKS,ENV_BLOCKS)(s)=B1 => ENV_signal_states(s) = st) 
           ELSE #s.(s:ENV_SIGNALS & prj1(ENV_BLOCKS,ENV_BLOCKS)(s)=B1 & ENV_signal_states(s) = st) END
         & (B2 |-> B1 /: dom(VIS_detected_sig_back) or VIS_detected_sig_back(B2|->B1) /= st)
         & dist = dist_back(back,B1,ENV_block_length(B1)-1)
         & dist <= VIS_max_detect_dist
      THEN 
         VIS_detected_sig_back(B2 |-> B1) := st ||
         IF st = Sh0 
            THEN VIS_detected_stops_back := VIS_detected_stops_back \/ {(B2|->dist) |-> signal_without_train_protect}
            ELSE VIS_detected_stops_back := VIS_detected_stops_back - {(B2|->dist) |-> signal_without_train_protect}
         END
      END;      
   VIS_DetectWrongSignal_Back(B,st,dist) = 
      ANY 
         back
      WHERE
         ENV_derailed(lok) = FALSE
         & back_of_object(lok,back)
         & B : closure(VIS_detected_track~)[{back}]
         & st : ENV_SIGNAL_STATES
         & dist : NATURAL1 & block_after_distance_backwards(back,ENV_object_back(lok)(back),dist,B) //dist < ENV_object_back(lok)(B)
         & dist <= VIS_max_detect_dist
      THEN
         IF st = Sh0 
            THEN VIS_detected_stops_back := VIS_detected_stops_back \/ {(B|->dist) |-> signal_without_train_protect}
            ELSE VIS_detected_stops_back := VIS_detected_stops_back - {(B|->dist) |-> signal_without_train_protect}
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
         VIS_detected_obj_front := { o | o : VIS_detected_obj_front & #(B,B_gauge).(back_of_object(o,B)
                                    & (B : closure(VIS_detected_track)[{frnt}]
                                       or ((B1,B_gauge,ENV_border_signs(B1, (B2,B3))) : dom(VIS_detected_border_signs_front)
                                          & dist_front(frnt, B, ENV_object_back(o)(B)) <= VIS_detected_border_signs_front(B1,B_gauge,ENV_border_signs(B1, (B2,B3))) )))};
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
         END ||
         IF (B1,B2,ENV_border_signs(B1,(B2,B3))) : dom(VIS_detected_border_signs_front) & B1|->B2 /: VIS_detected_track
            THEN VIS_detected_border_signs_front := ({(B1,B2,ENV_border_signs(B1,(B2,B3)))} <<| VIS_detected_border_signs_front) \/ {(B1,B3,ENV_border_signs(B1,(B2,B3))) |-> VIS_detected_border_signs_front((B1,B2,ENV_border_signs(B1,(B2,B3))))}
            ELSIF (B1,B3,ENV_border_signs(B1,(B2,B3))) : dom(VIS_detected_border_signs_front) & B1|->B3 /: VIS_detected_track
            THEN VIS_detected_border_signs_front := ({(B1,B3,ENV_border_signs(B1,(B2,B3)))} <<| VIS_detected_border_signs_front) \/ {(B1,B2,ENV_border_signs(B1,(B2,B3))) |-> VIS_detected_border_signs_front((B1,B3,ENV_border_signs(B1,(B2,B3))))}
         END 
      END;
   VIS_DetectWrongPointPosition_Front(B,st,dist) = 
      ANY
         frnt
      WHERE
         ENV_derailed(lok) = FALSE
         & front_of_object(lok,frnt)
         & B : closure(VIS_detected_track)[{frnt}]
         & st : ENV_POINT_STATES
         & dist : NATURAL1 & block_after_distance_forwards(frnt,ENV_object_front(lok)(frnt),dist,B) //ENV_object_front(lok)(B) + dist < ENV_block_length(B)
         & dist <= VIS_max_detect_dist
      THEN
         IF st = undef 
            THEN VIS_detected_stops_front := VIS_detected_stops_front \/ {(B|->dist) |-> undef_point}
            ELSE VIS_detected_stops_front := VIS_detected_stops_front - {(B|->dist) |-> undef_point}
         END
      END;

   VIS_DetectCorrectBorderSign_Front(P) =
      ANY
         frnt, B0, B1, B2, dist
      WHERE
         ENV_derailed(lok) = FALSE
         & P : ENV_POINTS
         & (P = (B0, (B1, B2)) or P = (B0, (B2, B1)))
         & front_of_object(lok,frnt)
         & B1 : closure(VIS_detected_track)[{frnt}]
         & ((B0,B1), ENV_border_signs(P)) /: dom(VIS_detected_border_signs_front)
         & dist = dist_front(frnt, B1, ENV_border_signs(P))
         & dist >= 0 & dist <= VIS_max_detect_dist
      THEN
         VIS_detected_border_signs_front := VIS_detected_border_signs_front \/ {((B0,B1), ENV_border_signs(P)) |-> dist}
      END;
   // DetectWrongBorderSign: Either everywhere along the route or only actual Ra12 with wrong distance (+- from original position).
   
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
   VIS_SetDetectedStopsBack(new) = VIS_detected_stops_back := new;
   VIS_SetDetectedSigFront(new) = VIS_detected_sig_front := new;
   VIS_SetDetectedSigBack(new) = VIS_detected_sig_back := new;
   VIS_SetDetectedPointsFront(new) = VIS_detected_points_front := new;
   VIS_SetDetectedBorderSignsFront(new) = VIS_detected_border_signs_front := new
END