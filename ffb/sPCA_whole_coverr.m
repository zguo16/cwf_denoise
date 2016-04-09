function [ U, D, sPCA_coeff, mean_coeff, err_cov ] = sPCA_whole_coverr(tr_pos_k, coeff_pos_k, basis, var_hat)
%Description: 
% Computes steerable PCA. It first estimate the mean Fourier-Bessel expansion coefficients, and then computes eigendecomposition of C^{(k)} for k>=0. The steerable PCA expansion coefficients are filtered.
%Input: 
%	coeff_pos_k: Fourier-Bessel expansion coefficients with k>=0
%	tr_pos_k: True Fourier-Bessel expansion coefficients with k>=0

%	basis: Fourier Bessel basis computed from Bessel_ns_radial.m
%	var_hat: estimated noise variance.
%Output:
%	U: eigenvectors of C^{(k)}'s
%	D: eigenvalues of C^{(k)}'s
%	sPCA_coeff: filtered steerable PCA expansion coefficients
%	mean_coeff: mean Fourier-Bessel expansion coefficients with k = 0.
%Update: 10/15 Zhizhen Zhao

max_ang_freqs = size(coeff_pos_k, 1)-1;
n_p = size(coeff_pos_k{1}, 2);

D = cell(max_ang_freqs+1, 1);
U = cell(max_ang_freqs+1, 1);
sPCA_coeff = cell(max_ang_freqs+1, 1);
mean_coeff = mean(coeff_pos_k{1}, 2);
tr_mean_coeff = mean(tr_pos_k{1}, 2);

for k=1:max_ang_freqs+1
    tmp=coeff_pos_k{k};
    tr_tmp=tr_pos_k{k};
    lr = size(coeff_pos_k, 1);
    if k == 1
    	tmp = bsxfun(@minus, tmp, mean_coeff);
    	C1=1/(n_p)*real(tmp*tmp');
    	tr_tmp = bsxfun(@minus, tr_tmp, tr_mean_coeff);
    	C1_tr=1/(n_p)*real(tr_tmp*tr_tmp');

        lambda = lr/n_p;
    else
        C1 = 1/(n_p)*real(tmp*tmp');
        C1_tr = 1/(n_p)*real(tr_tmp*tr_tmp');
        lambda = lr/(2*n_p);
    end;

    err_cov(k)=norm(C1_tr-C1,'fro')/norm(C1_tr,'fro');
    [u, d] = eig(C1);
    [d, id]=sort(diag(d), 'descend');
    if var_hat ~=0
	K = length(find(d > var_hat*(1+sqrt(lambda))^2 ));
    	if K~=0
        	d = d(1:K);
        	u = u(:, id(1:K));
        	U{k} = u;
        	D{k} = d;
        	l_k=0.5*((d-(lambda+1)*var_hat)+sqrt(((lambda+1)*var_hat-d).^2-4*lambda*var_hat^2));
       	 	% SNR_k
        	SNR_k=l_k/var_hat;
        	% SNR_{k, \lambda}
        	SNR=(SNR_k.^2-lambda)./(SNR_k+lambda);
        	weight=1./(1+1./SNR);
        	sPCA_coeff{k} = (diag(weight)*U{k}')*tmp;
        	%    Coeff{1} = U{1}'*data;
    	end
    else
        U{k} = u(:, id);
        D{k} = d;
        sPCA_coeff{k} = U{k}'*tmp;
    end;
end;

