function [fmt,spec,f] = area2fmt( A,tract_length,n_fmt,freq_step,lossy)
%AREA2FMT    Formant frequencies associated with a given area function.
%            [FMT,SPEC,F] = AREA2FMT(A, TRACT_LENGTH, N_FMT, FREQ_STEP, LOSSY)
%            is the vector of formant frequencies of a concatenation of uniform
%            tubes whose areas are defined by the vector A. If A is a matrix,
%            the areas are defined by the rows of A. 
%            The TRACT_LENGTH is given in cm. The default value is 17.5cm.
%            N_FMT is the number of formants (in Hz) desired. The default 
%            value is 5. 
%            FREQ_STEP is the step size used in the discretized frequency
%            grid. The default value is 25Hz, but a  finer resolution is
%            obtained by means of linear interpolation carried out in the
%            end of the procedure.
%            LOSSY is a flag that allows the user to choose between a lossy
%            (LOSSY = 1) and a lossless (LOSSY = 0) model for sound 
%            propagation in the vocal-tract. The default is LOSSY = 1.
%            If desired, the procedure returns the transfer function energy
%            desnsity (SPEC) and the frequency grid (F).
%
if nargin == 1, tract_length = 17.5; end
if nargin <  3, n_fmt = 5; end
if nargin <  4, freq_step = 25; end
if nargin <  5, lossy = 1; end
%
% Lw -> mass/(unit length); 
% Cw -> compliance/(unit length);
% Rw -> resistance/(unit length);
%
correction = 1;
%
a = correction*130*pi; 			% Rw / Lw
b = correction*(30*pi)^2; 		% 1 / (Lw * Cw)
c1 = 4;
w02 = correction*(406*pi)^2; 		% rho * c^2 /(area *Lw)
[K, N]  = size(A);

c = 3.5e4;              % Sound velocity in the tract in cm/s
rho = 1.14e-3;          % Air density in g/cm3

nyquist_freq = 6000;

l   = tract_length/N;
if (K > 1) & (length(l) == 1), l = l*ones(K,1); end
w  = 1:2*pi*freq_step:2*pi*nyquist_freq;
jw = j*w;
f   = w/(2*pi);
M   = length(jw);

if lossy 
  R = 128/(3*pi)^2 * rho*c;
  L = 8/(3*pi*c)   * rho*c;
  Rk = R ./ A(:,N);
  Lk = L ./ sqrt(pi*A(:,N));
  Z  = (Rk.*Lk)*jw./(Rk*ones(1,M)+Lk*jw);
  alpha = sqrt(jw*c1);
  beta = (jw*w02)./((jw+a).*jw+b) + alpha;
  gama = sqrt((alpha+jw)./(beta+jw));
  sigma = gama.*(beta+jw);
  x   = l*sigma/c;
  aux = rho*c*gama;
else
  aux = rho*c*ones(1,M);
  Z = 0;
  x = l*jw/c;
end

cx  = cosh(x);
sx  = sinh(x);

fmt = zeros(K,n_fmt);

Uo  = ones(K,M);
Po  = Z.*Uo;
for n = N:-1:1
  P =  Po.*cx + (1./A(:,n))*aux.*Uo.*sx;
  U =  A(:,n)*(1./aux).*Po.*sx + Uo.*cx;
  Po = P;
  Uo = U;
end
U = real(U);
for k = 1:K
  m = find(sign(U(k,:)) ~= sign([U(k,1) U(k,1:M-1)]));
  m = m(1:n_fmt);
  fmt(k,1:n_fmt) = f(m-1)-(f(m)-f(m-1))./(U(k,m)-U(k,m-1)).*U(k,m-1);
  if nargout > 1, spec(k,:) = -20*log10(abs(U)); end
  % plot(f/1000,spec(k,:));
end
