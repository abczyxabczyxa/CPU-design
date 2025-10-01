module tlb
#(
    parameter TLBNUM =16
)
 (
    input wire clk,

    //  search ports0(for fetch)
    input wire [18:0]  s0_vppn,            //虚拟访存地址�???31....13�???
    input wire s0_va_bit12,                //虚拟访存地址的第12位
    input wire [9:0] s0_asid,              //  CSR的ASID域，用于多线程比较
    output wire   s0_found,                //用于判断重填异常，页无效异常，特权等级不合规异常，页修改异常
    output wire  [$clog2(TLBNUM)-1:0] s0_index,         // 用于TLBSRCH指令，查找在第几项         
    output wire  [19:0] s0_ppn,                //用于产生物理地址
    output wire  [5:0] s0_ps,                  //用于产生物理地址
    output wire  [1:0] s0_plv,                 //用于判断特权等级不合规异常
    output wire  [1:0] s0_mat,                 
    output wire  s0_d,                          //用于判断页修改异常
    output wire s0_v,                           //用于判断页无效异常，页修改异常

    //  search ports1(for load/store)
    input wire [18:0]  s1_vppn,            //虚拟访存地址�???31....13�???
    input wire s1_va_bit12,                //虚拟访存地址的第12位
    input wire [9:0] s1_asid,              //  CSR的ASID域，用于多线程比较
    output wire   s1_found,                //用于判断重填异常，页无效异常，特权等级不合规异常，页修改异常
    output wire  [$clog2(TLBNUM)-1:0] s1_index,       // 用于TLBSRCH指令，查找在第几项       
    output wire  [19:0] s1_ppn,                //用于产生物理地址
    output wire  [5:0] s1_ps,                  //用于产生物理地址
    output wire  [1:0] s1_plv,                 //用于判断特权等级不合规异常
    output wire  [1:0] s1_mat,                 
    output wire  s1_d,                          //用于判断页修改异常
    output wire s1_v,                           //用于判断页无效异常，页修改异常

    //    search ports3(for tlbsrch)
    input wire [18:0] s2_vppn,
    input wire [9:0] s2_asid,
    output wire s2_found,
    output wire [$clog2(TLBNUM)-1:0] s2_index,

    //write port
    input wire    we,                           //写使能
    input wire   [$clog2(TLBNUM)-1:0] w_index,       //写的地址    
    input wire  w_e,                               //写数据
    input wire  [18:0]w_vppn,                      //要写的虚双页
    input wire  [5:0] w_ps,                       //要写的PS
    input wire  [9:0] w_asid,                     // 要写的ASID
    input wire  w_g,                             //要写的G
    input wire  [19:0] w_ppn0,                  //要写的ppn0
    input wire  [1:0] w_plv0,                     //要写的plv0
    input wire  [1:0] w_mat0,                     //要写的mat0
    input wire  w_d0,                           //要写的d0
    input wire  w_v0,                             //要写的v0
    input wire  [19:0] w_ppn1,                   //要写的ppn1
    input wire [1:0] w_plv1,                     //要写的plv1
    input wire  [1:0] w_mat1,                    //要写的mat1
    input wire  w_d1,                            //要写的d1
    input wire  w_v1,                            //要写的v1

    //read port
    input wire   [$clog2(TLBNUM)-1:0] r_index,       //读的地址    
    output wire  r_e,                               //读数据的e
    output wire  [18:0]r_vppn,                      //要读的虚双页
    output wire  [5:0] r_ps,                       //要读的PS
    output wire  [9:0] r_asid,                     // 要读的ASID
    output wire  r_g,                             //要读的G
    output wire  [19:0] r_ppn0,                  //要读的ppn0
    output wire  [1:0] r_plv0,                     //要读的plv0
    output wire  [1:0] r_mat0,                     //要读的mat0
    output wire  r_d0,                           //要读的d0
    output wire  r_v0,                             //要读的v0
    output wire  [19:0] r_ppn1,                   //要读的ppn1
    output wire [1:0] r_plv1,                     //要读的plv1
    output wire  [1:0] r_mat1,                    //要读的mat1
    output wire  r_d1,                            //要读的d1
    output wire  r_v1,                            //要读的v1

    // invtlb opcode
    input wire invtlb_valid,                     //用于Invtlb指令
    input wire [4:0] invtlb_op                 //Invtlb指令的操作码
);

    reg  [TLBNUM-1:0]tlb_e ;
    reg [TLBNUM-1:0] tlb_ps4MB;       // 1:4MB     0:4KB
    reg [18:0] tlb_vppn [TLBNUM-1:0];
    reg [9:0] tlb_asid [TLBNUM-1:0];
    reg tlb_g [TLBNUM-1:0];
    reg [19:0] tlb_ppn0 [TLBNUM-1:0];
    reg [1:0] tlb_plv0 [TLBNUM-1:0];
    reg [1:0] tlb_mat0 [TLBNUM-1:0];
    reg tlb_d0 [TLBNUM-1:0];
    reg tlb_v0 [TLBNUM-1:0];
    reg [19:0] tlb_ppn1 [TLBNUM-1:0];
    reg [1:0] tlb_plv1 [TLBNUM-1:0];
    reg [1:0] tlb_mat1 [TLBNUM-1:0];
    reg tlb_d1 [TLBNUM-1:0];
    reg tlb_v1 [TLBNUM-1:0];

    //查找操作
    wire [15:0] match0;
    wire [15:0] match1;
    wire [15:0] match2;

    
    assign match0[0] = (s0_vppn[18:9]==tlb_vppn[0][18:9]) &&
                        (tlb_ps4MB[0] || s0_vppn[8:0]==tlb_vppn[0][8:0]) &&
                        ((s0_asid==tlb_asid[0]) || tlb_g[0]) &&
                        tlb_e[0];
    assign match0[1] = (s0_vppn[18:9]==tlb_vppn[1][18:9]) &&
                        (tlb_ps4MB[1] || s0_vppn[8:0]==tlb_vppn[1][8:0]) &&
                        ((s0_asid==tlb_asid[1]) || tlb_g[1]) &&
                        tlb_e[1];
    assign match0[2] = (s0_vppn[18:9]==tlb_vppn[2][18:9]) &&
                        (tlb_ps4MB[2] || s0_vppn[8:0]==tlb_vppn[2][8:0]) &&
                        ((s0_asid==tlb_asid[2]) || tlb_g[2]) &&
                        tlb_e[2];
    assign match0[3] = (s0_vppn[18:9]==tlb_vppn[3][18:9]) &&
                        (tlb_ps4MB[3] || s0_vppn[8:0]==tlb_vppn[3][8:0]) &&
                        ((s0_asid==tlb_asid[3]) || tlb_g[3]) &&
                        tlb_e[3];
    assign match0[4] = (s0_vppn[18:9]==tlb_vppn[4][18:9]) &&
                        (tlb_ps4MB[4] || s0_vppn[8:0]==tlb_vppn[4][8:0]) &&
                        ((s0_asid==tlb_asid[4]) || tlb_g[4]) &&
                        tlb_e[4];
    assign match0[5] = (s0_vppn[18:9]==tlb_vppn[5][18:9]) &&
                        (tlb_ps4MB[5] || s0_vppn[8:0]==tlb_vppn[5][8:0]) &&
                        ((s0_asid==tlb_asid[5]) || tlb_g[5]) &&
                        tlb_e[5];
    assign match0[6] = (s0_vppn[18:9]==tlb_vppn[6][18:9]) &&
                        (tlb_ps4MB[6] || s0_vppn[8:0]==tlb_vppn[6][8:0]) &&
                        ((s0_asid==tlb_asid[6]) || tlb_g[6]) &&
                        tlb_e[6];
    assign match0[7] = (s0_vppn[18:9]==tlb_vppn[7][18:9]) &&
                        (tlb_ps4MB[7] || s0_vppn[8:0]==tlb_vppn[7][8:0]) &&
                        ((s0_asid==tlb_asid[7]) || tlb_g[7]) &&
                        tlb_e[7];
    assign match0[8] = (s0_vppn[18:9]==tlb_vppn[8][18:9]) &&
                        (tlb_ps4MB[8] || s0_vppn[8:0]==tlb_vppn[8][8:0]) &&
                        ((s0_asid==tlb_asid[8]) || tlb_g[8]) &&
                        tlb_e[8];
    assign match0[9] = (s0_vppn[18:9]==tlb_vppn[9][18:9]) &&
                        (tlb_ps4MB[9] || s0_vppn[8:0]==tlb_vppn[9][8:0]) &&
                        ((s0_asid==tlb_asid[9]) || tlb_g[9]) &&
                        tlb_e[9];
    assign match0[10] = (s0_vppn[18:9]==tlb_vppn[10][18:9]) &&
                        (tlb_ps4MB[10] || s0_vppn[8:0]==tlb_vppn[10][8:0]) &&
                        ((s0_asid==tlb_asid[10]) || tlb_g[10]) &&
                        tlb_e[10];
    assign match0[11] = (s0_vppn[18:9]==tlb_vppn[11][18:9]) &&
                        (tlb_ps4MB[11] || s0_vppn[8:0]==tlb_vppn[11][8:0]) &&
                        ((s0_asid==tlb_asid[11]) || tlb_g[11]) &&
                        tlb_e[11];
    assign match0[12] = (s0_vppn[18:9]==tlb_vppn[12][18:9]) &&
                        (tlb_ps4MB[12] || s0_vppn[8:0]==tlb_vppn[12][8:0]) &&
                        ((s0_asid==tlb_asid[12]) || tlb_g[12]) &&
                        tlb_e[12];
    assign match0[13] = (s0_vppn[18:9]==tlb_vppn[13][18:9]) &&
                        (tlb_ps4MB[13] || s0_vppn[8:0]==tlb_vppn[13][8:0]) &&
                        ((s0_asid==tlb_asid[13]) || tlb_g[13]) &&
                        tlb_e[13];
    assign match0[14] = (s0_vppn[18:9]==tlb_vppn[14][18:9]) &&
                        (tlb_ps4MB[14] || s0_vppn[8:0]==tlb_vppn[14][8:0]) &&
                        ((s0_asid==tlb_asid[14]) || tlb_g[14]) &&
                        tlb_e[14];
    assign match0[15] = (s0_vppn[18:9]==tlb_vppn[15][18:9]) &&
                        (tlb_ps4MB[15] || s0_vppn[8:0]==tlb_vppn[15][8:0]) &&
                        ((s0_asid==tlb_asid[15]) || tlb_g[15]) &&
                        tlb_e[15];
    assign match1[0] = (s1_vppn[18:9]==tlb_vppn[0][18:9]) &&
                        (tlb_ps4MB[0] || s1_vppn[8:0]==tlb_vppn[0][8:0]) &&
                        ((s1_asid==tlb_asid[0]) || tlb_g[0]) &&
                        tlb_e[0];
    assign match1[1] = (s1_vppn[18:9]==tlb_vppn[1][18:9]) &&
                        (tlb_ps4MB[1] || s1_vppn[8:0]==tlb_vppn[1][8:0]) &&
                        ((s1_asid==tlb_asid[1]) || tlb_g[1]) &&
                        tlb_e[1];
    assign match1[2] = (s1_vppn[18:9]==tlb_vppn[2][18:9]) &&
                        (tlb_ps4MB[2] || s1_vppn[8:0]==tlb_vppn[2][8:0]) &&
                        ((s1_asid==tlb_asid[2]) || tlb_g[2]) &&
                        tlb_e[2];
    assign match1[3] = (s1_vppn[18:9]==tlb_vppn[3][18:9]) &&
                        (tlb_ps4MB[3] || s1_vppn[8:0]==tlb_vppn[3][8:0]) &&
                        ((s1_asid==tlb_asid[3]) || tlb_g[3]) &&
                        tlb_e[3];
    assign match1[4] = (s1_vppn[18:9]==tlb_vppn[4][18:9]) &&
                        (tlb_ps4MB[4] || s1_vppn[8:0]==tlb_vppn[4][8:0]) &&
                        ((s1_asid==tlb_asid[4]) || tlb_g[4]) &&
                        tlb_e[4];
    assign match1[5] = (s1_vppn[18:9]==tlb_vppn[5][18:9]) &&
                        (tlb_ps4MB[5] || s1_vppn[8:0]==tlb_vppn[5][8:0]) &&
                        ((s1_asid==tlb_asid[5]) || tlb_g[5]) &&
                        tlb_e[5];
    assign match1[6] = (s1_vppn[18:9]==tlb_vppn[6][18:9]) &&
                        (tlb_ps4MB[6] || s1_vppn[8:0]==tlb_vppn[6][8:0]) &&
                        ((s1_asid==tlb_asid[6]) || tlb_g[6]) &&
                        tlb_e[6];
    assign match1[7] = (s1_vppn[18:9]==tlb_vppn[7][18:9]) &&
                        (tlb_ps4MB[7] || s1_vppn[8:0]==tlb_vppn[7][8:0]) &&
                        ((s1_asid==tlb_asid[7]) || tlb_g[7]) &&
                        tlb_e[7];
    assign match1[8] = (s1_vppn[18:9]==tlb_vppn[8][18:9]) &&
                        (tlb_ps4MB[8] || s1_vppn[8:0]==tlb_vppn[8][8:0]) &&
                        ((s1_asid==tlb_asid[8]) || tlb_g[8]) &&
                        tlb_e[8];
    assign match1[9] = (s1_vppn[18:9]==tlb_vppn[9][18:9]) &&
                        (tlb_ps4MB[9] || s1_vppn[8:0]==tlb_vppn[9][8:0]) &&
                        ((s1_asid==tlb_asid[9]) || tlb_g[9]) &&
                        tlb_e[9];
    assign match1[10] = (s1_vppn[18:9]==tlb_vppn[10][18:9]) &&
                        (tlb_ps4MB[10] || s1_vppn[8:0]==tlb_vppn[10][8:0]) &&
                        ((s1_asid==tlb_asid[10]) || tlb_g[10]) &&
                        tlb_e[10];
    assign match1[11] = (s1_vppn[18:9]==tlb_vppn[11][18:9]) &&
                        (tlb_ps4MB[11] || s1_vppn[8:0]==tlb_vppn[11][8:0]) &&
                        ((s1_asid==tlb_asid[11]) || tlb_g[11]) &&
                        tlb_e[11];
    assign match1[12] = (s1_vppn[18:9]==tlb_vppn[12][18:9]) &&
                        (tlb_ps4MB[12] || s1_vppn[8:0]==tlb_vppn[12][8:0]) &&
                        ((s1_asid==tlb_asid[12]) || tlb_g[12]) &&
                        tlb_e[12];
    assign match1[13] = (s1_vppn[18:9]==tlb_vppn[13][18:9]) &&
                        (tlb_ps4MB[13] || s1_vppn[8:0]==tlb_vppn[13][8:0]) &&
                        ((s1_asid==tlb_asid[13]) || tlb_g[13]) &&
                        tlb_e[13];
    assign match1[14] = (s1_vppn[18:9]==tlb_vppn[14][18:9]) &&
                        (tlb_ps4MB[14] || s1_vppn[8:0]==tlb_vppn[14][8:0]) &&
                        ((s1_asid==tlb_asid[14]) || tlb_g[14]) &&
                        tlb_e[14];
    assign match1[15] = (s1_vppn[18:9]==tlb_vppn[15][18:9]) &&
                        (tlb_ps4MB[15] || s1_vppn[8:0]==tlb_vppn[15][8:0]) &&
                        ((s1_asid==tlb_asid[15]) || tlb_g[15]) &&
                        tlb_e[15];

    assign match2[0] = (s2_vppn[18:9]==tlb_vppn[0][18:9]) &&
                        (tlb_ps4MB[0] || s2_vppn[8:0]==tlb_vppn[0][8:0]) &&
                        ((s2_asid==tlb_asid[0]) || tlb_g[0]) &&
                        tlb_e[0];
    assign match2[1] = (s2_vppn[18:9]==tlb_vppn[1][18:9]) &&
                        (tlb_ps4MB[1] || s2_vppn[8:0]==tlb_vppn[1][8:0]) &&
                        ((s2_asid==tlb_asid[1]) || tlb_g[1]) &&
                        tlb_e[1];
    assign match2[2] = (s2_vppn[18:9]==tlb_vppn[2][18:9]) &&
                        (tlb_ps4MB[2] || s2_vppn[8:0]==tlb_vppn[2][8:0]) &&
                        ((s2_asid==tlb_asid[2]) || tlb_g[2]) &&
                        tlb_e[2];
    assign match2[3] = (s2_vppn[18:9]==tlb_vppn[3][18:9]) &&
                        (tlb_ps4MB[3] || s2_vppn[8:0]==tlb_vppn[3][8:0]) &&
                        ((s2_asid==tlb_asid[3]) || tlb_g[3]) &&
                        tlb_e[3];
    assign match2[4] = (s2_vppn[18:9]==tlb_vppn[4][18:9]) &&
                        (tlb_ps4MB[4] || s2_vppn[8:0]==tlb_vppn[4][8:0]) &&
                        ((s2_asid==tlb_asid[4]) || tlb_g[4]) &&
                        tlb_e[4];
    assign match2[5] = (s2_vppn[18:9]==tlb_vppn[5][18:9]) &&
                        (tlb_ps4MB[5] || s2_vppn[8:0]==tlb_vppn[5][8:0]) &&
                        ((s2_asid==tlb_asid[5]) || tlb_g[5]) &&
                        tlb_e[5];
    assign match2[6] = (s2_vppn[18:9]==tlb_vppn[6][18:9]) &&
                        (tlb_ps4MB[6] || s2_vppn[8:0]==tlb_vppn[6][8:0]) &&
                        ((s2_asid==tlb_asid[6]) || tlb_g[6]) &&
                        tlb_e[6];
    assign match2[7] = (s2_vppn[18:9]==tlb_vppn[7][18:9]) &&
                        (tlb_ps4MB[7] || s2_vppn[8:0]==tlb_vppn[7][8:0]) &&
                        ((s2_asid==tlb_asid[7]) || tlb_g[7]) &&
                        tlb_e[7];
    assign match2[8] = (s2_vppn[18:9]==tlb_vppn[8][18:9]) &&
                        (tlb_ps4MB[8] || s2_vppn[8:0]==tlb_vppn[8][8:0]) &&
                        ((s2_asid==tlb_asid[8]) || tlb_g[8]) &&
                        tlb_e[8];
    assign match2[9] = (s2_vppn[18:9]==tlb_vppn[9][18:9]) &&
                        (tlb_ps4MB[9] || s2_vppn[8:0]==tlb_vppn[9][8:0]) &&
                        ((s2_asid==tlb_asid[9]) || tlb_g[9]) &&
                        tlb_e[9];
    assign match2[10] = (s2_vppn[18:9]==tlb_vppn[10][18:9]) &&
                        (tlb_ps4MB[10] || s2_vppn[8:0]==tlb_vppn[10][8:0]) &&
                        ((s2_asid==tlb_asid[10]) || tlb_g[10]) &&
                        tlb_e[10];
    assign match2[11] = (s2_vppn[18:9]==tlb_vppn[11][18:9]) &&
                        (tlb_ps4MB[11] || s2_vppn[8:0]==tlb_vppn[11][8:0]) &&
                        ((s2_asid==tlb_asid[11]) || tlb_g[11]) &&
                        tlb_e[11];
    assign match2[12] = (s2_vppn[18:9]==tlb_vppn[12][18:9]) &&
                        (tlb_ps4MB[12] || s2_vppn[8:0]==tlb_vppn[12][8:0]) &&
                        ((s2_asid==tlb_asid[12]) || tlb_g[12]) &&
                        tlb_e[12];
    assign match2[13] = (s2_vppn[18:9]==tlb_vppn[13][18:9]) &&
                        (tlb_ps4MB[13] || s2_vppn[8:0]==tlb_vppn[13][8:0]) &&
                        ((s2_asid==tlb_asid[13]) || tlb_g[13]) &&
                        tlb_e[13];
    assign match2[14] = (s2_vppn[18:9]==tlb_vppn[14][18:9]) &&
                        (tlb_ps4MB[14] || s2_vppn[8:0]==tlb_vppn[14][8:0]) &&
                        ((s2_asid==tlb_asid[14]) || tlb_g[14]) &&
                        tlb_e[14];
    assign match2[15] = (s2_vppn[18:9]==tlb_vppn[15][18:9]) &&
                        (tlb_ps4MB[15] || s2_vppn[8:0]==tlb_vppn[15][8:0]) &&
                        ((s2_asid==tlb_asid[15]) || tlb_g[15]) &&
                        tlb_e[15];
    
    
    assign s0_found = (match0 != 16'b0);
    assign s1_found = (match1 != 16'b0);
    assign s2_found = (match2 != 16'b0);
    assign s0_index =  match0[0] ?  4'd0: 
                match0[1] ?  4'd1:
                match0[2] ?  4'd2:
                match0[3] ?  4'd3:
                match0[4] ?  4'd4: 
                match0[5] ?  4'd5:
                match0[6] ?  4'd6:
                match0[7] ?  4'd7:
                match0[8] ?  4'd8: 
                match0[9] ?  4'd9:
                match0[10] ?  4'd10:
                match0[11] ?  4'd11:
                match0[12] ?  4'd12: 
                match0[13] ?  4'd13:
                match0[14] ?  4'd14:
                match0[15] ?  4'd15: 4'dx;
    assign s1_index =  match1[0] ?  4'd0: 
                match1[1] ?  4'd1:
                match1[2] ?  4'd2:
                match1[3] ?  4'd3:
                match1[4] ?  4'd4: 
                match1[5] ?  4'd5:
                match1[6] ?  4'd6:
                match1[7] ?  4'd7:
                match1[8] ?  4'd8: 
                match1[9] ?  4'd9:
                match1[10] ?  4'd10:
                match1[11] ?  4'd11:
                match1[12] ?  4'd12: 
                match1[13] ?  4'd13:
                match1[14] ?  4'd14:
                match1[15] ?  4'd15: 4'dx;
    assign s2_index =  match2[0] ?  4'd0: 
                match2[1] ?  4'd1:
                match2[2] ?  4'd2:
                match2[3] ?  4'd3:
                match2[4] ?  4'd4: 
                match2[5] ?  4'd5:
                match2[6] ?  4'd6:
                match2[7] ?  4'd7:
                match2[8] ?  4'd8: 
                match2[9] ?  4'd9:
                match2[10] ?  4'd10:
                match2[11] ?  4'd11:
                match2[12] ?  4'd12: 
                match2[13] ?  4'd13:
                match2[14] ?  4'd14:
                match2[15] ?  4'd15: 4'dx;
    assign s0_ppn = s0_va_bit12 ? tlb_ppn1[s0_index] :  tlb_ppn0[s0_index];
    assign s1_ppn = s1_va_bit12 ? tlb_ppn1[s1_index] :  tlb_ppn0[s1_index];
    assign s0_ps  = tlb_ps4MB[s0_index] ?  6'd21 : 6'd12;
    assign s1_ps  = tlb_ps4MB[s1_index] ?  6'd21:  6'd12;
    assign s0_plv = s0_va_bit12 ? tlb_plv1[s0_index] : tlb_plv0[s0_index];
    assign s1_plv = s1_va_bit12 ? tlb_plv1[s1_index] : tlb_plv0[s1_index];
    assign s0_mat = s0_va_bit12 ? tlb_mat1[s0_index] : tlb_mat0[s0_index];
    assign s1_mat = s1_va_bit12 ? tlb_mat1[s1_index] : tlb_mat0[s1_index];
    assign s0_d   = s0_va_bit12 ? tlb_d1[s0_index]   : tlb_d0[s0_index];
    assign s1_d   = s1_va_bit12 ? tlb_d1[s1_index]   : tlb_d0[s1_index];
    assign s0_v   = s0_va_bit12 ? tlb_v1[s0_index]   : tlb_v0[s0_index];
    assign s1_v   = s1_va_bit12 ? tlb_v1[s1_index]   : tlb_v0[s1_index];

     //写操作
     always @(posedge clk)
     begin
        if(we)
        begin
        tlb_vppn [w_index] <= w_vppn;
        tlb_asid [w_index] <= w_asid;
        tlb_g    [w_index] <= w_g; 
        tlb_ps4MB   [w_index] <= w_ps[0];  
        tlb_ppn0 [w_index] <= w_ppn0;
        tlb_plv0 [w_index] <= w_plv0;
        tlb_mat0 [w_index] <= w_mat0;
        tlb_d0   [w_index] <= w_d0;
        tlb_v0   [w_index] <= w_v0; 
        tlb_ppn1 [w_index] <= w_ppn1;
        tlb_plv1 [w_index] <= w_plv1;
        tlb_mat1 [w_index] <= w_mat1;
        tlb_d1   [w_index] <= w_d1;
        tlb_v1   [w_index] <= w_v1; 
        end
     end

     //读操作
    assign r_vppn  =  tlb_vppn [r_index]; 
    assign r_asid  =  tlb_asid [r_index]; 
    assign r_g     =  tlb_g    [r_index]; 
    assign r_ps    =  tlb_ps4MB[r_index] ? 6'd21 : 6'd12; 
    assign r_e     =  tlb_e    [r_index]; 
    assign r_v0    =  tlb_v0   [r_index]; 
    assign r_d0    =  tlb_d0   [r_index]; 
    assign r_mat0  =  tlb_mat0 [r_index]; 
    assign r_plv0  =  tlb_plv0 [r_index]; 
    assign r_ppn0  =  tlb_ppn0 [r_index]; 
    assign r_v1    =  tlb_v1   [r_index]; 
    assign r_d1    =  tlb_d1   [r_index]; 
    assign r_mat1  =  tlb_mat1 [r_index]; 
    assign r_plv1  =  tlb_plv1 [r_index]; 
    assign r_ppn1  =  tlb_ppn1 [r_index]; 

    // INVTLB 指令相关的操作
    always @(posedge clk)
    begin
        if(we)
        begin
            tlb_e[w_index]  <=w_e;
        end
        else if(invtlb_valid)
        begin
            case (invtlb_op)
                5'd0   :    begin
                    tlb_e <= 16'b0;
                end
                5'd1   :begin
                    tlb_e <= 16'b0;
                end
                5'd2   :begin
                    tlb_e[0]  <= tlb_g[0]  ? 1'b0 : tlb_e[0];
                    tlb_e[1]  <= tlb_g[1]  ? 1'b0 : tlb_e[1];
                    tlb_e[2]  <= tlb_g[2]  ? 1'b0 : tlb_e[2];
                    tlb_e[3]  <= tlb_g[3]  ? 1'b0 : tlb_e[3];
                    tlb_e[4]  <= tlb_g[4]  ? 1'b0 : tlb_e[4];
                    tlb_e[5]  <= tlb_g[5]  ? 1'b0 : tlb_e[5];
                    tlb_e[6]  <= tlb_g[6]  ? 1'b0 : tlb_e[6];
                    tlb_e[7]  <= tlb_g[7]  ? 1'b0 : tlb_e[7];
                    tlb_e[8]  <= tlb_g[8]  ? 1'b0 : tlb_e[8];
                    tlb_e[9]  <= tlb_g[9]  ? 1'b0 : tlb_e[9];
                    tlb_e[10] <= tlb_g[10] ? 1'b0 : tlb_e[10];
                    tlb_e[11] <= tlb_g[11] ? 1'b0 : tlb_e[11];
                    tlb_e[12] <= tlb_g[12] ? 1'b0 : tlb_e[12];
                    tlb_e[13] <= tlb_g[13] ? 1'b0 : tlb_e[13];
                    tlb_e[14] <= tlb_g[14] ? 1'b0 : tlb_e[14];
                    tlb_e[15] <= tlb_g[15] ? 1'b0 : tlb_e[15];
                end
                5'd3   :begin
                    tlb_e[0] <= (tlb_e[0] & tlb_g[0]);
                    tlb_e[1] <= (tlb_e[1] & tlb_g[1]);
                    tlb_e[2] <= (tlb_e[2] & tlb_g[2]);
                    tlb_e[3] <= (tlb_e[3] & tlb_g[3]);
                    tlb_e[4] <= (tlb_e[4] & tlb_g[4]);
                    tlb_e[5] <= (tlb_e[5] & tlb_g[5]);
                    tlb_e[6] <= (tlb_e[6] & tlb_g[6]);
                    tlb_e[7] <= (tlb_e[7] & tlb_g[7]);
                    tlb_e[8] <= (tlb_e[8] & tlb_g[8]);
                    tlb_e[9] <= (tlb_e[9] & tlb_g[9]);
                    tlb_e[10] <= (tlb_e[10] & tlb_g[10]);
                    tlb_e[11] <= (tlb_e[11] & tlb_g[11]);
                    tlb_e[12] <= (tlb_e[12] & tlb_g[12]);
                    tlb_e[13] <= (tlb_e[13] & tlb_g[13]);
                    tlb_e[14] <= (tlb_e[14] & tlb_g[14]);
                    tlb_e[15] <= (tlb_e[15] & tlb_g[15]);
                end
                5'd4   :begin
                    tlb_e[0]  <= (tlb_g[0]  == 0 && s2_asid == tlb_asid[0])  ? 1'b0 : tlb_e[0];
                    tlb_e[1]  <= (tlb_g[1]  == 0 && s2_asid == tlb_asid[1])  ? 1'b0 : tlb_e[1];
                    tlb_e[2]  <= (tlb_g[2]  == 0 && s2_asid == tlb_asid[2])  ? 1'b0 : tlb_e[2];
                    tlb_e[3]  <= (tlb_g[3]  == 0 && s2_asid == tlb_asid[3])  ? 1'b0 : tlb_e[3];
                    tlb_e[4]  <= (tlb_g[4]  == 0 && s2_asid == tlb_asid[4])  ? 1'b0 : tlb_e[4];
                    tlb_e[5]  <= (tlb_g[5]  == 0 && s2_asid == tlb_asid[5])  ? 1'b0 : tlb_e[5];
                    tlb_e[6]  <= (tlb_g[6]  == 0 && s2_asid == tlb_asid[6])  ? 1'b0 : tlb_e[6];
                    tlb_e[7]  <= (tlb_g[7]  == 0 && s2_asid == tlb_asid[7])  ? 1'b0 : tlb_e[7];
                    tlb_e[8]  <= (tlb_g[8]  == 0 && s2_asid == tlb_asid[8])  ? 1'b0 : tlb_e[8];
                    tlb_e[9]  <= (tlb_g[9]  == 0 && s2_asid == tlb_asid[9])  ? 1'b0 : tlb_e[9];
                    tlb_e[10] <= (tlb_g[10] == 0 && s2_asid == tlb_asid[10]) ? 1'b0 : tlb_e[10];
                    tlb_e[11] <= (tlb_g[11] == 0 && s2_asid == tlb_asid[11]) ? 1'b0 : tlb_e[11];
                    tlb_e[12] <= (tlb_g[12] == 0 && s2_asid == tlb_asid[12]) ? 1'b0 : tlb_e[12];
                    tlb_e[13] <= (tlb_g[13] == 0 && s2_asid == tlb_asid[13]) ? 1'b0 : tlb_e[13];
                    tlb_e[14] <= (tlb_g[14] == 0 && s2_asid == tlb_asid[14]) ? 1'b0 : tlb_e[14];
                    tlb_e[15] <= (tlb_g[15] == 0 && s2_asid == tlb_asid[15]) ? 1'b0 : tlb_e[15];
                end
                5'd5   :begin
                    tlb_e[0]  <= (tlb_g[0]  == 0 && s2_asid == tlb_asid[0]  && s2_vppn == tlb_vppn[0])  ? 1'b0 : tlb_e[0];
                    tlb_e[1]  <= (tlb_g[1]  == 0 && s2_asid == tlb_asid[1]  && s2_vppn == tlb_vppn[1])  ? 1'b0 : tlb_e[1];
                    tlb_e[2]  <= (tlb_g[2]  == 0 && s2_asid == tlb_asid[2]  && s2_vppn == tlb_vppn[2])  ? 1'b0 : tlb_e[2];
                    tlb_e[3]  <= (tlb_g[3]  == 0 && s2_asid == tlb_asid[3]  && s2_vppn == tlb_vppn[3])  ? 1'b0 : tlb_e[3];
                    tlb_e[4]  <= (tlb_g[4]  == 0 && s2_asid == tlb_asid[4]  && s2_vppn == tlb_vppn[4])  ? 1'b0 : tlb_e[4];
                    tlb_e[5]  <= (tlb_g[5]  == 0 && s2_asid == tlb_asid[5]  && s2_vppn == tlb_vppn[5])  ? 1'b0 : tlb_e[5];
                    tlb_e[6]  <= (tlb_g[6]  == 0 && s2_asid == tlb_asid[6]  && s2_vppn == tlb_vppn[6])  ? 1'b0 : tlb_e[6];
                    tlb_e[7]  <= (tlb_g[7]  == 0 && s2_asid == tlb_asid[7]  && s2_vppn == tlb_vppn[7])  ? 1'b0 : tlb_e[7];
                    tlb_e[8]  <= (tlb_g[8]  == 0 && s2_asid == tlb_asid[8]  && s2_vppn == tlb_vppn[8])  ? 1'b0 : tlb_e[8];
                    tlb_e[9]  <= (tlb_g[9]  == 0 && s2_asid == tlb_asid[9]  && s2_vppn == tlb_vppn[9])  ? 1'b0 : tlb_e[9];
                    tlb_e[10] <= (tlb_g[10] == 0 && s2_asid == tlb_asid[10] && s2_vppn == tlb_vppn[10]) ? 1'b0 : tlb_e[10];
                    tlb_e[11] <= (tlb_g[11] == 0 && s2_asid == tlb_asid[11] && s2_vppn == tlb_vppn[11]) ? 1'b0 : tlb_e[11];
                    tlb_e[12] <= (tlb_g[12] == 0 && s2_asid == tlb_asid[12] && s2_vppn == tlb_vppn[12]) ? 1'b0 : tlb_e[12];
                    tlb_e[13] <= (tlb_g[13] == 0 && s2_asid == tlb_asid[13] && s2_vppn == tlb_vppn[13]) ? 1'b0 : tlb_e[13];
                    tlb_e[14] <= (tlb_g[14] == 0 && s2_asid == tlb_asid[14] && s2_vppn == tlb_vppn[14]) ? 1'b0 : tlb_e[14];
                    tlb_e[15] <= (tlb_g[15] == 0 && s2_asid == tlb_asid[15] && s2_vppn == tlb_vppn[15]) ? 1'b0 : tlb_e[15];
                end
                5'd6   :begin
                    tlb_e[0]  <= ((tlb_g[0]  == 1 || s2_asid == tlb_asid[0])  && s2_vppn == tlb_vppn[0])  ? 1'b0 : tlb_e[0];
                    tlb_e[1]  <= ((tlb_g[1]  == 1 || s2_asid == tlb_asid[1])  && s2_vppn == tlb_vppn[1])  ? 1'b0 : tlb_e[1];
                    tlb_e[2]  <= ((tlb_g[2]  == 1 || s2_asid == tlb_asid[2])  && s2_vppn == tlb_vppn[2])  ? 1'b0 : tlb_e[2];
                    tlb_e[3]  <= ((tlb_g[3]  == 1 || s2_asid == tlb_asid[3])  && s2_vppn == tlb_vppn[3])  ? 1'b0 : tlb_e[3];
                    tlb_e[4]  <= ((tlb_g[4]  == 1 || s2_asid == tlb_asid[4])  && s2_vppn == tlb_vppn[4])  ? 1'b0 : tlb_e[4];
                    tlb_e[5]  <= ((tlb_g[5]  == 1 || s2_asid == tlb_asid[5])  && s2_vppn == tlb_vppn[5])  ? 1'b0 : tlb_e[5];
                    tlb_e[6]  <= ((tlb_g[6]  == 1 || s2_asid == tlb_asid[6])  && s2_vppn == tlb_vppn[6])  ? 1'b0 : tlb_e[6];
                    tlb_e[7]  <= ((tlb_g[7]  == 1 || s2_asid == tlb_asid[7])  && s2_vppn == tlb_vppn[7])  ? 1'b0 : tlb_e[7];
                    tlb_e[8]  <= ((tlb_g[8]  == 1 || s2_asid == tlb_asid[8])  && s2_vppn == tlb_vppn[8])  ? 1'b0 : tlb_e[8];
                    tlb_e[9]  <= ((tlb_g[9]  == 1 || s2_asid == tlb_asid[9])  && s2_vppn == tlb_vppn[9])  ? 1'b0 : tlb_e[9];
                    tlb_e[10] <= ((tlb_g[10] == 1 || s2_asid == tlb_asid[10]) && s2_vppn == tlb_vppn[10]) ? 1'b0 : tlb_e[10];
                    tlb_e[11] <= ((tlb_g[11] == 1 || s2_asid == tlb_asid[11]) && s2_vppn == tlb_vppn[11]) ? 1'b0 : tlb_e[11];
                    tlb_e[12] <= ((tlb_g[12] == 1 || s2_asid == tlb_asid[12]) && s2_vppn == tlb_vppn[12]) ? 1'b0 : tlb_e[12];
                    tlb_e[13] <= ((tlb_g[13] == 1 || s2_asid == tlb_asid[13]) && s2_vppn == tlb_vppn[13]) ? 1'b0 : tlb_e[13];
                    tlb_e[14] <= ((tlb_g[14] == 1 || s2_asid == tlb_asid[14]) && s2_vppn == tlb_vppn[14]) ? 1'b0 : tlb_e[14];
                    tlb_e[15] <= ((tlb_g[15] == 1 || s2_asid == tlb_asid[15]) && s2_vppn == tlb_vppn[15]) ? 1'b0 : tlb_e[15];

                end
                default: 
                    tlb_e <= tlb_e;
            endcase

        end        
    end









endmodule