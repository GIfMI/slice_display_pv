function layers = sd_config_layers(todo,varargin)
% SD_CONFIG_LAYERS Initializes empty layer variable or fills one with defaults
%
% DESCRIPTION
% This function initializes or completes the layer variable that is used
% by the sd_display function to visualize (layers of) NIfTI images. For
% each layer, it specifies relevant information, such as file name, color
% map, opacity level, and label.
%
% SYNTAX
% * Initialize an empty layers variable:
% layers = SD_CONFIG_LAYERS('init',layer_types)
%
% layer_type    - 1xN cell array of charater vectors that can take any of
%                 the following values: 
%                 - 'structural', for unthresholded maps (anatomical),
%                    colormaps are not centered and the full range is used
%                 - 'truecolor', for unthresholded maps
%                 - 'blob', for thresholded maps
%                 - 'dual', for dual-coded maps (Allen et al., 2012)
%                 - 'contour', for contour maps
%                 - 'cluster', for masks/cluster maps
%
% layers        - Nx1 struct array, with fields depending on the values in
%               layer_type:
%  
% * Fill an existing layers variable with defaults:
% layers = SD_CONFIG_LAYERS('fill-defaults',layers)
%
% EXAMPLES
% Initialize an empty layers variable for displaying a dual-coded image on
% top of a truecolor image.
% 
% layer_types = {'truecolor','dual'};
% layers = SD_CONFIG_LAYERS('init',layer_types);
%
% Fill an existing layers variable with default
% layers = SD_CONFIG_LAYERS('fill-defaults',layers);
%
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University

% Make sure required toolboxes are on path
assert(~isempty(spm('Dir')),'<a href="http://www.fil.ion.ucl.ac.uk/spm/">SPM</a> cannot be found; make sure it is on MATLAB''s search path.')
assert(exist('panel.m','file') > 0,'<a href="https://www.mathworks.com/matlabcentral/fileexchange/20003-panel">Panel</a> cannot be found; make sure it is on MATLAB''s search path')

switch lower(todo)
    case 'init'
        
        layer_type = varargin{1};
        
        % Check inputs
        % =================================================================

        if ~iscellstr(layer_type)
            error('Input must be an array of strings. Type ''help sd_config_layers''.')
        end

        valid_layers = ismember(lower(layer_type), ...
                                {'structural', 'truecolor','blob','dual','contour','cluster'});
        valid_layer_array = layer_type(valid_layers);
        n_layer = sum(valid_layers);
        
        if n_layer < numel(layer_type)
            invalid_ids = sprintf('%d, ',find(~valid_layers));
            warning('%d layers (%s) were incorrectly specified and will be ignored', ...
                    n_layer, ...
                    invalid_ids(1:end-2));
        end
        
        switch lower(valid_layer_array{1})
            case 'contour'
                error('First layer cannot be a contour image. Type ''help sd_config_layers''.')
        end
        
        % Initialize empty structure arrays
        % =================================================================
        
        color_struct        = struct('file','', ...
                                     'header',[], ...
                                     'hold',[], ...
                                     'map', [], ...
                                     'range', [], ...
                                     'opacity', [], ...
                                     'label', '', ...
                                     'show', true);

        color_struct_dual   = struct('file','', ...
                                     'header',[], ...
                                     'hold',[], ...
                                     'map', [], ...
                                     'range', [], ...
                                     'label', '', ...
                                     'show', true);

        color_struct_contour = struct('file','', ...
                                      'header',[], ...
                                      'hold',[], ...
                                      'map', [], ...
                                      'range', [], ...
                                      'opacity', [], ...
                                      'line_width',[], ...
                                      'line_style','', ...
                                      'label', '', ...
                                      'show', true);          

        opacity_struct      = struct('file', '', ...
                                     'header',[], ...
                                     'hold',[], ...
                                     'range', [], ...
                                     'label','');

        mask_struct         = struct('file','', ...
                                     'header',[], ...
                                     'hold',[], ...
                                     'label','');


        % Assemble layer-specific structure arrays

        structural_struct    = struct('type','structural', ...
                                     'color', color_struct, ...
                                     'mask', mask_struct);
                                 
        truecolor_struct    = struct('type','truecolor', ...
                                     'color', color_struct, ...
                                     'mask', mask_struct);


        blob_struct         = struct('type','blob', ...
                                     'color', color_struct, ...
                                     'mask', mask_struct);


        dual_struct         = struct('type','dual', ...
                                     'color', color_struct_dual, ...
                                     'opacity', opacity_struct, ...
                                     'mask', mask_struct);

        contour_struct      = struct('type','contour', ...
                                     'color', color_struct_contour, ...
                                     'mask', mask_struct);                 

        cluster_struct      = struct('type','cluster', ...
                                     'color', color_struct, ...
                                     'mask', mask_struct);
        
                            
        % Assemble structs in layer variable
        % =================================================================

        layers(n_layer,1) = struct();

        for i_layer = 1:n_layer

            switch lower(valid_layer_array{i_layer})
                case 'structural'
                    template_struct = structural_struct;
                case 'truecolor'
                    template_struct = truecolor_struct;
                case 'blob'
                    template_struct = blob_struct;
                case 'dual'
                    template_struct = dual_struct;
                case 'contour'
                    template_struct = contour_struct;
                case 'cluster'
                    template_struct = cluster_struct;
            end

            for fn = fieldnames(template_struct)'
                layers(i_layer).(fn{1}) = template_struct.(fn{1});
            end
        end
        
    case 'fill-defaults'
        
        layers = varargin{1};
        
        empty_layer_types = cellfun('isempty',{layers.type});
        
        if any(empty_layer_types)
            error('Layer type not specified for layer %d.', find(empty_layer_types))
        end
        
        
        for i_layer = 1:numel(layers)
            
                    
            % Color struct
            % =====================================================

            % File
            % -----------------------------------------------------
            if isempty(layers(i_layer).color.file)
                layers(i_layer).color.file = get_image_file(i_layer, ...
                                                           lower(layers(i_layer).type), ...
                                                           'color-coding');
            end

            % Header
            % -----------------------------------------------------
            if isempty(layers(i_layer).color.header)
                layers(i_layer).color.header = spm_vol(layers(i_layer).color.file);    
            end

            % Hold
            % -----------------------------------------------------
            if isempty(layers(i_layer).color.hold)
                layers(i_layer).color.hold = 0;    
            end

            % Color map
            % -----------------------------------------------------
            if isempty(layers(i_layer).color.map)
                switch lower(layers(i_layer).type)
                    case {'structural'}
                        layers(i_layer).color.map = gray(256);
                    case {'truecolor','blob','dual','cluster'}
                        if i_layer == 1
                            layers(i_layer).color.map = gray(256);
                        elseif i_layer > 1
                            layers(i_layer).color.map = parula(256);
                        end
                    case 'contour'
                        layers(i_layer).color.map = [0 0 0];
                end
            end
            
            % Range
            % -----------------------------------------------------
            if isempty(layers(i_layer).color.range)
                [color_max, color_min] = slover('volmaxmin', layers(i_layer).color.header);
                
                % Make map symmetrical only when it is not structural!
                if color_min < 0 && ~strcmp(lower(layers(i_layer).type), 'structural')
                    abs_color_max = max(abs([color_max, color_min]));
                    layers(i_layer).color.range = [-abs_color_max, abs_color_max];
                else
                    layers(i_layer).color.range = [color_min, color_max];
                end
            end
            
            switch lower(layers(i_layer).type)
                case {'structural', 'truecolor','blob','contour','cluster'}
                    
                    % Opacity
                    % -----------------------------------------------------
                    if isempty(layers(i_layer).color.opacity)
                        layers(i_layer).color.opacity = 1;
                    end
            end

            switch lower(layers(i_layer).type)
                case 'contour'
                    
                    if isempty(layers(i_layer).color.line_width)
                        layers(i_layer).color.line_width = 1;
                    end
                    
                    if isempty(layers(i_layer).color.line_style)
                        layers(i_layer).color.line_style = '-';
                    end
            end

            % Label
            % -----------------------------------------------------
            % Label can be empty, in which case no colorbar is
            % plotted
            if isempty(layers(i_layer).color.label)
            end
            
            
            % Opacity struct
            % =====================================================
            
            switch lower(layers(i_layer).type)
                case 'dual'
                    
                    % File
                    % -----------------------------------------------------
                    if isempty(layers(i_layer).opacity.file)
                        layers(i_layer).color.file = get_image_file(i_layer, ...
                                                                    lower(layers(i_layer).type), ...
                                                                    'opacity-coding');
                    end
                    
                    % Header
                    % -----------------------------------------------------
                    if isempty(layers(i_layer).opacity.header)
                        layers(i_layer).opacity.header = spm_vol(layers(i_layer).opacity.file);    
                    end
                    
                    % Hold
                    % -----------------------------------------------------
                    if isempty(layers(i_layer).opacity.hold)
                        layers(i_layer).opacity.hold = 0;
                    end
                    
                    % Range
                    % -----------------------------------------------------
                    % Assume opacity-coding uses absolute numbers and map
                    % ranges from 0 to absolute max.
                    if isempty(layers(i_layer).opacity.range)
                        [opacity_max, opacity_min] = slover('volmaxmin', layers(i_layer).color.header);
                        abs_opacity_max = max(abs([opacity_max, opacity_min]));
                        layers(i_layer).opacity.range = [0, abs_opacity_max];
                    end
                    
                    % Label
                    % -----------------------------------------------------
                    % Label can be empty, in which case no colorbar is
                    % plotted
                    if isempty(layers(i_layer).opacity.label)
                    end
                            
            end
            
            % Mask struct
            % =====================================================
            
            % File
            % -----------------------------------------------------
            % Mask can be empty
            if isempty(layers(i_layer).mask.file)
            end

            % Header
            % -----------------------------------------------------
            if isempty(layers(i_layer).mask.header)
                if ~isempty(layers(i_layer).mask.file)
                    layers(i_layer).mask.header = spm_vol(layers(i_layer).mask.file);
                end
            end

            % Hold
            % -----------------------------------------------------
            if isempty(layers(i_layer).color.hold)
                layers(i_layer).mask.hold = 0;
            end

            % Label
            % -----------------------------------------------------
            % Label can be empty
            if isempty(layers(i_layer).mask.label)
            end
            
        end
    otherwise
        error('First element must be ''init'' or ''fill-defaults''. Type ''help sd_config_layers''.')
end

function image_file = get_image_file(i_layer,layer_type,coding_type)
    image_file = spm_select(1, ...
                            'image', ...
                            sprintf('Select layer %d (%s) %s image',i_layer, layer_type, coding_type));
