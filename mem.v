module mem 
#(
    parameter DP = 256,
    //parameter FORCE_X2ZERO = 0,
    parameter DW = 32,
    //parameter MW = 4,
    parameter AW = 32
)
(
    //指令读取接口
    input                  clk,
    input                  rst_n,
    input       [AW-1:0]   addr,
    input                  cs,
    output      [DW-1:0]   dout

);
reg [DW-1:0] mem_r [0:DP-1];
reg [AW-1:0] addr_r;
wire ren;

assign ren = cs;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        addr_r <= 32'd0;
    end    
    else if(ren) begin
        addr_r <= addr;
    end
end

assign dout = mem_r[addr_r];

endmodule