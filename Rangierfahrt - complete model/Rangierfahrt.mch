MACHINE Rangierfahrt
INCLUDES Environment
/*PROMOTES 
   ENV_StartMovePoint, ENV_EndMovePoint, 
   ENV_ActivateDerailer, ENV_DeactivateDerailer, 
   ENV_PlaceBrakeShoe_Front, ENV_RemoveBrakeShoe_Front,
   ENV_SwitchSignalToSh0, ENV_SwitchSignalToSh1*/
DEFINITIONS
   "definitions.def"
OPERATIONS
   RF_MoveLokForwards(frnt,nxt,back,new_front,new_back,dist) = 
      SELECT 
         ENV_derailed(lok) = FALSE
         & ENV_brakes_forced_front = FALSE
         & front_of_object(lok,frnt) & (frnt |-> nxt : ENV_next or (front_of_track(frnt) & nxt = frnt))
         & back_of_object(lok,back)
         & frnt |-> new_front : closure(ENV_next)
         & block_after_distance_forwards(frnt,ENV_object_front(lok)(frnt),dist,new_front)
         & block_after_distance_forwards(back,ENV_object_back(lok)(back),dist,new_back)
         & dist > 0
         & !(i1,i2,i3).((i1,i2,i3) : ENV_stop_distances_front & i2 - dist <= IF i3 = brake_shoe THEN 0 ELSE -10 END
               & i1 : closure(ENV_next~)[ENV_next[{frnt}] \/ {frnt}]
               & i3 : ENV_STOP_REASONS - {signal_without_train_protect}
               => dist <= i2)
      THEN
         IF ENV_block_length(frnt)-ENV_object_front(lok)(frnt) <= dist //Forward movement, current block is shorter than travel distance
            THEN
               ENV_SetOccupied(ENV_occ \/ {lok |-> new_back} \/ %(b).(new_back |-> b : closure1(ENV_next) & b |-> new_front : closure1(ENV_next) | lok )~ \/ {lok |-> new_front}) ||
               // Interlocking logic: IF frnt |-> nxt: ENV_SIGNALS-ENV_DERAILERS-ENV_DERAILERS~ THEN ENV_SetSignalState(frnt,nxt,Sh0) END ||
               ENV_SetObjectFront(lok, ({frnt} <<| ENV_object_front(lok)) \/ {new_front |-> position_in_new_block_forwards(frnt,ENV_object_front(lok)(frnt),dist,new_front)})
            ELSE ENV_SetObjectFrontOfLokForBlock(frnt, ENV_object_front(lok)(frnt)+dist) //Forward movement, current block is sufficient for travel distance
         END;

         IF ENV_object_back(lok)(back) + dist >= ENV_block_length(back) //Forward movement, move up blocks from behind
            THEN 
               ENV_SetOccupied(ENV_occ - {lok |-> back} - %(b).(back |-> b : closure1(ENV_next) & b |-> new_back : closure1(ENV_next) | lok )~) ||
               ENV_SetObjectBack(lok, ({back} <<| ENV_object_back(lok)) \/ {new_back |-> position_in_new_block_forwards(back,ENV_object_back(lok)(back),dist,new_back)})
            ELSE ENV_SetObjectBackOfLokForBlock(back, ENV_object_back(lok)(back)+dist) //Forward movement, rear block is sufficient
         END ||
         ENV_SetStopDistancesFront({j | #(i1,i2,i3).((i1,i2,i3) : ENV_stop_distances_front
                                    & j = (i1 |-> i2 - dist) |-> i3)}) ||
         ENV_SetStopDistancesBack({j | #(i1,i2,i3).((i1,i2,i3) : ENV_stop_distances_back
                                    & j = (i1 |-> i2 + dist) |-> i3)});
         IF
            stop_reason_passed_front(frnt, {signal_with_train_protect, brake_shoe})
         THEN
            ENV_SetBrakesForcedFront(TRUE)
         ELSIF
            stop_reason_passed_front(frnt, {undef_point, derailer})
         THEN
            ENV_SetDerailedForLok(TRUE) ||
            ENV_SetSafetyCritical(TRUE)
         ELSIF
            stop_reason_passed_front(frnt, {human, wagon})
         THEN
            ENV_SetDerailed(ENV_derailed <+ 
               { j | #(o,B).(o : dom(ENV_derailed)
                  & o /= lok 
                  & back_of_object(o,B)
                     // derail if on the same track
                  & ((dist_front(new_front,B,ENV_object_back(o)(B)) <= 0 & ENV_object_type(o) : ENV_stop_distances_front[{B|->dist_front(new_front,B,ENV_object_back(o)(B))}])
                     // derail if clearance gauge at point is violated
                     or (#(B0,B2).(((B0,(B,B2)):ENV_POINTS & ENV_object_back(o)(B) <= ENV_border_signs(B0,(B,B2)) 
                                    or ((B0,(B2,B)):ENV_POINTS & ENV_object_back(o)(B) <= ENV_border_signs(B0,(B2,B))) 
                                 & dist_front(new_front,B2,ENV_object_back(o)(B)) <= 0
                                 & ENV_object_type(o) : ENV_stop_distances_front[{B2|->dist_front(new_front,B2,ENV_object_back(o)(B))}])
                        ))
                     )
                  & j = o|->TRUE)});
            ENV_SetDerailedForLok(TRUE) ||
            ENV_SetSafetyCritical(TRUE)
         ELSIF
            stop_reason_passed_front(frnt, ENV_STOP_REASONS) or stop_reason_passed_back(back, ENV_STOP_REASONS)
         THEN
            ENV_SetSafetyCritical(TRUE)
         ELSE
            ENV_SetSafetyCritical(FALSE) ||
            ENV_SetBrakesForcedFront(FALSE) ||
            ENV_SetBrakesForcedBack(FALSE)
         END
      END;
   RF_MoveLokBackwards(frnt,prev,back,new_front,new_back,dist) =
      SELECT
         ENV_derailed(lok) = FALSE
         & ENV_brakes_forced_back = FALSE
         & front_of_object(lok,frnt)
         & back_of_object(lok,back) & (prev |-> back : ENV_TRK or (back_of_track(back) & prev = back))
         & (new_back |-> back : closure(ENV_next) 
            or 
            #(p1,p2).((p1,p2):ENV_POINTS & new_back|->p1 : closure(ENV_TRK)
               & p1|->back : closure(ENV_TRK)))
         & block_after_distance_backwards(back,ENV_object_back(lok)(back),dist,new_back) 
         & block_after_distance_backwards(frnt,ENV_object_front(lok)(frnt),dist,new_front) 
         & dist > 0
         & !(i1,i2,i3).((i1,i2,i3) : ENV_stop_distances_back & i2 - dist <= IF i3 = brake_shoe THEN 0 ELSE -10 END
               & i1 : closure(ENV_next)[ENV_next~[{frnt}] \/ {frnt}]
               & i3 : {signal_with_train_protect, brake_shoe, undef_point, derailer, human, wagon}
               => dist <= i2)
      THEN
         IF ENV_object_back(lok)(back) < dist //Backward movement, current block is shorter than travel distance
            THEN
               ENV_SetOccupied(ENV_occ \/ {lok |-> new_front} \/ %(b).(new_front |-> b : closure1(ENV_next~) & b |-> new_back : closure1(ENV_next~) | lok )~ \/ {lok |-> new_back}) ||
               // Interlocking logic: IF back |-> prev: ENV_SIGNALS-ENV_DERAILERS-ENV_DERAILERS~ THEN ENV_SetSignalState(back,prev,Sh0) END || // Case never occurs in the current model
               ENV_SetObjectBack(lok, ({back} <<| ENV_object_back(lok)) \/ {new_back |-> position_in_new_block_backwards(back,ENV_object_back(lok)(back),dist,new_back)})
         ELSE ENV_SetObjectBackOfLokForBlock(back, ENV_object_back(lok)(back)-dist) //Backward movement, rear block is sufficient
         END;
         IF ENV_object_front(lok)(frnt) < dist //Move up blocks from the front
            THEN
               ENV_SetOccupied(ENV_occ - {lok |-> frnt} - %(b).(frnt |-> b : closure1(ENV_next~) & b |-> new_front : closure1(ENV_next~) | lok )~) ||
               ENV_SetObjectFront(lok, ({frnt} <<| ENV_object_front(lok)) \/ {new_front |-> position_in_new_block_backwards(frnt,ENV_object_front(lok)(frnt),dist,new_front)})
            ELSE ENV_SetObjectFrontOfLokForBlock(frnt, ENV_object_front(lok)(frnt)-dist)
         END;
         ENV_SetStopDistancesFront({j | #(i1,i2,i3).((i1,i2,i3) : ENV_stop_distances_front
                                    & j = (i1 |-> i2 + dist) |-> i3)}) ||
         ENV_SetStopDistancesBack({j | #(i1,i2,i3).((i1,i2,i3) : ENV_stop_distances_back
                                    & j = (i1 |-> i2 - dist) |-> i3)});
         IF
            stop_reason_passed_back(back, {signal_with_train_protect, brake_shoe})
         THEN
            ENV_SetBrakesForcedFront(TRUE)
         ELSIF
            stop_reason_passed_back(back, {undef_point, derailer})
         THEN
            ENV_SetDerailedForLok(TRUE) ||
            ENV_SetSafetyCritical(TRUE)
         ELSIF
            stop_reason_passed_back(back, {human, wagon})
         THEN
            ENV_SetDerailed(ENV_derailed <+ 
               { j | #(i,o,B).(i:ENV_derailed 
                  & o = prj1(ENV_OBJECTS,BOOL)(i) 
                  & o /= lok & front_of_object(o,B)
                  & dist_front(new_back,B,ENV_object_front(o)(B)) <= 0 
                  & ENV_object_type(o) : ENV_stop_distances_front[{B|->dist_front(new_back,B,ENV_object_front(o)(B))}]
                  & j = o|->TRUE)});
            ENV_SetDerailedForLok(TRUE) ||
            ENV_SetSafetyCritical(TRUE)
         ELSIF
            stop_reason_passed_back(back, ENV_STOP_REASONS) or stop_reason_passed_front(frnt, ENV_STOP_REASONS)
         THEN
            ENV_SetSafetyCritical(TRUE)
         ELSE
            ENV_SetSafetyCritical(FALSE) ||
            ENV_SetBrakesForcedFront(FALSE) ||
            ENV_SetBrakesForcedBack(FALSE)
         END
      END
END