function [kernel_epsp, kernel_epsc, epsp, epsc, integral_kernel_epsp,normalization_epsp,deconv_f] = kernel_convolved(varargin)
%KERNEL_CONVULVED Summary of this function goes here
%   Detailed explanation goes here

p = inputParser;
p.addParameter('dt',.001);
p.addParameter('length_kernel',.1);
p.addParameter('tau_output',0.01);
p.addParameter('tau_input',0.005);
p.addParameter('rate_input',false);
p.addParameter('input',1);
p.addParameter('periodic',true);
p.addParameter('do_deconvolution',false);

parse(p,varargin{:});
dt = p.Results.dt;
length_kernel = p.Results.length_kernel;
tau_output = p.Results.tau_output;
tau_input = p.Results.tau_input;
rate_input = p.Results.rate_input;
input = p.Results.input;
periodic = p.Results.periodic;
do_deconvolution = p.Results.do_deconvolution;

length_input = size(input,2);
                  %need about .06s to reach 0
tran                 = 0:dt:(length_kernel-dt);
% coeff                = tau_input/(tau_input-tau_output);
coeff                = 1/(tau_input-tau_output);
normalization_epsp   = 1/(tau_input-tau_output)*1/coeff;

kernel_epsp          = coeff*(exp(-tran/tau_input)-exp(-tran/tau_output));
integral_kernel_epsp = integral(@(t) coeff*(exp(-t/tau_input)-exp(-t/tau_output)),0,Inf);
% kernel_epsc          = exp(-tran/tau_input);
kernel_epsc          = 1/tau_input*exp(-tran/tau_input);

if rate_input
    coeff                = 1/tau_output;
    kernel_epsp          = coeff*(exp(-tran/tau_output));
    integral_kernel_epsp = integral(@(t) coeff*(exp(-t/tau_output)),0,Inf);
end  

if periodic
    epsp                 = conv2(repmat(input,1,2),kernel_epsp);
    epsp                 = epsp(:,length_input+1:2*length_input);
    
    epsc                 = conv2(repmat(input,1,2),kernel_epsc);
    epsc                 = epsc(:,length_input+1:2*length_input);
else
    epsp                 = conv2(input,kernel_epsp);
    epsc                 = conv2(input,kernel_epsc);
end
if do_deconvolution
    
    tran_dc                  = 0:dt:(length(input)*dt-dt); 
    kernel_epsp_dc           = coeff*(exp(-tran_dc/tau_input)-exp(-tran_dc/tau_output));
    kernel_epsp_dc           = kernel_epsp_dc(1:length(input));
    kernel_epsp_dc_fft       = fft(kernel_epsp_dc);
    input_fft                = fft(input);
    deconv_f                 = ifft(input_fft./kernel_epsp_dc_fft);
    
end
end

