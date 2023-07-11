MACHINE Rangierfahrt_KI_Random_Topology
EXTENDS Rangierfahrt_KI
DEFINITIONS
    "definitions.def"; 
    CUSTOM_GRAPH_NODES == ENV_BLOCKS;
    CUSTOM_GRAPH_EDGES == ENV_TRK
CONSTANTS A, N, C, D, E, F, G, H, I, J, K, L, M, Wag1, Wag2, Pers1, Pers2, Pers3
PROPERTIES
    ENV_OBJECTS = {lok, Wag1, Wag2, Pers1, Pers2, Pers3} &
    card({lok, Wag1, Wag2, Pers1, Pers2, Pers3}) = 6 &
    
    ENV_BLOCKS = {A, N, C, D, E, F, G, H, I, J, K, L, M} &
    card({A, N, C, D, E, F, G, H, I, J, K, L, M}) = 13 &
    
    ENV_TRK = {A |-> N,  N |-> C, C |-> D, D |-> E, D |-> M, M |-> G, M |-> F, N |-> H, H |-> I, H |-> K, I |-> J, K |-> L} &
    
    ENV_DERAILERS = {I |-> J, K |-> L} &

    ENV_SIGNALS = {A |-> N, C |-> D} \/ ENV_DERAILERS \/ ENV_DERAILERS~ &

    ENV_POINTS = {N |-> (C, H), D |-> (E, M), M |-> (G, F), H |-> (I, K)} /*@desc First next block is straight branch (Wn1)*/&
    
    ENV_occ_init = {lok |-> A, Wag1 |-> L, Wag2 |-> G, Pers1 |-> E, Pers2 |-> J, Pers3 |-> J} &
    ENV_next_init =  {A |-> N,  N |-> C, C |-> D, D |-> E, M |-> G, H |-> I, I |-> J, K |-> L} &
    ENV_signals_init = {(A |-> N) |-> Sh0, (C |-> D) |-> Sh0} \/ (ENV_DERAILERS * {Wn7}) \/ (ENV_DERAILERS~ * {Wn7}) &
    ENV_points_init = ENV_POINTS * {Wn1} &
    ENV_border_signs = ENV_POINTS * {10} &

    ENV_block_length = {(A,70),(N,20),(C,300),(D,20),(E,100),(F,80),(G,60),(H,150),(I,30),(J,100),(K,30),(L,100),(M,20)} &
    ENV_object_length = {lok |-> 20, Wag1 |-> 25, Wag2 |-> 20} \/ {Pers1,Pers2,Pers3} * {1} &
    ENV_object_front_init = {lok |-> {A |-> ENV_object_length(lok)}, 
                        Wag1 |-> {L |-> 30 + ENV_object_length(Wag1)},
                        Wag2 |-> {G |-> 10 + ENV_object_length(Wag2)},
                        Pers1 |-> {E |-> 80 + ENV_object_length(Pers1)},
                        Pers2 |-> {J |-> 70 + ENV_object_length(Pers2)},
                        Pers3 |-> {J |-> 77 + ENV_object_length(Pers3)}} &
    ENV_object_back_init = {lok |-> {A |-> 0}, 
                        Wag1 |-> {L |-> 30},
                        Wag2 |-> {G |-> 10},
                        Pers1 |-> {E |-> 80},
                        Pers2 |-> {J |-> 70},
                        Pers3 |-> {J |-> 77}} &
    ENV_object_type = {Wag1,Wag2}*{wagon} \/ {Pers1,Pers2,Pers3}*{human} &

    ENV_stop_distances_front_init = {(N,ENV_block_length(A)-ENV_object_length(lok)) |-> signal_without_train_protect,
                                    (D,ENV_block_length(A)+ENV_block_length(N)+ENV_block_length(C)-ENV_object_length(lok)) |-> signal_without_train_protect,
                                    (L,ENV_block_length(A)+ENV_block_length(N)+ENV_block_length(C)+ENV_block_length(D)+ENV_block_length(M)+ENV_object_back_init(Wag1)(L)-ENV_object_length(lok)) |-> wagon,
                                    (G,ENV_block_length(A)+ENV_block_length(N)+ENV_block_length(H)+ENV_block_length(K)+ENV_object_back_init(Wag2)(G)-ENV_object_length(lok)) |-> wagon,
                                    (E,ENV_block_length(A)+ENV_block_length(N)+ENV_block_length(C)+ENV_block_length(D)+ENV_object_back_init(Pers1)(E)-ENV_object_length(lok)) |-> human,
                                    (J,ENV_block_length(A)+ENV_block_length(N)+ENV_block_length(H)+ENV_block_length(I)+ENV_object_back_init(Pers2)(J)-ENV_object_length(lok)) |-> human,
                                    (J,ENV_block_length(A)+ENV_block_length(N)+ENV_block_length(H)+ENV_block_length(I)+ENV_object_back_init(Pers3)(J)-ENV_object_length(lok)) |-> human} &
    ENV_stop_positions_front_init = {(N,0) |-> signal_without_train_protect, 
                        (D,0) |-> signal_without_train_protect,
                        (L,ENV_object_back_init(Wag1)(L)) |-> wagon,
                        (G,ENV_object_back_init(Wag2)(G)) |-> wagon,
                        (E,ENV_object_back_init(Pers1)(E)) |-> human,
                        (J,ENV_object_back_init(Pers2)(J)) |-> human,
                        (J,ENV_object_back_init(Pers3)(J)) |-> human} &
    ENV_stop_distances_back_init = {} &
    ENV_stop_positions_back_init = {} &

    VIS_max_detect_dist = 200
END