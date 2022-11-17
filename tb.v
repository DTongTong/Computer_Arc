module tb (
);
reg                     clk, rst_n;
reg                     start;
wire    [31:0]          PC;
wire                    CS;
wire    [31:0]          insr_mem;
reg                     Jump;
reg     [31:0]          prdt_op1;
reg     [31:0]          prdt_op2;

initial begin
    rst_n = 1'b0;
    start = 1'b0;
    clk = 1'b1;

    Jump = 1'b0;
    prdt_op1 = 32'b0;
    prdt_op2 = 32'b0;
    #101
    rst_n = 1'b1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;
    #1300 //Jump test1:直接跳转到不对齐16bits指令地址处
    @(posedge clk);
    Jump = 1'b1;
    prdt_op1 = 32'h236;
    prdt_op2 = 32'b0;
    @(posedge clk);
    Jump = 1'b0;
    prdt_op1 = 32'b0;
    prdt_op2 = 32'b0;

    #500 //Jump test2:直接跳转到对齐16bits指令地址处
    @(posedge clk);
    Jump = 1'b1;
    prdt_op1 = 32'h54;
    prdt_op2 = 32'b0;
    @(posedge clk);
    Jump = 1'b0;
    prdt_op1 = 32'b0;
    prdt_op2 = 32'b0;

    #500 //Jump test3:直接跳转到不对齐32bits指令地址处
    @(posedge clk);
    Jump = 1'b1;
    prdt_op1 = 32'h3d6;
    prdt_op2 = 32'b0;
    @(posedge clk);
    Jump = 1'b0;
    prdt_op1 = 32'b0;
    prdt_op2 = 32'b0;

    #500 //Jump test4:直接跳转到对齐32bits指令地址处
    @(posedge clk);
    Jump = 1'b1;
    prdt_op1 = 32'h6014;
    prdt_op2 = 32'b0;
    @(posedge clk);
    Jump = 1'b0;
    prdt_op1 = 32'b0;
    prdt_op2 = 32'b0;
end

localparam clkT = 20;
always #(clkT/2) clk = ~clk;

IF IF_u(
    .clk                    (clk            ),
    .rst_n                  (rst_n          ),
    .start                  (start          ),
    .Jump                   (Jump           ),
    .prdt_op1               (prdt_op1       ),
    .prdt_op2               (prdt_op2       ),
    .insr_mem               (insr_mem       ),

    .PC                     (PC             ),
    .mem_cs                 (CS             ),
    .insr_dec               (               )    
);

mem # (
    .DP                     (32'd32769),
    .DW                     (32),
    .AW                     (32)
) mem_u (

    .clk                    (clk            ),
    .rst_n                  (rst_n          ),
    .addr                   ({2'b0, PC[31:2]}),
    .cs                     (CS             ),
    .dout                   (insr_mem       )

);

integer riscv_boot;
reg [31:0] instr;
integer i;
  //reg [31:0] mem_test [0:511];
  initial 
  begin
    riscv_boot = $fopen("E:\\RISCV_test_insr\\test_DFT","rb");
    //$readmemb("E:/RISC-V/assembler/bin.o",mem_test);
    for(i=0;i<32769;i=i+1)
      begin
        if ($fread(instr,riscv_boot))
           mem_u.mem_r[i] <= {instr[7:0],instr[15:8],instr[23:16],instr[31:24]};
        else
           mem_u.mem_r[i] <= 32'b0;
      end
    $fclose(riscv_boot);
  end
endmodule