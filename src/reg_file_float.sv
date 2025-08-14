// 32 registers of  32 bit each for floating point numbers
// 2 read ports and 1 write port
// x0 is always zero 

module reg_file_float (
    input clk,
    input rst,
    input [4:0] rd_addr1,
    input [4:0] rd_addr2,
    input [4:0] wr_addr,
    input [31:0] wr_data,
    input wr_enable,
    output [31:0] rd_data1,
    output [31:0] rd_data2
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

assign rd_data1= (rd_addr1 == 5'b0) ? 32'b00000000000000000000000000000000 : reg_file[rd_addr1];
assign rd_data2=(rd_addr2==5'b0) ? 32'b00000000000000000000000000000000 : reg_file[rd_addr2] ;

endmodule