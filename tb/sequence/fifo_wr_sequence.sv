class fifo_wr_sequence extends uvm_sequence #(fifo_item);

    `uvm_object_utils(fifo_wr_sequence)

    int unsigned num_items = 20;

    bit force_illegal = 1'b0;


    function new(string name = "fifo_wr_sequence");
        super.new(name);
    endfunction


    virtual task body();

        fifo_item req;

        repeat (num_items) begin

            req = fifo_item::type_id::create("req");

            start_item(req);


            if (!req.randomize()) begin

                `uvm_error(
                    "WR_SEQ",
                    "fifo_item randomize failed"
                )

            end


            req.force_illegal = force_illegal;


            finish_item(req);


            `uvm_info(
                "WR_SEQ",
                $sformatf(
                    "Generate write item: data=0x%0h illegal=%0b",
                    req.data,
                    req.force_illegal
                ),
                UVM_MEDIUM
            )

        end

    endtask

endclass
