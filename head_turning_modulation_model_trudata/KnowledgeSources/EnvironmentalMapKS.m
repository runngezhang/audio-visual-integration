
classdef EnvironmentalMapKS < AbstractKS
% EnvironmentalMapKS class
% This knowledge source aims at providing a representation of the internal representation of the environment
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
	htm;
	RIR; % Robot_Internal_Representation class
	MOKS;
	Jido;
	
	% figure_handle;
	fov_handle;
	fov_handle_naive;
	objects_handle;
	emitting_handle;
	robot_handle;
	shm_handle;
	naive_handle;
    hist_handle;
    focus_type_handle;
    classif_hist_handle;
    fo_handle;
	statistics_handle;
	hl;
	tl_handle;
	tc_handle;
	text_handle;

    ft_handle;
    ft_colors;

	depth_of_view;
	field_of_view;

	object_creation;

	sources = [];
    nb_sources = 0;
    % timeline;
    
    emitting_sources = [];

	% angles;

	dmax = 1;
	h;

	angles = [];
	angles_rad = [];
	angles_cpt = [];

	iStep;

	shms;

end

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = EnvironmentalMapKS (bbs)
	obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    htm = findKS(obj, 'HeadTurningModulationKS');
	
	obj.htm = htm;
	obj.RIR = htm.RIR;
	obj.Jido = bbs.robotConnect;
	obj.MOKS = htm.MOKS;

	obj.depth_of_view = 9;
	obj.field_of_view = 30;
    obj.nb_sources = 0;
    % obj.timeline = getInfo('timeline');
	% obj.angles = getInfo('sources_position');
	% obj.angles_rad = deg2rad(obj.angles);
	% obj.angles_cpt = [zeros(1, numel(obj.angles_rad)) ; zeros(1, numel(obj.angles_rad))];
 

	obj.createFigure();

	% obj.drawSources();

	obj.drawRobot();

	obj.drawFieldOfView('init');

	obj.emitting_handle = zeros(2, obj.nb_sources);

	obj.text_handle = zeros(1, obj.nb_sources);

	obj.tl_handle = zeros(1, 3);

	obj.tc_handle = zeros(3, obj.nb_sources);

	obj.shm_handle = zeros(1, obj.nb_sources);

	obj.statistics_handle = zeros(1, 3);

	obj.writeClassification('init');

	obj.drawSHM('init');

end
% === CONSTRUCTOR [END] === %

function execute (obj)
	obj.iStep = obj.htm.iStep;

	if obj.iStep > 1
	    % sources = getLastHypothesis(obj, 'ODKS', 'id_object');
	    obj.findSources();
	    obj.emitting_sources = (sources > 0)';
		obj.drawLocalizationResults();
		obj.drawEmittingSource();
		obj.drawSeenSources();
		obj.drawClassificationResults();
		% obj.drawMeanClassificationResults('update');
		% obj.drawHistograms('update');
        obj.drawFieldOfView('update');
		obj.writeClassification('update');
		% obj.drawFocusOrigin('update');
		% obj.drawMFIvsDW('update');
	end
	if obj.iStep > 2
		obj.drawSHM('update');
    end
	pause(0.01);
end

function findSources (obj)
	obj.nb_sources = obj.RIR.nb_objects;
	theta_a = getObject(obj, 'all', 'theta');
	theta_v = getObject(obj, 'all', 'theta_v');
	% obj.angles = getObject(obj, 'all', 'theta');
	obj.angles_rad = deg2rad(obj.angles);
	obj.angles_cpt = [zeros(1, numel(obj.angles_rad)) ; zeros(1, numel(obj.angles_rad))];
end

function writeClassification (obj, k)
	if strcmp(k, 'init')
		for iSource = 1:obj.nb_sources
			pos = get(obj.objects_handle(iSource), 'Position');
			if obj.angles(iSource) <= 90
				pos1 = [pos(1) + 2, pos(2) + 2];
				pos2 = [pos1(1), pos1(2)+0.5];
				pos3 = [pos1(1), pos1(2)+1];
			elseif obj.angles(iSource) <= 180
				pos1 = [pos(1) - 3, pos(2) + 2];
				pos2 = [pos1(1), pos1(2)+0.5];
				pos3 = [pos1(1), pos1(2)+1];
			elseif obj.angles(iSource) <= 270
				pos1 = [pos(1)-3, pos(2)-1.5];
				pos2 = [pos1(1), pos1(2)+0.5];
				pos3 = [pos1(1), pos1(2)+1];
			else
				pos1 = [pos(1)+1.5, pos(2)-1.5];
				pos2 = [pos1(1), pos1(2)+0.5];
				pos3 = [pos1(1), pos1(2)+1];
			end
			obj.tc_handle(1, iSource) = text(pos1(1), pos1(2), '',...
										  'FontSize', 12,...
										  'FontWeight', 'bold',...
										  'Color', [0, 153, 76]/255,...
										  'Parent', obj.h(1));
			obj.tc_handle(2, iSource) = text(pos2(1), pos2(2), '',...
										  'FontSize', 12,...
										  'FontWeight', 'bold',...
										  'Color', 'black',...
										  'Parent', obj.h(1));
			obj.tc_handle(3, iSource) = text(pos3(1), pos3(2), '',...
										  'FontSize', 12,...
										  'FontWeight', 'bold',...
										  'Color', 'black',...
										  'Parent', obj.h(1));
		end
	elseif strcmp(k, 'update')
		% for iSource = 1:obj.nb_sources
		if obj.htm.RIR.nb_objects ~= 0
			for iObject = 1:obj.htm.RIR.nb_objects
				iSource = getObject(obj, iObject, 'source');
				label1 = obj.htm.gtruth{iSource}{obj.iStep-1, 1};
				uscore_pos = strfind(label1, '_');
				str = [label1(1:uscore_pos-1), ' ', label1(uscore_pos+1:end)];
				set(obj.tc_handle(1, iSource), 'String', str);

				label2 = obj.htm.gtruth{iSource}{obj.iStep-1, 2};
				if strcmp(label2, label1)
					col = [0, 153, 76]/255;
				else
					col = [255, 51, 51]/255;
				end
				uscore_pos = strfind(label2, '_');
				str = [label2(1:uscore_pos-1), ' ', label2(uscore_pos+1:end)];
				set(obj.tc_handle(2, iSource),...
					'String', str,...
					'Color', col);

				label3 = obj.htm.classif_mfi{iSource}{obj.iStep-1};
				if strcmp(label3, label1)
					col = [0, 153, 76]/255;
				else
					col = [255, 51, 51]/255;
				end
				uscore_pos = strfind(label3, '_');
				str = [label3(1:uscore_pos-1), ' ', label3(uscore_pos+1:end)];
				set(obj.tc_handle(3, iSource),...
					'String', str,...
					'Color', col);
			end
		end
	end
end

function drawClassificationResults (obj)
    if obj.htm.RIR.nb_objects == 0,
        return;
    end
	objects = getLastHypothesis(obj, 'ODKS', 'id_object');
    
    for iSource = 1:obj.nb_sources
        if objects(iSource) ~= 0
	        current_object = objects(iSource);
	        l = getObject(obj, current_object, 'label');
	        g = obj.htm.gtruth{iSource}{obj.iStep, 1};
	        if strcmp(l, g)
	            set(obj.objects_handle(iSource), 'FaceColor', 'blue');
	        else
	            set(obj.objects_handle(iSource), 'FaceColor', 'red');
	        end
	    end
    end
end

function drawLocalizationResults (obj)
	for iObject = 1:obj.htm.RIR.nb_objects
		object = getObject(obj, iObject);
		% tmIdx = getObject(obj.htm, iObject, 'tmIdx');
		tmIdx = object.tmIdx(1);
		% current_theta = getObject(obj, iObject, 'theta');
		current_theta = object.theta(end);

		%source = obj.htm.sources(tmIdx);
        % source = getObject(obj, iObject, 'source');
        source = object.source;
		
		object_pos = get(obj.objects_handle(source), 'Position');
		
		x = object_pos(1)+object_pos(3);
		y = object_pos(2)+object_pos(4);
		
		if obj.text_handle(source) == 0
			obj.text_handle(source) = text(x+0.2, y+0.2, num2str(current_theta),...
										   'FontSize', 16,...
										   'FontWeight', 'bold',...
										   'Parent', obj.h(1));
		else
			set(obj.text_handle(source), 'Position', [x+0.2, y+0.2, 0],...
										 'String', [num2str(current_theta), '^\circ']);
		end
	end
end


function drawFieldOfView (obj, k)

	if strcmp(k, 'init') || strcmp(k, 'end')
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);
		theta1 = -(obj.field_of_view/2);
		theta2 = +(obj.field_of_view/2);
		[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
		[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);

		if strcmp(k, 'init')
			% === Naive robot
			l1 = line([x0, x1], [y0, y1], 'Color', 'g', 'LineStyle', '--', 'LineWidth', 1, 'Parent', obj.h(1));
			l2 = line([x1, x2], [y1, y2], 'Color', 'g', 'LineStyle', '--', 'LineWidth', 1, 'Parent', obj.h(1));
			l3 = line([x2, x0], [y2, y0], 'Color', 'g', 'LineStyle', '--', 'LineWidth', 1, 'Parent', obj.h(1));
			obj.fov_handle_naive = [l1, l2, l3];

			% === HTM robot
			l1 = line([x0, x1], [y0, y1], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h(1));
			l2 = line([x1, x2], [y1, y2], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h(1));
			l3 = line([x2, x0], [y2, y0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2, 'Parent', obj.h(1));
			
			obj.fov_handle = [l1, l2, l3];
		else
			set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);

			set(obj.fov_handle_naive(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle_naive(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle_naive(3), 'XData', [x2, x0], 'YData', [y2, y0]);
		end
    elseif strcmp(k, 'update')
		% hold(obj.h(1), 'on');
		x0 = obj.RIR.position(1);
		y0 = obj.RIR.position(2);

		% === Naive robot
		if ~isempty(obj.htm.naive_shm)
			naive_shm = obj.htm.naive_shm{end-1};
	        if ~isempty(naive_shm)
	        	if numel(naive_shm) > 1
	        		naive_shm = naive_shm(1);
	        	end
	            sources = getObject(obj, naive_shm, 'source');
	            % obj.angles_cpt(2, sources) = obj.angles_cpt(2, sources) + 1;

	            theta  = obj.angles(sources);
	            % [x2, y2] = pol2cart(obj.angles_rad, obj.angles_cpt(2, :));

				theta1 = theta - (obj.field_of_view/2);
				theta2 = theta + (obj.field_of_view/2);

				[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
				[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);

				set(obj.fov_handle_naive(1), 'XData', [x0, x1], 'YData', [y0, y1]);
				set(obj.fov_handle_naive(2), 'XData', [x1, x2], 'YData', [y1, y2]);
				set(obj.fov_handle_naive(3), 'XData', [x2, x0], 'YData', [y2, y0]);

	        end
	    end

	    % === HTM robot
		if ~isempty(obj.MOKS.head_position(end-1))
			theta1 = obj.MOKS.head_position(end) - (obj.field_of_view/2);
			theta2 = obj.MOKS.head_position(end) + (obj.field_of_view/2);

			[x1, y1] = pol2cart(deg2rad(theta1), obj.depth_of_view);
			[x2, y2] = pol2cart(deg2rad(theta2), obj.depth_of_view);
			
			set(obj.fov_handle(1), 'XData', [x0, x1], 'YData', [y0, y1]);
			set(obj.fov_handle(2), 'XData', [x1, x2], 'YData', [y1, y2]);
			set(obj.fov_handle(3), 'XData', [x2, x0], 'YData', [y2, y0]);
		end
		% hold(obj.h(1), 'off');
	end
	%pause(0.01);
end

function drawSHM (obj, k)
	if strcmp(k, 'init')
		[x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
		obj.shm_handle = compass([x, x], [y, y], 'Parent', obj.h(3));
		% pos = get(obj.h(3), 'Outerposition');
		% set(obj.h(3), 'OuterPosition', pos+[-0, -0.05, 0, 0.05])
		% set(obj.h(3), 'Outerposition', [pos(1), pos(2)-0.05, pos(3), pos(4)]);
        % set(obj.h(3), 'Position', [0.56, 0.07, 0.34, 0.42]);

		obj.focus_type_handle = bar([0, 0], 'FaceColor', [102, 178, 255]/255, 'EdgeColor', 'none', 'Parent', obj.h(5));
        % p = get(obj.focus_type_handle, 'Parent');
        pos = get(obj.h(5), 'Outerposition');
        set(obj.h(5), 'XTick'     	      , [1, 2],...
		       		  'XTickLabel'		  , {'naive', 'HTMKS'},...
		  	   		  'XTickLabelRotation', 45,...
		  	   		  'Outerposition', pos+[0.05, -0.03, 0, 0]);

	elseif strcmp(k, 'update')
		mo = obj.MOKS.motor_order(obj.iStep-1);
        fo = obj.htm.FCKS.focus(obj.iStep-1);
		if mo > 0
			%pos = find(obj.angles == mo);
            pos = getObject(obj, fo, 'source');
			obj.angles_cpt(1, pos) = obj.angles_cpt(1, pos) + 1;
            obj.shms(end+1) = 1;
		end
		[x, y] = pol2cart(obj.angles_rad, obj.angles_cpt(1, :));
		
		naive_shm = obj.htm.naive_shm{end};
        if ~isempty(naive_shm)
            sources = getObject(obj, naive_shm, 'source');
            obj.angles_cpt(2, sources) = obj.angles_cpt(2, sources) + 1;

            [x2, y2] = pol2cart(obj.angles_rad, obj.angles_cpt(2, :));

            obj.shm_handle = compass([x2, x], [y2, y], 'Parent', obj.h(3));
            set(obj.shm_handle(obj.nb_sources+1:end), 'LineWidth', 4);
            set(obj.shm_handle(1:obj.nb_sources), 'Color', 'red', 'LineWidth', 2);

            obj.shms(end+1) = 0;
        end
        uv = histc(obj.shms, [0, 1]);
        m = max(uv);
        if m < 10
            ytick = 0:m;
        elseif m < 20
        	ytick = 0:2:m;
        elseif m < 30
        	ytick = 0:4:m;
        elseif m < 40
        	ytick = 0:5:m;
        elseif m < 50
        	ytick = 0:10:m;
        else
        	ytick = 0:20:m;
        end
        set(obj.focus_type_handle, 'YData', uv);
        set(obj.h(5), 'YTick'     , ytick,...
        			  'YTickLabel', ytick);
	end
end

function drawEmittingSource (obj, varargin)
    sources = obj.emitting_sources;
	for iSource = 1:obj.nb_sources

		if sources(iSource) == 0
			obj.removeEmittingSources(iSource);
		else
			%info = getInfo('all');
			circle_size = 2;
			circle_size2 = 3;
			% --- Centering the center around [0, 0]
			% --- 'pos' is: [x, y, width, height]
			pos1 = [obj.sources(1, iSource)-circle_size/4, obj.sources(2, iSource)-circle_size/4,...
				   circle_size, circle_size];
			pos2 = [obj.sources(1, iSource)-circle_size2/3, obj.sources(2, iSource)-circle_size2/3,...
				   circle_size2, circle_size2];
			% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
			if obj.emitting_handle(1, iSource) == 0
				h1 = rectangle('Position' , pos1  ,...
							  'Curvature', [1 1],...
							  'LineStyle', '-.',...
							  'EdgeColor', [51, 102, 0]/255,...
						  	  'Parent'   , obj.h(1),...
						  	  'Tag', num2str(iSource));
				h2 = rectangle('Position' , pos2  ,...
							  'Curvature', [1 1],...
							  'LineStyle', '-.',...
							  'EdgeColor', [51, 102, 0]/255,...
						  	  'Parent'   , obj.h(1),...
						  	  'Tag', num2str(iSource));

				obj.emitting_handle(1, iSource) = h1;
				obj.emitting_handle(2, iSource) = h2;
			else
				set(obj.emitting_handle(1, iSource), 'Visible', 'on');
				set(obj.emitting_handle(2, iSource), 'Visible', 'on');
			end
		end
	end
end

function drawSeenSources (obj)
	head_position = obj.MOKS.head_position(end);
	for iSource = 1:numel(obj.objects_handle)
		source = find(head_position == getInfo('sources_position'));
		if ~isempty(source)
			set(obj.objects_handle(source), 'LineStyle', '-', 'LineWidth', 2);
		end
	end

end

function drawSources (obj, h)
	if nargin == 1
		h = obj.h(1);
	end

	info = getInfo('all');
	% for iSource = 1:obj.nb_sources
	for iSource = 1:obj.RIR.nb_objects
		th = info.sources_position(iSource);
		d = info.distances(iSource);
		[x, y] = pol2cart(deg2rad(th), d);
		pos = [x-0.5, y-0.5, 1, 1];
		
		obj.objects_handle(end+1) = rectangle('Position' , pos ,...
			  		   			 			  'Curvature', 0.4 ,...
			  		   			 			  'LineWidth', 1   ,...
          									  'LineStyle', '--',...
          									  'FaceColor', [201, 230, 204]/255,...
			  		   			 			  'Parent'   , h...
			  		   			 			 );
		obj.sources(:, end+1) = pos;
	end
end

function drawRobot (obj)
	circle_size = 0.5;
	% --- Centering the center around [0, 0]
	% --- 'pos' is: [x, y, width, height]
	pos = [obj.RIR.position(1)-circle_size/2, obj.RIR.position(2)-circle_size/2,...
		   circle_size, circle_size];
	% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
	obj.robot_handle = rectangle('Position' , pos  ,...
			  		   			 'Curvature', [1 1],...
			  		   			 'LineWidth', 2,...
			  		   			 'FaceColor', 'black',...
			  		   			 'Parent'   , obj.h(1));
			  		   			 % 'Parent'   , obj.figure_handle);
	circle_size = 3;
	% --- Centering the center around [0, 0]
	% --- 'pos' is: [x, y, width, height]
	x0 = obj.RIR.position(1);
	y0 = obj.RIR.position(2);
	pos = [x0-circle_size/2, y0-circle_size/2, circle_size, circle_size];
	% --- The 'Curvature' is allowing to draw a circle from the 'rectangle' function
	obj.shm_handle = rectangle('Position' , pos  ,...
			  		   		   'Curvature', [1 1],...
			  		   		   'LineWidth', 2,...
			  		   		   'FaceColor', 'none',...
			  		   		   'Parent'   , obj.h(1));
end

function drawSilence (obj)
	info = getInfo('cpt_silence', 'cpt_object', 'nb_steps');
	vec = 1 :(info.cpt_silence+info.cpt_object): info.nb_steps;
	hold(obj.h(2), 'on');

	for iSilence = 1:numel(vec)
		x = vec(iSilence);
        X = [x, x, x+info.cpt_silence, x+info.cpt_silence];
        Y1 = [0, 1, 1, 0];
        C = [0.75, 0.75, 0.75];
		patch(X, Y1, C,...
			  'FaceAlpha', 0.6,...
			  'EdgeColor', 'none',...
			  'Parent', obj.h(2));
	end

	hold(obj.h(2), 'off');
end

function createFigure (obj)
	p = figure();
	set(p, 'Units', 'normalized',...
		   'Outerposition', [0 0 1 1],...
		   'Color', [1, 1, 1],...
		   'Tag', 'EMKS');
	obj.h = zeros(1, 6);

	% --- h(1) = environment
	% obj.h(1) = subplot(5, 6, [1:3, 7:9, 13:15], 'Parent', p);
	% obj.h(1) = subplot(3, 7, [1, 2, 3, 4, 8, 9, 10, 11, 15, 16, 17, 18], 'Parent', p);
	obj.h(1) = subplot(1, 2, 1, 'Parent', p);
	set(obj.h(1), 'XLim', [-11, 11],...
				'YLim', [-11, 11])%,...
	axis square;
                % 'Position', [0.05, 0.4, 0.45, 0.45])
	axis off;

	% --- h(2) = mean classification results
	% obj.h(2) = subplot(5, 6, [4, 5, 10, 11, 16, 17], 'Parent', p);
	obj.h(2) = subplot(1, 2, 2, 'Parent', p);
	set(obj.h(2), 'XLim', [0, getInfo('nb_steps')],...
				  'YLim', [0, 1]);%,...
	% axis square;
				% 'Position', [0.6, 0.4, 0.18, 0.45]);

	% --- h(3) = SHMs
	% obj.h(3) = subplot(5, 6, [22, 23, 28, 29], 'Parent', p);
	% obj.h(3) = subplot(3, 7, [19, 20], 'Parent', p);
	% axis square;
	% set(obj.h(3), 'Position', [0.6, 0.05, 0.18, 0.25]);

	% --- h(4) = focus origin
	% obj.h(4) = subplot(5, 6, [19:21, 25:27], 'Parent', p);
	% obj.h(4) = subplot(3, 7, [12, 13], 'Parent', p);
	% axis square;
	% set(obj.h(4), 'Position', [0.05, 0.05, 0.45, 0.25]);

	% --- h(5) = bar SHMs naive vs HTMKS
	% obj.h(5) = subplot(5, 6, [24, 30], 'Parent', p);
	% obj.h(5) = subplot(3, 7, [21], 'Parent', p);
	% axis square;
	% set(obj.h(5), 'Outerposition', [0.8, 0.05, 0.15, 0.4]);

	% --- h(6) = bar classification results, naive w/o SHM vs naive w. SHM vs HTMKS
	% obj.h(6) = subplot(5, 6, [6, 12, 18], 'Parent', p);
	% obj.h(6) = subplot(3, 7, [7], 'Parent', p);
	% set(obj.h(6), 'Outerposition', [0.8, 0.5, 0.15, 0.4]);
    % set(obj.h(6), 'Position', [0.8, 0.4, 0.15, 0.45]);
	% axis square;

	% obj.h(7) = subplot(3, 7, [14], 'Parent', p);

	% img = imread('../../audio-visual-integration/head_turning_modulation_model_simdata/Img/Two!Ears.png');
	% imagesc(-12, 12, img, 'Parent', obj.h(1));
end

function removeEmittingSources (obj, iSource)
	% for iSource = 1:obj.nb_sources
		% if ~isempty(obj.emitting_handle)
		if obj.emitting_handle(1, iSource) ~= 0
			set(obj.emitting_handle(1, iSource), 'Visible', 'off');
			set(obj.emitting_handle(2, iSource), 'Visible', 'off');
		end
	% end
end

function removeAllEmittingSources (obj)
    for iSource = 1:obj.nb_sources
        if obj.emitting_handle(1, iSource) ~= 0
            set(obj.emitting_handle(1, iSource), 'Visible', 'off');
            set(obj.emitting_handle(2, iSource), 'Visible', 'off');
        end
    end
end


function endSimulation (obj)
	obj.drawFieldOfView('end');
	obj.drawLocalizationResults();
	obj.removeAllEmittingSources();
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === % 
% =================== %
end
