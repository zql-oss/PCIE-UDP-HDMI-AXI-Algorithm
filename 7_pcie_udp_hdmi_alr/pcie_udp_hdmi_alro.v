module top_pcie_udp_hdmi_alro#(
  parameter PCIE_ENABLE           = 1                  ,//PCIE模块例化，0不例化，1例化
  parameter PROJECT_MODE          = 1                  ,//PROJECT_MODE 0:仿真；>=1：上板子；2：使用pcie
  parameter VIDEO_LENGTH          = 1920               ,
  parameter VIDEO_HIGTH           = 1080               ,
  parameter ZOOM_VIDEO_LENGTH     = 960                ,
  parameter ZOOM_VIDEO_HIGTH      = 540                ,
  parameter PIXEL_WIDTH           = 32                 ,    
  parameter MEM_ROW_ADDR_WIDTH    = 14                 ,
  parameter MEM_COL_ADDR_WIDTH    = 12                 ,
  parameter MEM_BADDR_WIDTH       = 3                  ,
  parameter MEM_DQ_WIDTH          = 32                 ,
  parameter MEM_DM_WIDTH          = MEM_DQ_WIDTH/8     ,
  parameter MEM_DQS_WIDTH         = MEM_DQ_WIDTH/8     ,
  parameter M_AXI_BRUST_LEN       = 8                  ,
  parameter RW_ADDR_MIN           = 20'b0              ,
  parameter RW_ADDR_MAX           = ZOOM_VIDEO_LENGTH*ZOOM_VIDEO_HIGTH*PIXEL_WIDTH/MEM_DQ_WIDTH   ,//@540p  518400个地址   
  parameter CTRL_ADDR_WIDTH       = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH -1  ,//29 [CTRL_ADDR_WIDTH:0]
  parameter IDELAY_VALUE          = 0                  ,
  parameter BOARD_MAC             = 48'h00_11_22_33_44_55       ,//开发板MAC地址 00-11-22-33-44-55
  parameter BOARD_IP              = {8'd192,8'd168,8'd1,8'd10}  ,//开发板IP地址 192.168.1.10
  parameter DES_MAC               = 48'h98_FA_9B_ED_09_D5       ,//目的MAC地址 98_FA_9B_ED_09_D5
  parameter DES_IP                = {8'd192,8'd168,8'd1,8'd20}   //目的IP地址 192.168.1.20
)
(    
    input                 sys_clk        ,  //系统时钟
    input                 sys_rst_n      ,  //系统复位，低电平有效
    //摄像头1接口                       
    input                 cam_pclk_1     ,  //cmos 数据像素时钟
    input                 cam_vsync_1    ,  //cmos 场同步信叿
    input                 cam_href_1     ,  //cmos 行同步信叿
    input   [7:0]         cam_data_1     ,  //cmos 数据
    output                cam_rst_n_1    ,  //cmos 复位信号，低电平有效
    output                cam_pwdn_1 ,      //电源休眠模式选择 0：正常模弿 1：电源休眠模弿
    output                cam_scl_1      ,  //cmos SCCB_SCL线
    inout                 cam_sda_1      ,  //cmos SCCB_SDA线
    //摄像头2接口     
    input                 cam_pclk_2     ,  //cmos 数据像素时钟
    input                 cam_vsync_2    ,  //cmos 场同步信叿
    input                 cam_href_2     ,  //cmos 行同步信叿
    input   [7:0]         cam_data_2     ,  //cmos 数据
    output                cam_rst_n_2    ,  //cmos 复位信号，低电平有效
    output                cam_pwdn_2     ,  //电源休眠模式选择 0：正常模弿 1：电源休眠模弿
    output                cam_scl_2      ,  //cmos SCCB_SCL线
    inout                 cam_sda_2      ,  //cmos SCCB_SDA线   
    //DDR3                            
    inout   [31:0]        ddr3_dq        ,   //ddr3 数据
    inout   [3:0]         ddr3_dqs_n     ,   //ddr3 dqs贿
    inout   [3:0]         ddr3_dqs_p     ,   //ddr3 dqs歿  
    output  [13:0]        ddr3_addr      ,   //ddr3 地址   
    output  [2:0]         ddr3_ba        ,   //ddr3 banck 选择
    output                ddr3_ras_n     ,   //ddr3 行鿉择
    output                ddr3_cas_n     ,   //ddr3 列鿉择
    output                ddr3_we_n      ,   //ddr3 读写选择
    output                ddr3_reset_n   ,   //ddr3 复位
    output  [0:0]         ddr3_ck_p      ,   //ddr3 时钟歿
    output  [0:0]         ddr3_ck_n      ,   //ddr3 时钟贿
    output  [0:0]         ddr3_cke       ,   //ddr3 时钟使能
    output  [0:0]         ddr3_cs_n      ,   //ddr3 片鿿
    output  [3:0]         ddr3_dm        ,   //ddr3_dm
    output  [0:0]         ddr3_odt       ,   //ddr3_odt  
    //eth                          
    input                 eth_rxc        , 
    input                 eth_rx_ctl     , 
    input   [3:0]         eth_rxd        , 
    output                eth_txc        , 
    output                eth_tx_ctl     , 
    output  [3:0]         eth_txd        , 
    output                eth_rst_n      ,  
    //pcie        
    input   [1:0]	      pcie_mgt_rxn   ,
    input   [1:0]	      pcie_mgt_rxp   ,
    output  [1:0]	      pcie_mgt_txn   ,
    output  [1:0]	      pcie_mgt_txp   ,
    input   [0:0]	      pcie_ref_clk_n ,
    input   [0:0]	      pcie_ref_clk_p ,
    input  			      pcie_rst_n     ,
    //hdmi in
    input                 hdmi_clk_in    ,
    input                 hdmi_de_in     ,
    input                 hdmi_vs_in     ,
    input                 hdmi_hs_in     ,        
    input   [23:0]        hdmi_data_in   ,
    output                hdmi_rst_n_out ,  
    output                hdmi_scl       , 
    inout                 hdmi_sda       , 
    //hdmi out                          
    output                tmds_clk_p     ,  // TMDS 时钟通道
    output                tmds_clk_n     ,
    output  [2:0]         tmds_data_p    ,  // TMDS 数据通道
    output  [2:0]         tmds_data_n    
    );  
    //ov5640分辨率配置
    parameter  V_CMOS_DISP    = 11'd540;                  //CMOS分辨率 540p
    parameter  H_CMOS_DISP    = 11'd960;                  	
    parameter  TOTAL_H_PIXEL  = H_CMOS_DISP + 12'd1216; //CMOS总分辨率
    parameter  TOTAL_V_PIXEL  = V_CMOS_DISP + 12'd504;      
    //待时钟锁定后产生复位结束信号
    assign  rst_n = sys_rst_n & locked;  
    //系统初始化完成：DDR3初始化完房
    assign  sys_init_done = ddr_init_done;

    assign  hdmi_rst_n_out = 1'b1;
    //wire reg  assign
    /********************* 例化子模块所需的内部信号定义 *********************/
    //------------------ 时钟/复位/锁定信号 ------------------//
    wire        locked;             // clk_wiz_0 输出的时钟锁定信号
    wire        ddr_init_done;      // MIG输出的DDR初始化完成信号
    wire        ui_clk;             // MIG输出的AXI用户时钟
    wire        ui_rst;             // MIG输出的AXI用户复位 (同步低有效)
    
    //------------------ DDR AXI总线信号 ------------------//
    // 写地址通道
    wire [3:0]  M_AXI_AWID;
    wire [28:0] M_AXI_AWADDR;
    wire [7:0]  M_AXI_AWLEN;
    wire [2:0]  M_AXI_AWSIZE;
    wire [1:0]  M_AXI_AWBURST;
    wire [0:0]  M_AXI_AWLOCK;
    wire [3:0]  M_AXI_AWCACHE;
    wire [2:0]  M_AXI_AWPROT;
    wire [3:0]  M_AXI_AWQOS;
    wire        M_AXI_AWVALID;
    wire        M_AXI_AWREADY;
    
    // 写数据通道
    wire [31:0] M_AXI_WDATA;
    wire [3:0]  M_AXI_WSTRB;
    wire        M_AXI_WLAST;
    wire        M_AXI_WVALID;
    wire        M_AXI_WREADY;
    
    // 写响应通道
    wire [3:0]  M_AXI_BID;
    wire [1:0]  M_AXI_BRESP;
    wire        M_AXI_BVALID;
    wire        M_AXI_BREADY;
    
    // 读地址通道
    wire [3:0]  M_AXI_ARID;
    wire [28:0] M_AXI_ARADDR;
    wire [7:0]  M_AXI_ARLEN;
    wire [2:0]  M_AXI_ARSIZE;
    wire [1:0]  M_AXI_ARBURST;
    wire [0:0]  M_AXI_ARLOCK;
    wire [3:0]  M_AXI_ARCACHE;
    wire [2:0]  M_AXI_ARPROT;
    wire [3:0]  M_AXI_ARQOS;
    wire        M_AXI_ARVALID;
    wire        M_AXI_ARREADY;
    
    // 读数据通道
    wire [3:0]  M_AXI_RID;
    wire [31:0] M_AXI_RDATA;
    wire [1:0]  M_AXI_RRESP;
    wire        M_AXI_RLAST;
    wire        M_AXI_RVALID;
    wire        M_AXI_RREADY;
    
    //------------------ AXI_M模块内视频信号 ------------------//
    wire [31:0] video0_data_out;
    wire [31:0] video1_data_out;
    wire [31:0] video2_data_out;
    wire [31:0] video3_data_out;
    wire        fram0_done;
    wire        fram1_done;
    wire        fram2_done;
    wire        fram3_done;
    wire [11:0] x_act;
    wire [11:0] y_act;
    
    //------------------ CMOS1/CMOS2采集数据 ------------------//
    wire                 cmos_frame_vsync_1;
    wire                 cmos_frame_href_1;
    wire                 cmos_frame_valid_1;
    wire [15:0]          cmos_frame_data_1;
    wire                 cmos_frame_vsync_2;
    wire                 cmos_frame_href_2;
    wire                 cmos_frame_valid_2;
    wire [15:0]          cmos_frame_data_2;
    
    //------------------ 以太网输入数据 ------------------//
    wire         eth0_rx_de;        //从 eth_img_rec 输出
    wire [15:0]  eth0_rx_data;      //从 eth_img_rec 输出
    wire         eth0_rx_vs;        //从 eth_img_rec 输出
    
    //------------------ GMII/RGMII信号 ------------------//
    wire        gmii_rx_clk;
    wire        gmii_rx_dv;
    wire [7:0]  gmii_rxd;
    wire        gmii_tx_clk;
    wire        gmii_tx_en;
    wire [7:0]  gmii_txd;
    
    //------------------ UDP相关 ------------------//
    wire [31:0] rec_data;
    wire        rec_en;
    wire [15:0] rec_byte_num;
    wire        rec_pkt_done;
    wire        tx_req;
    wire [31:0] tx_data;
    wire [15:0] tx_byte_num;
    wire        tx_start_en;
    wire        udp_tx_done;
    
    //------------------ PCIE AXI-Stream --------------//
    wire        pcie_axi_clk;       // XDMA或DMA Bridge输出的 AXI 时钟
    wire        pcie_axi_resetn;    // 对应的复位信号
    wire [63:0] s_axis_tdata_0;     // axi_stream_packer 输出
    wire        s_axis_tvalid_0;
    wire        s_axis_tlast_0;
    wire        s_axis_tready_0;
    
    //------------------ HDMI输出时序控制用寄存器 ---------//
    reg  r_vs_out;  
    reg  r_hs_out;  
    reg  r_de_out;  
    reg  [7:0] r_r_out; 
    reg  [7:0] r_g_out; 
    reg  [7:0] r_b_out; 
    
    reg  vs_out_d0, vs_out_d1;
    reg  r_de_out_d0;
    reg  v_sync_flag;
    
    //------------------ 多路FIFO读使能 --------------//
    reg  video0_rd_en;
    reg  video1_rd_en;
    reg  video2_rd_en;
    reg  video3_rd_en;
    reg  video_pre_rd_flag;
    reg  [2:0] out_state;
    
    //------------------ 坐标相关 --------------//
    reg  [11:0] r_x_act_d0;
  
    //输出时序稳定与仲裁预读
    //将传输后的信号进行输出
    always @(posedge pix_clk_out) begin
        if(ui_rst) begin
            r_vs_out <= 'd0;
            r_hs_out <= 'd0;
            r_de_out <= 'd0;
            r_r_out  <= 'd0;
            r_g_out  <= 'd0;
            r_b_out  <= 'd0;
            v_sync_flag <= 'd0;
            video0_rd_en <= 1'b0; 
            video1_rd_en <= 1'b0; 
            video2_rd_en <= 1'b0; 
            video3_rd_en <= 1'b0; 
            video_pre_rd_flag <= 1'b0;
            
            out_state <= 'd0;
        end 
        else if(ddr_init_done) begin 
            r_vs_out_d0 <= vs_out;
            r_vs_out    <= r_vs_out_d0;
            r_hs_out <= hs_out;
            r_de_out_d0 <= de_out;
            r_de_out <= r_de_out_d0;
            //r_de_out <= de_out;
    
            r_x_act_d0 <= x_act;//X轴坐标随着多打+一拍
            r_x_act <= r_x_act_d0;
    
           if(vs_out_d0 && !vs_out_d1) begin
                video_pre_rd_flag <= 'd0;
           end  //新的一帧需要提前读取数据，因为fifo会被清空
           else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done || fram1_done || fram2_done || fram3_done)) begin
                video0_rd_en      <= 'd1;
                video1_rd_en      <= 'd1;
                video2_rd_en      <= 'd1;
                video3_rd_en      <= 'd1;
                video_pre_rd_flag <= 'd1;
                out_state         <= 'd1;
           end
           else begin
               if( fram0_done && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act < ZOOM_VIDEO_HIGTH ) && (y_act >= 0)) begin//左上角
                    //test
                    //test_out <=  video0_data_out;
                    r_r_out  <=  video0_data_out[31:24];//高8位   video0_data_out是{r_r_out,2'b0,r_g_out,2'b0,r_b_out,4'b0}
                    r_g_out  <=  video0_data_out[21:14];
                    r_b_out  <=  video0_data_out[11: 4];  
                    video0_rd_en <= de_out; //预读出
                    video1_rd_en <= 'd0; 
                    video2_rd_en <= 'd0; 
                    video3_rd_en <= 'd0; //'d0; 
                    out_state    <= 'd2;
                    if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                        video1_rd_en <= de_out;
                        video0_rd_en <= 'd0;
                    end
                end
                if(fram1_done &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act < ZOOM_VIDEO_HIGTH )&& (y_act >= 0)) begin//实际上是r_x_act 0~63
                    //r_r_out  <= video1_data_out[31:24] ; 
                    //r_g_out  <='d0 ; 
                    //r_b_out  <='d0 ;
                    //test
                    //test_out <=  video1_data_out; 
                    r_r_out  <= video1_data_out[31:24];
                    r_g_out  <= video1_data_out[21:14];
                    r_b_out  <= video1_data_out[11: 4];
                    //r_r_out  <= {video1_data_out[15 : 11],3'b0};
                    //r_g_out  <= {video1_data_out[10 :  5],2'b0};
                    //r_b_out  <= {video1_data_out[4  :  0],3'b0}; 
                    //
                    //r_r_out  <= 'hff;
                    //r_g_out  <= 'd00;
                    //r_b_out  <= 'd00;
                    video0_rd_en <= 'd0; 
                    video1_rd_en <= de_out; 
                    video2_rd_en <= 'd0; 
                    video3_rd_en <= 'd0; 
                    out_state    <= 'd3;
    
                end  
                if( fram2_done &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act < VIDEO_HIGTH )&& (y_act >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                    //r_r_out  <='d0 ; 
                    //r_g_out  <= video2_data_out[21:14] ; 
                    //r_b_out  <='d0 ; 
                    //test
                    //test_out <=  video2_data_out;
                    r_r_out  <= video2_data_out[31:24] ;
                    r_g_out  <= video2_data_out[21:14] ;
                    r_b_out  <= video2_data_out[11: 4] ;  
                    video0_rd_en <= 'd0; 
                    video1_rd_en <= 'd0; 
                    video2_rd_en <= de_out; 
                    video3_rd_en <= 'd0; 
                    out_state    <= 'd4;
                    if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                        video3_rd_en <= de_out;
                        video2_rd_en <= 'd0;
                    end
                end    
                if(fram3_done &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act < VIDEO_HIGTH )&& (y_act >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                    //r_r_out  <='d0 ; 
                    //r_g_out  <='d0 ; 
                    //r_b_out  <=video3_data_out[11:4] ;
                    //test
                    //test_out <=  video3_data_out;
                    r_r_out  <= video3_data_out[31:24];
                    r_g_out  <= video3_data_out[21:14];
                    r_b_out  <= video3_data_out[11: 4];     
                    video0_rd_en <= 'd0; 
                    video1_rd_en <= 'd0; 
                    video2_rd_en <= 'd0; 
                    video3_rd_en <= de_out; 
                    
                    out_state    <= 'd5;
                end 
            end         
        end
        else begin
            r_vs_out <= 'd0;
            r_hs_out <= 'd0;
            r_de_out <= 'd0;
            r_r_out  <= 8'hff ;
            r_g_out  <= 8'h00 ;
            r_b_out  <= 8'h00 ;
            video0_rd_en <= 1'b0; 
            video1_rd_en <= 1'b0; 
            video2_rd_en <= 1'b0; 
            video3_rd_en <= 1'b0; 
            out_state    <= 'd7; 
        end            
    end
    //时钟生成模块
    clk_wiz_0 u_clk_wiz_0
    (
     // Clock out ports
     .clk_out1              (clk_200m     ),     
     .clk_out2              (clk_50m      ),
     .clk_out3              (pix_clk_out_5),
     .clk_out4              (pix_clk_out  ),
     // Status and control signals
     .reset                 (1'b0         ), 
     .locked                (locked       ),       
    // Clock in ports
     .clk_in1               (sys_clk      )
     );    
     
    //hdmi_in 寄存器配置
    i2c_ctrl u_i2c_ctrl(
    .ADV_CLK   (clk_50m      ),
    .ADV_RST   (sys_init_done),//低电平复位
    .ADV_SCLK  (hdmi_scl     ),
    .ADV_SDAT  (hdmi_sda     ),
    .init_done (             )
    );
    //hdmi_out
    video_driver video_driver_inst(
    .pixel_clk  (pix_clk_out          ),
    .sys_rst_n  (sys_init_done & rst_n),

    .video_hs   (hs_out               ),//延迟两拍输出给hdmi显示引脚
    .video_vs   (vs_out               ),
    .video_de   (de_out               ),
    .video_rgb  (),//output [15:0] 

    .pixel_data (),//input
    .pixel_xpos (x_act                ),
    .pixel_ypos (y_act                ),
    .h_disp     (),
    .v_disp     (),
    .data_req   () 
    );
    dvi_transmitter_top dvi_transmitter_top_inst(
    .pclk       (pix_clk_out          ),
    .pclk_x5    (pix_clk_out_5        ),
    .reset_n    (sys_init_done & rst_n),

    .video_din  ({r_r_out[7:0],r_g_out[7:0],r_b_out[7:0]}),//[23:0]
    .video_hsync(r_hs_out),
    .video_vsync(r_vs_out),
    .video_de   (r_de_out),

    .tmds_clk_p (tmds_clk_p),
    .tmds_clk_n (tmds_clk_n),
    .tmds_data_p(tmds_data_p),
    .tmds_data_n(tmds_data_n),
    .tmds_oen   ()
    );
    //ov5640 驱动1
    ov5640_dri u_ov5640_dri_1(
        .clk               (clk_50m),
        .rst_n             (rst_n),
    
        .cam_pclk          (cam_pclk_1),
        .cam_vsync         (cam_vsync_1),
        .cam_href          (cam_href_1 ),
        .cam_data          (cam_data_1 ),
        .cam_rst_n         (cam_rst_n_1),
        .cam_pwdn          (cam_pwdn_1),
        .cam_scl           (cam_scl_1  ),
        .cam_sda           (cam_sda_1  ),
        
        .capture_start     (ddr_init_done),
        .cmos_h_pixel      (H_CMOS_DISP),
        .cmos_v_pixel      (V_CMOS_DISP),
        .total_h_pixel     (TOTAL_H_PIXEL),
        .total_v_pixel     (TOTAL_V_PIXEL),
        .cmos_frame_vsync  (cmos_frame_vsync_1),
        .cmos_frame_href   (cmos_frame_href_1),
        .cmos_frame_valid  (cmos_frame_valid_1),
        .cmos_frame_data   (cmos_frame_data_1)
        );   
 
    //ov5640 驱动2
    ov5640_dri u_ov5640_dri_2(
        .clk               (clk_50m),
        .rst_n             (rst_n),
    
        .cam_pclk          (cam_pclk_2 ),
        .cam_vsync         (cam_vsync_2),
        .cam_href          (cam_href_2 ),
        .cam_data          (cam_data_2),
        .cam_rst_n         (cam_rst_n_2),
        .cam_pwdn          (cam_pwdn_2 ),
        .cam_scl           (cam_scl_2  ),
        .cam_sda           (cam_sda_2 ),
        
        .capture_start     (ddr_init_done),
        .cmos_h_pixel      (H_CMOS_DISP),
        .cmos_v_pixel      (V_CMOS_DISP),
        .total_h_pixel     (TOTAL_H_PIXEL),
        .total_v_pixel     (TOTAL_V_PIXEL),
        .cmos_frame_vsync  (cmos_frame_vsync_2),
        .cmos_frame_href   (cmos_frame_href_2),
        .cmos_frame_valid  (cmos_frame_valid_2),
        .cmos_frame_data   (cmos_frame_data_2)
        );  
       
    //对hdmi_in 1080p压缩至540p
    video_zoom hdmi_video_zoom(
    .clk                (hdmi_clk_in),
    .rstn               (~ui_rst && ddr_init_done     ),
    .vs_in              (hdmi_vs_in                   ),
    .hs_in              (hdmi_hs_in                   ),
    .de_in              (hdmi_de_in                   ),
    .video_data_in      ({hdmi_data_in[23:16],2'b0,hdmi_data_in[15:8],2'b0,hdmi_data_in[7:0],4'b0}),//[31:0]
    .de_out             (zoom_de_out                  ),
    .video_data_out     (zoom_data_out                )
    );
    //axi_ctrl 模块
    //顺序：hdmi_in r[7:0]  g[7:0]  b[7:0] ----> 拼成rgb[31:0] = {r[7:0],2'b0,g[7:0],2'b0,b[7:0],4'b0}输入进video_zoom模块，压缩后的数据输入进fifo。输出到video_enhance模块同时重新分解成r[7:0]  g[7:0]  b[7:0]
    //初始化顺序：DDR->AXI_M & FIFO ->IIC PLL -HDMI
    axi_m_arbitration #(
        .VIDEO_LENGTH     (VIDEO_LENGTH)                    ,
        .VIDEO_HIGTH      (VIDEO_HIGTH)                     ,
        .ZOOM_VIDEO_LENGTH(ZOOM_VIDEO_LENGTH )              ,
        .ZOOM_VIDEO_HIGTH (ZOOM_VIDEO_HIGTH )               ,
        .PIXEL_WIDTH      (PIXEL_WIDTH  )                   ,
    	.CTRL_ADDR_WIDTH  (CTRL_ADDR_WIDTH  )               ,
    	.DQ_WIDTH	      (DQ_WIDTH  )                       ,
        .M_AXI_BRUST_LEN  (M_AXI_BRUST_LEN   )
    )
    user_axi_m_arbitration (
    	.DDR_INIT_DONE           (ddr_init_done),
    	.M_AXI_ACLK              (ui_clk       ),                          
    	.M_AXI_ARESETN           (~ui_rst  && ddr_init_done),              
        .pix_clk_out             (pix_clk_out  ),//1080p 148.5m            
                                                                          
    	//写地址通道↓                                                              
    	.M_AXI_AWID              (M_AXI_AWID   ),                         
    	.M_AXI_AWADDR            (M_AXI_AWADDR ),                         
    	.M_AXI_AWLEN             (M_AXI_BRUST_LEN),          
    	//.M_AXI_AWUSER            (M_AXI_AWUSER ),                                
        .M_AXI_AWPROT            (M_AXI_AWPROT ),              
        .M_AXI_AWLOCK            (M_AXI_AWLOCK ),              
        .M_AXI_AWCACHE           (M_AXI_AWCACHE),              
        .M_AXI_AWQOS             (M_AXI_AWQOS  ),              
    	.M_AXI_AWVALID           (M_AXI_AWVALID),              
    	.M_AXI_AWREADY           (M_AXI_AWREADY),              
    	.M_AXI_AWSIZE            (M_AXI_AWSIZE ),              
        .M_AXI_AWBURST           (M_AXI_AWBURST),                           
        //写数据通道↓                                                         
    	.M_AXI_WDATA             (M_AXI_WDATA  ),              
    	.M_AXI_WSTRB             (M_AXI_WSTRB  ),              
    	.M_AXI_WLAST             (M_AXI_WLAST  ),              
        .M_AXI_WREADY            (M_AXI_WREADY ),              
    	//.M_AXI_WUSER             (M_AXI_WUSER  ),
        //写响应通道
        .M_AXI_BID               (M_AXI_BID   ),
        .M_AXI_BRESP             (M_AXI_BRESP ),
        .M_AXI_BVALID            (M_AXI_BVALID),
        .M_AXI_BREADY            (M_AXI_BREADY),                            
    	//读地址通道↓                                                              
    	.M_AXI_ARID              (M_AXI_ARID   ),     
       // .M_AXI_ARUSER            (M_AXI_ARUSER ),   
    	.M_AXI_ARADDR            (M_AXI_ARADDR ),     
    	.M_AXI_ARLEN             (M_AXI_BRUST_LEN),   
    	.M_AXI_ARVALID           (M_AXI_ARVALID),     
    	.M_AXI_ARREADY           (M_AXI_ARREADY),     
        .M_AXI_ARPROT            (M_AXI_ARPROT ),
        .M_AXI_ARLOCK            (M_AXI_ARLOCK ),
        .M_AXI_ARCACHE           (M_AXI_ARCACHE),
        .M_AXI_ARQOS             (M_AXI_ARQOS  ),
        .M_AXI_ARSIZE            (M_AXI_ARSIZE ),
        .M_AXI_ARBURST           (M_AXI_ARBURST),
        
    	//读数据通道↓                                                              
    	.M_AXI_RID               (M_AXI_RID   ),
    	.M_AXI_RDATA             (M_AXI_RDATA ),
    	.M_AXI_RLAST             (M_AXI_RLAST ),
    	.M_AXI_RVALID            (M_AXI_RVALID),
        .M_AXI_RREADY            (M_AXI_RREADY),
        .M_AXI_RRESP             (M_AXI_RRESP ),
        //video
        .vs_in                   (hdmi_clk_in ),
        .vs_out                  (vs_out      ),
    //fifo0信号          
        .video0_clk_in           (hdmi_clk_in),                                //wr fifo                                                                               
        .video0_de_in            (zoom_de_out    ),//32bit 拼接zoom数据到     32bit-> [fifo] ->256bit 传输到  axi ->ddr   因为axi突发长度设置为8，且axi256bit对应wr_fifo_rd端口位宽，所以每M_AXI_WLAST突发一次即256bit*8
        .video0_data_in          (zoom_data_out  ),//                                  
        .video0_rd_en            (video0_rd_en   ),//                                 
        .video0_data_out         (video0_data_out),//rd_fifo dataout
        .fram0_done              (fram0_done     ),
        .video0_vs_in            (hdmi_clk_in    ),//用于抓取复位
    //fifo1信号
        //.video1_clk_in           (hdmi_clk_in),                                                               
        //.video1_de_in            (zoom_de_out    ),
        //.video1_data_in          (zoom_data_out  ),
        //.video1_rd_en            (video1_rd_en   ),
        //.video1_data_out         (video1_data_out),                
        //.fram1_done              (fram1_done     ),                   
        //.video1_vs_in            (hdmi_clk_in    ),//用于抓取复位     
        .video1_clk_in           (gmii_rx_clk    ),                 
        .video1_de_in            (eth0_rx_de     ),
        .video1_data_in          ({eth0_rx_data[15:11],5'b0,eth0_rx_data[10:5],4'b0,eth0_rx_data[4:0],7'b0} ),
        .video1_rd_en            (video1_rd_en   ),
        .video1_data_out         (video1_data_out),
        .fram1_done              (fram1_done     ),
        .video1_vs_in            (eth0_rx_vs     ),//用于抓取复位
    //fifo2信号，接CMOS1                                  
        .video2_clk_in           (cam_pclk_1         ),                       
        .video2_de_in            (cmos_frame_valid_1 ),
        .video2_data_in          ({cmos_frame_data_1[4:0],5'b0,cmos_frame_data_1[10:5],4'b0,cmos_frame_data_1[15:11],7'b0}),//27
        .video2_rd_en            (video2_rd_en   ),
        .video2_data_out         (video2_data_out),
        .fram2_done              (fram2_done     ),
        .video2_vs_in            (cmos_frame_vsync_1 ),//用于抓取复位
    //fifo3信号                                        
        .video3_clk_in           (cam_pclk_2            ),                       
        .video3_de_in            (cmos_frame_valid_2    ),
        .video3_data_in          ({cmos_frame_data_2[4:0],5'b0,cmos_frame_data_2[10:5],4'b0,cmos_frame_data_2[15:11],7'b0}  ),
        .video3_rd_en            (video3_rd_en   ),
        .video3_data_out         (video3_data_out),
        .fram3_done              (fram3_done     ),
        .video3_vs_in            (cmos_frame_vsync_2 ),//用于抓取复位
        //其他
        .wr_addr_min             (RW_ADDR_MIN),//写数据ddr最小地址0地址开始算，1920*1080*16 = 33177600 bits
        .wr_addr_max             (RW_ADDR_MAX), //写数据ddr最大地址，一个地址存32位 33177600/32 = 1036800 = 20'b1111_1101_0010_0000_0000
        .y_act                   (y_act)        , 
        .x_act                   (x_act)  
    
    );

    //rst_n_d1、rst_n_sync
    reg                     rst_n_d1      ;
    reg                     rst_n_sync    ;
    always@(posedge clk_200m or negedge rst_n) begin
        if(~rst_n) begin  //异步复位
            rst_n_d1    <= 1'b0;
            rst_n_sync  <= 1'b0;
        end else begin   //同步释放
            rst_n_d1    <= 1'b1;
            rst_n_sync  <= rst_n_d1;
        end
    end
   //ddr ip 
   // Vivado MIG IP栿
   mig_7series_0 axi_ddr3_mig_inst (
     // DDR3存储器接叿
     .ddr3_addr              (ddr3_addr          ),  // output [13:0]    ddr3_addr
     .ddr3_ba                (ddr3_ba            ),  // output [2:0]     ddr3_ba
     .ddr3_cas_n             (ddr3_cas_n         ),  // output           ddr3_cas_n
     .ddr3_ck_n              (ddr3_ck_n          ),  // output [0:0]     ddr3_ck_n
     .ddr3_ck_p              (ddr3_ck_p          ),  // output [0:0]     ddr3_ck_p
     .ddr3_cke               (ddr3_cke           ),  // output [0:0]     ddr3_cke
     .ddr3_ras_n             (ddr3_ras_n         ),  // output           ddr3_ras_n
     .ddr3_reset_n           (ddr3_reset_n       ),  // output           ddr3_reset_n
     .ddr3_we_n              (ddr3_we_n          ),  // output           ddr3_we_n
     .ddr3_dq                (ddr3_dq            ),  // inout [31:0]     ddr3_dq
     .ddr3_dqs_n             (ddr3_dqs_n         ),  // inout [3:0]      ddr3_dqs_n
     .ddr3_dqs_p             (ddr3_dqs_p         ),  // inout [3:0]      ddr3_dqs_p
     .init_calib_complete    (ddr_init_done      ),  // output           init_calib_complete
     .ddr3_cs_n              (ddr3_cs_n          ),  // output [0:0]     ddr3_cs_n
     .ddr3_dm                (ddr3_dm            ),  // output [3:0]     ddr3_dm
     .ddr3_odt               (ddr3_odt           ),  // output [0:0]     ddr3_odt
     
     // 用户接口
     .ui_clk                 (ui_clk             ),  // output           ui_clk
     .ui_clk_sync_rst        (ui_rst             ),  // output           ui_clk_sync_rst
     .mmcm_locked            (                   ),  // output           mmcm_locked             
     .aresetn                (rst_n_sync         ),  // input            aresetn
     .app_sr_req             (1'b0               ),  // input            app_sr_req
     .app_ref_req            (1'b0               ),  // input            app_ref_req
     .app_zq_req             (1'b0               ),  // input            app_zq_req
     .app_sr_active          (                   ),  // output           app_sr_active
     .app_ref_ack            (                   ),  // output           app_ref_ack
     .app_zq_ack             (                   ),  // output           app_zq_ack
                                                                                                    
     // AXI写地坿通道                                                                               
     .s_axi_awid             (M_AXI_AWID           ),  // input [3:0]      s_axi_awid               
     .s_axi_awaddr           (M_AXI_AWADDR         ),  // input [28:0]     s_axi_awaddr             
     .s_axi_awlen            (M_AXI_BRUST_LEN      ),  // input [7:0]      s_axi_awlen              
     .s_axi_awsize           (M_AXI_AWSIZE         ),  // input [2:0]      s_axi_awsize             
     .s_axi_awburst          (M_AXI_AWBURST        ),  // input [1:0]      s_axi_awburst            
     .s_axi_awlock           (M_AXI_AWLOCK         ),  // input [0:0]      s_axi_awlock             
     .s_axi_awcache          (M_AXI_AWCACHE        ),  // input [3:0]      s_axi_awcache            
     .s_axi_awprot           (M_AXI_AWPROT         ),  // input [2:0]      s_axi_awprot             
     .s_axi_awqos            (M_AXI_AWQOS          ),  // input [3:0]      s_axi_awqos              
     .s_axi_awvalid          (M_AXI_AWVALID        ),  // input            s_axi_awvalid            
     .s_axi_awready          (M_AXI_AWREADY        ),  // output           s_axi_awready            
                                                                                                    
     // AXI写数据鿚道                                                                               
     .s_axi_wdata            (M_AXI_WDATA          ),  // input [AXI_WIDTH-1:0]     s_axi_wdata     
     .s_axi_wstrb            (M_AXI_WSTRB          ),  // input [AXI_WSTRB_W-1:0]   s_axi_wstrb     
     .s_axi_wlast            (M_AXI_WLAST          ),  // input                     s_axi_wlast     
     .s_axi_wvalid           (M_AXI_WVALID         ),  // input                                          s_axi_wvalid    
     .s_axi_wready           (M_AXI_WREADY         ),  // output                    s_axi_wready    
                                                                                                    
     // AXI写响应鿚道                                                                               
     .s_axi_bid              (M_AXI_BID            ),  // output [3:0]                          s_axi_bid       
     .s_axi_bresp            (M_AXI_BRESP          ),  // output [1:0]                          s_axi_bresp     
     .s_axi_bvalid           (M_AXI_BVALID         ),  // output                                s_axi_bvalid    
     .s_axi_bready           (M_AXI_BREADY         ),  // input                                 s_axi_bready    
                                                                                                    
     // AXI读地坿通道                                                                               
     .s_axi_arid             (M_AXI_ARID           ),  // input [3:0]               s_axi_arid      
     .s_axi_araddr           (M_AXI_ARADDR         ),  // input [28:0]              s_axi_araddr    
     .s_axi_arlen            (M_AXI_BRUST_LEN      ),  // input [7:0]               s_axi_arlen     
     .s_axi_arsize           (M_AXI_ARSIZE         ),  // input [2:0]               s_axi_arsize    
     .s_axi_arburst          (M_AXI_ARBURST        ),  // input [1:0]               s_axi_arburst   
     .s_axi_arlock           (M_AXI_ARLOCK         ),  // input [0:0]               s_axi_arlock    
     .s_axi_arcache          (M_AXI_ARCACHE        ),  // input [3:0]               s_axi_arcache   
     .s_axi_arprot           (M_AXI_ARPROT         ),  // input [2:0]               s_axi_arprot    
     .s_axi_arqos            (M_AXI_ARQOS          ),  // input [3:0]               s_axi_arqos     
     .s_axi_arvalid          (M_AXI_ARVALID        ),  // input                     s_axi_arvalid   
     .s_axi_arready          (M_AXI_ARREADY        ),  // output                    s_axi_arready   
                                                                                                    
     // AXI读数据鿚道                                                                               
     .s_axi_rid              (M_AXI_RID            ),  // output [3:0]              s_axi_rid
     .s_axi_rdata            (M_AXI_RDATA          ),  // output [AXI_WIDTH-1:0]    s_axi_rdata
     .s_axi_rresp            (M_AXI_RRESP          ),  // output [1:0]              s_axi_rresp
     .s_axi_rlast            (M_AXI_RLAST          ),  // output                    s_axi_rlast
     .s_axi_rvalid           (M_AXI_RVALID         ),  // output                    s_axi_rvalid
     .s_axi_rready           (M_AXI_RREADY         ),  // input                     s_axi_rready
     
     // AXI从机系统时钟
     .sys_clk_i              (clk_200m           ),
     // 参迃时钿
     .clk_ref_i              (clk_200m           ),
     .sys_rst                (rst_n_sync         )   // input            sys_rst
    );
  wire             video_enhance_vs_out;
  wire             video_enhance_hs_out;
  wire             video_enhance_de_out;
  wire [7 : 0]     video_enhance_r_out;
  wire [7 : 0]     video_enhance_g_out;
  wire [7 : 0]     video_enhance_b_out;
  
  wire [7  : 0]    video_enhance_lightdown_num;
  wire             video_enhance_lightdown_sw ;
  wire [7  : 0]    video_enhance_darkup_num   ;
  wire             video_enhance_darkup_sw    ;
  
  wire             eth_zoom_de_out/* synthesis PAP_MARK_DEBUG="1" */;
  wire [31 : 0]    eth_zoom_data_out;
  wire [31 : 0]    eth_zoom_data__in;
  assign eth_zoom_data__in = {video_enhance_r_out,2'b0,video_enhance_g_out,2'b0,video_enhance_b_out,4'b0};
  // 图像增强模块 rgb2yuv and yuv2rgb
  video_enhance u_video_enhance(
     .pix_clk(pix_clk_out),//input  wire            
     .vs_in  (r_vs_out),//input  wire            
     .hs_in  (),//input  wire            
     .de_in  (r_de_out),//input  wire         zoom_de_out              
     .r_in   (r_r_out),//input  wire [7 : 0] zoom_data_out[31 : 24]   
     .g_in   (r_g_out),//input  wire [7 : 0] zoom_data_out[21 : 14]   
     .b_in   (r_b_out),//input  wire [7 : 0] zoom_data_out[11 :  4]
        
     .vs_out (video_enhance_vs_out  ),//output wire                               
     .hs_out (video_enhance_hs_out  ),//output wire            
     .de_out (video_enhance_de_out  ),//output wire            
     .r_out  (video_enhance_r_out   ),//output wire [7 : 0]    
     .g_out  (video_enhance_g_out   ),//output wire [7 : 0]    
     .b_out  (video_enhance_b_out   ), //output wire [7 : 0]    
     .video_enhance_lightdown_num (video_enhance_lightdown_num),//input wire [7 : 0]            
     .video_enhance_lightdown_sw  (video_enhance_lightdown_sw ),//input wire                    
     .video_enhance_darkup_num    (video_enhance_darkup_num   ),//input wire [7 : 0]            
     .video_enhance_darkup_sw     (video_enhance_darkup_sw    )//input wire                            
   );
  //二次图像压缩，对hdmi_out数据进行压缩传给eth
  video_zoom eth_video_zoom(
     .clk                (pix_clk_out             ),
     .rstn               (sys_init_done & rst_n   ),
     .vs_in              (video_enhance_vs_out    ),
     .hs_in              (video_enhance_hs_out    ),
     .de_in              (video_enhance_de_out    ),
     .video_data_in      (eth_zoom_data__in       ),
     .de_out             (eth_zoom_de_out         ),
     .video_data_out     (eth_zoom_data_out       )
   );
   
 ////************************************    PCIE        ***********************************************  
  wire [15:0] pcie_data_in;
  assign pcie_data_in = {video_enhance_r_out[7:3],video_enhance_g_out[7:2],video_enhance_b_out[7:3]};
  wire pcie_axi_clk;
  wire [63:0 ]s_axis_tdata_0;
  wire s_axis_tlast_0 ;
  wire s_axis_tready_0;
  wire s_axis_tvalid_0;
  wire pcie_axi_resetn;
  axi_stream_packer #(
    parameter integer VIDEO_LENGTH = 1920 ,
    parameter integer VIDEO_HIGTH  = 1080                                                      
    )
  axi_stream_packer_inst(
    .clk        (pcie_axi_clk         ),
    .pixel_clk  (pix_clk_out          ),
    .rstn       (sys_init_done & rst_n),
    .vs_in      (video_enhance_vs_out ),
    .pixel_in   (pcie_data_in         ),
    .pixel_valid(video_enhance_de_out ),
    .tdata      (s_axis_tdata_0       ),
    .tvalid     (s_axis_tvalid_0      ),
    .tlast      (s_axis_tlast_0       ),
    .tready     (s_axis_tready_0      )
  
  );                                          
  design_1 design_1_i                         
   .pcie_axi_clk(pcie_axi_clk),               
   .pcie_axi_resetn(pcie_axi_resetn),         
   .pcie_mgt_0_rxn(pcie_mgt_rxn),             
   .pcie_mgt_0_rxp(pcie_mgt_rxp),             
   .pcie_mgt_0_txn(pcie_mgt_txn),             
   .pcie_mgt_0_txp(pcie_mgt_txp),
   .s_axis_tdata_0(s_axis_tdata_0),
   .s_axis_tlast_0(s_axis_tlast_0),
   .s_axis_tready_0(s_axis_tready_0),
   .s_axis_tvalid_0(s_axis_tvalid_0),
   .sys_clk_clk_n(pcie_ref_clk_n),
   .sys_clk_clk_p(pcie_ref_clk_p),
   .sys_rstn(pcie_rst_n & sys_init_done & rst_n);
 
 ////************************************    PCIE-end    ***********************************************  
 
 
 ////************************************    ETH         ***********************************************
  eth_img_rec
    //#(
    //parameter integer PIXEL_WIDTH = 32                                   ,
    //parameter integer VIDEO_LENGTH = 16'd960                             ,
    //parameter integer VIDEO_HIGTH  = 16'd540                             
    //)
  eth0_img_rec(
    .eth_rx_clk   (gmii_rx_clk  ),//input wire                         
    .rstn         (sys_init_done & rst_n    ),//input wire                         
    .udp_date_rcev(rec_data     ),//input wire [31: 0]   
    .udp_date_en  (rec_en       ),//input wire                         
    .img_data_en  (eth0_rx_de   ),//output reg                         
    .img_data_vs  (eth0_rx_vs   ),//output reg                         
    .img_data     (eth0_rx_data ) //output reg [15: 0]   
   );
  eth_img_pkt eth0_img_pkt(    
    .rst_n              (sys_init_done & rst_n       ), //input                    
    ////图像相关信号              
    .cam_pclk           (pix_clk_out      ), //input  图像时钟             
    .img_vsync          (video_enhance_vs_out           ), //input  帧同步               
    .img_data_en        (eth_zoom_de_out     ), //input  de               
    .img_data           ({eth_zoom_data_out[31 : 27],eth_zoom_data_out[21 : 16],eth_zoom_data_out[11 :  7]}), //input  [15:0]   //vesa_debug_data //eth0_img_data
    .transfer_flag      (1               ), //input                                        
    ////以太网相关信号
    .eth_tx_clk         (gmii_tx_clk     ), //input                          
    .udp_tx_req         (tx_req          ), //input                
    .udp_tx_done        (udp_tx_done     ), //input                
    .udp_tx_start_en    (tx_start_en     ), //output  reg          
    .udp_tx_data        (tx_data         ), //output       [31:0]  
    .udp_tx_byte_num    (tx_byte_num     )  //output  reg  [15:0]  
    ); 
    //UDP通信
  udp_top                                             
    #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
     )
  u_udp(
    .rst_n         (sys_init_done & rst_n   ),  //input       复位信号，低电平有效            
    //GMII接口                                
    .gmii_rx_clk   (gmii_rx_clk         ),  //input       GMII接收数据时钟                    
    .gmii_rx_dv    (gmii_rx_dv          ),  //input       GMII输入数据有效信号                
    .gmii_rxd      (gmii_rxd            ),  //input [7:0] GMII输入数据                              
    .gmii_tx_clk   (gmii_tx_clk         ),  //input       GMII发送数据时钟            
    .gmii_tx_en    (gmii_tx_en          ),  //output      GMII输出数据有效信号                  
    .gmii_txd      (gmii_txd            ),  //output[7:0] GMII输出数据              
    //用户接口                                  
    .rec_pkt_done  (rec_pkt_done        ),  //output      以太网单包数据接收完成信号          
    .rec_en        (rec_en              ),  //output      以太网接收的数据使能信号            
    .rec_data      (rec_data            ),  //output[31:0]以太网接收的数据                    
    .rec_byte_num  (rec_byte_num        ),  //output[15:0]以太网接收的有效字节数 单位:byte  
    
    .tx_start_en   (tx_start_en         ),  //input       以太网开始发送信号                  
    .tx_data       (tx_data             ),  //input [31:0]以太网待发送数据                    
    .tx_byte_num   (tx_byte_num         ),  //input [15:0]以太网发送的有效字节数 单位:byte   
    .des_mac       (DES_MAC             ),  //input [47:0]发送的目标MAC地址            
    .des_ip        (DES_IP              ),  //input [31:0]发送的目标IP地址              
    .tx_done       (udp_tx_done         ),  //output      以太网发送完成信号                  
    .tx_req        (tx_req              )   //output      读数据请求信号                      
    ); 
   gmii_to_rgmii 
    #(
    .IDELAY_VALUE (IDELAY_VALUE)
     )
    u_gmii_to_rgmii(
    .idelay_clk    (clk_200m    ),

    .gmii_rx_clk   (gmii_rx_clk ),
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),
    .gmii_tx_en    (gmii_tx_en  ),
    .gmii_txd      (gmii_txd    ),
    
    .rgmii_rxc     (eth_rxc     ),
    .rgmii_rx_ctl  (eth_rx_ctl  ),
    .rgmii_rxd     (eth_rxd     ),
    .rgmii_txc     (eth_txc     ),
    .rgmii_tx_ctl  (eth_tx_ctl  ),
    .rgmii_txd     (eth_txd     )
    );
    
   endmodule