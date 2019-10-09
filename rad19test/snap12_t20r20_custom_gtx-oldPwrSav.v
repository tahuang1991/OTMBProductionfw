///////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version : 1.8
//  \   \         Application : Virtex-6 FPGA GTX Transceiver Wizard
//  /   /         Filename : snap12_t20r20_gtx.v
// /___/   /\     Timestamp :
// \   \  /  \ 
//  \___\/\___\
//
//
// Module SNAP12_T20R20_GTX (a GTX Wrapper)
// Generated by Xilinx Virtex-6 FPGA GTX Transceiver Wizard
// 

`timescale 1ns / 1ps

//
// New: ignore send_lim.  Ignore rxdv after the first one (continuous looping).
//   ignore check_ok and check_bad.
//
//   Add RX checking in here. Return only:  CheckOK, CheckBAD, rxdv, rxcomma, RstDone, TxClk?
//      Need to give:  PwrDown, UsrClk2, TxDat, TxKout, Reset, comma_align, gtx_wait, send_lim
//      Need internal additions to GTX:  rx_dat and counter/check logic, rxdv logic,
//  --> how many PwrDown bits are needed?  CHECK
//

//***************************** Entity Declaration ****************************

module SNAP12_T20R20_GTX #
(
    // Simulation attributes
    parameter   GTX_SIM_GTXRESET_SPEEDUP   =   0,      // Set to 1 to speed up sim reset
    
    // Share RX PLL parameter
    parameter   GTX_TX_CLK_SOURCE          =   "TXPLL",
    // Save power parameter
// old default
    parameter   GTX_POWER_SAVE             =   10'b0000000000
//    parameter   GTX_POWER_SAVE             =   10'b0000110000
)
(
    //---------------------- Loopback and Powerdown Ports ----------------------
    input   [1:0]   RXPOWERDOWN_IN,
    input   [1:0]   TXPOWERDOWN_IN,
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
//jg    output  [1:0]   RXCHARISCOMMA_OUT,
//jg    output  [1:0]   RXDISPERR_OUT,
//jg    output  [1:0]   RXNOTINTABLE_OUT,
    input gtx_wait,
    output rxdv, rxcomma, // my RxDV and Comma
    output reg check_ok, check_bad, good_byte, bad_byte, lost_byte,
    output reg [31:0] err_count,
    //----------------- Receive Ports - Clock Correction Ports -----------------
    output  [2:0]   RXCLKCORCNT_OUT,
    //------------- Receive Ports - Comma Detection and Alignment --------------
    output          RXBYTEREALIGN_OUT,
    output          RXCOMMADET_OUT,      //jg: useful?
    input           RXENMCOMMAALIGN_IN,
    input           RXENPCOMMAALIGN_IN,
    //----------------- Receive Ports - RX Data Path interface -----------------
    output  [15:0]  RXDATA_OUT,
    output  [1:0]   RXCHARISK_OUT,
    input           RXRESET_IN,
    input           RXUSRCLK2_IN,
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    input           RXCDRRESET_IN,
    input           RXN_IN,
    input           RXP_IN,
    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
//jg    output  [2:0]   RXBUFSTATUS_OUT,
    //------------- Receive Ports - RX Loss-of-sync State Machine --------------
    output  [1:0]   RXLOSSOFSYNC_OUT,
    //---------------------- Receive Ports - RX PLL Ports ----------------------
    input           GTXRXRESET_IN,
    input   [1:0]   MGTREFCLKRX_IN,
    input           PLLRXRESET_IN,
    output          RXPLLLKDET_OUT,
    output          RXRESETDONE_OUT,
    //------------ Receive Ports - RX Pipe Control for PCI Express -------------
    output          RXVALID_OUT,         //jg: useful?
    //--------------- Receive Ports - RX Polarity Control Ports ----------------
    input           RXPOLARITY_IN,
    //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
    //---------------- Transmit Ports - TX Data Path interface -----------------
    input   [64:0]  iseed,
    input   [64:0]  rxseed,
    input           force_error,
    output          TXOUTCLK_OUT,
    input           TXRESET_IN,
    input           TXUSRCLK2_IN,
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    output          TXN_OUT,
    output          TXP_OUT,
    //------ Transmit Ports - TX Elastic Buffer and Phase Alignment Ports ------
    input           TXDLYALIGNDISABLE_IN,
    input           TXDLYALIGNMONENB_IN,
    output  [7:0]   TXDLYALIGNMONITOR_OUT,
    input           TXDLYALIGNRESET_IN,
    input           TXENPMAPHASEALIGN_IN,
    input           TXPMASETPHASE_IN,
    //--------------------- Transmit Ports - TX PLL Ports ----------------------
    input           GTXTXRESET_IN,
    input   [1:0]   MGTREFCLKTX_IN,
    input           PLLTXRESET_IN,
    output          TXPLLLKDET_OUT,
    output          TXRESETDONE_OUT
);


//***************************** Wire Declarations *****************************
    // ground and vcc signals
    wire            tied_to_ground_i;
    wire    [63:0]  tied_to_ground_vec_i;
    wire            tied_to_vcc_i;
    wire    [63:0]  tied_to_vcc_vec_i;

    wire   tx_clk2 =  TXUSRCLK2_IN;
    wire   reset  =  GTXTXRESET_IN | GTXRXRESET_IN;
    //RX Datapath signals
    wire    [31:0]  rx_dat;
    wire    [2:0]   rxchariscomma_float_i;
    wire    [1:0]   rxcharisk_float_i;    // rxer[1:0]
    wire    [1:0]   rxdisperr_float_i;    // rxer[3:2]
    wire    [1:0]   rxnotintable_float_i;  // rxer[5:4]
    wire    [1:0]   rxrundisp_float_i;
    wire [1:0] 	RXCHARISCOMMA_OUT;

    wire [5:0]  rxer;
    wire [2:0] 	rx_bufstat;
    wire 	rxen;
    wire [15:0] compdat;
    reg  [15:0] lrx_dat;
    reg 	missed_byte, lrxdv;


    //TX Datapath signals
    wire    [31:0]  txdata_i;
    wire    [1:0]   txkerr_float_i;
    wire    [1:0]   txrundisp_float_i;
    wire    [15:0]  prng_txdata;
    reg     [15:0]  txdata;
    reg     [1:0]   txk_out;
    reg 	    ferr_r, ferr_rr, ferr_done;

   

        
// 
//********************************* Main Body of Code**************************
                       
    //-------------------------  Static signal Assigments ---------------------   

    assign tied_to_ground_i             = 1'b0;
    assign tied_to_ground_vec_i         = 64'h0000000000000000;
    assign tied_to_vcc_i                = 1'b1;
    assign tied_to_vcc_vec_i            = 64'hffffffffffffffff;
    assign RXCHARISK_OUT = rxer[1:0];
    
    //-------------------  GTX Datapath byte mapping  -----------------

    assign  RXDATA_OUT    =   rx_dat[15:0];

    // The GTX transmits little endian data (TXDATA[7:0] transmitted first)     
    assign  txdata_i    =   {tied_to_ground_vec_i[15:0],txdata};
   





    //------------------------- GTX Instantiations  --------------------------
        GTXE1 #
        (
            //_______________________ Simulation-Only Attributes __________________
    
            .SIM_RECEIVER_DETECT_PASS   ("TRUE"),
            
            .SIM_TX_ELEC_IDLE_LEVEL     ("X"),
    
            .SIM_GTXRESET_SPEEDUP       (GTX_SIM_GTXRESET_SPEEDUP),
            .SIM_VERSION                ("2.0"),
            .SIM_TXREFCLK_SOURCE        (3'b000),
            .SIM_RXREFCLK_SOURCE        (3'b000),
            

           //--------------------------TX PLL----------------------------
            .TX_CLK_SOURCE                          (GTX_TX_CLK_SOURCE),
            .TX_OVERSAMPLE_MODE                     ("FALSE"),
            .TXPLL_COM_CFG                          (24'h21680a),
            .TXPLL_CP_CFG                           (8'h0D),
            .TXPLL_DIVSEL_FB                        (2),
            .TXPLL_DIVSEL_OUT                       (1),
            .TXPLL_DIVSEL_REF                       (1),
            .TXPLL_DIVSEL45_FB                      (5),
            .TXPLL_LKDET_CFG                        (3'b111),
            .TX_CLK25_DIVIDER                       (7),
            .TXPLL_SATA                             (2'b00),
            .TX_TDCC_CFG                            (2'b11),
            .PMA_CAS_CLK_EN                         ("FALSE"),
            .POWER_SAVE                             (GTX_POWER_SAVE),

           //-----------------------TX Interface-------------------------
            .GEN_TXUSRCLK                           ("TRUE"),
            .TX_DATA_WIDTH                          (20),
            .TX_USRCLK_CFG                          (6'h00),
            .TXOUTCLK_CTRL                          ("TXPLLREFCLK_DIV1"),
            .TXOUTCLK_DLY                           (10'b0000000000),

           //------------TX Buffering and Phase Alignment----------------
            .TX_PMADATA_OPT                         (1'b1),
            .PMA_TX_CFG                             (20'h80082),
            .TX_BUFFER_USE                          ("FALSE"),
            .TX_BYTECLK_CFG                         (6'h00),
            .TX_EN_RATE_RESET_BUF                   ("TRUE"),
            .TX_XCLK_SEL                            ("TXUSR"),
            .TX_DLYALIGN_CTRINC                     (4'b0100),
            .TX_DLYALIGN_LPFINC                     (4'b0110),
            .TX_DLYALIGN_MONSEL                     (3'b000),
            .TX_DLYALIGN_OVRDSETTING                (8'b10000000),

           //-----------------------TX Gearbox---------------------------
            .GEARBOX_ENDEC                          (3'b000),
            .TXGEARBOX_USE                          ("FALSE"),

           //--------------TX Driver and OOB Signalling------------------
            .TX_DRIVE_MODE                          ("DIRECT"),
            .TX_IDLE_ASSERT_DELAY                   (3'b100),
            .TX_IDLE_DEASSERT_DELAY                 (3'b010),
            .TXDRIVE_LOOPBACK_HIZ                   ("FALSE"),
            .TXDRIVE_LOOPBACK_PD                    ("FALSE"),

           //------------TX Pipe Control for PCI Express/SATA------------
            .COM_BURST_VAL                          (4'b1111),

           //----------------TX Attributes for PCI Express---------------
            .TX_DEEMPH_0                            (5'b11010),
            .TX_DEEMPH_1                            (5'b10000),
            .TX_MARGIN_FULL_0                       (7'b1001110),
            .TX_MARGIN_FULL_1                       (7'b1001001),
            .TX_MARGIN_FULL_2                       (7'b1000101),
            .TX_MARGIN_FULL_3                       (7'b1000010),
            .TX_MARGIN_FULL_4                       (7'b1000000),
            .TX_MARGIN_LOW_0                        (7'b1000110),
            .TX_MARGIN_LOW_1                        (7'b1000100),
            .TX_MARGIN_LOW_2                        (7'b1000010),
            .TX_MARGIN_LOW_3                        (7'b1000000),
            .TX_MARGIN_LOW_4                        (7'b1000000),

           //--------------------------RX PLL----------------------------
            .RX_OVERSAMPLE_MODE                     ("FALSE"),
            .RXPLL_COM_CFG                          (24'h21680a),
            .RXPLL_CP_CFG                           (8'h0D),
            .RXPLL_DIVSEL_FB                        (2),
            .RXPLL_DIVSEL_OUT                       (1),
            .RXPLL_DIVSEL_REF                       (1),
            .RXPLL_DIVSEL45_FB                      (5),
            .RXPLL_LKDET_CFG                        (3'b111),
            .RX_CLK25_DIVIDER                       (7),

           //-----------------------RX Interface-------------------------
            .GEN_RXUSRCLK                           ("TRUE"),
            .RX_DATA_WIDTH                          (20),
            .RXRECCLK_CTRL                          ("RXRECCLKPMA_DIV2"),
            .RXRECCLK_DLY                           (10'b0000000000),
            .RXUSRCLK_DLY                           (16'h0000),

           //--------RX Driver,OOB signalling,Coupling and Eq.,CDR-------
            .AC_CAP_DIS                             ("TRUE"),
            .CDR_PH_ADJ_TIME                        (5'b10100),
            .OOBDETECT_THRESHOLD                    (3'b011),
            .PMA_CDR_SCAN                           (27'h640404C),
            .PMA_RX_CFG                             (25'h05ce008),
            .RCV_TERM_GND                           ("FALSE"),
            .RCV_TERM_VTTRX                         ("FALSE"),
            .RX_EN_IDLE_HOLD_CDR                    ("FALSE"),
            .RX_EN_IDLE_RESET_FR                    ("TRUE"),
            .RX_EN_IDLE_RESET_PH                    ("TRUE"),
            .TX_DETECT_RX_CFG                       (14'h1832),
            .TERMINATION_CTRL                       (5'b00000),
            .TERMINATION_OVRD                       ("FALSE"),
            .CM_TRIM                                (2'b01),
            .PMA_RXSYNC_CFG                         (7'h00),
            .PMA_CFG                                (76'h0040000040000000003),
            .BGTEST_CFG                             (2'b00),
            .BIAS_CFG                               (17'h00000),

           //------------RX Decision Feedback Equalizer(DFE)-------------
            .DFE_CAL_TIME                           (5'b01100),
            .DFE_CFG                                (8'b00011011),
            .RX_EN_IDLE_HOLD_DFE                    ("TRUE"),
            .RX_EYE_OFFSET                          (8'h4C),
            .RX_EYE_SCANMODE                        (2'b00),

           //-----------------------PRBS Detection-----------------------
            .RXPRBSERR_LOOPBACK                     (1'b0),

           //----------------Comma Detection and Alignment---------------
            .ALIGN_COMMA_WORD                       (2), // 1 == any byte.  2 == even byte.
            .COMMA_10B_ENABLE                       (10'b1111111111),
            .COMMA_DOUBLE                           ("FALSE"),
            .DEC_MCOMMA_DETECT                      ("TRUE"),
            .DEC_PCOMMA_DETECT                      ("TRUE"),
            .DEC_VALID_COMMA_ONLY                   ("FALSE"),
            .MCOMMA_10B_VALUE                       (10'b1010000011),
            .MCOMMA_DETECT                          ("TRUE"),
            .PCOMMA_10B_VALUE                       (10'b0101111100),
            .PCOMMA_DETECT                          ("TRUE"),
            .RX_DECODE_SEQ_MATCH                    ("TRUE"),
            .RX_SLIDE_AUTO_WAIT                     (5),
            .RX_SLIDE_MODE                          ("OFF"),
            .SHOW_REALIGN_COMMA                     ("FALSE"),

           //---------------RX Loss-of-sync State Machine----------------
            .RX_LOS_INVALID_INCR                    (8),
            .RX_LOS_THRESHOLD                       (128),
            .RX_LOSS_OF_SYNC_FSM                    ("FALSE"),

           //-----------------------RX Gearbox---------------------------
            .RXGEARBOX_USE                          ("FALSE"),

           //-----------RX Elastic Buffer and Phase alignment------------
            .RX_BUFFER_USE                          ("TRUE"),
            .RX_EN_IDLE_RESET_BUF                   ("TRUE"),
            .RX_EN_MODE_RESET_BUF                   ("TRUE"),
            .RX_EN_RATE_RESET_BUF                   ("TRUE"),
            .RX_EN_REALIGN_RESET_BUF                ("FALSE"),
            .RX_EN_REALIGN_RESET_BUF2               ("FALSE"),
            .RX_FIFO_ADDR_MODE                      ("FULL"),
            .RX_IDLE_HI_CNT                         (4'b1000),
            .RX_IDLE_LO_CNT                         (4'b0000),
            .RX_XCLK_SEL                            ("RXREC"),
            .RX_DLYALIGN_CTRINC                     (4'b1110),
            .RX_DLYALIGN_EDGESET                    (5'b00010),
            .RX_DLYALIGN_LPFINC                     (4'b1110),
            .RX_DLYALIGN_MONSEL                     (3'b000),
            .RX_DLYALIGN_OVRDSETTING                (8'b10000000),

           //----------------------Clock Correction----------------------
            .CLK_COR_ADJ_LEN                        (2),
            .CLK_COR_DET_LEN                        (2),
            .CLK_COR_INSERT_IDLE_FLAG               ("FALSE"),
            .CLK_COR_KEEP_IDLE                      ("FALSE"),
            .CLK_COR_MAX_LAT                        (18),
            .CLK_COR_MIN_LAT                        (14),
            .CLK_COR_PRECEDENCE                     ("TRUE"),
            .CLK_COR_REPEAT_WAIT                    (0),
            .CLK_COR_SEQ_1_1                        (10'b0111110111),
            .CLK_COR_SEQ_1_2                        (10'b0111110111),
            .CLK_COR_SEQ_1_3                        (10'b0100000000),
            .CLK_COR_SEQ_1_4                        (10'b0100000000),
            .CLK_COR_SEQ_1_ENABLE                   (4'b1111),
            .CLK_COR_SEQ_2_1                        (10'b0100000000),
            .CLK_COR_SEQ_2_2                        (10'b0100000000),
            .CLK_COR_SEQ_2_3                        (10'b0100000000),
            .CLK_COR_SEQ_2_4                        (10'b0100000000),
            .CLK_COR_SEQ_2_ENABLE                   (4'b1111),
            .CLK_COR_SEQ_2_USE                      ("FALSE"),
            .CLK_CORRECT_USE                        ("TRUE"),

           //----------------------Channel Bonding----------------------
            .CHAN_BOND_1_MAX_SKEW                   (1),
            .CHAN_BOND_2_MAX_SKEW                   (1),
            .CHAN_BOND_KEEP_ALIGN                   ("FALSE"),
            .CHAN_BOND_SEQ_1_1                      (10'b0000000000),
            .CHAN_BOND_SEQ_1_2                      (10'b0000000000),
            .CHAN_BOND_SEQ_1_3                      (10'b0000000000),
            .CHAN_BOND_SEQ_1_4                      (10'b0000000000),
            .CHAN_BOND_SEQ_1_ENABLE                 (4'b1111),
            .CHAN_BOND_SEQ_2_1                      (10'b0000000000),
            .CHAN_BOND_SEQ_2_2                      (10'b0000000000),
            .CHAN_BOND_SEQ_2_3                      (10'b0000000000),
            .CHAN_BOND_SEQ_2_4                      (10'b0000000000),
            .CHAN_BOND_SEQ_2_CFG                    (5'b00000),
            .CHAN_BOND_SEQ_2_ENABLE                 (4'b1111),
            .CHAN_BOND_SEQ_2_USE                    ("FALSE"),
            .CHAN_BOND_SEQ_LEN                      (1),
            .PCI_EXPRESS_MODE                       ("FALSE"),

           //-----------RX Attributes for PCI Express/SATA/SAS----------
            .SAS_MAX_COMSAS                         (52),
            .SAS_MIN_COMSAS                         (40),
            .SATA_BURST_VAL                         (3'b100),
            .SATA_IDLE_VAL                          (3'b100),
            .SATA_MAX_BURST                         (8),
            .SATA_MAX_INIT                          (23),
            .SATA_MAX_WAKE                          (8),
            .SATA_MIN_BURST                         (4),
            .SATA_MIN_INIT                          (13),
            .SATA_MIN_WAKE                          (4),
            .TRANS_TIME_FROM_P2                     (12'h03c),
            .TRANS_TIME_NON_P2                      (8'h19),
            .TRANS_TIME_RATE                        (8'hff),
            .TRANS_TIME_TO_P2                       (10'h064)

            
        ) 
        gtxe1_i 
        (
        
        //---------------------- Loopback and Powerdown Ports ----------------------
        .LOOPBACK                       (tied_to_ground_vec_i[2:0]),
        .RXPOWERDOWN                    (RXPOWERDOWN_IN),
        .TXPOWERDOWN                    (TXPOWERDOWN_IN),
        //------------ Receive Ports - 64b66b and 64b67b Gearbox Ports -------------
        .RXDATAVALID                    (),
        .RXGEARBOXSLIP                  (tied_to_ground_i),
        .RXHEADER                       (),
        .RXHEADERVALID                  (),
        .RXSTARTOFSEQ                   (),
        //--------------------- Receive Ports - 8b10b Decoder ----------------------
        .RXCHARISCOMMA                  ({rxchariscomma_float_i,RXCHARISCOMMA_OUT}),
        .RXCHARISK                      ({rxcharisk_float_i,rxer[1:0]}),
        .RXDEC8B10BUSE                  (tied_to_vcc_i),
        .RXDISPERR                      ({rxdisperr_float_i,rxer[3:2]}),
        .RXNOTINTABLE                   ({rxnotintable_float_i,rxer[5:4]}),
        .RXRUNDISP                      (),
        .USRCODEERR                     (tied_to_ground_i),
        //----------------- Receive Ports - Channel Bonding Ports ------------------
        .RXCHANBONDSEQ                  (),
        .RXCHBONDI                      (tied_to_ground_vec_i[3:0]),
        .RXCHBONDLEVEL                  (tied_to_ground_vec_i[2:0]),
        .RXCHBONDMASTER                 (tied_to_ground_i),
        .RXCHBONDO                      (),
        .RXCHBONDSLAVE                  (tied_to_ground_i),
        .RXENCHANSYNC                   (tied_to_ground_i),
        //----------------- Receive Ports - Clock Correction Ports -----------------
        .RXCLKCORCNT                    (RXCLKCORCNT_OUT),
        //------------- Receive Ports - Comma Detection and Alignment --------------
        .RXBYTEISALIGNED                (),
        .RXBYTEREALIGN                  (RXBYTEREALIGN_OUT),
        .RXCOMMADET                     (RXCOMMADET_OUT),
        .RXCOMMADETUSE                  (tied_to_vcc_i),
        .RXENMCOMMAALIGN                (RXENMCOMMAALIGN_IN),
        .RXENPCOMMAALIGN                (RXENPCOMMAALIGN_IN),
        .RXSLIDE                        (tied_to_ground_i),
        //--------------------- Receive Ports - PRBS Detection ---------------------
        .PRBSCNTRESET                   (tied_to_ground_i),
        .RXENPRBSTST                    (tied_to_ground_vec_i[2:0]),
        .RXPRBSERR                      (),
        //----------------- Receive Ports - RX Data Path interface -----------------
        .RXDATA                         (rx_dat),
        .RXRECCLK                       (),
        .RXRECCLKPCS                    (),
        .RXRESET                        (RXRESET_IN),
        .RXUSRCLK                       (tied_to_ground_i),
        .RXUSRCLK2                      (RXUSRCLK2_IN),
        //---------- Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
        .DFECLKDLYADJ                   (tied_to_ground_vec_i[5:0]),
        .DFECLKDLYADJMON                (),
        .DFEDLYOVRD                     (tied_to_vcc_i),
        .DFEEYEDACMON                   (),
        .DFESENSCAL                     (),
        .DFETAP1                        (tied_to_ground_vec_i[4:0]),
        .DFETAP1MONITOR                 (),
        .DFETAP2                        (tied_to_ground_vec_i[4:0]),
        .DFETAP2MONITOR                 (),
        .DFETAP3                        (tied_to_ground_vec_i[3:0]),
        .DFETAP3MONITOR                 (),
        .DFETAP4                        (tied_to_ground_vec_i[3:0]),
        .DFETAP4MONITOR                 (),
        .DFETAPOVRD                     (tied_to_vcc_i),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .GATERXELECIDLE                 (tied_to_vcc_i),
        .IGNORESIGDET                   (tied_to_vcc_i),
        .RXCDRRESET                     (RXCDRRESET_IN),
        .RXELECIDLE                     (),
        .RXEQMIX                        (10'b0000000111),
        .RXN                            (RXN_IN),
        .RXP                            (RXP_IN),
        //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
        .RXBUFRESET                     (tied_to_ground_i),
        .RXBUFSTATUS                    (rx_bufstat),
        .RXCHANISALIGNED                (),
        .RXCHANREALIGN                  (),
        .RXDLYALIGNDISABLE              (tied_to_ground_i),
        .RXDLYALIGNMONENB               (tied_to_ground_i),
        .RXDLYALIGNMONITOR              (),
        .RXDLYALIGNOVERRIDE             (tied_to_vcc_i),
        .RXDLYALIGNRESET                (tied_to_ground_i),
        .RXDLYALIGNSWPPRECURB           (tied_to_vcc_i),
        .RXDLYALIGNUPDSW                (tied_to_ground_i),
        .RXENPMAPHASEALIGN              (tied_to_ground_i),
        .RXPMASETPHASE                  (tied_to_ground_i),
        .RXSTATUS                       (),
        //------------- Receive Ports - RX Loss-of-sync State Machine --------------
        .RXLOSSOFSYNC                   (RXLOSSOFSYNC_OUT),
        //-------------------- Receive Ports - RX Oversampling ---------------------
        .RXENSAMPLEALIGN                (tied_to_ground_i),
        .RXOVERSAMPLEERR                (),
        //---------------------- Receive Ports - RX PLL Ports ----------------------
        .GREFCLKRX                      (tied_to_ground_i),
        .GTXRXRESET                     (GTXRXRESET_IN),
        .MGTREFCLKRX                    (MGTREFCLKRX_IN),
        .NORTHREFCLKRX                  (tied_to_ground_vec_i[1:0]),
        .PERFCLKRX                      (tied_to_ground_i),
        .PLLRXRESET                     (PLLRXRESET_IN),
        .RXPLLLKDET                     (RXPLLLKDET_OUT),
        .RXPLLLKDETEN                   (tied_to_vcc_i),
        .RXPLLPOWERDOWN                 (tied_to_ground_i),
        .RXPLLREFSELDY                  (tied_to_ground_vec_i[2:0]),
        .RXRATE                         (tied_to_ground_vec_i[1:0]),
        .RXRATEDONE                     (),
        .RXRESETDONE                    (RXRESETDONE_OUT),
        .SOUTHREFCLKRX                  (tied_to_ground_vec_i[1:0]),
        //------------ Receive Ports - RX Pipe Control for PCI Express -------------
        .PHYSTATUS                      (),
        .RXVALID                        (RXVALID_OUT),
        //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .RXPOLARITY                     (RXPOLARITY_IN),
        //------------------- Receive Ports - RX Ports for SATA --------------------
        .COMINITDET                     (),
        .COMSASDET                      (),
        .COMWAKEDET                     (),
        //----------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
        .DADDR                          (tied_to_ground_vec_i[7:0]),
        .DCLK                           (tied_to_ground_i),
        .DEN                            (tied_to_ground_i),
        .DI                             (tied_to_ground_vec_i[15:0]),
        .DRDY                           (),
        .DRPDO                          (),
        .DWE                            (tied_to_ground_i),
        //------------ Transmit Ports - 64b66b and 64b67b Gearbox Ports ------------
        .TXGEARBOXREADY                 (),
        .TXHEADER                       (tied_to_ground_vec_i[2:0]),
        .TXSEQUENCE                     (tied_to_ground_vec_i[6:0]),
        .TXSTARTSEQ                     (tied_to_ground_i),
        //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        .TXBYPASS8B10B                  (tied_to_ground_vec_i[3:0]),
        .TXCHARDISPMODE                 (tied_to_ground_vec_i[3:0]),
        .TXCHARDISPVAL                  (tied_to_ground_vec_i[3:0]),
        .TXCHARISK                      ({tied_to_ground_vec_i[1:0],txk_out}),
        .TXENC8B10BUSE                  (tied_to_vcc_i),
        .TXKERR                         (),
        .TXRUNDISP                      (),
        //----------------------- Transmit Ports - GTX Ports -----------------------
        .GTXTEST                        (13'b1000000000000),
        .MGTREFCLKFAB                   (),
        .TSTCLK0                        (tied_to_ground_i),
        .TSTCLK1                        (tied_to_ground_i),
        .TSTIN                          (20'b11111111111111111111),
        .TSTOUT                         (),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .TXDATA                         (txdata_i),
        .TXOUTCLK                       (TXOUTCLK_OUT),
        .TXOUTCLKPCS                    (),
        .TXRESET                        (TXRESET_IN),
        .TXUSRCLK                       (tied_to_ground_i),
        .TXUSRCLK2                      (TXUSRCLK2_IN),
        //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .TXBUFDIFFCTRL                  (3'b100),
        .TXDIFFCTRL                     (4'b0000),
        .TXINHIBIT                      (tied_to_ground_i),
        .TXN                            (TXN_OUT),
        .TXP                            (TXP_OUT),
        .TXPOSTEMPHASIS                 (5'b00000),
        //------------- Transmit Ports - TX Driver and OOB signalling --------------
        .TXPREEMPHASIS                  (4'b0000),
        //--------- Transmit Ports - TX Elastic Buffer and Phase Alignment ---------
        .TXBUFSTATUS                    (),
        //------ Transmit Ports - TX Elastic Buffer and Phase Alignment Ports ------
        .TXDLYALIGNDISABLE              (TXDLYALIGNDISABLE_IN),
        .TXDLYALIGNMONENB               (TXDLYALIGNMONENB_IN),
        .TXDLYALIGNMONITOR              (TXDLYALIGNMONITOR_OUT),
        .TXDLYALIGNOVERRIDE             (tied_to_ground_i),
        .TXDLYALIGNRESET                (TXDLYALIGNRESET_IN),
        .TXDLYALIGNUPDSW                (tied_to_ground_i),
        .TXENPMAPHASEALIGN              (TXENPMAPHASEALIGN_IN),
        .TXPMASETPHASE                  (TXPMASETPHASE_IN),
        //--------------------- Transmit Ports - TX PLL Ports ----------------------
        .GREFCLKTX                      (tied_to_ground_i),
        .GTXTXRESET                     (GTXTXRESET_IN),
        .MGTREFCLKTX                    (MGTREFCLKTX_IN),
        .NORTHREFCLKTX                  (tied_to_ground_vec_i[1:0]),
        .PERFCLKTX                      (tied_to_ground_i),
        .PLLTXRESET                     (PLLTXRESET_IN),
        .SOUTHREFCLKTX                  (tied_to_ground_vec_i[1:0]),
        .TXPLLLKDET                     (TXPLLLKDET_OUT),
        .TXPLLLKDETEN                   (tied_to_vcc_i),
        .TXPLLPOWERDOWN                 (tied_to_ground_i),
        .TXPLLREFSELDY                  (tied_to_ground_vec_i[2:0]),
        .TXRATE                         (tied_to_ground_vec_i[1:0]),
        .TXRATEDONE                     (),
        .TXRESETDONE                    (TXRESETDONE_OUT),
        //------------------- Transmit Ports - TX PRBS Generator -------------------
        .TXENPRBSTST                    (tied_to_ground_vec_i[2:0]),
        .TXPRBSFORCEERR                 (tied_to_ground_i),
        //------------------ Transmit Ports - TX Polarity Control ------------------
        .TXPOLARITY                     (tied_to_ground_i),
        //--------------- Transmit Ports - TX Ports for PCI Express ----------------
        .TXDEEMPH                       (tied_to_ground_i),
        .TXDETECTRX                     (tied_to_ground_i),
        .TXELECIDLE                     (TXPOWERDOWN_IN[0]),  // connect to TXPOWERDOWN[0] or GND?
        .TXMARGIN                       (tied_to_ground_vec_i[2:0]),
        .TXPDOWNASYNCH                  (tied_to_ground_i),
        .TXSWING                        (tied_to_ground_i),
        //------------------- Transmit Ports - TX Ports for SATA -------------------
        .COMFINISH                      (),
        .TXCOMINIT                      (tied_to_ground_i),
        .TXCOMSAS                       (tied_to_ground_i),
        .TXCOMWAKE                      (tied_to_ground_i)

     );
     

     assign rxdv = ~(|rxer | rx_bufstat[2] | gtx_wait); // idle is K28.5,D16.2  =  BC,50 in time order
     assign rxcomma = (rxer[1:0] == 2'b01 && rx_dat[15:0] == 16'h50bc);
     assign rxen = rxdv | lrxdv;

     prng65_16 rand_txdat(
        .init_dat (iseed),
	.en  (!gtx_wait),
        .dout (prng_txdata),
	.rst (reset),
	.clk (tx_clk2)
     );
   
     prng65_16 rand_rxdat(
        .init_dat (rxseed),
	.en  (lrxdv),
        .dout (compdat),
	.rst (reset),
	.clk (tx_clk2)
     );

     always @(posedge tx_clk2) // everything that uses USR clock, no reset
     begin
	lrx_dat[15:0] <= rx_dat[15:0];
     end

     always @(posedge tx_clk2 or posedge reset) // everything that uses USR clock w/reset
     begin
	if (reset) begin
	   bad_byte <= 0;   // register to specify bad byte count > 0
	   good_byte <= 0;  // register to specify good byte count > 0
	   lrxdv <= 0;
	   check_ok <= 0;
	   check_bad <= 0;
	   err_count <= 32'h00000000;
	   txdata <= 16'h50bc;
	   txk_out <= 2'h1;
	   ferr_r <= 0;
	   ferr_rr <= 0;	      
	end

	else if (!gtx_wait) begin // Not Reset-Wait case
	   ferr_r <= force_error;
	   if (!ferr_done) begin
	      ferr_rr <= ferr_r;
	      ferr_done <= ferr_r; // <<-- ferr_rr causes 2 fake err, should be ferr_r
	   end
	   else begin
	      ferr_rr <= 0;
	      ferr_done <= force_error;  // <<-- could be ferr_r, but OK
	   end

// note: This TXdata does not return to THIS RX port!
	   if (!ferr_rr) txdata <= prng_txdata;  // normally we DON'T cause an error!
	   else txdata <= prng_txdata^16'h0400;  // flip bit 10 to force an error
	   txk_out <= 2'h0;  // But duplicate PRNGs with matching seeds take care of it.

// note: This RX data does not come from THIS TX port!
	   if (rxdv) lrxdv <= 1;  // once it starts, assume EVERY word needs checked:
	   // an SEU may cause a bit error and rxdv can go false, but we can't skip it because
	   // the next word in sequence may be good

	   if (lrxdv) begin // check against rx_prng & accum results
	      if (lrx_dat[15:0] == compdat[15:0]) begin
		 good_byte <= 1'b1;
		 check_ok <= 1'b1;
		 check_bad <= 0;
	      end
	      else begin
		 err_count <= err_count + 1'b1;
		 bad_byte <= 1'b1;
		 check_bad <= 1'b1;
		 check_ok <= 0;
	      end
	   end  // if (rxdv > 0)
	end  // if (!gtx_wait)

	else begin  // in case it goes to WAIT again...should not need this, it won't help
	   txdata <= 16'h50bc;
	   txk_out <= 2'h1;
	end // else: !if(!gtx_wait)

     end

endmodule
