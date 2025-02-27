//****************************************Copyright (c)***********************************//
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           hdmi_top
// Last modified Date:  2025/1/15 9:30:00
// Last Version:        V1.1
// Descriptions:        DVI发送端顶层模块
//----------------------------------------------------------------------------------------
// Created by:          ZQL
// Created date:        2025/12/25 9:30:00
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  hdmi_top(
    input           pixel_clk,
    input           pixel_clk_5x,    
    input           sys_rst_n,
   //hdmi接口        
    output          tmds_clk_p,    // TMDS 时钟通道
    output          tmds_clk_n,
    output  [2:0]   tmds_data_p,   // TMDS 数据通道
    output  [2:0]   tmds_data_n,
   //用户接口 
    output          video_vs,       //HDMI场信号      
    output  [10:0]  h_disp,         //HDMI屏水平分辨率
    output  [10:0]  v_disp,         //HDMI屏垂直分辨率     
    output  [10:0]  pixel_xpos,     //像素点横坐标
    output  [10:0]  pixel_ypos,     //像素点纵坐标           
    input   [15:0]  data_in,        //CMOS传感器像素点数据
    output          data_req        //请求像素点颜色数据输入   
);

//wire define
wire          pixel_clk;
wire          pixel_clk_5x;
wire          clk_locked;
wire  [2:0]   tmds_data_p;   // TMDS 数据通道
wire  [2:0]   tmds_data_n;
wire  [10:0]  pixel_xpos;
wire  [10:0]  pixel_ypos;
wire  [15:0]  pixel_data_w;
wire  [10:0]  h_disp;
wire  [10:0]  v_disp;
wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;
wire  [15:0]  video_rgb_565;
//*****************************************************
//**                    main code
//*****************************************************

//将摄像头16bit数据转换为24bit的hdmi数据
assign video_rgb = {video_rgb_565[15:11],3'b000,video_rgb_565[10:5],2'b00,
                    video_rgb_565[4:0],3'b000};  

//例化视频显示驱动模块
video_driver u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb_565),
   
    .data_req       (data_req),
    .h_disp         (h_disp),
    .v_disp         (v_disp), 
    .pixel_xpos     (pixel_xpos),
    .pixel_ypos     (pixel_ypos),
    .pixel_data     (data_in)
    );   

//例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n),
                
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n), 
    .tmds_oen       ()
    );

endmodule 