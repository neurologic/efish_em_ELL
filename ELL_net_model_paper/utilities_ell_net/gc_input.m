function [gc_input_rate, cell_type, spk_tim]= gc_input(pth,file_name,dt_model,t_before_model,varargin)
% This function creates a matrix providing the rate of all active GC
% inputs. The matrix is NrGC x Time, with indicated dt and t_before.

p = inputParser;
addRequired(p,'pth');
addRequired(p,'file_name');
addRequired(p,'dt_model',@isnumeric); % in s
addRequired(p,'t_before_model',@isnumeric); % in s
addParameter(p,'time_after_command',.2); % in s
addParameter(p,'sort_by_type',false);

parse(p,pth,file_name,dt_model,t_before_model,varargin{:});
sort_by_type = p.Results.sort_by_type;
time_after_command = p.Results.time_after_command;
%%
addpath(pth);
load([pth '/' file_name]); % this should upload, spikes_per_command, rateAll, celltypes, dt, t_before
dt = dt_gc_model;
t_before = t_before_gc_model;
spikes_per_command = sum(rateAll,2);
active_cells = find(spikes_per_command);
rate_active_gc = rateAll(active_cells,:);
cell_type = celltypes(active_cells);
if exist('spike_times','var')
    spk_tim = spike_times(active_cells);
else
    spk_tim = 0;
end
%% sort rate_active_gc based on cell_type

if sort_by_type
    
    [cell_type_inx,~,ic]=unique(cell_type);
    
    rate_active_gc_sorted=zeros(size(rate_active_gc));
    cell_type=cell(length(ic),1);
    
    index=1;
    for i=1:length(cell_type_inx)
        ind=find(ic==i);
        rate_active_gc_sorted(index:length(ind)+index-1,:) = rate_active_gc(ind,:);
        cell_type(index:length(ind)+index-1)=cell_type_inx(i);
        index=index+length(ind);
    end
    rate_active_gc = rate_active_gc_sorted;
end
%% align rate_active_gc to command based on t_before

t_before_adjust = t_before - t_before_model;

if t_before_adjust < 0
    error('t_before is too long to compare with input rate')
end

if time_after_command < .2
    nr_bins_after_remove = floor((.2-time_after_command)/dt);
    rate_active_gc = rate_active_gc(:,1:end-nr_bins_after_remove);
end

nr_bins_before_remove = floor(t_before_adjust/dt);
rate_active_gc = rate_active_gc(:,nr_bins_before_remove+1:end);

%% condense rate_active_gc to reflect dt
bins_to_sum_dt=round(dt_model/dt);
gc_input_rate=zeros(size(rate_active_gc,1),size(rate_active_gc,2)/bins_to_sum_dt);
index=1;
for i=1:size(gc_input_rate,2)
    gc_input_rate(:,index)=sum(rate_active_gc(:,(i-1)*bins_to_sum_dt+1:i*bins_to_sum_dt),2);
    index=index+1;
end

end