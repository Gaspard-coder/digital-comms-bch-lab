% [symbols] = symbols_lut(modulation_type, constellation_size)
%%
%% Look Up Table for various constellations
%%
%% modulation_type = constellation type
%% constellation_size = constellation size
%%
%% symbols = vector with all symbols of the considered constellation

%% Location: Telecom ParisTech
%% Author:  Ph. Ciblat <ciblat@telecom-paristech.fr>
%% Date : 16/10/2018

function [symbols] = symbols_lut(modulation_type, constellation_size)

if (constellation_size-2^(floor(log2(constellation_size)))~= 0)
    disp ('Error: constellation_size is not a power of 2');
    symbols = 0;
    return;
end


if(modulation_type=='PAM')
    symbols = [0:(constellation_size-1)]*2-constellation_size+1;
    symbols = sqrt(log2(constellation_size))*symbols/sqrt(sum(([0:constellation_size-1]*2-constellation_size+1).^2)/constellation_size);
end

if(modulation_type=='PSK')
    symbols = sqrt(log2(constellation_size))*exp(2*i*pi*([0:(constellation_size-1)]/constellation_size));
end

if(modulation_type=='QAM')
    if (floor(sqrt(constellation_size))^2-constellation_size ==0)
        side_length = floor(sqrt(constellation_size));
        
        for jj=0:(side_length-1)
            symbols(1,[1:side_length]+jj*side_length) = [0:(side_length-1)]*2-side_length+1+1i*(jj*2-side_length+1);
        end
        
        symbols = sqrt(log2(constellation_size))*symbols/sqrt(2*sum(([0:side_length-1]*2-side_length+1).^2)/side_length);
    
    elseif (constellation_size==8)
        symbols = [(1+sqrt(3))*1i; 1+1i; 1+sqrt(3); 1-1i; -(1+sqrt(3)); -1+1i;-(1+sqrt(3))*1i; -1-1i].';
        symbols = symbols*sqrt(log2(constellation_size))./sqrt(mean(abs(symbols).^2)); % Normalize to average energy Es = 3Eb and Eb =1;
        
    else
        disp ('Error: constellation_size has to be square or equal to 8');
        symbols = 0;
        return;
    end
    
    
end

if(modulation_type=='OOK')
    symbols = [0:(constellation_size-1)] * sqrt(constellation_size * log2(constellation_size) * 6 / ((constellation_size-1)*constellation_size*(2*constellation_size-1)));
end
