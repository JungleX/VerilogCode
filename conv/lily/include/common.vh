`define SRC_2_BIAS 1

function integer ceil_a_by_b;
    input integer a;
    input integer b;
    integer c;
    begin
        c = a < b ? 1 : a%b == 0 ? a/b : a/b+1;
        ceil_a_by_b = c;
    end
endfunction