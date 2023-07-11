MACHINE Environment
SETS
   ENV_BLOCKS /*@desc "Blöcke" */;   
   ENV_OBJECTS /*@desc "Bewegliche Objekte, z.B. Lok, Personen und Waggons" */;
   //ENV_FIELD_ELEMENTS /*@desc "Static (valid) field elements, e.g. magnets, border signs" */;
   ENV_SIGNAL_STATES /*@desc "Signalzustände" */;
   ENV_POINT_STATES /*@desc "Weichenzustände" */;
   ENV_STOP_REASONS
   //ENV_POINTS /*@desc "Weichen" */  // not needed at the moment; points are inferred from ENV_TRK
CONSTANTS
   ENV_TRK /*@desc "Die Gleistopologie" */,
   lok /*@desc "Die Rangierlok" */,
   ENV_DERAILERS /*@desc "Gleissperren" */,
   ENV_SIGNALS  /*@desc "Signale" */,
   ENV_POINTS /*@desc "Weichen" */,
   ENV_next_init /*@desc "Anfangszustand der Gleistopologie" */,
   ENV_occ_init /*@desc "Anfangsbelegung" */,
   Sh0, Sh1, Wn7 /*@desc "Signalzustände" */,
   Wn1, Wn2, undef /*@desc "Weichenzustände" */,
   signal_with_train_protect, signal_without_train_protect, undef_point, derailer, brake_shoe, human, wagon /*@desc "Stoppgründe" */,
   ENV_signals_init /*@desc "Anfangszustände der Signale" */,
   ENV_points_init /*@desc "Anfangszustände der Weichen" */,
   ENV_block_length /*@desc "Länge der Blöcke" */,
   ENV_object_length /*@desc "Länge der Objekte" */,
   ENV_object_front_init /*@desc "Anfangspositionen der vorderen Objektenden" */,
   ENV_object_back_init /*@desc "Anfangspositionen der hinteren Objektenden" */,
   ENV_object_type /*@desc "Art eines Hindernisses" */,
   ENV_stop_distances_front_init /*@desc "Zwingende Stopppositionen auf aktueller Strecke zu Beginn (Vorwärtsrichtung; Distanz)" */,
   ENV_stop_positions_front_init /*@desc "Zwingende Stopppositionen zu Beginn (Vorwärtsrichtung; Position aus Block und Entfernung im Block)" */
PROPERTIES
   lok : ENV_OBJECTS &
   ENV_TRK: ENV_BLOCKS <-> ENV_BLOCKS &
   dom(ENV_TRK) \/ ran(ENV_TRK) = ENV_BLOCKS &
   ENV_TRK /\ ENV_TRK~ = {} /*@desc "anti-symmetrisch" */ &
   closure1(ENV_TRK) : FIN(closure1(ENV_TRK)) & // for WD-POs
   closure1(ENV_TRK~) : FIN(closure1(ENV_TRK~)) &

   ENV_next_init <: ENV_TRK & ENV_next_init: ENV_BLOCKS >+> ENV_BLOCKS &
   ENV_occ_init : ENV_OBJECTS --> ENV_BLOCKS &
   !(o,b1,b2).(o:ENV_OBJECTS & {b1,b2} <: ENV_occ_init[{o}] & b1|->b2 :ENV_TRK => b1|->b2:ENV_next_init) /*@desc "object not broken in two" */ &

   ENV_DERAILERS <: ENV_TRK &

   ENV_SIGNALS <: ENV_TRK \/ ENV_TRK~ &
   ENV_SIGNAL_STATES = {Sh0, Sh1, Wn7} &
   card(ENV_SIGNAL_STATES) = 3 &
   ENV_signals_init : ENV_SIGNALS --> ENV_SIGNAL_STATES &

   ENV_POINTS : ENV_BLOCKS <-> ENV_BLOCKS*ENV_BLOCKS &
   !(B1,B2,B3).(B1 : ENV_BLOCKS & {(B2,B3)} = ENV_POINTS[{B1}] & B2 /= B3 => B1 |-> B2 : ENV_TRK & B1 |-> B3 : ENV_TRK) &
   ENV_POINT_STATES = {Wn1, Wn2, undef} &
   card(ENV_POINT_STATES) = 3 &
   ENV_points_init : ENV_POINTS --> ENV_POINT_STATES &

   ENV_block_length : ENV_BLOCKS --> NATURAL &
   ENV_object_length : ENV_OBJECTS --> NATURAL &
   ENV_object_front_init : ENV_OBJECTS --> (ENV_BLOCKS +-> NATURAL) &
   ENV_object_back_init : ENV_OBJECTS --> (ENV_BLOCKS +-> NATURAL) &

   ENV_STOP_REASONS = {signal_with_train_protect, signal_without_train_protect, undef_point, derailer, brake_shoe, human, wagon} &
   card(ENV_STOP_REASONS) = 7 &
   ENV_stop_distances_front_init : (ENV_BLOCKS*INTEGER) <-> ENV_STOP_REASONS &
   ENV_stop_positions_front_init : (ENV_BLOCKS*NATURAL) <-> ENV_STOP_REASONS &
   
   ENV_object_type : ENV_OBJECTS - {lok} --> {human, wagon}
VARIABLES
   ENV_occ, ENV_next,
   ENV_active_derailers, ENV_signal_states, ENV_point_states, ENV_old_point_states,
   ENV_object_front, ENV_object_back,
   ENV_stop_distances_front,
   ENV_stop_positions_front,
   ENV_derailed, ENV_safety_critical
INVARIANT
   ENV_occ: ENV_OBJECTS <-> ENV_BLOCKS &
   dom(ENV_occ) = ENV_OBJECTS  /*@desc "Jedes bewegliche Objekt steht auf mindestens einem Block" */ &

   ENV_next <: ENV_TRK &
   ENV_next : ENV_BLOCKS >+> ENV_BLOCKS /*@desc "Jeder Block hat maximal einen (eindeutigen) Nachfolger und Vorgänger" */ &
   closure1(ENV_next) : FIN(closure1(ENV_next)) & // for WD-POs
   closure1(ENV_next~) : FIN(closure1(ENV_next~)) &

   !(o,b1,b2).(o:ENV_OBJECTS & {b1,b2} <: ENV_occ[{o}] & b1|->b2 :ENV_TRK => b1|->b2:ENV_next) /*@desc "object not broken in two / derailed" */ &
   ENV_active_derailers <: ENV_DERAILERS &
   !(b1,b2).(b1|->b2:ENV_active_derailers & lok|->b1:ENV_occ => lok|->b2 /:ENV_occ) /*@desc "Die Lok steht nicht auf einer Gleissperre" */ &

   ENV_signal_states : ENV_SIGNALS --> ENV_SIGNAL_STATES &
   !(s1,s2).(s1:ENV_SIGNALS & s2:ENV_SIGNALS & s1/=s2 & prj1(ENV_BLOCKS,ENV_BLOCKS)(s1)=prj1(ENV_BLOCKS,ENV_BLOCKS)(s2) => ENV_signal_states(s1) = ENV_signal_states(s2)) /*@desc "Signale an Abzweigungen haben denselben Zustand" */ &
   // Interlocking logic: !(s).(s : ENV_SIGNALS & ENV_signal_states(s)=Sh1 => ENV_occ~[{prj2(ENV_BLOCKS,ENV_BLOCKS)(s)}] = {}) /*@desc "Next block behind the signal is free" */ &
   !(s).(s : (ENV_SIGNALS /\ ENV_DERAILERS) & ENV_signal_states(s)=Wn7 => s /: ENV_active_derailers) /*@desc "Zum Signal Wn7 gehörende Gleissperre ist abgelegt" */ &

   !(B1,B2,B3).(B1 : dom(ENV_next) & {(B2,B3)} = ENV_POINTS[{B1}] & B2 /= B3 => (B1 |-> B2 : ENV_next or B1 |-> B3 : ENV_next)) &
   //!B.(B : dom(ENV_POINTS) => B : dom(ENV_next)) & // for WD-POs
   ENV_point_states : ENV_POINTS --> ENV_POINT_STATES &
   ENV_old_point_states : ENV_POINTS --> ENV_POINT_STATES &

   ENV_object_front : ENV_OBJECTS --> (ENV_BLOCKS +-> NATURAL) &
   ENV_object_back : ENV_OBJECTS --> (ENV_BLOCKS +-> NATURAL) &
   !(b,o).(b : ENV_BLOCKS & o : ENV_OBJECTS & back_of_object(o,b) => 0 <= ENV_object_back(o)(b) & ENV_object_back(o)(b) < ENV_block_length(b)) /*@desc "ENV_object_back ist für den hintersten Block größer gleich Null und kleiner als die Länge des Blocks" */ &
   //!(b,o).(b : ENV_BLOCKS & o : ENV_OBJECTS & front_of_object(o,b) => b : dom(ENV_object_front(o))) /*@desc "object_front of the frontmost block is part of the function" */ &
   //!(b,o).(b : ENV_BLOCKS & o : ENV_OBJECTS & back_of_object(o,b) => b : dom(ENV_object_back(o))) /*@desc "object_back of the rearmost block is part of the function" */ &
   !(b,o).(b : ENV_BLOCKS & o : ENV_OBJECTS & not(front_of_object(o,b)) => b /: dom(ENV_object_front(o)) & card(dom(ENV_object_front(o))) = 1) /*@desc "objekt_front belegter Blöcke (nicht vorderster) sind nicht Teil der Funktion" */ &
   !(b,o).(b : ENV_BLOCKS & o : ENV_OBJECTS & not(back_of_object(o,b)) => b /: dom(ENV_object_back(o)) & card(dom(ENV_object_back(o))) = 1) /*@desc "objekt_back belegter Blöcke (nicht hinterster) sind nicht Teil der Funktion" */ &
   !(b1,b2,o).(b1 : ENV_BLOCKS & b2 : ENV_BLOCKS & o : ENV_OBJECTS & back_of_object(o,b1) & front_of_object(o,b2) =>
              ENV_object_length(o) = IF b1 /= b2 THEN ENV_block_length(b1) ELSE 0 END - ENV_object_back(o)(b1)
                               + SIGMA(l,b).(b1 |-> b : closure1(ENV_next) & b |-> b2 : closure1(ENV_next) & l=ENV_block_length(b) | l)
                               + ENV_object_front(o)(b2)) /*@desc "Die Summe von objekt_front/_back und aller Längen belegter Blöcke, die nicht front oder back sind, entspricht der Objektlänge" */ &
   !(b,o).(b : ENV_BLOCKS & o : ENV_OBJECTS & b:dom(ENV_object_front(o)) 
        => ENV_object_front(o)(b) < ENV_block_length(b)) /*@desc Object kann keine höhere Position im Block haben, als dieser lang ist */&

   ENV_stop_distances_front : (ENV_BLOCKS*INTEGER) <-> ENV_STOP_REASONS &
   ENV_stop_distances_front : FIN(ENV_stop_distances_front) &
   ENV_stop_positions_front : (ENV_BLOCKS*NATURAL) <-> ENV_STOP_REASONS &
   ENV_stop_positions_front : FIN(ENV_stop_positions_front) &

   ENV_derailed : ENV_OBJECTS --> BOOL &
   ENV_safety_critical : BOOL
INITIALISATION
   ENV_occ := ENV_occ_init ||
   ENV_next := ENV_next_init ||
   ENV_active_derailers := {} ||
   ENV_signal_states := ENV_signals_init ||
   ENV_point_states := ENV_points_init ||
   ENV_old_point_states := ENV_points_init ||
   ENV_object_front := ENV_object_front_init ||
   ENV_object_back := ENV_object_back_init ||
   ENV_stop_distances_front := ENV_stop_distances_front_init ||
   ENV_stop_positions_front := ENV_stop_positions_front_init ||
   ENV_derailed := ENV_OBJECTS*{FALSE} ||
   ENV_safety_critical := FALSE
DEFINITIONS
   "definitions.def"
OPERATIONS
   ENV_StartMovePoint(Block,N1,N2) = 
      ANY
         frnt, back, dist
      WHERE 
         front_of_object(lok,frnt)
         & back_of_object(lok,back)
         & Block|->(N1,N2) : ENV_POINTS 
         /*& IF Block|->N1 : ENV_next & Block|->N1 : ENV_SIGNALS THEN ENV_signal_states(Block|->N1)=Sh0 ELSE 1=1 END
         & IF Block|->N2 : ENV_next & Block|->N2 : ENV_SIGNALS THEN ENV_signal_states(Block|->N2)=Sh0 ELSE 1=1 END*/
         & !o.(o:ENV_OBJECTS & o|->Block : ENV_occ => o|->N1 /: ENV_occ & o|->N2 /: ENV_occ) /*@desc "No Object derailed" */
         & {Wn1,Wn2} /\ ENV_point_states[{Block|->(N1,N2)}] /= {}
         & IF Block : closure(ENV_next)[{frnt}]
            THEN dist = dist_front(frnt,N1,0)
            ELSE dist = dist_back(back,Block,ENV_block_length(Block)-1)
           END
      THEN
         ENV_point_states(Block|->(N1,N2)) := undef ||
         ENV_old_point_states(Block|->(N1,N2)) := ENV_point_states(Block|->(N1,N2)) ||
         IF Block : dom(ENV_next) & Block : closure(ENV_next)[{frnt}]
            THEN ENV_stop_distances_front := ENV_stop_distances_front \/ {(ENV_next(Block),dist)}*{undef_point}
         END ||
         ENV_stop_positions_front := ENV_stop_positions_front \/ {(N1,0),(N2,0)}*{undef_point}
      END;
   ENV_EndMovePoint(Block,N1,N2) =
      ANY
         frnt, back, dist, new_ENV_next
      WHERE 
         front_of_object(lok,frnt)
         & back_of_object(lok,back)
         & Block|->(N1,N2) : ENV_POINTS 
         & ENV_point_states(Block|->(N1,N2)) = undef
         & ((ENV_old_point_states(Block|->(N1,N2)) = Wn1 & new_ENV_next = N2) or (ENV_old_point_states(Block|->(N1,N2)) = Wn2 & new_ENV_next = N1))
         & !o.(o:ENV_OBJECTS & o|->Block : ENV_occ => o|->N1 /: ENV_occ & o|->N2 /: ENV_occ) /*@desc "No Object derailed" */
         & IF Block : closure(ENV_next)[{frnt}]
            THEN dist = dist_front(frnt,N1,0)
            ELSE dist = dist_back(back,Block,ENV_block_length(Block)-1)
           END
      THEN
         ENV_next(Block) := new_ENV_next;
         IF ENV_old_point_states(Block|->(N1,N2)) = Wn1
            THEN ENV_point_states(Block|->(N1,N2)) := Wn2
            ELSE ENV_point_states(Block|->(N1,N2)) := Wn1
         END ||
         IF Block : closure(ENV_next)[{frnt}]
            THEN ENV_stop_distances_front := {j | #(block,d,r).((block,d,r):ENV_stop_positions_front 
                                             & block : closure(ENV_next)[{frnt}]
                                             & j = (block |-> dist_front(frnt,block,d) 
                                                      |-> r ))} // Stop distances for new branch only
                                          - {(N1,dist), (N2,dist)}*{undef_point}
         END ||
         ENV_stop_positions_front := ENV_stop_positions_front - {(N1,0),(N2,0)}*{undef_point}
      END;

   ENV_ActivateDerailer(B1,B2) = 
      ANY 
         frnt, back, dist
      WHERE 
         B1|->B2 : ENV_DERAILERS - ENV_active_derailers 
         & not(lok|->B1:ENV_occ & lok|->B2:ENV_occ)
         & front_of_object(lok,frnt)
         & back_of_object(lok,back)
         & IF B1 : closure(ENV_next)[{frnt}]
            THEN dist = dist_front(frnt,B2,0)
            ELSE dist = dist_back(back,B1,ENV_block_length(B1)-1)
           END
      THEN
         ENV_active_derailers := ENV_active_derailers \/ {B1|->B2} ||
         ENV_signal_states := ENV_signal_states <+ {(B1|->B2), (B2|->B1)}*{Sh0} ||
         IF B1 : closure(ENV_next)[{frnt}]
            THEN ENV_stop_distances_front := ENV_stop_distances_front \/ {(B2,dist) |-> derailer}
         END ||
         ENV_stop_positions_front := ENV_stop_positions_front \/ {(B2,0) |-> derailer}
      END;
   ENV_DeactivateDerailer(B1,B2) = 
      ANY
         frnt, back, dist
      WHERE 
         B1|->B2 : ENV_active_derailers
         & front_of_object(lok,frnt)
         & back_of_object(lok,back)
         & IF B1 : closure(ENV_next)[{frnt}]
            THEN dist = dist_front(frnt,B2,0)
            ELSE dist = dist_back(back,B1,ENV_block_length(B1)-1)
           END
      THEN
         ENV_active_derailers := ENV_active_derailers - {B1|->B2} ||
         ENV_signal_states := ENV_signal_states <+ {(B1|->B2), (B2|->B1)}*{Wn7} ||
         IF B1 : closure(ENV_next)[{frnt}]
            THEN ENV_stop_distances_front := ENV_stop_distances_front - {(B2,dist) |-> derailer}
         END ||
         ENV_stop_positions_front := ENV_stop_positions_front - {(B2,0) |-> derailer}
      END;

   ENV_SwitchSignalToSh0(B1,B2) =
      ANY 
         frnt, B3
      WHERE
         front_of_object(lok,frnt)
	      & B1 : closure(ENV_next)[{frnt}]
         & B1 |-> B2 : ENV_next /\ ENV_SIGNALS-ENV_DERAILERS
         & IF B1 : dom(ENV_POINTS) 
	            THEN (B1, (B2,B3)) : ENV_POINTS or (B1, (B3,B2)) : ENV_POINTS 
               ELSE B2 = B3
           END
         & !(s).(s:ENV_SIGNALS & prj1(ENV_BLOCKS,ENV_BLOCKS)(s)=B1 => ENV_signal_states(s)=Sh1)
      THEN
         ENV_signal_states(B1 |-> B2) := Sh0;
	      ENV_signal_states(B1 |-> B3) := Sh0 ||
         ENV_stop_distances_front := ENV_stop_distances_front \/ {(B2,dist_front(frnt,B2,0)) |-> signal_without_train_protect} ||
         ENV_stop_positions_front := ENV_stop_positions_front \/ {(B2,0),(B3,0)}*{signal_without_train_protect}
      END;
   ENV_SwitchSignalToSh1(B1,B2) = 
      ANY 
         frnt, B3
      WHERE
         front_of_object(lok,frnt)
	      & B1 : closure(ENV_next)[{frnt}]
         & B1 |-> B2 : ENV_next /\ ENV_SIGNALS-ENV_DERAILERS
         & IF B1 : dom(ENV_POINTS) 
	            THEN (B1, (B2,B3)) : ENV_POINTS or (B1, (B3,B2)) : ENV_POINTS 
               ELSE B2 = B3
           END
         & !(s).(s:ENV_SIGNALS & prj1(ENV_BLOCKS,ENV_BLOCKS)(s)=B1 => ENV_signal_states(s)=Sh0)
         // & ENV_occ~[{nxt}] = {} // rather interlocking logic
         // & !b.(B1 |-> b : dom(ENV_point_states) => ENV_point_states(B1 |-> b) /= undef)
      THEN
         ENV_signal_states(B1 |-> B2) := Sh1;
	      ENV_signal_states(B1 |-> B3) := Sh1 ||
         ENV_stop_distances_front := ENV_stop_distances_front 
                                    - {(B2,dist_front(frnt,B2,0)) |-> signal_without_train_protect} 
                                    - {(B3,dist_front(frnt,B3,0)) |-> signal_without_train_protect} ||
         ENV_stop_positions_front := ENV_stop_positions_front - {(B2,0),(B3,0)}*{signal_without_train_protect}
      END;
      
   ENV_SetOccupied(new_ENV_occ) = ENV_occ := new_ENV_occ;
   ENV_SetObjectFront(O,new_of) = ENV_object_front(O) := new_of;
   ENV_SetObjectFrontOfLokForBlock(B,new_of) = ENV_object_front(lok)(B) := new_of;
   ENV_SetObjectBack(O,new_ob) = ENV_object_back(O) := new_ob;
   ENV_SetObjectBackOfLokForBlock(B,new_ob) = ENV_object_back(lok)(B) := new_ob;
   ENV_SetStopDistancesFront(new_sd) = ENV_stop_distances_front := new_sd;
   ENV_SetSignalState(B1,B2,st) = ENV_signal_states(B1 |-> B2) := st;
   ENV_SetSafetyCritical(b) = ENV_safety_critical := b;
   ENV_SetDerailed(new_d) = ENV_derailed := new_d;
   ENV_SetDerailedForLok(new_d) = ENV_derailed(lok) := new_d
END