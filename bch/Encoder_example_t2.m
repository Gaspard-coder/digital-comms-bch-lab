% This script encodes an information word using G2 for the t=2 case

clear; clc;

generator_poly_t2 = [1 1 1 0 1 1 0 1 0 0 1];  % 11-bit generator polynomial
info_word = [1 0 1 1 0 1 0 1 1 0 0 1 1 0 1 0 1 0 0 1 1]; % 21-bit information word

redundancy_bits = length(generator_poly_t2)-1; % redundancy_bits = 10
extended_message = [info_word, zeros(1, redundancy_bits)]; % 31 bits
remainder = shift_register_modulo(extended_message, generator_poly_t2);
codeword = [info_word, remainder]; % 31 bits

fprintf('Info word: [%s]\n', num2str(info_word));
fprintf('CRC: [%s]\n', num2str(remainder));
fprintf('Codeword: [%s]\n', num2str(codeword));
fprintf('Length: %d bits\n', length(codeword));

% Verification
syndrome_check = shift_register_modulo(codeword, generator_poly_t2);
if all(syndrome_check == 0)
    fprintf('\nThe codeword is valid and has length: %d bits\n', length(codeword));
else
    fprintf('\nEncoding issue\n');
end

% Save the codeword into codeword.mat
save('codeword.mat', 'codeword');
