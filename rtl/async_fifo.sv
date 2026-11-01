`timescale 1ns/1ps
module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);
    localparam int ADDR_WIDTH = $clog2(DEPTH);
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0] wbin;
    logic [PTR_WIDTH-1:0] wbin_next;

    logic [PTR_WIDTH-1:0] wgray;
    logic [PTR_WIDTH-1:0] wgray_next;

    logic [PTR_WIDTH-1:0] rbin;
    logic [PTR_WIDTH-1:0] rbin_next;

    logic [PTR_WIDTH-1:0] rgray;
    logic [PTR_WIDTH-1:0] rgray_next;

    logic [PTR_WIDTH-1:0] rgray_sync1;
    logic [PTR_WIDTH-1:0] rgray_sync2;

    logic [PTR_WIDTH-1:0] wgray_sync1;
    logic [PTR_WIDTH-1:0] wgray_sync2;

    logic full_next;
    logic empty_next;

    logic write_fire;
    logic read_fire;
    // ----------------------------


   function automatic logic [PTR_WIDTH-1:0] binary_to_gray(logic [PTR_WIDTH-1:0] bin);
    logic [PTR_WIDTH-1:0] gray;
    gray = bin ^ (bin >> 1);
    return gray;
    endfunction

    assign write_fire=wr_en&&!full;
    assign read_fire=rd_en&&!empty; 
 
    always_ff @(negedge rd_rst_n or posedge rd_clk)begin
    if(!rd_rst_n) 
    rd_data <= 0;
    else if (read_fire)begin
    rd_data<=mem[rbin[ADDR_WIDTH-1:0]];
    end
    end


assign    wbin_next=wbin+write_fire;
assign    wgray_next=binary_to_gray(wbin_next);


    always_ff @(negedge wr_rst_n or posedge wr_clk)begin
    if(!wr_rst_n) begin
    wbin<=0;
    wgray<=0;
 end
    else begin
    wbin<=wbin_next;
    wgray<=wgray_next;
    if(write_fire)
    mem[wbin[ADDR_WIDTH-1:0]]<=wr_data;
    end
    end


assign    rbin_next=rbin+read_fire;
assign    rgray_next=binary_to_gray(rbin_next);


    always_ff @(negedge rd_rst_n or posedge rd_clk)begin
    if(!rd_rst_n) begin
    rbin<=0;
    rgray<=0;
    end
    else begin
    rbin<=rbin_next;
    rgray<=rgray_next;
    end
    end


    always_ff @(posedge wr_clk or negedge wr_rst_n)begin
    if(!wr_rst_n)begin
    rgray_sync1<=0;
    rgray_sync2<=0; end
    else begin
    rgray_sync1<=rgray;
    rgray_sync2<=rgray_sync1;
    end
    end



    always_ff @(posedge rd_clk or negedge rd_rst_n)begin
    if(!rd_rst_n)begin
    wgray_sync1<=0;
    wgray_sync2<=0; end
    else begin
    wgray_sync1<=wgray;
    wgray_sync2<=wgray_sync1;
    end
    end

assign  empty_next=(rgray_next == wgray_sync2);

    always_ff @(posedge rd_clk or negedge rd_rst_n)begin
    if(!rd_rst_n)
    empty<=1; 
    else begin
    empty <= empty_next;
    end
    end

assign  full_next=(wgray_next =={~rgray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],rgray_sync2[PTR_WIDTH-3:0]});
 
    always_ff @(posedge wr_clk or negedge wr_rst_n)begin
    if(!wr_rst_n)
    full<=0; 
    else begin
    full<=full_next;    
    end
    end




endmodule
