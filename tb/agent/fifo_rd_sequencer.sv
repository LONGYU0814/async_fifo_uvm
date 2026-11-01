class fifo_rd_sequencer extends uvm_sequencer #(fifo_item);

    `uvm_component_utils(fifo_rd_sequencer)

    function new(
        string name = "fifo_rd_sequencer",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

endclass
