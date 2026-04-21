function BPSK_performance_plotting()

num_bits = 1e7; % bits sent for the simulation
symbol_energy = 1; % Symbol energy is fixed to 1 joule for example
constellation_size = 2; % Constellation size
code_rate = 1; % Coding rate

info_bits = randi([0,1],num_bits,1);

% Encoding to be implemented later

% Modulation
modulated_signal = bits2symbols(info_bits,'PAM',2);

% Add Gaussian noise
eb_n0_db = 0:0.5:10;  % Eb/N0 range in dB
ber_simulated = zeros(size(eb_n0_db));
%{
for i = 1:length(eb_n0_db)

    noise_power = 10^(log10(symbol_energy/(code_rate*log2(constellation_size))) - eb_n0_db(i)/10);
    noise = sqrt(noise_power/2) * randn(size(modulated_signal));
    received_signal = modulated_signal + noise;

    % Normalization and demodulation
    hard_decision = sign(received_signal(:)); % +1 or -1, never any odd value
    demodulated_bits = symbols2bits(hard_decision, 'PAM', 2);

    % Optional decoding

    % Compare the number of errors
    num_errors = sum(info_bits(:) ~= demodulated_bits(:));
    ber_simulated(i) = num_errors / num_bits;

end
%}
% Generate all the noise at once as a matrix (num_bits x length(eb_n0_db))
noise_power_linear = (symbol_energy / (code_rate * log2(constellation_size))) * 10.^(-eb_n0_db/10);  % N0 vector for all Eb/N0 values
noise_matrix = sqrt(noise_power_linear/2) .* randn(num_bits, length(eb_n0_db));

% Received signal for all Eb/N0 values in a single operation
received_matrix = modulated_signal + noise_matrix;

% Hard decision over the whole matrix
hard_matrix = sign(received_matrix);

% BER for each column
%{
for i = 1:length(eb_n0_db)
    demodulated_bits = symbols2bits(hard_matrix(:,i), 'PAM', 2);
    num_errors = sum(info_bits ~= demodulated_bits(:));
    ber_simulated(i) = num_errors / num_bits;
end
%}

% Optimization without symbols2bits
demodulated_matrix = (hard_matrix + 1) / 2;  % converts +1/-1 to 1/0
ber_simulated = sum(info_bits ~= demodulated_matrix) / num_bits;
% Practical curve
semilogy(eb_n0_db, ber_simulated, 'o-');

% Theoretical BPSK curve
%gamma = (6*log2(constellation_size))/(constellation_size*constellation_size-1)

ber_theoretical = qfunc(sqrt(2 * 10.^(eb_n0_db/10)));
hold on;
semilogy(eb_n0_db, ber_theoretical, '--');

% Legend
%legend('Simulated BER', 'Theoretical BER', 'Location', 'southwest');
grid on;
xlabel('E_b/N_0 (dB)');
ylabel('BER');
title('BPSK Performance on AWGN Channel');


% Get plot handle
line_hdl = get(gca, 'children');
set(line_hdl, {'marker'}, {'none'; 's'})
set(line_hdl, {'color'}, {[255,102,102]/255; [255,0,00]/256})
set(line_hdl, 'linewidth', 2)


% Font size for all elements
set(gca, 'fontsize', 15)
set(get(gca, 'title'),  'fontsize', 15)
set(get(gca, 'xlabel'), 'fontsize', 15)
set(get(gca, 'ylabel'), 'fontsize', 15)
