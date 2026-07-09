`timescale 1ns/1ps
`ifndef LF_FUNCTIONAL_COVERAGE_SV
`define LF_FUNCTIONAL_COVERAGE_SV

import LF_pkg::*;

//==============================================================================
// Module  : lf_functional_coverage
//------------------------------------------------------------------------------
// SystemVerilog functional coverage for the LF-SDR X1 baseband processor.
// Collects coverage on:
//   - All modulation types (BPSK, QPSK, 16QAM, 64QAM)
//   - Configuration changes
//   - Health monitor events
//   - Performance metric ranges
//
// FIX: Removed self-referencing assigns (original had assign current_modulation
//      = current_modulation which is illegal). Covergroup now samples from
//      internal registered copies of the input signals.
//
// NOT synthesizable - simulation only.
//==============================================================================

module lf_functional_coverage (
    input logic clk,
    input logic rst_n,

    // From status/control
    input logic [1:0]  current_modulation,
    input logic [31:0] packet_count,
    input logic [2:0]  health_events  // bit0=crc, bit1=fifo, bit2=sync
);

    // Registered copies for covergroup sampling (avoid self-reference)
    logic [1:0]  mod_reg;
    logic [31:0] pkt_cnt_reg;
    logic [2:0]  health_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mod_reg     <= '0;
            pkt_cnt_reg <= '0;
            health_reg  <= '0;
        end else begin
            mod_reg     <= current_modulation;
            pkt_cnt_reg <= packet_count;
            health_reg  <= health_events;
        end
    end

    covergroup cg_sdr_coverage @(posedge clk);

        // Modulation type coverage
        cp_modulation: coverpoint mod_reg {
            bins bpsk  = {MOD_BPSK};
            bins qpsk  = {MOD_QPSK};
            bins qam16 = {MOD_QAM16};
            bins qam64 = {MOD_QAM64};
        }

        // Packet counter ranges
        cp_packet_count: coverpoint pkt_cnt_reg {
            bins low    = {[0:10]};
            bins mid    = {[11:100]};
            bins high   = {[101:$]};
        }

        // Health events
        cp_health: coverpoint health_reg {
            bins healthy     = {0};
            bins crc_err     = {1};
            bins fifo_err    = {2};
            bins sync_err    = {4};
            bins multi_err   = {3,5,6,7};
        }

        // Cross coverage: modulation x health
        cx_mod_health: cross cp_modulation, cp_health;

    endgroup

    cg_sdr_coverage cg = new();

endmodule

`endif