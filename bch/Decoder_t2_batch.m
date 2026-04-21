function corrected_info_bits = Decoder_t2_batch(received_words, syndrome_table_t2)
% Vectorized version: received_words is (num_words x n)
% Returns corrected_info_bits (num_words x k)

G2 = [1 1 0 1 1 0 1 0 0 1];
[~, n] = size(received_words);
k = n - length(G2);

% Compute syndromes for all words in one pass
[~, syndromes] = compute_crc_fast(received_words, G2);  % (num_words x r2)

% Initialize output with the first k bits
corrected_info_bits = received_words(:, 1:k);

% Error-free words: zero syndrome -> nothing to do
no_error = all(syndromes == 0, 2);
error_idx = find(~no_error);

if isempty(error_idx)
    return;
end

% Syndromes of words in error
error_syndromes = syndromes(error_idx, :);  % (ne x r2)

% Syndrome table (columns 3:end)
syndrome_table = syndrome_table_t2(:, 3:end);  % (496 x r2)

% Vectorized lookup: one ismember pass for all error syndromes
[found, row_idx] = ismember(error_syndromes, syndrome_table, 'rows');

for ii = 1:length(error_idx)
    if ~found(ii)
        continue;  % unknown syndrome -> keep the k bits unchanged
    end
    
    w    = error_idx(ii);
    pos1 = syndrome_table_t2(row_idx(ii), 1);
    pos2 = syndrome_table_t2(row_idx(ii), 2);
    
    corrected_word = received_words(w, :);
    corrected_word(pos1) = mod(corrected_word(pos1) + 1, 2);
    if pos2 ~= 0
        corrected_word(pos2) = mod(corrected_word(pos2) + 1, 2);
    end
    corrected_info_bits(w, :) = corrected_word(1:k);
end

end
