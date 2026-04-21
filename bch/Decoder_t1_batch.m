function corrected_info_bits = Decoder_t1_batch(received_words, syndrome_table_t1)
% Vectorized version: received_words is (num_words x n)
% Returns corrected_info_bits (num_words x k)

generator_poly_t1 = [0 0 1 0 1];
[num_words, n] = size(received_words);
k = n - length(generator_poly_t1);

% Compute syndromes for all words at once
[~, syndromes] = compute_crc_fast(received_words, generator_poly_t1);  % (num_words x r)

% Error-free words: zero syndrome
no_error_mask = all(syndromes == 0, 2);  % (num_words x 1) logical

% Initialize output
corrected_info_bits = received_words(:, 1:k);

% For words with errors, search in the table
error_indices = find(~no_error_mask);

if ~isempty(error_indices)
    error_syndromes = syndromes(error_indices, :);  % (num_errors x r)
    
    % Row-wise ismember against the table
    syndrome_table_only = syndrome_table_t1(:, 2:end);  % (n x r)
    
    % For each errored word, find the matching table row
    [found, row_indices] = ismember(error_syndromes, syndrome_table_only, 'rows');
    
    for ii = 1:length(error_indices)
        if found(ii)
            word_idx = error_indices(ii);
            error_position = syndrome_table_t1(row_indices(ii), 1);
            corrected_word = received_words(word_idx, :);
            corrected_word(error_position) = mod(corrected_word(error_position) + 1, 2);
            corrected_info_bits(word_idx, :) = corrected_word(1:k);
        end
        % Otherwise keep the first k bits unchanged (already initialized)
    end
end

end
