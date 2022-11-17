`define     rv32        32
`define     XLEN        32
`define     ADI0        `XLEN'h00000013
`define     Rst_INSR    32'h000000f8
module IF (

clk,
rst_n,
start,
Jump,
prdt_op1,
prdt_op2,
insr_mem,

PC,
mem_cs,
insr_dec
);
input                           clk;
input                           rst_n;
input                           start;          //上电后启动信号
input                           Jump;           //跳转信号
input       [`rv32-1:0]         prdt_op1;       //跳转指令地址计算操作数1
input       [`rv32-1:0]         prdt_op2;       //跳转指令地址计算操作数2
input       [`XLEN-1:0]         insr_mem;       //从mem中直接读取的32bits指令，可能需要拼接

output      [`rv32-1:0]         PC;             //输入给mem，取指地址索引
output                          mem_cs;         //指令mem读取使能信号
output      [`XLEN-1:0]         insr_dec;       //输入给后面译码模块的指令

reg         [`rv32-1:0]         PC_mem_r;       //即为PC
wire        [`rv32-1:0]         PC_mem;
wire        [`rv32-1:0]         PC_op1;
wire        [`rv32-1:0]         PC_op2;

reg         [15:0]              left;           //对于16 bits指令，用于保存余下的16 bits
wire        [15:0]              left_wire;

//---------------------------计算取指指令地址，输入给mem---------------------------
assign  PC_op1      = Jump ? prdt_op1 : PC_mem_r;
assign  PC_op2      = Jump ? prdt_op2 : 3'd4;
assign  PC_mem      = start ? `Rst_INSR : (Jump | mem_cs) ? (PC_op1 + PC_op2) : PC_mem_r;
assign  PC          = PC_mem_r;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        PC_mem_r    <= `rv32'd0;
    end
    else begin
        PC_mem_r    <= PC_mem;
    end
end

//-----------------------------计算每条指令的实际地址----------------------------------
wire        Restart     = Jump | start;         //表示每次重新取指信号
reg         Restart_d1, Restart_d2;             //对Restart信号延迟打拍，d1周期PC_mem_r
                                                //取到新地址，d2周期用于计算dec_rv32
wire        [6:0]               opcode_rv32;    //取每次指令的低7bits，用于译码指令长度
reg         [`rv32-1:0]         PC_insr_r;
wire        [`rv32-1:0]         PC_insr;
wire        [2:0]               PC_incr_ofst;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        Restart_d1  <= 1'b0;
        Restart_d2  <= 1'b0;
    end
    else begin
        Restart_d1  <= Restart;
        Restart_d2  <= Restart_d1;
    end
end

assign  opcode_rv32     = ~PC_insr_r[1] ? insr_mem[6:0] :  Restart_d2 ? insr_mem[22:16] 
                        : left[6:0];    
wire    dec_rv32        = (~(opcode_rv32[4:2] == 3'b111)) & (opcode_rv32[1:0] == 2'b11); 
assign  PC_incr_ofst    = dec_rv32 ? 3'd4 : 3'd2;    
wire    if_se           = Restart_d2 & PC_insr_r[1] & dec_rv32; //该指令需要两次取指拼接完成   
assign  PC_insr         = Restart_d1 ? PC_mem_r : if_se ? PC_insr_r : (PC_insr_r + PC_incr_ofst);
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        PC_insr_r   <= `rv32'd0;
    end
    else begin
        PC_insr_r   <= PC_insr;
    end
end

//-----------------mem_cs只有一种情况取零：非跳转时不对齐16bits指令--------------------
assign  mem_cs          = (~PC_insr_r[1]) | dec_rv32 | Restart_d2;

//------------------------left赋值，保留每次剩余的16bits指令--------------------------
assign  left_wire       = PC_insr[1] ? insr_mem[31:16] : 16'd0;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        left        <= 16'd0;
    end
    else begin
        left        <= left_wire;
    end
end

//------------------------insr_dec赋值，后面需要执行的指令-----------------------------
assign  insr_dec        = ~PC_insr_r[1] ? (dec_rv32 ? insr_mem[31:0] : {16'b0, insr_mem[15:0]}) 
                        : Restart_d2 ? (dec_rv32 ? `ADI0 : {16'b0, insr_mem[31:16]}) 
                        : (dec_rv32 ? {insr_mem[15:0], left[15:0]} : {16'b0, left[15:0]}); 



endmodule