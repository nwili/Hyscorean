function [corner_index,rho,eta,reg_param] = l_curve_mod(U,sm,b,method,L,V,noise) 
%L_CURVE_MOD Plot the L-curve and find its "corner". 
% 
% [corner_index,rho,eta,reg_param] = 
%                  l_curve(U,s,b,method) 
%                  l_curve(U,sm,b,method)  ,  sm = [sigma,mu] 
%                  l_curve(U,s,b,method,L,V) 
% 
% Plots the L-shaped curve of eta, the solution norm || x || or 
% semi-norm || L x ||, as a function of rho, the residual norm 
% || A x - b ||, for the following methods: 
%    method = 'Tikh'  : Tikhonov regularization   (solid line ) 
%    method = 'tsvd'  : truncated SVD or GSVD     (o markers  ) 
%    method = 'dsvd'  : damped SVD or GSVD        (dotted line) 
%    method = 'mtsvd' : modified TSVD             (x markers  ) 
% The corresponding reg. parameters are returned in reg_param.  If no
% method is specified then 'Tikh' is default.  For other methods use plot_lc.
%
% Note that 'Tikh', 'tsvd' and 'dsvd' require either U and s (standard-
% form regularization) or U and sm (general-form regularization), while
% 'mtvsd' requires U and s as well as L and V.
% 
% If any output arguments are specified, then the corner of the L-curve 
% is identified and the corresponding reg. parameter reg_corner is 
% returned.  Use routine l_corner if an upper bound on eta is required. 
% 
% If the Spline Toolbox is not available and reg_corner is requested, 
% then the routine returns reg_corner = NaN for 'tsvd' and 'mtsvd'. 
 
% Reference: P. C. Hansen & D. P. O'Leary, "The use of the L-curve in 
% the regularization of discrete ill-posed problems",  SIAM J. Sci. 
% Comput. 14 (1993), pp. 1487-1503. 
 
% Per Christian Hansen, IMM, Sep. 13, 2001.
% slightly modified for more stable corner localization in the context of
% DEER data by G. Jeschke, Sept. 29, 2016
 
if ~exist('noise','var'),
    noise = 0;
end;
% Set defaults. 
if (nargin==3), method='Tikh'; end  % Tikhonov reg. is default. 
npoints = 200;  % Number of points on the L-curve for Tikh and dsvd. 
% smin_ratio = 16*eps;  % Smallest regularization parameter. 
smin_ratio = 16*eps*1e6;  % Ratio of smallest to largest regularization parameter. 
% The following scaling of the L curve range improves L curve corner detection for DEER
% applications
noise_rat = noise/0.0025;
smin_ratio = smin_ratio*2^noise_rat;

 
% Initialization. 
[m,n] = size(U); [p,ps] = size(sm); 
if (nargout > 0), locate = 1; else locate = 0; end 
beta = U'*b; beta2 = norm(b)^2 - norm(beta)^2; 
if (ps==1) 
  s = sm; beta = beta(1:p); 
else 
  s = sm(p:-1:1,1)./sm(p:-1:1,2); beta = beta(p:-1:1); 
end 
xi = beta(1:p)./s; 
 
if (strncmp(method,'Tikh',4) | strncmp(method,'tikh',4)) 
 
  eta = zeros(npoints,1); rho = eta; reg_param = eta; s2 = s.^2;
  reg_param(npoints) = max([s(p),s(1)*smin_ratio]);
  ratio = (s(1)/reg_param(npoints))^(1/(npoints-1));
  for i=npoints-1:-1:1, reg_param(i) = ratio*reg_param(i+1); end
%   [~,start_reg] = min(abs(reg_param-1e5));
%   [~,end_reg] = min(abs(reg_param-1e-3));
%   reg_param = reg_param(start_reg:end_reg);
%   npoints = length(reg_param);
  for i=1:npoints 
    f = s2./(s2 + reg_param(i)^2); 
    eta(i) = norm(f.*xi); 
    rho(i) = norm((1-f).*beta(1:p)); 
  end 
  if (m > n & beta2 > 0), rho = sqrt(rho.^2 + beta2); end 
  marker = '-'; pos = .8; txt = 'Tikh.'; 
 
elseif (strncmp(method,'tsvd',4) | strncmp(method,'tgsv',4)) 
 
  eta = zeros(p,1); rho = eta; 
  eta(1) = abs(xi(1))^2; 
  for k=2:p, eta(k) = eta(k-1) + abs(xi(k))^2; end 
  eta = sqrt(eta); 
  if (m > n) 
    if (beta2 > 0), rho(p) = beta2; else rho(p) = eps^2; end 
  else 
    rho(p) = eps^2; 
  end 
  for k=p-1:-1:1, rho(k) = rho(k+1) + abs(beta(k+1))^2; end 
  rho = sqrt(rho); 
  reg_param = [1:p]'; marker = 'o'; pos = .75; 
  if (ps==1) 
    U = U(:,1:p); txt = 'TSVD'; 
  else 
    U = U(:,1:p); txt = 'TGSVD'; 
  end 
 
elseif (strncmp(method,'dsvd',4) | strncmp(method,'dgsv',4)) 
 
  eta = zeros(npoints,1); rho = eta; reg_param = eta; 
  reg_param(npoints) = max([s(p),s(1)*smin_ratio]); 
  ratio = (s(1)/reg_param(npoints))^(1/(npoints-1)); 
  for i=npoints-1:-1:1, reg_param(i) = ratio*reg_param(i+1); end 
  for i=1:npoints 
    f = s./(s + reg_param(i)); 
    eta(i) = norm(f.*xi); 
    rho(i) = norm((1-f).*beta(1:p)); 
  end 
  if (m > n & beta2 > 0), rho = sqrt(rho.^2 + beta2); end 
  marker = ':'; pos = .85; 
  if (ps==1), txt = 'DSVD'; else txt = 'DGSVD'; end 
 
elseif (strncmp(method,'mtsv',4)) 
 
  if (nargin~=6) 
    error('The matrices L and V must also be specified') 
  end 
  [p,n] = size(L); rho = zeros(p,1); eta = rho; 
  [Q,R] = qr(L*V(:,n:-1:n-p),0); 
  for i=1:p 
    k = n-p+i; 
    Lxk = L*V(:,1:k)*xi(1:k); 
    zk = R(1:n-k,1:n-k)\(Q(:,1:n-k)'*Lxk); zk = zk(n-k:-1:1); 
    eta(i) = norm(Q(:,n-k+1:p)'*Lxk); 
    if (i < p) 
      rho(i) = norm(beta(k+1:n) + s(k+1:n).*zk); 
    else 
      rho(i) = eps; 
    end 
  end 
  if (m > n & beta2 > 0), rho = sqrt(rho.^2 + beta2); end 
  reg_param = [n-p+1:n]'; txt = 'MTSVD'; 
  U = U(:,reg_param); sm = sm(reg_param); 
  marker = 'x'; pos = .7; ps = 2;  % General form regularization. 
  
else, error('Illegal method'), 
end 


eta = log(eta);
rho = log(rho);
etamin=min(eta);
rhomin=min(rho);
etamax=max(eta);
rhomax=max(rho);

eta1=(eta-etamin)/(etamax-etamin);
rho1=(rho-rhomin)/(rhomax-rhomin);

[~,corner_index]=min(eta1.^2+rho1.^2);
