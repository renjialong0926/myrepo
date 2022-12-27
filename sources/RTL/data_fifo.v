/*************************************************************/
//function: 16*8bit同步FIFO模块
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2022.9.2
//Version : V 1.1
/*************************************************************/
`timescale 1 ns / 1 ps

module data_fifo (clk,rst_n,data_in,data_in_valid,data_in_ready,data_out,data_out_valid,data_out_ready);
/************************工作参数设置************************/
parameter Width=8;               /*定义FIFO宽度*/
parameter Deepth=16;             /*定义FIFO深度(2的n次方)*/
/************************************************************/
input clk;                       /*系统时钟*/
input rst_n;                     /*低电平异步复位信号*/
input [Width-1:0] data_in;       /*输入数据*/
input data_in_valid;             /*输入数据有效标志,高电平有效*/
output data_in_ready ;           /*当FIFO未满时,data_in_ready为高电平,指示前级模块可向FIFO输入数据*/
output [Width-1:0] data_out;     /*输出数据*/
output reg data_out_valid;       /*输出数据有效标志,高电平有效*/
input data_out_ready;            /*当后级模块可以接收FIFO的数据输出时,data_out_ready为高电平*/


reg [Width-1:0] fifo_mem [Deepth-1:0];


/************************判断FIFO空满************************/
reg [$clog2(Deepth)-1:0] wr_addr; /*写指针*/
reg [$clog2(Deepth)-1:0] rd_addr; /*读指针*/
reg full;                         /*满标志信号*/
reg empty;                        /*空标志信号*/
wire wr_en;                       /*写使能信号*/
wire rd_en;                       /*读使能信号*/
wire [$clog2(Deepth)-1:0] wr_addr_next;
wire [$clog2(Deepth)-1:0] rd_addr_next;

assign wr_addr_next=wr_addr+1;
assign rd_addr_next=rd_addr+1;
assign data_in_ready=!full;                 /*FIFO未满时,允许前级模块向FIFO传输数据*/
assign wr_en=data_in_ready&&data_in_valid;  /*FIFO未满且前级产生有效输出时,FIFO发生写入行为*/
assign rd_en=(!empty)&&data_out_ready;      /*FIFO非空且后级模块可以接收FIFO的数据输出时,FIFO发生读出行为*/

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    full<=1'b0;/*初始情况下FIFO为空*/
  else
    begin
      if(wr_en&&(wr_addr_next==rd_addr))/*发生本次写入后,读写指针重合,代表FIFO满*/
        full<=1'b1;
      else if(full&&rd_en)/*FIFO满状态下进行了读出操作,导致FIFO脱离满状态*/
        full<=1'b0;
      else
        full<=full;
    end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    empty<=1'b1;/*初始情况下FIFO为空*/    
  else
    begin
      if(rd_en&&(rd_addr_next==wr_addr))/*发生本次读取后,读写指针重合,代表FIFO空*/
        empty<=1'b1;
      else if(empty&&wr_en)/*FIFO空状态下进行了写入操作,导致FIFO脱离空状态*/
        empty<=1'b0;
      else
        empty<=empty;
    end
end
/************************************************************/



/***********************向FIFO读写数据***********************/
reg [Width-1:0] data_out_reg;

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    wr_addr<=0;
  else
    begin
      if(wr_en)
        wr_addr<=wr_addr+1;
      else
        wr_addr<=wr_addr;
    end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    rd_addr<=0;
  else
    begin
      if(rd_en)
        rd_addr<=rd_addr+1;
      else
        rd_addr<=rd_addr;
    end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    data_out_valid<=1'b0;
  else
    begin
      if(rd_en)
        data_out_valid<=1'b1;
      else
        begin
          if(data_out_ready)
            data_out_valid<=1'b0;
          else
            data_out_valid<=data_out_valid;
        end
    end
end

always@(posedge clk)
begin
  if(wr_en)
    fifo_mem[wr_addr]<=data_in;
  else
    fifo_mem[wr_addr]<=fifo_mem[wr_addr];
end

always@(posedge clk)
begin
  if(rd_en)
    data_out_reg<=fifo_mem[rd_addr];
  else
    data_out_reg<=data_out_reg;
end

assign data_out=rst_n?data_out_reg:0;
/************************************************************/

endmodule