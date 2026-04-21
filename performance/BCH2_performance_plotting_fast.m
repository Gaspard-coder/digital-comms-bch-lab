function BCH2_performance_plotting_fast()
% ULTRA-OPTIMIZED version - fully vectorized, no word-by-word loop
% BCH(31,21) t=2 on BPSK AWGN channel

%% Parameters
symbol_energy = 1;
modulation_order = 2;
correction_capability = 2;
info_bits_per_word = 21;
coded_bits_per_word = 31;
code_rate = info_bits_per_word/coded_bits_per_word;
generator_poly = [1 1 0 1 1 0 1 0 0 1];

min_errors = 200;     % increase for better precision
max_words = 2e8;      % limit for low SNR values
batch_words = 5000;   % batch size (larger = less overhead)

eb_n0_db = 0:0.5:10;  % you can go up to 12 dB

%% Precompute syndrome table (only once, 496 rows)
fprintf('Precomputing syndrome table for t=2...\n');
syndrome_lookup_t2 = build_syndrome_table_t2();
fprintf('Table built: %d rows.\n', size(syndrome_lookup_t2, 1));

%% Simulation
ber_simulated = zeros(size(eb_n0_db));
ber_uncertainty = zeros(size(eb_n0_db)); % Uncertainty array

for i = 1:length(eb_n0_db)
    total_errors = 0;
    total_bits   = 0;
    
    noise_power = (symbol_energy / (code_rate * log2(modulation_order))) * 10^(-eb_n0_db(i)/10);
    sigma = sqrt(noise_power/2);
    
    while total_errors < min_errors && total_bits/info_bits_per_word < max_words
        
        %% --- GENERATION (vectorized) ---
        % bits_batch: (batch_words x info_bits_per_word)
        bits_batch = randi([0,1], batch_words, info_bits_per_word);
        
        %% --- VECTORIZED ENCODING ---
        % compute_crc_fast accepts a matrix (batch_words x info_bits_per_word)
        % -> coded_batch: (batch_words x coded_bits_per_word)
        coded_batch = compute_crc_fast(bits_batch, generator_poly);
        
        %% --- MODULATION + NOISE + HARD DECISION ---
        % BPSK: 0 -> -1, 1 -> +1
        tx   = 2*coded_batch - 1;                        % (batch_words x n)
        rx   = tx + sigma * randn(batch_words, coded_bits_per_word);  % AWGN noise
        hard = double(rx > 0);                           % hard decision -> 0/1
        
        %% --- VECTORIZED DECODING ---
        % Decoder_t2_batch takes (batch_words x coded_bits_per_word), returns (batch_words x info_bits_per_word)
        decoded_batch = Decoder_t2_batch(hard, syndrome_lookup_t2);
        
        %% --- ERROR COUNTING ---
        total_errors = total_errors + sum(bits_batch(:) ~= decoded_batch(:));
        total_bits   = total_bits + batch_words * info_bits_per_word;
    end
    
    ber_simulated(i) = total_errors / total_bits;

    % Compute the half-width of the confidence interval (95%)
    % Binomial proportion standard deviation formula * 1.96
    ber_uncertainty(i) = 1.96 * sqrt((ber_simulated(i) * (1 - ber_simulated(i))) / total_bits);

    fprintf('EbN0 = %5.1f dB | BER = %.3e | simulated words = %.2e\n', ...
             eb_n0_db(i), ber_simulated(i), total_bits/info_bits_per_word);
end

%% Theoretical curve
p = qfunc(sqrt(2 * code_rate * 10.^(eb_n0_db/10)));
ber_theoretical = zeros(size(eb_n0_db));
for idx = 1:length(p)
    sum_terms = 0;
    for j = correction_capability+1:coded_bits_per_word
        sum_terms = sum_terms + j * nchoosek(coded_bits_per_word,j) * p(idx)^j * (1-p(idx))^(coded_bits_per_word-j);
    end
    ber_theoretical(idx) = sum_terms / info_bits_per_word;
end

%% Plot
%figure;
%semilogy(eb_n0_db, ber_simulated,        'o-', 'LineWidth', 2, 'Color', [0,0,255]/255, 'MarkerSize', 6);
errorbar(eb_n0_db, ber_simulated, ber_uncertainty, 'o-', 'LineWidth', 2, 'Color', [0,0,255]/255, 'MarkerSize', 6);
hold on;
semilogy(eb_n0_db, ber_theoretical, 's--','LineWidth', 2, 'Color', [102,102,255]/256,  'MarkerSize', 6);

set(gca, 'YScale', 'log');
%legend('Simulated BER BCH(31,21) t=2', 'Theoretical coded BPSK BER', 'Location', 'southwest');
grid on;
xlabel('E_b/N_0 (dB)', 'FontSize', 15);
ylabel('BER',          'FontSize', 15);
title('Coded BPSK performance BCH(31,21) t=2 - AWGN channel', 'FontSize', 15);
set(gca, 'FontSize', 15);

end
