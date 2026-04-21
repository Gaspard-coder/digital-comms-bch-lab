function [codeword, remainder] = compute_crc_fast(info_bits, generator_polynomial)
% Optimized version: supports matrix input (num_words x k)
% If info_bits is a matrix, returns codeword (num_words x n) and remainder (num_words x r)

num_registers = length(generator_polynomial);

% --- Vector mode (word matrix) ---
if size(info_bits, 1) > 1
    num_words = size(info_bits, 1);
    k = size(info_bits, 2);
    
    % Extended message: [info_bits | zeros] with size (num_words x (k + num_registers))
    extended_message = [info_bits, zeros(num_words, num_registers)];
    
    registers = zeros(num_words, num_registers);
    
    % Polynomial in practical order
    polynomial = generator_polynomial;
    poly_degree = num_registers;
    
    for i = 1:size(extended_message, 2)
        input_bit = extended_message(:, i);   % current column (num_words x 1)
        output_bit = registers(:, 1);         % register MSB
        
        new_registers = zeros(num_words, num_registers);
        
        if polynomial(poly_degree) == 1
            new_registers(:, poly_degree) = xor(input_bit, output_bit);
        end
        
        for j = (num_registers-1):-1:1
            if polynomial(j) == 1
                new_registers(:, j) = xor(output_bit, registers(:, j+1));
            else
                new_registers(:, j) = registers(:, j+1);
            end
        end
        registers = new_registers;
    end
    
    codeword = [info_bits, registers];
    remainder = registers;
    return;
end

% --- Original scalar mode (row vector) ---
info_bits = info_bits(:)';
registers = zeros(1, num_registers);
shifted_registers = zeros(1, num_registers);
extended_message = [info_bits, zeros(1, num_registers)];
poly_degree = num_registers;

for i = 1:length(extended_message)
    input_bit = extended_message(i);
    output_bit = registers(1);
    
    if generator_polynomial(poly_degree) == 1
        shifted_registers(poly_degree) = xor(input_bit, output_bit);
    end
    
    for j = (num_registers-1):-1:1
        if generator_polynomial(j) == 1
            shifted_registers(j) = xor(output_bit, registers(j+1));
        else
            shifted_registers(j) = registers(j+1);
        end
    end
    registers = shifted_registers;
end

codeword = [info_bits, registers];
remainder = registers;
end
