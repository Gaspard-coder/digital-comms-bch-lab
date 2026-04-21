function corrected_info_bits = Decoder_t1(received_word, syndrome_table_t1)

received_word = received_word(:)';  % force row vector
generator_poly_t1 = [0 0 1 0 1];
k = length(received_word) - length(generator_poly_t1);

[~, syndrome_t1] = compute_crc(received_word, generator_poly_t1);

% No-error condition: zero syndrome
if all(syndrome_t1 == 0)
    corrected_info_bits = received_word(1:k);
    return;
end

% Search in the syndrome table
row_index = find(ismember(syndrome_table_t1(:, 2:end), syndrome_t1, 'rows'));

if isempty(row_index)
    corrected_info_bits = received_word(1:k);
    return;
end

% Correction
error_position = syndrome_table_t1(row_index, 1);
corrected_word = received_word;
corrected_word(error_position) = mod(corrected_word(error_position) + 1, 2);
corrected_info_bits = corrected_word(1:k);

end