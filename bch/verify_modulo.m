function result = verify_modulo(codeword, generator_polynomial)
% Role: compute modulo verification on a codeword
% using the generator polynomial with c(x) mod(g(x))
% 
% Inputs: codeword (codeword c(x) used as modulo-computation input for verification),
% generator_polynomial (code generator polynomial used to compute mod(g(x)))
% 
% Output: result (modulo computation output on codeword c(x))


% Compute number of registers and degree of g(x)
num_registers = length(generator_polynomial);
poly_degree = num_registers;   

% Register initialization (memory at time t-1)
registers = zeros(1, num_registers); % Registers are initialized to 0
shifted_registers = zeros(1, num_registers); % Backup registers for the next clock step

disp('--- Start of bit-by-bit modulo computation ---');

% --- Time loop (clock tick) ---
for i = 1:length(codeword)

    % 1. Read the incoming bit (input)
    input_bit = codeword(i);
    
    % 2. Read the bit leaving the last register (leftmost/MSB)
    output_bit = registers(1);
    
    % If the first generator polynomial bit is 1 (LSB), apply XOR
    % between incoming and outgoing bits
    if generator_polynomial(poly_degree) == 1  
        shifted_registers(poly_degree) = xor(input_bit, output_bit);
    end

    % Loop over all registers except the first one,
    % decreasing from num_registers-1 to 1
    for j = (num_registers-1):-1:1
        if generator_polynomial(j) == 1 
            % If the j-th generator polynomial bit is 1, apply XOR
            % between outgoing bit and the previous register bit
            shifted_registers(j) = xor(output_bit, registers(j+1)); 
        else
            % Otherwise copy the previous register into
            % the next register
            shifted_registers(j) = registers(j+1);
        end
    end
    % Store new register values as current ones
    registers = shifted_registers;
end

% Final result (remainder/modulo) is what remains in the registers
disp('--- End of modulo computation ---');

% registers = c(x) mod(g(x))
result = registers;

end