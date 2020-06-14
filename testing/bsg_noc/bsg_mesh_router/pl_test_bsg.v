`define DATA_WIDTH_P 11
`define TS_WIDTH_P   8
`define MESH_EDGE_P  3 // tests a 2^(MESH_EDGE_P) x 2^(MESH_EDGE_P) mesh network

/************************** TEST RATIONALE *********************************
* 1. STATE SPACE
*
*   A n x n, where n is a power of 2, mesh network of UUTs is instantiated 
*   with fifos bridging them. Test data,(tile no.) ^ 0 1 2 .... (total no. 
*   of tiles) is continuously fed through proc fifos of each router at y=0.
*   All packets are continuously sent to the router at x=0,y=0, creating a
*   parking lot problem that will be handled poorly by round robin arb, but
*   fairly by age arb.  The test ends when the router at x=0,y=0 receives a
*   packet from the router at x=2^(MESH_EDGE_P) - 1,y=0.
* 
* 2. PARAMETERIZATION
*
*   DATA_WIDTH_P is the width of test data excluding the embedded coordinates.
*   MESH_EDGE_P is log(edge length of the mesh). A reasonable set tests would
*   be MESH_EDGE_P = 0 1 2 with sufficient DATA_WIDTH_P.
* **************************************************************************/

// import enum Dirs for directions
import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (processor core)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south


module test_bsg
  (input i_clk);
  
  // clock and reset generation
  localparam cycle_time_lp = 20;
  wire clk;
  wire reset;

  assign clk = i_clk;
  // bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_lp)
  //                         )  clock_gen
  //                         (  .o(clk)
  //                         );
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(1)
                           , .reset_cycles_hi_p(5)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          ); 

  localparam medge_lp     = 2**(`MESH_EDGE_P);         // edge length of the mesh 
  localparam msize_lp     = medge_lp**2;               // area (total no. of routers)
  localparam lg_node_x_lp = `BSG_SAFE_CLOG2(medge_lp); // width of x coordinate
  localparam lg_node_y_lp = `BSG_SAFE_CLOG2(medge_lp); // width of y coordinate

  // data width including embedded coordinates
  localparam width_lp = (`DATA_WIDTH_P) + lg_node_x_lp + lg_node_y_lp;
  localparam ts_width_lp = (`TS_WIDTH_P);

  localparam dirs_lp = 5;
  
  initial
  begin
    $display("\n\n\n");
    $display("===========================================================");
    $display("testing  %0d x %0d network with...", medge_lp, medge_lp);
    $display("DATA_WIDTH = %0d\n", (`DATA_WIDTH_P));
  end

  
  // I/O signal of UUTs

  logic [msize_lp-1:0][dirs_lp-1:0] test_input_valid;
  logic [msize_lp-1:0][dirs_lp-1:0] test_input_ready;
  logic [msize_lp-1:0][dirs_lp-1:0][width_lp-1:0] test_input_data;
  logic [msize_lp-1:0][dirs_lp-1:0][ts_width_lp-1:0] test_input_ts;

  logic [msize_lp-1:0][dirs_lp-1:0] test_output_yumi;
  logic [msize_lp-1:0][dirs_lp-1:0] test_output_valid;
  logic [msize_lp-1:0][dirs_lp-1:0][width_lp-1:0] test_output_data;
  logic [msize_lp-1:0][dirs_lp-1:0][ts_width_lp-1:0] test_output_ts;
  
  /*******************************************************
  * Instantiation of medge_lp x medge_lp mesh network
  * -- medge_lp is a power of 2
  ********************************************************/ 
  
  genvar i, j; 
  
  for(i=0; i<msize_lp; i=i+1)
    bsg_mesh_router_age_arb #( .dirs_p     (dirs_lp)
                              ,.width_p    (width_lp)
                              ,.ts_width_p (ts_width_lp)
                              ,.lg_node_x_p(lg_node_x_lp)
                              ,.lg_node_y_p(lg_node_y_lp)
                              ) uut
                     ( .clk_i  (clk)
                      ,.reset_i(reset)
                      
                      ,.data_i (test_input_data[i])
                      ,.ts_i   (test_input_ts[i])
                      ,.valid_i(test_input_valid[i])
                      ,.yumi_o (test_output_yumi[i])

                      ,.data_o (test_output_data[i])
                      ,.ts_o   (test_output_ts[i])
                      ,.valid_o(test_output_valid[i])
                      ,.ready_i(test_input_ready[i])

                      ,.my_x_i(lg_node_x_lp'(i%medge_lp))
                      ,.my_y_i(lg_node_y_lp'(i/medge_lp))
                     );

  // disables the peripheral ports of the mesh
  for(i=0; i<msize_lp; i=i+1)
  begin
    if(i/medge_lp == 0)
      begin
        assign test_input_valid[i][N] = 1'b0;
        assign test_input_ready[i][N] = 1'b0;
      end

    if(i/medge_lp == medge_lp-1) 
      begin
        assign test_input_valid[i][S] = 1'b0;
        assign test_input_ready[i][S] = 1'b0;
      end

    if(i%medge_lp == 0) 
      begin
        assign test_input_valid[i][W] = 1'b0;
        assign test_input_ready[i][W] = 1'b0;
      end

    if(i%medge_lp == medge_lp-1) 
      begin
        assign test_input_valid[i][E] = 1'b0;
        assign test_input_ready[i][E] = 1'b0;
      end
  end


  
  /*********************************************
  * Instantiation of fifos bridging the routers
  /*********************************************/
  
  // vertical fifos => data flow N to S or vice-versa
  for(i=0; i<((medge_lp)*(medge_lp-1)); i=i+1)
  begin
    bsg_fifo_1r1w_small #( .width_p(width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) fifo_up // north to south data flow
                         ( .clk_i  (clk)
                          ,.reset_i(reset)
                          
                          ,.data_i (test_output_data[i][S])
                          ,.v_i    (test_output_valid[i][S])
                          ,.ready_o(test_input_ready[i][S])

                          ,.data_o(test_input_data[i+medge_lp][N])
                          ,.v_o   (test_input_valid[i+medge_lp][N])
                          ,.yumi_i(test_output_yumi[i+medge_lp][N])
                         );

    bsg_fifo_1r1w_small #( .width_p(width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) fifo_down // south to north data flow
                         ( .clk_i  (clk)
                          ,.reset_i(reset)
                          
                          ,.data_i (test_output_data[i+medge_lp][N])
                          ,.v_i    (test_output_valid[i+medge_lp][N])
                          ,.ready_o(test_input_ready[i+medge_lp][N])

                          ,.data_o(test_input_data[i][S])
                          ,.v_o   (test_input_valid[i][S])
                          ,.yumi_i(test_output_yumi[i][S])
                         );
  end

  // horizontal fifos => data flow E to W or vice versa
  for(i=0; i<medge_lp; i=i+1)
  begin
    for(j=0; j<medge_lp-1; j=j+1)
    begin
      bsg_fifo_1r1w_small #( .width_p(width_lp)
                            ,.els_p  (msize_lp)
                            ,.ready_THEN_valid_p(0)
                           ) fifo_right // west to east data flow
                           ( .clk_i  (clk)
                            ,.reset_i(reset)
                            
                            ,.data_i (test_output_data[i*medge_lp + j][E])
                            ,.v_i    (test_output_valid[i*medge_lp + j][E])
                            ,.ready_o(test_input_ready[i*medge_lp + j][E])

                            ,.data_o(test_input_data[i*medge_lp+j+1][W])
                            ,.v_o   (test_input_valid[i*medge_lp+j+1][W])
                            ,.yumi_i(test_output_yumi[i*medge_lp+j+1][W])
                           );
  
      bsg_fifo_1r1w_small #( .width_p(width_lp)
                            ,.els_p  (msize_lp)
                            ,.ready_THEN_valid_p(0)
                           ) fifo_left // east to west data flow
                           ( .clk_i  (clk)
                            ,.reset_i(reset)
                            
                            ,.data_i (test_output_data[i*medge_lp+j+1][W])
                            ,.v_i    (test_output_valid[i*medge_lp+j+1][W])
                            ,.ready_o(test_input_ready[i*medge_lp+j+1][W])

                            ,.data_o(test_input_data[i*medge_lp+j][E])
                            ,.v_o   (test_input_valid[i*medge_lp+j][E])
                            ,.yumi_i(test_output_yumi[i*medge_lp+j][E])
                           );
    end
  end

  // vertical fifos => ts flow N to S or vice-versa
  for(i=0; i<((medge_lp)*(medge_lp-1)); i=i+1)
  begin
    bsg_fifo_1r1w_small #( .width_p(ts_width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) ts_fifo_up // north to south ts flow
                         ( .clk_i  (clk)
                          ,.reset_i(reset)

                          ,.data_i (test_output_ts[i][S])
                          ,.v_i    (test_output_valid[i][S])
                          ,.ready_o(test_input_ready[i][S])

                          ,.data_o(test_input_ts[i+medge_lp][N])
                          ,.v_o   (test_input_valid[i+medge_lp][N])
                          ,.yumi_i(test_output_yumi[i+medge_lp][N])
                         );

    bsg_fifo_1r1w_small #( .width_p(ts_width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) ts_fifo_down // south to north ts flow
                         ( .clk_i  (clk)
                          ,.reset_i(reset)

                          ,.data_i (test_output_ts[i+medge_lp][N])
                          ,.v_i    (test_output_valid[i+medge_lp][N])
                          ,.ready_o(test_input_ready[i+medge_lp][N])

                          ,.data_o(test_input_ts[i][S])
                          ,.v_o   (test_input_valid[i][S])
                          ,.yumi_i(test_output_yumi[i][S])
                         );
  end

  // horizontal fifos => ts flow E to W or vice versa
  for(i=0; i<medge_lp; i=i+1)
  begin
    for(j=0; j<medge_lp-1; j=j+1)
    begin
      bsg_fifo_1r1w_small #( .width_p(ts_width_lp)
                            ,.els_p  (msize_lp)
                            ,.ready_THEN_valid_p(0)
                           ) ts_fifo_right // west to east ts flow
                           ( .clk_i  (clk)
                            ,.reset_i(reset)

                            ,.data_i (test_output_ts[i*medge_lp + j][E])
                            ,.v_i    (test_output_valid[i*medge_lp + j][E])
                            ,.ready_o(test_input_ready[i*medge_lp + j][E])

                            ,.data_o(test_input_ts[i*medge_lp+j+1][W])
                            ,.v_o   (test_input_valid[i*medge_lp+j+1][W])
                            ,.yumi_i(test_output_yumi[i*medge_lp+j+1][W])
                           );

      bsg_fifo_1r1w_small #( .width_p(ts_width_lp)
                            ,.els_p  (msize_lp)
                            ,.ready_THEN_valid_p(0)
                           ) ts_fifo_left // east to west ts flow
                           ( .clk_i  (clk)
                            ,.reset_i(reset)

                            ,.data_i (test_output_ts[i*medge_lp+j+1][W])
                            ,.v_i    (test_output_valid[i*medge_lp+j+1][W])
                            ,.ready_o(test_input_ready[i*medge_lp+j+1][W])

                            ,.data_o(test_input_ts[i*medge_lp+j][E])
                            ,.v_o   (test_input_valid[i*medge_lp+j][E])
                            ,.yumi_i(test_output_yumi[i*medge_lp+j][E])
                           );
    end
  end


  // proc fifo
  
  // actual test data;
  // fed through input proc fifo
  logic [medge_lp-1:0][width_lp-1:0] test_stim_data_in;
  logic [medge_lp-1:0][ts_width_lp-1:0] test_stim_ts_in;
  logic [medge_lp-1:0] test_stim_valid_in;
  logic [medge_lp-1:0] test_stim_ready_out;

  for(i=0; i<medge_lp; i=i+1)
  begin
    bsg_fifo_1r1w_small #( .width_p(width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) fifo_proc_in
                         ( .clk_i  (clk)
                          ,.reset_i(reset)

                          ,.data_i (test_stim_data_in[i])
                          ,.v_i    (test_stim_valid_in[i])
                          ,.ready_o(test_stim_ready_out[i])

                          ,.data_o(test_input_data[i][P])
                          ,.v_o   (test_input_valid[i][P])
                          ,.yumi_i(test_output_yumi[i][P])
                         );

    bsg_fifo_1r1w_small #( .width_p(ts_width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) ts_fifo_proc_in
                         ( .clk_i  (clk)
                          ,.reset_i(reset)

                          ,.data_i (test_stim_ts_in[i])
                          ,.v_i    (test_stim_valid_in[i])
                          ,.ready_o(test_stim_ready_out[i])

                          ,.data_o(test_input_ts[i][P])
                          ,.v_o   (test_input_valid[i][P])
                          ,.yumi_i(test_output_yumi[i][P])
                         );
  end

  for(i=medge_lp; i<msize_lp; i=i+1)
  begin
    bsg_fifo_1r1w_small #( .width_p(width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) fifo_proc_in
                         ( .clk_i  (clk)
                          ,.reset_i(reset)

                          ,.data_i (0)
                          ,.v_i    (0)

                          ,.yumi_i(0)
                         );

    bsg_fifo_1r1w_small #( .width_p(ts_width_lp)
                          ,.els_p  (msize_lp)
                          ,.ready_THEN_valid_p(0)
                         ) ts_fifo_proc_in
                         ( .clk_i  (clk)
                          ,.reset_i(reset)

                          ,.data_i (0)
                          ,.v_i    (0)

                          ,.yumi_i(0)
                         );
  end




  /**************************************************
  * Test stimuli
  ***************************************************/
  
  logic [ts_width_lp-1:0] global_ts;
  logic finish;
  
  for(i=0; i<medge_lp; i=i+1)
    begin
      assign test_input_ready[i][P]  = 1'b1;
      // Send data to the first router.
      assign test_stim_data_in[i]  = {(lg_node_x_lp)'(i)
                                      ,global_ts
                                      ,(lg_node_x_lp+lg_node_y_lp)'(0)
                                      };
      assign test_stim_ts_in[i] = global_ts;
      assign test_stim_valid_in[i] = !finish;
    end

  always_ff @(posedge clk)
    begin
      global_ts <= global_ts + 1;
      if (reset)
        global_ts <= 0;
    end


  /**************************************************
  * Verification
  ***************************************************/

  for(i=0; i<msize_lp; i=i+1)
    always_ff @(posedge clk)
    begin
      if(reset)
          finish <= 1'b0;
      else
        if(test_output_valid[i][P] & !finish)
          begin
            $display(  "tile # %0d receiving packet from # %0d after %d cycles (global_ts = %d)."
                     , i, test_output_data[i][P][(width_lp - 1):(width_lp - lg_node_x_lp)]
                     , global_ts - test_output_data[i][P][(width_lp - lg_node_x_lp - 1):(width_lp - lg_node_x_lp - ts_width_lp)], global_ts
                    );

            assert(test_output_data[i][P][0+:(lg_node_x_lp+lg_node_y_lp)] == i)
              else $error("received at tile: %0d, should go to tile: %0d"
                          ,i
                          ,test_output_data[i][P][0+:(lg_node_x_lp+lg_node_y_lp)]
                         );

            // If received from last router, we're done.
            if(test_output_data[i][P][(width_lp - 1):(width_lp - lg_node_x_lp)] == (medge_lp - 1))
              finish <= 1'b1;
          end

      if (finish)
          begin
            $display("============================================================");
            $finish;
          end
    end
endmodule
