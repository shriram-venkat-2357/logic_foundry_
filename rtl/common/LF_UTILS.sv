`ifndef LF_UTILS_SV
`define LF_UTILS_SV

package LF_UTILS;

    //------------------------------------------------------------
    // Ceiling Log2 Function
    //------------------------------------------------------------
    function automatic int clog2(input int value);

        int i;

        begin
            value = value - 1;

            for(i=0; value>0; i++)
                value = value >> 1;

            return i;
        end

    endfunction

    //------------------------------------------------------------
    // Even Parity Generator
    //------------------------------------------------------------
    function automatic logic parity_even
    (
        input logic [31:0] data
    );

        parity_even = ^data;

    endfunction

    //------------------------------------------------------------
    // Odd Parity Generator
    //------------------------------------------------------------
    function automatic logic parity_odd
    (
        input logic [31:0] data
    );

        parity_odd = ~(^data);

    endfunction

    //------------------------------------------------------------
    // One Hot Check
    //------------------------------------------------------------
    function automatic logic one_hot
    (
        input logic [31:0] value
    );

        one_hot = ((value != 0) &&
                   ((value & (value-1)) == 0));

    endfunction

    //------------------------------------------------------------
    // Binary To Gray
    //------------------------------------------------------------
    function automatic logic [31:0] bin2gray
    (
        input logic [31:0] bin
    );

        bin2gray = bin ^ (bin >> 1);

    endfunction

    //------------------------------------------------------------
    // Gray To Binary
    //------------------------------------------------------------
    function automatic logic [31:0] gray2bin
    (
        input logic [31:0] gray
    );

        integer i;

        begin

            gray2bin[31] = gray[31];

            for(i=30;i>=0;i--)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];

        end

    endfunction

    //------------------------------------------------------------
    // Maximum Function
    //------------------------------------------------------------
    function automatic int max2
    (
        input int a,
        input int b
    );

        max2 = (a>b) ? a : b;

    endfunction

    //------------------------------------------------------------
    // Minimum Function
    //------------------------------------------------------------
    function automatic int min2
    (
        input int a,
        input int b
    );

        min2 = (a<b) ? a : b;

    endfunction

endpackage

`endif