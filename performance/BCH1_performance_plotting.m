function BCH1_performance_plotting()

num_bits = 1e7; % bits sent for the simulation
symbol_energy = 1; % Symbol energy is fixed to 1 joule for example
modulation_order = 2; % Constellation cardinality

info_bits_per_word = 26;
coded_bits_per_word = 31;
code_rate = info_bits_per_word/coded_bits_per_word; % Coding rate

% Make num_bits a multiple of info_bits_per_word
num_bits = floor(num_bits / info_bits_per_word) * info_bits_per_word;
info_bits = randi([0,1], num_bits, 1);

% Word-by-word encoding
num_words = num_bits / info_bits_per_word;
% Convert the vector into a matrix (each column is one info_bits_per_word-bit word)
info_bits_matrix = reshape(info_bits, info_bits_per_word, num_words);

%% Information word encoding
coded_matrix = zeros(coded_bits_per_word, num_words);

generator_poly = [0 0 1 0 1]; 

for w = 1:num_words
    % Column-wise access is much faster in MATLAB
    coded_matrix(:, w) = compute_crc(info_bits_matrix(:, w)', generator_poly)';
end
% Instant vectorization
coded_bits = coded_matrix(:);

% coded_bits = zeros(num_words * coded_bits_per_word, 1);
% for w = 1:num_words
%     word = info_bits((w-1)*info_bits_per_word+1 : w*info_bits_per_word);
%     coded_bits((w-1)*coded_bits_per_word+1 : w*coded_bits_per_word) = compute_crc(word', [0 0 1 0 1]); % Input must be a row vector
% end

%% Modulation
modulated_signal = bits2symbols(coded_bits, 'PAM', 2);
num_coded_symbols = length(modulated_signal);

% Add Gaussian noise
eb_n0_db = 0:0.5:10;  % Eb/N0 range in dB

% Generate all noise at once as a matrix (num_coded_symbols x length(eb_n0_db))
noise_power_linear = (symbol_energy / (code_rate * log2(modulation_order))) * 10.^(-eb_n0_db/10);  % N0 vector for all Eb/N0 points
noise_matrix = sqrt(noise_power_linear/2) .* randn(num_coded_symbols, length(eb_n0_db));

% Received signal for all Eb/N0 points in a single operation
received_matrix = modulated_signal(:) + noise_matrix;

% Hard decision over the whole matrix
hard_matrix = (sign(received_matrix) + 1) / 2;  % +1/-1 -> 1/0 directly

%% BER for each column
ber_simulated = zeros(size(eb_n0_db));
syndrome_table_t1 = build_syndrome_table_t1();

for i = 1:length(eb_n0_db)

    demodulated_bits = hard_matrix(:,i);
    
    % Convert the received column into a matrix of coded_bits_per_word-sized words
    hard_matrix_reshaped = reshape(demodulated_bits, coded_bits_per_word, num_words);
    decoded_matrix = zeros(info_bits_per_word, num_words);

    for w = 1:num_words
        % Direct column-wise calls avoid slowing MATLAB down with heavy indexing
        decoded_matrix(:, w) = Decoder_t1(hard_matrix_reshaped(:, w), syndrome_table_t1);
    end
    
    % Re-vectorization and BER computation
    decoded_bits = decoded_matrix(:);
    ber_simulated(i) = sum(info_bits ~= decoded_bits) / num_bits;
end

% Practical curve
semilogy(eb_n0_db, ber_simulated, 'o-');

% BCH1 theoretical curve
%gamma = (6*log2(C))/(C*C-1)
ber_theoretical = qfunc(sqrt(2 * 10.^(eb_n0_db/10)));
hold on;
semilogy(eb_n0_db, ber_theoretical, '--');

% Legend
legend('Simulated BER BCH(31,26) t=1', 'Theoretical BER uncoded BPSK', 'Location', 'southwest');
grid on;
xlabel('E_b/N_0 (dB)');
ylabel('BER');
title('Coded BPSK performance with BCH(31,26) correcting t = 1 error on AWGN channel');


% Get plot handle
line_handle = get(gca, 'children');
set(line_handle, {'marker'}, {'none'; 's'})
set(line_handle, {'color'}, {[252,119,83]/256; [64,61,88]/256})
set(line_handle, 'linewidth', 2)


% Font size for all elements
set(gca, 'fontsize', 15)
set(get(gca, 'title'),  'fontsize', 15)
set(get(gca, 'xlabel'), 'fontsize', 15)
set(get(gca, 'ylabel'), 'fontsize', 15)
