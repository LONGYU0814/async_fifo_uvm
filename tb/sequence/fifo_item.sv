class fifo_item extends uvm_sequence_item;

    rand logic [DATA_WIDTH-1:0] data;

    // 0: normal transaction
    // 1: intentionally violate FULL/EMPTY protection
    bit force_illegal;


    `uvm_object_utils(fifo_item)


    function new(string name = "fifo_item");
        super.new(name);
    endfunction

endclass
