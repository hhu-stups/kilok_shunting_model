MACHINE Rangierfahrt_KI_1_1
EXTENDS Rangierfahrt_KI
DEFINITIONS
    "definitions.def";
    VISB_JSON_FILE == "visb_rangierfahrt.json";
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
    
    ENV_occ_init = {lok |-> B347a, C55 |-> B855b, Person |-> B855b} &
    ENV_next_init =  {B347a |-> B347b, B347b |-> B347c, 
                B855a |-> B855b} &
    ENV_signals_init = {(B347a |-> B855a) |-> Sh0, (B347a |-> B347b) |-> Sh0} \/ (ENV_DERAILERS * {Wn7}) \/ (ENV_DERAILERS~ * {Wn7}) &
    ENV_points_init = {(B347a |-> (B347b, B855a)) |-> Wn1} &
    ENV_border_signs = {(B347a |-> (B347b, B855a)) |-> 20} &

    ENV_block_length = ENV_BLOCKS * {100} &
    ENV_object_length = {lok |-> 30, C55 |-> 20, Person |-> 1} &
    ENV_object_front_init = {lok |-> {B347a |-> ENV_object_length(lok)}, 
                        C55 |-> {B855b |-> ENV_block_length(B855b)-1}, 
                        Person |-> {B855b |-> ENV_block_length(B855b)-ENV_object_length(C55)-2}} &
    ENV_object_back_init = {lok |-> {B347a |-> 0}, 
                        C55 |-> {B855b |-> ENV_block_length(B855b)-ENV_object_length(C55)-1}, 
                        Person |-> {B855b |-> ENV_block_length(B855b)-ENV_object_length(C55)-ENV_object_length(Person)-2}} &
    B855b : dom(ENV_object_back_init(C55)) & B855b : dom(ENV_object_back_init(Person)) & //for WD-POs
    ENV_object_type = {C55 |-> wagon, Person |-> human} &

    ENV_stop_distances_front_init = {(B347b,ENV_block_length(B347a)-ENV_object_length(lok)) |-> signal_without_train_protect} &
    ENV_stop_positions_front_init = {(B347b,0) |-> signal_without_train_protect, 
                        (B855a,0) |-> signal_without_train_protect,
                        (B855b,ENV_object_back_init(C55)(B855b)) |-> wagon, 
                        (B855b,ENV_object_back_init(Person)(B855b)) |-> human} &
    ENV_stop_distances_back_init = {} &
    ENV_stop_positions_back_init = {} &

    VIS_max_detect_dist = 200
END