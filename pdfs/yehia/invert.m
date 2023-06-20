function [vt_area, vt_length] = invert(fmt, M, N, method, epsilon, max_count)
%
%INVERT  Estimates the area function trajectory given the trajectories
%        of the first three formants frequencies.
%
%        Usage: [VT_AREA, VT_LENGTH] = INVERT(FMT, M, METHOD, EPSILON)
%        Where: VT_AREA = vocal-tract cross-sectional area as a function 
%        of time and position along the vocal-tract. The columns of 
%        VT_AREA contain N = 32 rows containing the areas (in cm2)
%        from the glottis to the lips. Each column corresponds to
%        one sample. Samples were acquired at 50Hz.
%               VT_LENGTH = vocal-tract length (in cm) as a function
%        of time. The sampling-rate is of 50Hz.
%               FMT = formant frequency vectors (in Hz). Each column of 
%        FMT contains a vector with the first formant frequency in the 
%        first row and the last in the last row. 
%               M = number of parameters used to represent a sequence 
%        of vectors. The default value is M = 4, which is appropriate for 
%        sequences of about 10 vectors. The parameters are the cosine
%        coefficients of the truncated Fourier cosine series expansion 
%        of the sequence under analysis.
%               N = number of parameters used to represent a log-area
%        vector. If METHOD = 'pca', INVERT sets N = 5, otherwise N can be
%        any value between the number of formant frequencies (number of 
%        rows of FMT) and 10 (default).
%               METHOD is the parametric representation used for the 
%        log-area function along the vocal-tract. The possibilities
%        available are: 'pca'      -> principal component analysis (default)
%                       'fourier'  -> Fourier cosine series
%                       'fourier0' -> Fourier cosine series with even
%                                     coefficients set to zero.
%               EPSILON is the average relative Euclidean distance between 
%                       desired and obtained acoustic variables (formant 
%                       frequencies). The default value is 0.0005.
%               MAX_COUNT is the maximum number of iterations used in the 
%                         procedure. If MAX_COUNT iterations are done,
%                         INVERT stops even if the distance between desired
%                         and obtained acoustic variables is still larger
%                         than EPSILON. The default is MAX_COOUNT = 5.
%

%
% Set default values for unspecified parameters
%
if nargin < 1,  error('Not enough arguments.'); end
if nargin < 2, M = 4;  end
if nargin < 4, method = 'pca     '; end
if nargin < 5, epsilon = 0.0005; end
if nargin < 6, max_count = 5; end
K = 32;
fmt = fmt';
[Q, n_fmt] = size(fmt);
method = [method, setstr(kron(ones(1,8-length(method)),' '))];
%
% Load basis vectors, mean vectors and transformation matrices for log-area
% vector parametrization.
%
if method == 'pca     '
  load pca; 
  N = 5; 
  Un = U1(:,1:N);
  x_mean(33) = 1.03*x_mean(33); 	% Neutral length adjusted to get 
                                        % better results
elseif method == 'fourier ';
  load fourier; 
  if nargin < 3, N = 10; end
  if isempty(N), N = 10; end
  x_mean(33) = 1*x_mean(33); 		% Neutral length adjusted to get 
                                        % better results
elseif method == 'fourier0', 
  load fourier; 
  if nargin < 3, N = 10; end
  if isempty(N), N = 10; end
  x_mean(33) = 1.08*x_mean(33); 	% Neutral length adjusted to get 
                                        % better results
else
  fprintf(1,'Unknown method'); 
end
%
% Compute basis vectors (discretized cosine functions) for temporal
% parametrization.
%
if Q == 1
  Ym = 1;
else
  n_frames = Q;
  t = pi*(1/(2*n_frames):1/n_frames:(1-1/(2*n_frames)))'*(0:n_frames-1);
  Y1 = cos(t)*sqrt(2/n_frames)*diag([1/sqrt(2) ones(1,n_frames-1)]);
  Ym = Y1(1:Q,1:M);
end
%
% Initialize matrix for shape-time parametric representation.
%
B = zeros(N,M);
%
% Compute VT area and length of the neutral position of the vocal-tract.
%
area_neutral = exp(x_mean(1:K));
L_neutral = x_mean(K+1)/norma;
%
% Compute desired variation in acoustic variables "h" from desired variation
% in acoustic frequencies (in log-scale).
%
delta_h = Ugh'*Tfg*(log10(fmt') - f_mean*ones(1,Q));
%
% Compute matrix used to calculate the cost of a given vocal-tract position 
%
Hp = inv(Ubg'*Tab*S(1:N,1:N)*Tab'*Ubg);
if method == 'fourier0', Hp = eye(N); end
%
% Compute matrix used to obtain temporal parametrization of a sequence of
% parametrized log-area vectors.
%
CC = zeros(Q*N,N*M);
for m = 1:Q
  for j = 1:N
    CC((m-1)*N+j,(j-1)*M+1:j*M) = Ym(m,:);
  end
end
%
% Temporal cost matrix currently set to identity.
% (It will change when the system is modified to handle sounds other
% than oral vowels.)
%
HH = diag(ones(Q*N,1));

error = 1e12; 
counter = 0;
A = B * Ym'; 
slow = 1;
%
% Main loop. See http://www.hip.atr.co.jp/~yehia/Publications/thesis.ps.gz
% for explanation of the theory.
%
while (error > epsilon) & (counter < max_count) 
  MM = zeros(Q*N,Q*N); 
  dg = zeros(Q*N,1);
  for m = 1:Q 
    gamma = A(:,m); 
    Mua = dhdgamma(gamma,method);
    Mu1 = Mua(:,1:n_fmt); 
    Mu2 = Mua(:,n_fmt+1:N); 
    aux = [-inv(Mu1)*Mu2; eye(N - n_fmt)]; 
    Mup = aux' * Hp; 
    Mu = [Mua; Mup]; 
    if method == 'pca     ', gp = -Mup * (gamma - gamma_max); 
    else gp = -Mup * gamma * 0; end
    delta_g = [delta_h(:,m); gp]; 
    MM((m-1)*N+1:m*N,(m-1)*N+1:m*N) = Mu;
    dg((m-1)*N+1:m*N,1) = delta_g; 
  end 
  MC = MM * CC; 
  db = (MC' * (HH+HH') * MC) \ (MC' * (HH+HH') * dg); 
  delta_B = [reshape(db,M,N)]'; 
  B_ant = B;
  B = B + delta_B * slow; 
  A_ant = A;
  A = B * Ym'; 
  X = Un * (inv(Tab)*Ubg*A + alf_mean*ones(1,Q)) + x_mean*ones(1,Q); 
  area = exp(X(1:K,:)); 
  L = X(K+1,:)/norma; 
  new_fmt = area2fmt(area',L',n_fmt); 
  delta_h_ant = delta_h;
  delta_h = Ugh'*Tfg*(log10(fmt')-log10(new_fmt'));;
  error_ant = error; 
  error = norm(delta_h,'fro')/(Q * n_fmt); 
  if error >= error_ant 
    A = A_ant; 
    B = B_ant; 
    delta_h = delta_h_ant; 
    slow = slow/2; 
  end 
  counter = counter + 1;
  fprintf(1,'Counter = %d    Error = %f\n',counter,error);
end
X = Un * (inv(Tab)*Ubg*B*Ym' + alf_mean*ones(1,Q)) + x_mean*ones(1,Q); 
vt_area = exp(X(1:K,:));
vt_length   = X(K+1,:) / norma;

