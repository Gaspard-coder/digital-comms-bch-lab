function BPSK_coded_equalizer_plotting()
% Cross-evaluation of BPSK performance with coding (uncoded, BCH1, BCH2)
% on selective channels with equalizers (threshold, ZF, DFE)

%% Global Parameters
eb_n0_db = 0:2:20;               % SNR range (adjustable)
min_errors = 150;                % Minimum number of errors for statistical reliability
max_bits = 2e7;                  % Maximum number of bits to avoid infinite loops
batch_frames = 200;              % Number of frames per batch (speeds up computation)

% Frame and coding parameters
codeword_length = 31;            % BCH word length
words_per_frame = 10;            % Words per frame
equalized_frame_length = codeword_length * words_per_frame;        % Equalized frame size (310 symbols)
batch_words = words_per_frame * batch_frames; % Total number of words per batch

generator_poly_t1 = [0 0 1 0 1];               % BCH(31,26) generator
generator_poly_t2 = [1 1 0 1 1 0 1 0 0 1];     % BCH(31,21) generator

%% Precompute syndrome tables (to speed up execution)
fprintf('--- Precomputing syndrome tables ---\n');
syndrome_table_t1 = build_syndrome_table_t1();
syndrome_table_t2 = build_syndrome_table_t2();

%% Display labels
equalizer_names = {'Threshold Detector', 'Zero-Forcing (ZF)', 'Decision-Feedback (DFE)'};
code_names = {'Uncoded', 'BCH(31,26) t=1', 'BCH(31,21) t=2'};

%% Main Loop: Channels
for channel_id = 1:3
    fprintf('\n=== Evaluating Channel %d ===\n', channel_id);
    
    % Build the channel matrix H
    channel_impulse_response = response_channel(channel_id);  
    half_length = (length(channel_impulse_response) - 1) / 2;           
    center_idx = half_length + 1;                     
    row_H = zeros(1, equalized_frame_length); row_H(1:half_length+1) = channel_impulse_response(center_idx : end);       
    col_H = zeros(equalized_frame_length, 1); col_H(1:half_length+1) = flip(channel_impulse_response(1 : center_idx));   
    channel_matrix = toeplitz(col_H, row_H); 
    
    % Equalizer precomputations
    H_inv = inv(channel_matrix);           
    [Q, R] = qr(channel_matrix); Q_H = Q'; 
    
    % Create the figure for this channel
    figure('Name', sprintf('Channel %d Performance - Coded BPSK', channel_id), ...
           'Position', [100, 100, 1400, 500]);
    
    %% Loop: Equalizers (Threshold, ZF, DFE)
    for eq_id = 1:3
        subplot(1, 3, eq_id); hold on;
        
        %% Loop: Coding schemes (Uncoded, BCH1, BCH2)
        for code_id = 0:2
            
            % Parameter selection according to the code
            if code_id == 0       % Uncoded
                info_bits_per_word = 31; 
                R_code = 1;
            elseif code_id == 1   % BCH t=1
                info_bits_per_word = 26; 
                R_code = info_bits_per_word/codeword_length;
            elseif code_id == 2   % BCH t=2
                info_bits_per_word = 21; 
                R_code = info_bits_per_word/codeword_length;
            end
            
            ber_curve = zeros(size(eb_n0_db));
            
            % Loop: SNR
            for snr_idx = 1:length(eb_n0_db)
                snr = eb_n0_db(snr_idx);
                
                % Noise calculation (adjusted by coding rate R_code)
                N0 = (1 / R_code) * 10^(-snr/10); 
                sigma = sqrt(N0/2);
                
                total_errors = 0;
                total_bits = 0;
                
                % Batch simulation until enough errors are collected
                while total_errors < min_errors && total_bits < max_bits
                    
                    %% 1. Generation and Encoding
                    info_bits = randi([0, 1], batch_words, info_bits_per_word);
                    
                    if code_id == 0
                        coded_bits = info_bits; 
                    elseif code_id == 1
                        coded_bits = compute_crc_fast(info_bits, generator_poly_t1);
                    elseif code_id == 2
                        coded_bits = compute_crc_fast(info_bits, generator_poly_t2);
                    end
                    
                    % Reshape into frames of size equalized_frame_length=310 (columns = frames)
                    % The transpose lets BCH words be chained without breaking them
                    tx_bits_mat = reshape(coded_bits.', equalized_frame_length, batch_frames);
                    
                    %% 2. BPSK Modulation (0->-1, 1->1)
                    tx_symbols = 2 * tx_bits_mat - 1;
                    
                    %% 3. Channel + Noise
                    z_clean = channel_matrix * tx_symbols;
                    w_noise = sigma * (randn(equalized_frame_length, batch_frames) + 1i * randn(equalized_frame_length, batch_frames));
                    z_received = z_clean + w_noise;
                    
                    %% 4. Equalization
                    if eq_id == 1       % THRESHOLD
                        rx_symbols = sign(real(z_received));
                        
                    elseif eq_id == 2   % ZF
                        z_zf = H_inv * z_received;
                        rx_symbols = sign(real(z_zf));
                        
                    elseif eq_id == 3   % DFE
                        z_tilde = Q_H * z_received;
                        rx_symbols = zeros(equalized_frame_length, batch_frames);
                        for idx_k = equalized_frame_length:-1:1
                            if idx_k == equalized_frame_length
                                interference = zeros(1, batch_frames);
                            else
                                interference = R(idx_k, idx_k+1:equalized_frame_length) * rx_symbols(idx_k+1:equalized_frame_length, :);
                            end
                            soft_symbols = (z_tilde(idx_k,:) - interference) / R(idx_k,idx_k);
                            rx_symbols(idx_k,:) = sign(real(soft_symbols));
                        end
                    end
                    rx_symbols(rx_symbols == 0) = 1; % Safety if sign() returns 0
                    
                    %% 5. Demodulation and Decoding
                    rx_bits_mat = double(rx_symbols > 0);
                    
                    % Return to dimensions (batch_words x codeword_length)
                    rx_words = reshape(rx_bits_mat, codeword_length, batch_words).';
                    
                    if code_id == 0
                        rx_info = rx_words;
                    elseif code_id == 1
                        rx_info = Decoder_t1_batch(rx_words, syndrome_table_t1);
                    elseif code_id == 2
                        rx_info = Decoder_t2_batch(rx_words, syndrome_table_t2);
                    end
                    
                    %% 6. Error counting
                    total_errors = total_errors + sum(info_bits(:) ~= rx_info(:));
                    total_bits = total_bits + (batch_words * info_bits_per_word);
                end
                
                % Store BER
                ber_curve(snr_idx) = total_errors / total_bits;
            end
            
            % Display the curve on the active subplot
            markers = {'o-', 's--', 'd-.'};
            colors = {[0 0 0], [0 0.5 0], [0 0 1]}; % Black, Green, Blue
            
            semilogy(eb_n0_db, ber_curve, markers{code_id+1}, ...
                     'LineWidth', 2, 'Color', colors{code_id+1}, ...
                     'DisplayName', code_names{code_id+1});
        end
        
        % Subplot decoration
        set(gca, 'YScale', 'log');
        ylim([1e-5 1]);
        grid on;
        title(equalizer_names{eq_id}, 'FontSize', 14);
        xlabel('E_b/N_0 (dB)', 'FontSize', 12);
        if eq_id == 1
            ylabel('BER', 'FontSize', 12);
        end
        legend('show', 'Location', 'southwest');
        set(gca, 'FontSize', 12);
    end
    
    sgtitle(sprintf('Performance on Channel %d (Frame = %d, Modulation = BPSK)', channel_id, equalized_frame_length), ...
            'FontSize', 16, 'FontWeight', 'bold');
end
end