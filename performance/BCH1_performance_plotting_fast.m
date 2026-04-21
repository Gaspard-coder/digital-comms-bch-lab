function BCH1_performance_plotting_fast()
% ULTRA-OPTIMIZED version - fully vectorized, no word-by-word loop
% BCH(31,26) t=1 on BPSK AWGN channel

%% Parameters
symbol_energy = 1;
modulation_order = 2;
t_correction = 1;
info_bits_per_word = 26;
coded_bits_per_word = 31;
code_rate = info_bits_per_word/coded_bits_per_word;
generator_poly = [0 0 1 0 1];

min_errors = 200;     % increase for better precision
max_words = 2e7;      % increase for low SNR values
batch_words = 5000;   % batch size (larger = less overhead)

eb_n0_db = 0:0.5:10;  % you can go up to 12 without issues now

%% Precompute syndrome table (only once)
fprintf('Precomputing syndrome table...\n');
syndrome_lookup_t1 = build_syndrome_table_t1();

%% Simulation
ber_simulated = zeros(size(eb_n0_db));

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
        % Decoder_t1_batch takes (batch_words x coded_bits_per_word), returns (batch_words x info_bits_per_word)
        decoded_batch = Decoder_t1_batch(hard, syndrome_lookup_t1);
        
        %% --- ERROR COUNTING ---
        total_errors = total_errors + sum(bits_batch(:) ~= decoded_batch(:));
        total_bits   = total_bits + batch_words * info_bits_per_word;
    end
    
    ber_simulated(i) = total_errors / total_bits;
    fprintf('EbN0 = %5.1f dB | BER = %.3e | simulated words = %.2e\n', ...
             eb_n0_db(i), ber_simulated(i), total_bits/info_bits_per_word);
end

%% Theoretical curve
bit_error_prob = qfunc(sqrt(2 * code_rate * 10.^(eb_n0_db/10)));
ber_theoretical = zeros(size(eb_n0_db));
for idx = 1:length(bit_error_prob)
    ber_sum = 0;
    for j = t_correction+1:coded_bits_per_word
        ber_sum = ber_sum + j * nchoosek(coded_bits_per_word,j) * bit_error_prob(idx)^j * (1-bit_error_prob(idx))^(coded_bits_per_word-j);
    end
    ber_theoretical(idx) = ber_sum / info_bits_per_word;
end

%% Plot
%figure;
semilogy(eb_n0_db, ber_simulated,   'o-', 'LineWidth', 2, 'Color', [0,255,0]/255, 'MarkerSize', 6);
hold on;
semilogy(eb_n0_db, ber_theoretical, 's--','LineWidth', 2, 'Color', [102,255,102]/256,  'MarkerSize', 6);

%legend('Simulated BER BCH(31,26) t=1', 'Theoretical BER coded BPSK', 'Location', 'southwest');
grid on;
xlabel('E_b/N_0 (dB)', 'FontSize', 15);
ylabel('BER',          'FontSize', 15);
title('Coded BPSK Performance BCH(31,26) t=1 - AWGN channel', 'FontSize', 15);
set(gca, 'FontSize', 15);

end
