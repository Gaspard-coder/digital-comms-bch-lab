%This script encodes an information word using G1 for the t=1 case
clear; clc;

G1 = [1 0 0 1 0 1]; %5-bit generator polynomial
info_word = [1 0 1 1 0 1 0 1 1 0 0 1 1 0 1 0 1 0 0 1 1 0 1 0 1 0]; %26-bit information word

fprintf('Info word: [%s]\n', num2str(info_word));

[code_word, remainder] = compute_crc(info_word, G1);

fprintf('CRC: [%s]\n', num2str(remainder));
fprintf('Code word: [%s]\n', num2str(code_word));
fprintf('Length: %d bits\n', length(code_word));

%Save the code word in code_word.mat
save('code_word.mat', 'code_word');

