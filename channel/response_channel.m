%% [h] = response_channel(c)


%% Channel generation for deliverable D4
%%
%% c = channel index

%% h = channel filter vector

%% Location : Telecom ParisTech
%% Author : Philippe Ciblat <ciblat@telecom-paristech.fr>
%% Date   : 11/03/2019

function [h] = response_channel(c);

r=0.5;
T=1/(20e6);
 
%% Design of paths (attenuation and delay)
if(c==1)  
AR=[1 0.1 0.1 0.1 0.1];
end 

if(c==2)  
AR=[1 0.8 0.6 0.4 0.2];
end 

if(c==3)  
AR=[1 0.8 0.8 0.8 0.8];
end 

TR=[0 0.5 1 1.5 2];  
  
 
%% Channel length 
Npath=5;
T_h = ceil(2+1/r); % approximation of shaping filter length
TRmax = max(TR);
t = [-ceil(T_h+TRmax):1:ceil(TRmax+T_h)]*T; %% tested points


%% Filter vector computation
h = zeros(1,length(t));
 
for ii=1:Npath
    h = h + AR(ii)*nyquist(t-TR(ii)*T,T,r);
end;
   
h=h/norm(abs(h));

%% Channel display
% stem(t,abs(h))
% grid
