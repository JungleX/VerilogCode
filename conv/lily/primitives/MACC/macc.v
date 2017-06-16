/*
 * supported operations:
 * MULTIPLY      : OP = 000 or 0
 * MULTIPLY-ACC  : OP = 010 or 2
 * MULTIPLY-ADD  : OP = 100 or 4
 * SQUARE        : OP = 001 or 1
 * SQUARE-ACC    : OP = 011 or 3
 * SQUARE-ADD    : OP = 101 or 5
 */
 
 module macc #(
    parameter TYPE = "FIXED_POINT"
 )(
 );
 
localparam integer OP_CODE_WIDTH = 3;

generate
if(TYPE == "FLOATING_POINT") begin
    
end

endgenerate
 
endmodule