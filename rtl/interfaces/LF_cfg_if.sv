`timescale 1ns/1ps
`ifndef LF_CFG_IF_SV
`define LF_CFG_IF_SV

import LF_pkg::*;

interface LF_cfg_if
(
    input logic clk,
    input logic rst_n
);

    //------------------------------------------------------------
    // Configuration Signals
    //------------------------------------------------------------

    logic        cfg_valid;
    logic        cfg_ready;

    cfg_t        cfg;

    //------------------------------------------------------------
    // Configuration Update
    //------------------------------------------------------------

    logic        update_req;
    logic        update_ack;

    //------------------------------------------------------------
    // Soft Reset
    //------------------------------------------------------------

    logic        soft_reset;

    //------------------------------------------------------------
    // Host Processor (Master)
    //------------------------------------------------------------

    modport host
    (
        input  cfg_ready,
        input  update_ack,

        output cfg_valid,
        output cfg,
        output update_req,
        output soft_reset
    );

    //------------------------------------------------------------
    // Configuration Register (Slave)
    //------------------------------------------------------------

    modport cfg_reg
    (
        input  cfg_valid,
        input  cfg,
        input  update_req,
        input  soft_reset,

        output cfg_ready,
        output update_ack
    );

    //------------------------------------------------------------
    // Main Controller
    //------------------------------------------------------------

    modport controller
    (
        input cfg
    );

endinterface

`endif