module axi_stream_packer #(
  parameter VIDEO_LENGTH = 1920,  // 水平像素数
  parameter VIDEO_HIGTH  = 1080   // 垂直像素数（暂未用到）
)(
    input             clk,         // AXI‑Stream侧时钟（例如XDMA侧时钟）
    input             pixel_clk,   // 像素采集时钟（视频采集侧时钟）
    input             rstn,        // 同步复位（低有效）
    input             vs_in,       // 新帧信号（在AXI域同步过来的新帧标志，发生时重置打包状态）
    input      [15:0] pixel_in,
    input             pixel_valid,    
    output reg [63:0] tdata,       // AXI‑Stream数据（打包后的64位数据）
    output reg        tvalid,      // 当 tdata 有效时拉高
    output reg        tlast,       // 表示当前传输数据为一行（或一帧）的最后一个数据字
    input             tready       // 下游模块指示可以接收数据
);

  // 计算每行需要输出的64位数据个数：
  // 每个像素16bit，4个像素拼接成64bit，所以每行64位字数 = VIDEO_LENGTH / 4
  localparam LINE_MAX = (VIDEO_LENGTH / 4);
  
  // --------------------
  // 异步FIFO实例，将pixel_clk域的16位数据跨到clk域
  // 异步FIFO输出信号：
  wire [15:0] fifo_dout;
  wire fifo_empty;
  wire fifo_full;
  // 我们在AXI域连续读出数据（当fifo非空时），不采用手动rd_en控制，
  // 这里我们在AXI域内部根据状态自动“消费”FIFO数据。
  reg fifo_rd_en;  // 由状态机控制
  /*
  async_fifo_16 async_fifo_inst (
      .wr_clk(pixel_clk),
      .rd_clk(clk),
      .rst(~rstn),
      .din(pixel_in),
      .wr_en(pixel_valid),
      .rd_en(fifo_rd_en),
      .dout(fifo_dout),
      .empty(fifo_empty),
      .full(fifo_full)
  );
  */ //16转16
      wr_fifo async_fifo_16 (
        .rst                (~rst_n || vs_in            ),  
        .wr_clk             (pixel_clk                  ),  //hdmi_out 时钟
        .rd_clk             (clk                        ),  //axi时钟
        .din                (pixel_in                   ),  
        .wr_en              (pixel_valid                ),  
        .rd_en              (fifo_rd_en                 ),  //
        .dout               (fifo_dout                  ),  //
        .full               (                           ),  
        .almost_full        (                           ),  
        .empty              (fifo_empty                 ),  
        .almost_empty       (                           ),  
        .rd_data_count      (                           ),  //
        .wr_data_count      (                           ),  
        .wr_rst_busy        (                           ),  
        .rd_rst_busy        (                           )   
    );
  // --------------------
  // 在AXI时钟域内进行数据打包
  reg [1:0] pixel_count;  // 计数已经打包的像素数（0~3）
  reg [63:0] data_buf;    // 缓存4个像素数据
  
  // 用于统计当前行已打包的64位字个数（0~LINE_MAX-1）
  reg [11:0] line_count;
  
  // 状态机：本模块主要功能是连续从FIFO中读取数据进行打包，
  // 并在每行最后输出tlast。如果下游确认数据传输（tready拉高且tvalid拉高），
  // 则清除tvalid和tlast信号。
  always @(posedge clk or negedge rstn) begin
    if (!rstn || vs_in) begin
      pixel_count   <= 2'd0;
      data_buf      <= 64'd0;
      tvalid        <= 1'b0;
      tlast         <= 1'b0;
      tdata         <= 64'd0;
      line_count    <= 0;
      fifo_rd_en    <= 1'b0;
    end else begin
      // 如果FIFO不空，则使能读取
      if (!fifo_empty) begin
         fifo_rd_en <= 1'b1;
         // 读取一个像素数据，打包入data_buf（先到的数据放高位或低位视设计而定，这里采用小端，即先到的数据放低位）
         data_buf <= {data_buf[47:0], fifo_dout};
         pixel_count <= pixel_count + 1;
         // 当累积满4个像素时，构成一个64位数据
         if (pixel_count == 2'd3) begin
            tdata  <= {data_buf[47:0], fifo_dout}; // 拼接成64位数据
            tvalid <= 1'b1;
            // 检查是否到行尾
            if (line_count == LINE_MAX - 1) begin
               tlast <= 1'b1;
               line_count <= 0;
            end else begin
               tlast <= 1'b0;
               line_count <= line_count + 1;
            end
            pixel_count <= 2'd0;
            data_buf    <= 64'd0;
         end
      end else begin
         fifo_rd_en <= 1'b0;
      end
      
      // 当下游接口接收（tready为1）且本模块已输出数据（tvalid为1）时，清除tvalid/tlast
      if (tvalid && tready) begin
         tvalid <= 1'b0;
         tlast  <= 1'b0;
      end
    end
  end

endmodule
