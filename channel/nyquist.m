%% [h] = nyquist (t, T, r)
%%
%% Nyquist filter (raised cosine)
%%
%%  t = time index t (1xN)
%%  T = filter period
%%  r = roll-off
%%
%%  h = output filter (1xN)

%% Location   : Universite de Marne-la-Vallee
%% Author : Laurent Mazet <mazet@univ-mlv.fr>
%% Date   : 28/02/97

function [h] = nyquist (t, T, r)

  t = t+((t == 0) | (abs(abs(t)- T/2/r) < 5e-16*T) )*T*5e-16;

  teta = t*(pi/T);

  h = sin(teta).*cos(r*teta)./((t*(pi/T)).*(1-(t.*(2*r/T)).^2));

  for ii=1:size(h,1)
    for jj=1:size(h,2)
      if (isnan(h(ii,jj)) | isinf(h(ii,jj)))
       	if (abs(t(ii,jj)) < T/4/r)
	  h(ii,jj) = 1;
	else
	  h(ii,jj) = sin(pi/2/r)*r/2;
	end;
      end;
    end;
  end;









