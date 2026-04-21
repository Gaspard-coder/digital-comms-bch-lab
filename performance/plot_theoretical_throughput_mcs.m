function plot_theoretical_throughput_mcs()
% Computes and plots the theoretical throughput T as a function of Es/N0
% for 9 MCS configurations (BPSK, 8QAM, 16QAM crossed with Uncoded, BCH1, BCH2)

%% System Parameters
symbol_duration = 0.05e-6;      % Symbol duration (0.05 µs according to the assignment)
symbol_rate = 1 / symbol_duration; % Symbol rate (20 MBauds)
codeword_length = 31;           % BCH codeword length
es_n0_db = 0:0.5:20;            % Es/N0 range (in dB)
es_n0_lin = 10.^(es_n0_db/10);

%% Definition of the 9 MCSs (Modulation and Coding Schemes)
% Each row: [M, k, t]
% M = constellation size (2, 8, 16)
% k = number of information bits (31=Uncoded, 26=BCH1, 21=BCH2)
% t = correction capability (0, 1, 2)
mcs_list = [
    2, 31, 0;  % 1: BPSK Uncoded
    2, 26, 1;  % 2: BPSK BCH1
    2, 21, 2;  % 3: BPSK BCH2
    8, 31, 0;  % 4: 8QAM Uncoded
    8, 26, 1;  % 5: 8QAM BCH1
    8, 21, 2;  % 6: 8QAM BCH2
   16, 31, 0;  % 7: 16QAM Uncoded
   16, 26, 1;  % 8: 16QAM BCH1
   16, 21, 2   % 9: 16QAM BCH2
];

labels = {'BPSK Uncoded', 'BPSK + BCH1', 'BPSK + BCH2', ...
          '8-QAM Uncoded', '8-QAM + BCH1', '8-QAM + BCH2', ...
          '16-QAM Uncoded', '16-QAM + BCH1', '16-QAM + BCH2'};

colors = {[0 0 1], [1 0 0], [0 0.5 0]}; % BPSK: Blue, 8QAM: Red, 16QAM: Green
line_styles = {'-', '--', '-.'};        % Uncoded: -, BCH1: --, BCH2: -.

%% Figure Setup
figure('Name', 'Theoretical Throughput vs Es/N0', 'Position', [100, 100, 900, 600]);
hold on;

%% Compute and plot for each MCS
for i = 1:size(mcs_list, 1)
    
    modulation_order = mcs_list(i, 1);
    info_bits_per_word = mcs_list(i, 2);
    correction_capability = mcs_list(i, 3);
    bits_per_symbol = log2(modulation_order);
    
    % 1. Compute the raw BER (p) according to the modulation (analytical formulas)
    if modulation_order == 2
        p = qfunc(sqrt(2 * es_n0_lin));
    elseif modulation_order == 8
        % Standard approximation for 8-QAM
        p = (2/3) * qfunc(sqrt((6/7) * es_n0_lin)); 
    elseif modulation_order == 16
        % Exact expression for 16-QAM
        p = (3/4) * qfunc(sqrt((1/5) * es_n0_lin)); 
    end
    
    % 2. Compute BER after decoding (BER_dec)
    ber_decoded = zeros(size(p));
    if correction_capability == 0
        ber_decoded = p; % No coding
    else
        for idx = 1:length(p)
            sum_terms = 0;
            for j = (correction_capability+1):codeword_length
                sum_terms = sum_terms + j * nchoosek(codeword_length, j) * (p(idx)^j) * ((1-p(idx))^(codeword_length-j));
            end
            ber_decoded(idx) = sum_terms / info_bits_per_word;
        end
    end
    
    % 3. Compute the Frame Success Rate (FSR)
    % According to the formula in your report: (1 - BER_dec)^k
    frame_success_rate = (1 - ber_decoded).^info_bits_per_word;
    
    % 4. Compute throughput T (in Mbps)
    % T = FSR * (k/n) * log2(M) * (1/Ts)
    throughput_bps = frame_success_rate .* (info_bits_per_word / codeword_length) .* bits_per_symbol .* symbol_rate;
    throughput_mbps = throughput_bps / 1e6; 
    
    % Visual choices (Color = Modulation, Style = Coding)
    modulation_idx = log2(modulation_order)/log2(2); 
    if modulation_order == 8, modulation_idx = 2; elseif modulation_order == 16, modulation_idx = 3; end % Mapping index
    
    style_idx = correction_capability + 1;
    
    % Plot
    plot(es_n0_db, throughput_mbps, 'LineWidth', 2.5, ...
         'Color', colors{modulation_idx}, 'LineStyle', line_styles{style_idx}, ...
         'DisplayName', labels{i});
end

%% Plot Styling
grid on;
set(gca, 'FontSize', 14);
xlabel('E_s/N_0 (dB)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Throughput T (Mbps)', 'FontSize', 14, 'FontWeight', 'bold');
title('Theoretical throughput as a function of E_s/N_0 for different codings and modulations (AWGN, Threshold)', 'FontSize', 16);
legend('Location', 'northwest', 'FontSize', 11, 'NumColumns', 3);

% Set limits to keep the plot clean
xlim([0 20]);
ylim([0 85]);

end