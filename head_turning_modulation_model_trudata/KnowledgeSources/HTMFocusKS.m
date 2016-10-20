% 'HTMFocusKS' class
% This knowledge source compute the object to be focused on.
% It is based on two distinct algorithms:
% 1. The Dynamic Weighting module
% 2. The Multimodal Fusion & Inference module
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef HTMFocusKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    htm; 
    RIR;

    bbs;

    focus_origin = 0; % to be renamed as "focus_type"
    focus = 0;

    shm = 0;
end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS (BEG) === %
% ===================== %
methods

% === Constructor [BEG] === %
function obj = HTMFocusKS (bbs, htm)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    obj.htm = htm;
    obj.RIR = htm.RIR;
end
% === Constructor [END] === %

% === Other Methods === %
% --- Execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    RIR = obj.RIR; % --- RobotInternalRepresentaion

    if RIR.nb_objects == 0
        obj.blackboard.addData('FocusedObject', 0,...
                               false, obj.trigger.tmIdx);
        notify(obj, 'KsFiredEvent');
        return;
    end
    
    % --- DWmod-based focus computing
    dwmod_focus = obj.computeDWmodFocus();

    % --- MFI-based focus computing
    mfi_focus = obj.computeMFIFocus();

    % --- Comparison of the two results
    if mfi_focus == 0 && dwmod_focus > 0 % DWmod takes the lead
        focus = dwmod_focus;
        focus_origin = 1;
    elseif mfi_focus == 0 && dwmod_focus == 0 % No focused object
        focus = obj.focus(end);
        focus_origin = 0;
    elseif mfi_focus == 0 && dwmod_focus == -1
        focus = obj.focus(end);
        focus_origin = 0;
    else % MFImod takes the lead over the DWmod
        focus = mfi_focus;
        focus_origin = -1;
    end

    % === USEFUL??? === %
    if ~obj.isPresent(focus)
        focus = 0;
    end
    % === USEFUL??? === %

    obj.focus_origin(end+1) = focus_origin;
    obj.focus(end+1) = focus;

    % --- List the focus
    focusedObject = containers.Map({'focus', 'focus_origin'},...
                                   {focus, focus_origin});

    obj.blackboard.addData('FocusedObject', focusedObject,...
                            false, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent');
end

% === Compute focused object thanks to the DYNAMIC WEIGHTING module (DWmod) algorithm
function focus = computeDWmodFocus (obj)
    focus = obj.getMaxWeightObject();
    object = getObject(obj.RIR, focus);
    if object.weight < 0.98
        focus = 0;
    elseif ~isPerformant(obj.htm.RIR.getEnv(), object.cat)
        focus = -1;
    end
end

% === Compute focused object thanks to the MULTIMODAL FUSION and INFERENCE module (MFImod) algorithm
function focus = computeMFIFocus (obj)
    focus = 0;
    current_object = obj.blackboard.getLastData('objectDetectionHypotheses').data;
    current_object = current_object.id_object;
    if current_object == 0
        focus = 0;
        return;
    end

    if getObject(obj.RIR, current_object, 'presence')
        requests = getObject(obj.RIR, current_object, 'requests');
        if requests.check 
            focus = current_object;
            % === TO BE CHENGED === %
            obj.RIR.getEnv().objects{current_object}.requests.checked = true;
            % === TO BE CHENGED === %
        elseif requests.checked
            focus = current_object;
        end
    end
end

% === Check if the considered object is present in the environment
function bool = isPresent (obj, idx)
    if find(idx == obj.RIR.getEnv().present_objects)
        bool = true;
    else
        bool = false;
    end 
end


% === Get Objects of Max Weight (DWmod computation)
function request = getMaxWeightObject (obj)
    RIR = obj.RIR;
    obj_weights = getObject(RIR, 'all', 'weight');
    [val, pos] = max(obj_weights);
    max_weight_obj = find(obj_weights == val);
    if numel(max_weight_obj) > 1
        tsteps = getObject(RIR, max_weight_obj, 'tsteps');
        [~, pos] = min(tsteps);
        request = max_weight_obj(pos);
    else
        request = pos;
    end
    request = int32(request);
end

% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %
end