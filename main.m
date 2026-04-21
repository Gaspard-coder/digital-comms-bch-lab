clc;
clear;
close all;

% Data

info_bits = randi([0,1],[1,26]);    % randomly generated information bits (26 information bits for k = n-deg(g(x))

% Generator polynomial 1+x^2+x^5 with MSB on the left and LSB on the right (without
% the most significant bit because it corresponds to the feedback loop)
generator_polynomial = [0 0 1 0 1];

%% Question 2 : Standard coding operation (systematic shape)

codeword = compute_crc(info_bits,generator_polynomial);
disp('le mot de code est : ')
disp(codeword);

% Verification function by computing c(x) mod(g(x)), which must be 0 
verification_result = verify_modulo(codeword,generator_polynomial);
disp('la sortie du calcul du modulo est : ')
disp(verification_result);

%% Question 4 : BER=f(Eb/N0)
figure; hold on;

BPSK_performance_plotting();
BCH1_performance_plotting_fast();
BCH2_performance_plotting_fast();

legend('Simulated BER for BPSK', 'BER théorique BPSK', ...
       'Simulated BER for BCH(31,26) t=1', 'Theorical BER BCH(31,26) t=1', ...
       'Simulated BER for BCH(31,21) t=2', 'Theorical BER BCH(31,21) t=2', ...
       'Location', 'southwest', 'FontSize', 12);

grid on;
xlabel('E_b/N_0 (dB)', 'FontSize', 15);
ylabel('BER', 'FontSize', 15);
title(' BPSK / BCH(31,26) t=1 / BCH(31,21) t=2 — AWGN canal', 'FontSize', 15);
set(gca, 'FontSize', 15);
set(gca, 'Yscale', 'log')

%% Question 5 : display h for channels 1, 2 and 3 

for i = 1:3
    figure('Name', ['Channel Impulse Response ' num2str(i)]);
    h = response_channel(i); % Function call 

    line_hdl = stem(h);      % Plot display
    title(['Reponse Impulsionnelle du canal ' num2str(i)])
    xlabel('Index m')
    ylabel('Amplitude')
    grid on
    set(line_hdl,'linewidth',2)
    set(gca,'fontsize',15)
    set(get(gca,'title'),'fontsize',15)
    set(get(gca,'xlabel'),'fontsize',15)
    set(get(gca,'ylabel'),'fontsize',15)

end

%% Question 6 to 8 : plot BER=f(Eb/N0) for different modulations
figure; hold on;

BPSK_equalizer_plotting();
QAM8_equalizer_plotting();
QAM16_equalizer_plotting();
