function channels = NM_GetMEEGChannels(s_type, data)

% Get the type channels
global GLA_meeg_type;
load([GLA_meeg_type '_channel_types.mat']);
type_ch = channel_types.(s_type);

% Could only have some of the channels
if exist('data','var')
    data_ch = data.label;
else
    data_ch = channel_types.all; 
end

channels = {};
for d = 1:length(data_ch)
    for t = 1:length(type_ch)
        if strcmp(data_ch{d},type_ch{t})
            channels{end+1} = data_ch{d}; %#ok<AGROW>
            break;
        end
    end
end
