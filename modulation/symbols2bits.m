%% [bits] = symbols2bits(symbols, modulation_type, constellation_size)
%%
%%
%% symbols = symbols sequence
%% modulation_type = constellation type ('PAM','PSK','QAM')
%% constellation_size = constellation size
%%
%% bits = bit sequence (associated with the symbols sequence)
%%


%% Author: Philippe Ciblat (ciblat@telecom-paris.fr)
%% Location: Telecom Paris
%% Date: 22/07/2021

function [bits]=symbols2bits(symbols, modulation_type, constellation_size)

bits_per_symbol = log2(constellation_size);

%% PAM demapping
if (modulation_type=='PAM')
    
    % Gray-Binary lookup table
    input_binary = [0:constellation_size-1];
    output_gray = bitxor(input_binary,floor(input_binary/2));
    [~, gray_index] = sort(output_gray);
    
    % PAM renormalization
    symbols = sqrt(sum(([0:constellation_size-1]*2-constellation_size+1).^2)/constellation_size)*symbols/sqrt(log2(constellation_size));
    symbol_index = (symbols+constellation_size-1)/2;
    
    % Sort Gray code elements to form the lookup table
    decimal_output = gray_index(symbol_index+1)-1;
    binary_matrix = dec2bin([decimal_output,constellation_size-1]);
    selected_rows = binary_matrix([1:length(symbols)] ,:);
    bit_string = reshape(selected_rows',1,bits_per_symbol*length(symbols));

    bits = bit_string - '0';
    % for ii=1:(m*length(s)) 
    %     a(ii)=str2num(d(ii));
    % end
    
end

%% PSK demapping
if (modulation_type=='PSK')
    
    % Gray-Binary lookup table
    input_binary = [0:constellation_size-1];
    output_gray = bitxor(input_binary,floor(input_binary/2));
    [~, gray_index] = sort(output_gray);
    
    % PAM renormalization
    symbol_index = constellation_size*angle(symbols/sqrt(log2(constellation_size)))/(2*pi);
    symbol_index = round(symbol_index-constellation_size*floor(symbol_index/constellation_size));
    
    
    % Sort Gray code elements to form the lookup table
    decimal_output = gray_index(symbol_index+1)-1;
    binary_matrix = dec2bin([decimal_output,constellation_size-1]);
    selected_rows = binary_matrix([1:length(symbols)] ,:);
    bit_string = reshape(selected_rows',1,bits_per_symbol*length(symbols));
    for ii=1:(bits_per_symbol*length(symbols)) bits(ii)=str2num(bit_string(ii));
    end
    
end

%% QAM demapping
if(modulation_type=='QAM')
    if (floor(sqrt(constellation_size))^2-constellation_size ==0)
        
    % Gray-Binary lookup table
    input_binary = [0:constellation_size-1];
    output_gray = bitxor(input_binary,floor(input_binary/2));
    [~, gray_index] = sort(output_gray);
    
    symbols_real = real(symbols);
    symbols_imag = imag(symbols);
    
    % QAM renormalization
    side_length = floor(sqrt(constellation_size));
    symbols = sqrt(2*sum(([0:side_length-1]*2-side_length+1).^2)/side_length)*symbols/sqrt(log2(constellation_size));
    symbols_real = real(symbols);
    symbols_imag = imag(symbols);
    
    real_index = (symbols_real+side_length-1)/2;
    imag_index = (symbols_imag+side_length-1)/2;
    
    % Sort Gray code elements to form the lookup table
    decimal_output_real = gray_index(real_index+1)-1;
    decimal_output_imag = gray_index(imag_index+1)-1;
    
    binary_real = dec2bin([decimal_output_real,side_length-1]);
    binary_imag = dec2bin([decimal_output_imag,side_length-1]);
    
    binary_matrix = [binary_real,binary_imag];
    
    selected_rows = binary_matrix([1:length(symbols)] ,:);
    bit_string = reshape(selected_rows',1,bits_per_symbol*length(symbols));
    % for ii=1:(m*length(s)) 
    %     a(ii)=str2num(d(ii));
    % end
    bits = bit_string - '0';
    
    elseif(constellation_size==8) % assumes cross 8-QAM
        %constellation = [(1+sqrt(3))*1i; 1+1i; 1+sqrt(3); 1-1i; -(1+sqrt(3)); -1+1i;-(1+sqrt(3))*1i; -1-1i];      
        [~,location] = threshold_detector(symbols,modulation_type,constellation_size) ;
        location = location -1;
        binary_output = dec2bin(location,bits_per_symbol);
        bit_string = reshape(binary_output',1,length(location)*bits_per_symbol);
        % for ii=1:(length(b)) 
        %     a(ii)=str2num(b(ii));
        % end
        bits = bit_string - '0';


    else
        disp ('Error: constellation size has to be square or equal to 8');
        return;
    end
end





