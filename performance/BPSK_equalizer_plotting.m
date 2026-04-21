function BPSK_equalizer_plotting()

%% System Parameters

modulation_type = 'PAM';           % Modulation type ('PAM' for BPSK, 'QAM' for 8-QAM or 16-QAM)
constellation_size = 2;            % Constellation size (2, 8, or 16)
bits_per_symbol = log2(constellation_size);           % Number of bits per symbol

frame_length = 100;                            % Frame length
num_frames = 1000;                             % Number of frames simulated in parallel
eb_n0_db = 0:1:20;                             % Eb/N0 range in dB
num_snr_points = length(eb_n0_db);             % Number of SNR points
total_bits_per_snr = frame_length * bits_per_symbol * num_frames; % Bits per SNR block

%% Precompute the reference ideal constellation

all_bits = zeros(bits_per_symbol, constellation_size);
for idx = 0:constellation_size-1
    all_bits(:, idx+1) = dec2bin(idx, bits_per_symbol) - '0'; 
end
ideal_constellation = bits2symbols(all_bits(:), modulation_type, constellation_size);
ideal_constellation = ideal_constellation(:).'; % Row vector (1 x M)

%% Loop over the three different channels (channel 1, 2 and 3)
for channel_id = 1:3
    
    fprintf('\n Evaluating Channel %d \n', channel_id);
    
    %% Retrieve the channel and build matrix H

    channel_response = response_channel(channel_id);  
    half_length = (length(channel_response) - 1) / 2;           
    center_idx = half_length + 1;                     

    row_H = zeros(1, frame_length); row_H(1:half_length+1) = channel_response(center_idx : end);       
    col_H = zeros(frame_length, 1); col_H(1:half_length+1) = flip(channel_response(1 : center_idx));   
    H = toeplitz(col_H, row_H); % Toeplitz matrix [cite: 123-143]                                        

    % Preliminary equalizer computations
    H_inv = inv(H);           % For ZF
    [Q, R] = qr(H); Q_H = Q'; % For DFE

    %% Generation and Modulation of information words
    bits_matrix = randi([0 1], frame_length * bits_per_symbol, num_frames);

    symbol_vector = bits2symbols(bits_matrix(:), modulation_type, constellation_size);
    symbol_matrix = reshape(symbol_vector, frame_length, num_frames);    

    %% Matrix optimization (remove the SNR loop)
    % Duplicate symbol_matrix and z_clean for each SNR value
    z_clean = H * symbol_matrix; 
    z_clean_all = repmat(z_clean, 1, num_snr_points);
    
    % Compute noise powers for all SNR values
    snr_linear = 10.^(eb_n0_db/10);
    N0 = 1 ./ (bits_per_symbol * snr_linear); 
    sigma_noise = sqrt(N0/2);
    
    % Repeat each sigma value to expand it to the corresponding num_frames frames
    sigma_expanded = repelem(sigma_noise, num_frames);
    
    % Generate ALL noise at once with element-wise vector multiplication (.*)
    w_all = sigma_expanded .* (randn(frame_length, num_frames * num_snr_points) + 1i*randn(frame_length, num_frames * num_snr_points));
    
    % Global received signal for all SNR values in a single addition
    z_all = z_clean_all + w_all;
    
    % Reference matrix containing duplicated bits in columns (for BER computation at the end)
    bits_reference_mat = repmat(bits_matrix(:), 1, num_snr_points);

    %% Equalizer 1: Threshold detection
    threshold_distances = abs(z_all(:) - ideal_constellation).^2;      
    [~, min_idx_threshold] = min(threshold_distances, [], 2);    
    
    estimated_bits_threshold = symbols2bits(ideal_constellation(min_idx_threshold).', modulation_type, constellation_size);
    
    % Reshape into a matrix (total_bits_per_snr x num_snr_points) and compute BER per column
    ber_threshold = sum(reshape(estimated_bits_threshold, total_bits_per_snr, num_snr_points) ~= bits_reference_mat, 1) / total_bits_per_snr;
    
    %% Equalizer 2: Zero Forcing (ZF)
    
    % Channel cancellation by matrix inversion
    z_zf_all = H_inv * z_all; 
    
    % Compute distances to the ideal constellation points
    zf_distances = abs(z_zf_all(:) - ideal_constellation).^2;
    
    % Hard decision: select the closest point
    [~, min_idx_zf] = min(zf_distances, [], 2);
    
    % Demodulation: convert selected symbols into bits
    estimated_bits_zf = symbols2bits(ideal_constellation(min_idx_zf).', modulation_type, constellation_size);
    
    % Reshape and compute BER for each SNR
    ber_zf = sum(reshape(estimated_bits_zf, total_bits_per_snr, num_snr_points) ~= bits_reference_mat, 1) / total_bits_per_snr;
    
    
    %% Equalizer 3: Decision-Feedback (DFE)
    
    % Feed-forward filtering via matrix Q
    z_tilde_all = Q_H * z_all;
    
    % Initialize the decision matrix
    estimated_symbols_dfe_all = zeros(frame_length, num_frames * num_snr_points);
    
    % Feedback loop, from end to beginning
    for k = frame_length:-1:1
        if k == frame_length
            % No future interference for the last symbol
            interference = zeros(1, num_frames * num_snr_points); 
        else
            % Compute the interference caused by already decided symbols
            interference = R(k, k+1:frame_length) * estimated_symbols_dfe_all(k+1:frame_length, :);
        end
        
        % Subtract interference and normalize
        soft_symbols = (z_tilde_all(k, :) - interference) / R(k, k);
        
        % Compute distances for the decision
        dfe_distances = abs(soft_symbols(:) - ideal_constellation).^2; 
        
        % Hard decision
        [~, min_idx_dfe] = min(dfe_distances, [], 2);
        
        % Store the ideal symbol found for the next iteration
        estimated_symbols_dfe_all(k, :) = reshape(ideal_constellation(min_idx_dfe), 1, num_frames * num_snr_points);
    end
    
    % Demodulation: convert chosen symbols into bits
    estimated_bits_dfe = symbols2bits(estimated_symbols_dfe_all(:), modulation_type, constellation_size);
    
    % Reshape and compute BER for each SNR
    ber_dfe = sum(reshape(estimated_bits_dfe, total_bits_per_snr, num_snr_points) ~= bits_reference_mat, 1) / total_bits_per_snr;
    
    %% Display the figure for the current channel
    figure('Name', ['Channel Performance ' num2str(channel_id)]);
    
    semilogy(eb_n0_db, ber_threshold, 'k-s', 'LineWidth', 2, 'DisplayName', 'Threshold Detector'); hold on;
    semilogy(eb_n0_db, ber_zf,        'b-o', 'LineWidth', 2, 'DisplayName', 'Zero-Forcing (ZF)');
    semilogy(eb_n0_db, ber_dfe,       'r-*', 'LineWidth', 2, 'DisplayName', 'Decision-Feedback (DFE)');

    grid on;
    title(['Equalizer Comparison - Channel ' num2str(channel_id)]);
    xlabel('E_b/N_0 (dB)');
    ylabel('Bit Error Rate (BER)');
    legend('show', 'Location', 'southwest');

    % Adjust font size to match section 4.1 of the document
    set(gca, 'FontSize', 15);
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15); % [cite: 660-665]
    
end