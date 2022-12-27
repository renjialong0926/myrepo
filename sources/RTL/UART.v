/*************************************************************/
//function: UART顶层模块
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2022.9.1
//Version : V 1.1
/*************************************************************/
`timescale 1 ns / 1 ps

module UART (clk,rst_n,tx_en,data_in,data_in_valid,data_in_ready,tx,rx_en,rx,data_out_ready,data_out,data_out_valid,check_flag);
input clk;                  /*系统时钟*/
input rst_n;                /*低电平异步复位信号*/
input tx_en;                /*发送模块使能信号,高电平有效*/
input [7:0] data_in;        /*来自信源的待发送数据*/
input data_in_valid;        /*待发送数据有效标志,高电平有效*/
output data_in_ready;       /*data_in_ready=1时,允许信源向发送模块传输新的待发送数据*/
output tx;                  /*FPGA端UART发送口*/

input rx_en;                /*接收模块使能信号,高电平有效*/
input rx;                   /*FPGA端UART接收口*/
input data_out_ready;       /*当后级模块可以接收data_out的数据时,data_in_ready为高*/
output [7:0] data_out;      /*输出UART接收到的数据*/
output data_out_valid;      /*输出数据有效标志,高电平有效*/
output check_flag;          /*校验标志位,当校验位存在且校验出错时check_flag被拉到高电平,data_out_valid也可作为check_flag的有效标志*/

/************************工作参数设置************************/
parameter system_clk=50_000000;    /*定义系统时钟频率*/
parameter band_rate=9600;          /*定义波特率*/
parameter data_bits=8;             /*定义数据位数,在5-8取值*/
parameter check_mode=1;            /*定义校验位类型——check_mode=0-无校验位,check_mode=1-偶校验位,check_mode=2-奇校验位,check_mode=3-固定0校验位,check_mode=4-固定1校验位*/
parameter stop_mode=0;             /*定义停止位类型——stop_mode=0——1位停止位,stop_mode=1——1.5位停止位,stop_mode=2——2位停止位*/
parameter fifo_deepth=16;          /*定义FIFO深度(2的n次方)*/
/************************************************************/

wire tx_clk_en,rx_clk_en;
wire tx_clk,rx_clk;
wire [7:0] tx_data,rx_data;
wire tx_data_valid,tx_data_ready,rx_data_valid,rx_data_ready;

baud_rate_clk #(.system_clk(system_clk),
                .band_rate(band_rate)
                ) U1(.clk(clk),
                     .rst_n(rst_n),
                     .tx_clk_en(tx_clk_en),
                     .rx_clk_en(rx_clk_en),
                     .tx_clk(tx_clk),
                     .rx_clk(rx_clk)
                     );
					 
data_fifo #(.Width(8),
            .Deepth(fifo_deepth)
            ) U_tx(.clk(clk),
                   .rst_n(rst_n),
                   .data_in(data_in),
                   .data_in_valid(data_in_valid),
                   .data_in_ready(data_in_ready),
                   .data_out(tx_data),
                   .data_out_valid(tx_data_valid),
                   .data_out_ready(tx_data_ready)
                   );
                 
uart_tx #(.system_clk(system_clk),
          .band_rate(band_rate),
          .data_bits(data_bits),
          .check_mode(check_mode),
          .stop_mode(stop_mode)
          ) U2(.clk(clk),
               .rst_n(rst_n),
               .tx_en(tx_en),
               .tx_clk(tx_clk),
               .data_in(tx_data),
               .data_in_valid(tx_data_valid),
               .data_in_ready(tx_data_ready),
               .tx(tx),
               .tx_clk_en(tx_clk_en)
               );	
			   
uart_rx #(.data_bits(data_bits),  
          .check_mode(check_mode)
          ) U3(.clk(clk),
               .rst_n(rst_n),
               .rx_en(rx_en),
               .rx_clk(rx_clk),
               .rx(rx),
               .data_out_ready(rx_data_ready),
               .data_out(rx_data),
               .data_out_valid(rx_data_valid),
               .rx_clk_en(rx_clk_en),
               .check_flag(check_flag)
               );

data_fifo #(.Width(8),
            .Deepth(16)
            ) U_rx(.clk(clk),
                   .rst_n(rst_n),
                   .data_in(rx_data),
                   .data_in_valid(rx_data_valid),
                   .data_in_ready(rx_data_ready),
                   .data_out(data_out),
                   .data_out_valid(data_out_valid),
                   .data_out_ready(data_out_ready)
                   );		   
endmodule