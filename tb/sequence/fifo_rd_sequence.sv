class fifo_rd_sequence extends uvm_sequence #(fifo_item);

    `uvm_object_utils(fifo_rd_sequence)

    int unsigned num_items = 20;

    bit force_illegal = 1'b0;


    function new(string name = "fifo_rd_sequence");
        super.new(name);
    endfunction


    virtual task body();

        fifo_item req;

        repeat (num_items) begin

            req = fifo_item::type_id::create("req");

            start_item(req);


            req.force_illegal = force_illegal;


            finish_item(req);


            `uvm_info(
                "RD_SEQ",
                $sformatf(
                    "Generate read request: illegal=%0b",
                    req.force_illegal
                ),
                UVM_MEDIUM
            )

        end

    endtask

endclass
