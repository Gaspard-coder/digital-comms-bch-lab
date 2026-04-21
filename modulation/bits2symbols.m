%% [symbols] = bits2symbols(bit_sequence, modulation_type, constellation_size)
%%
%% bit_sequence = bits sequence
%% modulation_type = constellation type ('PAM','PSK','QAM')
%% constellation_size = constellation size
%%
%% symbols = symbol sequence (with Eb=1 when uncoded bits are sent) associated with the bits sequence
%%


%% Author: Philippe Ciblat (ciblat@telecom-paris.fr)
%% Location: Telecom Paris
%% Date: 22/07/2021


function [symbols]=bits2symbols(bit_sequence, modulation_type, constellation_size)

bits_per_symbol = log2(constellation_size);

%% Size check
if ((length(bit_sequence)-bits_per_symbol*floor(length(bit_sequence)/bits_per_symbol))~=0)
    disp('Bit sequence length is not compatible with the constellation size')
    symbols = 0;
    return;
end

%% PAM constellation
if (modulation_type=='PAM')
    bit_matrix = reshape(bit_sequence,bits_per_symbol,floor(length(bit_sequence)/bits_per_symbol))';
    decimal_symbols = bin2dec(num2str(bit_matrix(:,[1:bits_per_symbol])));
    gray_decimal_symbols = bitxor(decimal_symbols,floor(decimal_symbols/2));
    
    symbols = gray_decimal_symbols*2-constellation_size+1;
    symbols = sqrt(log2(constellation_size))*symbols/sqrt(sum(([0:constellation_size-1]*2-constellation_size+1).^2)/constellation_size);%% energy normalization
end

%% PSK constellation
if(modulation_type=='PSK')
    bit_matrix = reshape(bit_sequence,bits_per_symbol,floor(length(bit_sequence)/bits_per_symbol))';
    decimal_symbols = bin2dec(num2str(bit_matrix(:,[1:bits_per_symbol])));
    gray_decimal_symbols = bitxor(decimal_symbols,floor(decimal_symbols/2));
    
    symbols = sqrt(log2(constellation_size))*exp(2*1i*pi*(gray_decimal_symbols/constellation_size));
end


%% QAM constellation
if(modulation_type=='QAM')
    if (floor(sqrt(constellation_size))^2-constellation_size ==0)
        bit_matrix = reshape(bit_sequence,bits_per_symbol,floor(length(bit_sequence)/bits_per_symbol))';
        
        % Take the first bits to encode the real axis
        real_decimal = bin2dec(num2str(bit_matrix(:,[1:bits_per_symbol/2])));
        gray_real_decimal = bitxor(real_decimal,floor(real_decimal/2));
        
        % Take the last bits to encode the imaginary axis
        imag_decimal = bin2dec(num2str(bit_matrix(:,[bits_per_symbol/2+1:bits_per_symbol])));
        gray_imag_decimal = bitxor(imag_decimal,floor(imag_decimal/2));
        
        side_length = floor(sqrt(constellation_size));
        
        symbols = (gray_real_decimal*2-side_length+1)+1i*(gray_imag_decimal*2-side_length+1);
        symbols = sqrt(bits_per_symbol)*symbols/sqrt(2*sum(([0:side_length-1]*2-side_length+1).^2)/side_length);%% energy normalization
        
    elseif(constellation_size==8)
        % disp('Generating cross 8-QAM');
        constellation = [(1+sqrt(3))*1i; 1+1i; 1+sqrt(3); 1-1i; -(1+sqrt(3)); -1+1i;-(1+sqrt(3))*1i; -1-1i];
        bit_matrix = reshape(bit_sequence,bits_per_symbol,[]).';
        symbol_index = 1 + bit_matrix*2.^(bits_per_symbol-1:-1:0)';
        symbols = constellation(symbol_index);
        symbols = symbols*sqrt(bits_per_symbol)./sqrt(mean(abs(constellation).^2)); % Normalize to average energy Es = 3Eb and Eb = 1;
    else
        
        disp ('Error: constellation size has to be square or equal to 8');
        symbols = 0;
        return;
    end
end


end




