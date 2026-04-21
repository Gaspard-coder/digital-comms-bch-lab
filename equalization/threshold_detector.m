%% [s_est,loc] = threshold_detector(y,mod,M)
%%
%% Threshold detector (assuming Eb=1)
%%
%% y = received signal (complex-valued column vector)
%% mod = constellation type
%% M = constellation size
%%
%% s_est = detected symbol sequence
%% loc = index of symbols in s

%% Location : Telecom ParisTech
%% Author :  Ph. Ciblat <philippe.ciblat@telecom-paristech.fr>
%% Date: 16/10/2018

function [s_est,loc] = threshold_detector(y,mod,M)

  symb=symbols_lut(mod,M); 

  for kk=1:size(symb,2)
    aux(:,kk)=y-symb(1,kk);
  end
  
  [val,loc]=min(abs(aux'));

  aux_est=symb(1,loc); %%row-vector
  s_est=aux_est.'; %%column-vector
