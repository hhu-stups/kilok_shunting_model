MACHINE Rangierfahrt_KI_1_2b
EXTENDS Rangierfahrt_KI
DEFINITIONS
    "definitions.def";
    VISB_JSON_FILE == "visb_rangierfahrt_1_2.json";
    CUSTOM_GRAPH_NODES == ENV_BLOCKS;
    CUSTOM_GRAPH_EDGES == ENV_next
CONSTANTS B347a, B347b, B347c, B855a, B855b, C55, Person
PROPERTIES
    ENV_OBJECTS = {lok, C55, Person} &
    card({lok, C55, Person}) = 3 &
    
    ENV_BLOCKS = {B347a, B347b, B347c, B855a, B855b} &
    card({B347a, B347b, B855a, B855b, B347c}) = 5 &
    
    ENV_TRK = {B347a |-> B347b,  B347b |-> B347c, B347a |-> B855a, B855a |-> B855b} &
    
    ENV_DERAILERS = {B855a |-> B855b, B347b |-> B347c} &

    ENV_SIGNALS = {B347a |-> B855a, B347a |-> B347b} \/ ENV_DERAILERS \/ ENV_DERAILERS~ &

    ENV_POINTS = {B347a |-> (B347b, B855a)} /*@desc First next block is straight branch (Wn1)*/&
    
    ENV_occ_init = {lok |-> B347a, C55 |-> B347b, Person |-> B855a} &
    ENV_next_init =  {B347a |-> B855a, B347b |-> B347c, 
                B855a |-> B855b} &
    ENV_signals_init = {(B347a |-> B855a) |-> Sh0, (B347a |-> B347b) |-> Sh0} \/ (ENV_DERAILERS * {Wn7}) \/ (ENV_DERAILERS~ * {Wn7}) &
    ENV_points_init = {(B347a |-> (B347b, B855a)) |-> Wn2} &
    ENV_border_signs = {(B347a |-> (B347b, B855a)) |-> 20} &

    ENV_block_length = ENV_BLOCKS * {100} &
    ENV_object_length = {lok |-> 30, C55 |-> 20, Person |-> 1} &
    ENV_object_front_init = {lok |-> {B347a |-> ENV_object_length(lok)}, 
                        C55 |-> {B347b |-> ENV_border_signs(B347a |-> (B347b, B855a)) - 5 + ENV_object_length(C55)},
                        Person |-> {B855a |-> 50 + ENV_object_length(Person)}} &
    ENV_object_back_init = {lok |-> {B347a |-> 0},
                        C55 |-> {B347b |-> ENV_border_signs(B347a |-> (B347b, B855a)) - 5}, 
                        Person |-> {B855a |-> 50}} &
    ENV_object_type = {C55 |-> wagon, Person |-> human} &

    ENV_stop_distances_front_init = {(B855a,ENV_block_length(B855a)-ENV_object_length(lok)) |-> signal_without_train_protect,
                                    (B347b,ENV_block_length(B347a)+ENV_object_back_init(C55)(B347b)-ENV_object_length(lok)) |-> wagon,
                                    (B855a,ENV_block_length(B347a)+ENV_object_back_init(C55)(B347b)-ENV_object_length(lok)) |-> wagon} &
    ENV_stop_positions_front_init = {(B347b,0) |-> signal_without_train_protect, 
                        (B855a,0) |-> signal_without_train_protect,
                        (B347b,ENV_object_back_init(C55)(B347b)) |-> wagon,
                        (B855a,ENV_object_back_init(C55)(B347b)) |-> wagon,
                        (B855a,ENV_object_back_init(Person)(B855a)) |-> human} &
    ENV_stop_distances_back_init = {} &
    ENV_stop_positions_back_init = {} &

    VIS_max_detect_dist = 200
END