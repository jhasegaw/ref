function jacobian = dhdgamma(gamma, method)
%
% JACOBIAN = DHDGAMMA(GAMMA, METHOD)
%
% This function computes the Jacobian matrix JACOBIAN containing the 
% variations of the acoustic variable vector H with respect to the 
% articulatory variable GAMMA.
%
if nargin < 2,  method = 'pca'; end
method = [method, setstr(kron(ones(1,8-length(method)),' '))];

N = length(gamma);

if     method == 'pca     ', load pca; Un = U1(:,1:N);
elseif method == 'fourier ', load fourier;
elseif method == 'fourier0', load fourier;
else,  fprintf(1,'Unknown method'); 
end

n_fmt = length(f_mean);
aux = ones(1,N);
delta = diag(0.001*ones(N,1));
x = Un*(inv(Tab)*Ubg*gamma + alf_mean) + x_mean;
kl  = exp(x(1:32));
L = x(33) / norma;
f1 = log10(area2fmt(kl',L,n_fmt))'*aux;
h1 = Ugh'*Tfg*(f1 - f_mean*aux);

x2 = Un*(inv(Tab)*Ubg*(gamma*aux + delta) + alf_mean*aux) + x_mean*aux;
kl  = exp(x2(1:32,:));
L = x2(33,:) / norma;
f2 = log10(area2fmt(kl',L',n_fmt))';
h2 = Ugh'*Tfg*(f2 - f_mean*aux);
jacobian = (h2 - h1)/delta(1,1);
