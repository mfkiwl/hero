// Copyright 2019 ETH Zurich and University of Bologna.
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

// TODO: Replace behavior with instantiation of cuts.

module sram #(
  parameter int unsigned DATA_WIDTH = 0,   // [bit]
  parameter int unsigned N_WORDS    = 0,
  // Dependent parameters, do not override!
  parameter int unsigned STRB_WIDTH = DATA_WIDTH/8,
  parameter type addr_t = logic[$clog2(N_WORDS)-1:0],
  parameter type data_t = logic[DATA_WIDTH-1:0],
  parameter type strb_t = logic[STRB_WIDTH-1:0]
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  input  logic  req_i,
  input  logic  we_i,
  input  addr_t addr_i,
  input  data_t wdata_i,
  input  strb_t be_i,
  output data_t rdata_o
);


`ifdef SYNTHESIS
  `ifdef TARGET_XILINX
    strb_t we;
    for (genvar p = 0; p < STRB_WIDTH; p++) begin : gen_we
      assign we[p] = we_i & be_i[p];
    end
    xpm_memory_spram #(
      .ADDR_WIDTH_A         ($clog2(N_WORDS)),
      .AUTO_SLEEP_TIME      (0),
      .BYTE_WRITE_WIDTH_A   (8),
      .CASCADE_HEIGHT       (0),
      .ECC_MODE             ("no_ecc"),
      .MEMORY_INIT_FILE     ("none"),
      .MEMORY_INIT_PARAM    (""),
      .MEMORY_OPTIMIZATION  ("true"),
      .MEMORY_PRIMITIVE     ("block"),
      .MEMORY_SIZE          (N_WORDS*DATA_WIDTH),
      .MESSAGE_CONTROL      (0),
      .READ_DATA_WIDTH_A    (DATA_WIDTH),
      .READ_LATENCY_A       (1),
      .READ_RESET_VALUE_A   ("0"),
      .RST_MODE_A           ("SYNC"),
      .SIM_ASSERT_CHK       (1),
      .USE_MEM_INIT         (0),
      .WAKEUP_TIME          ("disable_sleep"),
      .WRITE_DATA_WIDTH_A   (DATA_WIDTH),
      .WRITE_MODE_A         ("read_first")
    ) i_xpm_memory_spram (
      .addra          (addr_i),
      .clka           (clk_i),
      .dbiterra       (),
      .dina           (wdata_i),
      .douta          (rdata_o),
      .ena            (req_i),
      .injectdbiterra (1'b0),
      .injectsbiterra (1'b0),
      .regcea         (1'b1),
      .rsta           (~rst_ni),
      .sbiterra       (),
      .sleep          (1'b0),
      .wea            (we)
    );
  `else
   
   logic [31:0] BE_BW;
  
   assign BE_BW      = { {8{be_i[3]}}, {8{be_i[2]}}, {8{be_i[1]}}, {8{be_i[0]}} };
     
   IN22FDX_S1D_NFRG_W04096B032M04C128  cut
     (
      .CLK          ( clk_i            ), // input
      .CEN          ( ~req_i           ), // input
      .RDWEN        ( we_i             ), // input
      .DEEPSLEEP    ( 1'b0             ), // input
      .POWERGATE    ( 1'b0             ), // input
      .AS           ( addr_i[6:4]      ), // input
      .AW           ( {addr_i[11:7],addr_i[3:2]} ), // input
      .AC           ( addr_i[1:0]      ), // input
      .D            ( wdata_i          ), // input
      .BW           ( BE_BW            ), // input
      .T_BIST       ( 1'b0             ), // input
      .T_LOGIC      ( 1'b0             ), // input
      .T_CEN        ( 1'b1             ), // input
      .T_RDWEN      ( 1'b1             ), // input
      .T_DEEPSLEEP  ( 1'b0             ), // input
      .T_POWERGATE  ( 1'b0             ), // input
      .T_AS         ( '0               ), // input
      .T_AW         ( '0               ), // input
      .T_AC         ( '0               ), // input
      .T_D          ( '0               ), // input
      .T_BW         ( '0               ), // input
      .T_WBT        ( 1'b0             ), // input
      .T_STAB       ( 1'b0             ), // input
      .MA_SAWL      ( '0               ), // input
      .MA_WL        ( '0               ), // input
      .MA_WRAS      ( '0               ), // input
      .MA_WRASD     ( 1'b0             ), // input
      .Q            ( rdata_o          ), // output
      .OBSV_CTL     (                  )  // output
      );
   
  `endif

`else // behavioral
  data_t mem [N_WORDS-1:0];
  always_ff @(posedge clk_i) begin
    if (req_i) begin
      if (we_i) begin
        for (int unsigned i = 0; i < STRB_WIDTH; i++) begin
          if (be_i[i]) begin
            mem[addr_i][i*8+:8] <= wdata_i[i*8+:8];
          end
        end
      end else begin
        rdata_o <= mem[addr_i];
      end
    end
  end
`endif

endmodule
