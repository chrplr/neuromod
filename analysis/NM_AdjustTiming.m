% Checks and adjusts all of the timing

function NM_AdjustTiming()

% Load the data
global GLA_subject;
disp(['Adjusting timing for ' GLA_subject '...']);
NM_LoadSubjectData({{'log_checked',1},... % Need to have checked the log
    {'meg_data_checked',1},...      % And all the triggers...
    {'eeg_data_checked',1},...
    {'et_data_checked',1},...
    });

% Nothing to do, if no diodes
global GLA_subject_data;
if ~isfield(GLA_subject_data.runs(1).trials(1),'diode_times')
    return;
end

% Record the adjustments
fid = fopen([NM_GetCurrentDataDirectory() '/analysis/'...
    GLA_subject '/' GLA_subject '_timing_report.txt'],'a');

% The run triggers...
all_adjusts = [];
for r = 1:GLA_subject_data.parameters.num_runs
    for t = 1:length(GLA_subject_data.runs(r).trials)
        [GLA_subject_data.runs(r).trials(t) all_adjusts(end+1:end+length(GLA_subject_data.runs(r).trials(t).meg_triggers))] = ...
            readjustTrialTriggers(GLA_subject_data.runs(r).trials(t));
    end
end

adj_str = ['Adjusted run triggers by ' num2str(mean(all_adjusts)) ' ms avg. [' ...
    num2str(std(all_adjusts)) ' ms std.]'];
disp(adj_str);
fprintf(fid,[adj_str '\n']);


% And the baseline triggers...
all_adjusts = [];
b_types = {'blinks','eye_movements','noise'};
for b = 1:length(b_types)
    for t = 1:length(GLA_subject_data.baseline.(b_types{b}))
        [GLA_subject_data.baseline.(b_types{b})(t) all_adjusts(end+1:end+length(GLA_subject_data.baseline.(b_types{b})(t).meg_triggers))] = ...
            readjustTrialTriggers(GLA_subject_data.baseline.(b_types{b})(t));
    end
end
adj_str = ['Adjusted baseline triggers by ' num2str(mean(all_adjusts)) ' ms avg. [' ...
    num2str(std(all_adjusts)) ' ms std.]'];
disp(adj_str);
fprintf(fid,[adj_str '\n']);


fclose(fid);

% And save
NM_SaveSubjectData({{'timing_adjusted',1}});
disp('Done.');



function [trial adjusts] = readjustTrialTriggers(trial)

% These are the possibilities to adjust
trigger_types = {'et','meg','eeg'};

adjusts = zeros(length(trial.meg_triggers),1);
max_adjust = 150;
for t = 1:length(trial.meg_triggers)
        
    % Find the closest diode and set
    t_time = trial.meg_triggers(t).meg_time;
    adjusts(t) = max_adjust+1;
    for d = 1:length(trial.diode_times)
        if abs(trial.diode_times(d) - t_time) < abs(adjusts(t))
            adjusts(t) = trial.diode_times(d) - t_time;
        end
    end

    % Check
    if abs(adjusts(t)) > max_adjust
        
        % Might be the delay, so just use the average so far...
        if t == 6
             adjusts(t) = round(mean(adjusts(1:t-1)));
        else
            error('Adjustment too big.');
        end
    end
    
    % And reset them 
    for i = 1:length(trigger_types)
        
        % Make sure we have them
        if isfield(trial,[trigger_types{i} '_triggers'])

            trial.([trigger_types{i} '_triggers'])(t).([trigger_types{i} '_unadjusted_time']) = ...
                trial.([trigger_types{i} '_triggers'])(t).([trigger_types{i} '_time']);
            trial.([trigger_types{i} '_triggers'])(t).([trigger_types{i} '_time']) = ...
                trial.([trigger_types{i} '_triggers'])(t).([trigger_types{i} '_time']) + adjusts(t);
        end
    end
end


