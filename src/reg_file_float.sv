// 32 registers of  32 bit each for floating point numbers
// 3 read ports and 1 write port
// f0 is always zero (though not enforced in RISC-V FP)

module reg_file_float (
    input clk,
    input rst,
    input [4:0] rd_addr1,
    input [4:0] rd_addr2,
    input [4:0] rd_addr3,
    input [4:0] wr_addr,
    input [31:0] wr_data,
    input wr_enable,
    output [31:0] rd_data1,
    output [31:0] rd_data2,
    output [31:0] rd_data3
);

logic [31:0] reg_file[31:0];

initial begin 
    for(int i=0;i<32;i++) begin
        reg_file[i]=32'b00000000000000000000000000000000;
    end
end

always_ff @(posedge clk) begin 
    if(rst) begin
        for(int i=0;i<32;i++) begin
            reg_file[i]<=32'b00000000000000000000000000000000;
        end
    end
    else if(wr_enable && wr_addr!=5'b0) begin
        reg_file[wr_addr]<=wr_data;
    end
end

assign rd_data1 = reg_file[rd_addr1];
assign rd_data2 = reg_file[rd_addr2];
assign rd_data3 = reg_file[rd_addr3];

endmodule