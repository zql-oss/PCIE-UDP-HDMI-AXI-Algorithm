`timescale 1ns / 1ps


module i2c_ctrl
(
	input     ADV_CLK  ,
	input     ADV_RST  ,//�͵�ƽ��λ
	output    ADV_SCLK ,
	inout     ADV_SDAT ,
	output    init_done
);
parameter  CLK_FREQ   = 26'd50_000_000 ;  //i2c_driģ�������ʱ��Ƶ�� 50.0MHz
parameter  I2C_FREQ   = 18'd250000     ;  //I2C��SCLʱ��Ƶ��,������400KHz

//wire define  
wire  [9:0]    i2c_config_index;
wire  [23:0]   i2c_config_data ;
wire  [9:0]    i2c_config_size ;
wire           i2c_config_done ;
wire           i2c_RW_flag     ;
wire  [7:0]    i2c_rdata       ;  //i2c register data
wire           i2c_exec        ; 
wire  [23:0]   i2c_data        ;   
wire           i2c_done        ;  //I2C�Ĵ�����������ź�
	
i2c_dri
#(             
	.CLK_FREQ               (CLK_FREQ  ),           
	.I2C_FREQ               (I2C_FREQ  )            
	)          
u_i2c_dri
(
//global clock
.clk                    (ADV_CLK        ),   
.rst_n                  (ADV_RST        ),   
//i2c interface         
.i2c_exec               (i2c_exec       ),   
.bit_ctrl               (1'b0           ),   
.i2c_rh_wl              (1'b0           ),          
.slaver_addr            (i2c_data[23:16]),
.i2c_addr               (i2c_data[15:8] ),
.i2c_data_w             (i2c_data[7:0]  ), 
.i2c_data_r             (),   
.i2c_done               (i2c_done       ), 
.i2c_ack                (),    
.scl                    (ADV_SCLK       ),   
.sda                    (ADV_SDAT       ),    
.dri_clk                (i2c_dri_clk    )  
);                    

i2c_adv7611_cfg    u_i2c_adv7611_cfg
(
.clk                    (i2c_dri_clk),
.rst_n                  (ADV_RST    ),
.i2c_done               (i2c_done   ),
.i2c_exec               (i2c_exec   ),
.i2c_data               (i2c_data   ),
.init_done              (init_done  )
);   
endmodule
