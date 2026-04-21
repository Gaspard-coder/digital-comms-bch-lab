function corrected_info_bits = Decoder_t2(received_word, syndrome_table_t2)

received_word = received_word(:)';  % force row vector
G2 = [1 1 0 1 1 0 1 0 0 1];
k = length(received_word) - length(G2);

[~, syndrome] = compute_crc(received_word, G2);

% No-error condition: zero syndrome
if all(syndrome == 0)
    corrected_info_bits = received_word(1:k);
    return;
end

% Search in the syndrome table
row_idx = find(ismember(syndrome_table_t2(:, 3:end), syndrome, 'rows'));

if isempty(row_idx)
    corrected_info_bits = received_word(1:k);
    return;
end

% Correct up to two errors
pos1 = syndrome_table_t2(row_idx, 1);
pos2 = syndrome_table_t2(row_idx, 2);

corrected_word = received_word;
corrected_word(pos1) = mod(corrected_word(pos1) + 1, 2);
if pos2 ~= 0
    corrected_word(pos2) = mod(corrected_word(pos2) + 1, 2);
end
corrected_info_bits = corrected_word(1:k);

end