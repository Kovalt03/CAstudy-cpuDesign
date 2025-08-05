`define BP_NOTINITIALIZED   2'b00
`define BP_JUMP             2'b01
`define BP_BRANCH           2'b10
module BP (
    input         clk,
    input         rst,
    input         branch_taken,
    input [31:0]  pc,
    input [31:0]  upc,
    input [31:0]  update_target1,
    input [31:0]  update_target2,
    input         JR,
    input         Branch,
    input         Jump,

    output reg [31:0] predicted_target
);
    reg [23:0] btb_tag   [0:63];
    reg [31:0] btb_target[0:63];
    reg [1:0]  btb_valid [0:63];

    reg [1:0] pht[0:255];

    wire [5:0]  btb_idx;
    wire [7:0]  pht_idx;
    wire [23:0] tag;

    assign btb_idx = pc[7:2];
    assign tag = pc[31:8];
    assign pht_idx = pc[9:2];

    wire [5:0] ubtb_idx;
    wire [7:0]  upht_idx;
    wire [23:0] utag;

    assign ubtb_idx = upc[7:2];
    assign utag = upc[31:8];
    assign upht_idx = upc[9:2];

    always @(*) begin
        if(btb_valid[btb_idx] == `BP_JUMP && btb_tag[btb_idx] == tag)
            predicted_target = btb_target[btb_idx];
        else if (btb_valid[btb_idx] == `BP_BRANCH && btb_tag[btb_idx] == tag && pht[pht_idx] >= 2) begin
            predicted_target = btb_target[btb_idx];
        end else begin
            predicted_target = pc + 4;
        end
    end

    integer i;
    // Predictor state update
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 64; i = i + 1) begin
                btb_tag[i]    <= 24'hFFFFFF;
                btb_target[i] <= 32'd0;
                btb_valid[i]  <= `BP_NOTINITIALIZED;
            end
            for (i = 0; i < 256; i = i + 1) begin
                pht[i] <= 2'b01; // weakly not taken
            end
        end
    end

    always @(*) begin
        if(Branch || JR || Jump) begin
            btb_tag[ubtb_idx] <= utag;
            if(branch_taken) begin
                btb_target[ubtb_idx] <= update_target1;
            end else begin
                btb_target[ubtb_idx] <= update_target2;
            end

            if(JR || Jump) begin
                btb_valid[ubtb_idx] <= `BP_JUMP;
            end else if(Branch) begin
                btb_valid[ubtb_idx] <= `BP_BRANCH;

                case (branch_taken)
                    1'b1: if (pht[upht_idx] < 2'b11) pht[upht_idx] <= pht[upht_idx] + 1;
                    1'b0: if (pht[upht_idx] > 2'b00) pht[upht_idx] <= pht[upht_idx] - 1;
                endcase
            end
        end
    end

endmodule
