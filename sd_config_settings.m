function settings = sd_config_settings(todo, varargin)
% SD_CONFIG_SETTINGS Initializes empty settings variable or fills one with defaults
%
% DESCRIPTION
% This function initializes or completes the settings variable that is used
% by the sd_display function to visualize NIfTI images.
%
% SYNTAX
% settings = sd_config_settings('init')
% settings = sd_config_settings('fill-defaults',settings)
%
% EXAMPLES
% Initialize an empty settings variable:
% settings = SD_CONFIG_SETTINGS('init');
%
% Fill an existing settings variable with defaults:
% settings = SD_CONFIG_SETTINGS('fill-defaults',settings);
%
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University
% Modified by Pieter Vandemaele (pieter.vandemaele@gmail.com), Ghent University

% Make sure required toolboxes are on path
assert(~isempty(spm('Dir')),'<a href="http://www.fil.ion.ucl.ac.uk/spm/">SPM</a> cannot be found; make sure it is on MATLAB''s search path.')
assert(exist('panel.m','file') > 0,'<a href="https://www.mathworks.com/matlabcentral/fileexchange/20003-panel">Panel</a> cannot be found; make sure it is on MATLAB''s search path')

switch lower(todo)
    case 'init'
        
        m           = struct('figure', [], ...
                             'panel', [], ...
                             'slice', [], ...
                             'colorbar', []);
        
        wh          = struct('figure', [], ...
                             'map_panel', [], ...
                             'legend_panel', [], ...
                             'slice', [], ...
                             'colorbar', []);
        
        constraints = struct('slice', [], ...
                             'colorbar', []);
        
        n           = struct('slice', [], ...
                             'slice_row', [], ...
                             'slice_column', [], ...
                             'colorbar', []);
                         
        fig_specs   = struct('title', '', ...
                             'margin',m, ...
                             'width', wh, ...
                             'height', wh, ...
                             'width_constraints', constraints, ...
                             'height_constraints', constraints, ...
                             'height_width_ratio', constraints, ...
                             'panel', [], ...
                             'n', n, ...
                             'i', struct('colorbar',[]));
        
        slice       = struct('orientation','', ...
                             'disp_slices', [], ...
                             'show_labels',[], ...
                             'show_orientation',[], ...
                             'transform',[], ...
                             'xmm', [], ...
                             'ymm', [], ...
                             'zmm', [], ...
                             'x', [], ...
                             'y', [], ...
                             'vdims', [], ...
                             'pandims', []);
        
        paper       = struct('type','', ...
                             'orientation', '');
                       
        settings    = struct('slice',slice, ...
                             'fig_specs',fig_specs, ...
                             'paper',paper);
        
    case 'fill-defaults'
        
        settings = varargin{1};
        
        % settings.slice
        % =================================================================
        
        if isempty(settings.slice.orientation)
            settings.slice.orientation = 'axial';
        end
        
        if isempty(settings.slice.disp_slices)
            settings.slice.disp_slices = -20:4:40;
        end
        
        if isempty(settings.slice.show_labels)
            settings.slice.show_labels = true;
        end
        
        if isempty(settings.slice.show_orientation)
            settings.slice.show_orientation = true;
        end
        
        % settings.fig_specs
        % =================================================================
        
        % settings.fig_specs.margin
        % -----------------------------------------------------------------
        
        pf = settings.fig_specs.panel;
        if ~isempty(pf)
            % Calculate width and height of panel
            % ---------------------------------------------------------------------
            size_fig = getpixelposition(pf.figure);
            pf_size = pf.position .* repmat(size_fig(3:4),1,2);
            % Override default width and height with parent panel size
            settings.fig_specs.width.figure = pf_size(3);
            settings.fig_specs.height.figure = pf_size(4);
            settings.fig_specs.width.map_panel = [];
            settings.fig_specs.height.map_panel = [];
            %             settings.fig_specs.margin.figure = [50 50 50 50 ];
            settings.fig_specs.margin.figure = [0 0 0 0 ];
            settings.fig_specs.width.legend_panel = [];
            if ~isempty(settings.fig_specs.title)
                settings.fig_specs.height.title_panel = 25;
            else
                settings.fig_specs.height.title_panel = 0;
            end
            
        else
            if isempty(settings.fig_specs.margin.figure)
                if isempty(settings.fig_specs.title)
                    settings.fig_specs.margin.figure = [15 15 5 5];
                else
                    settings.fig_specs.margin.figure = [15 15 5 20];
                end
            end
        end

        if isempty(settings.fig_specs.margin.panel)
            settings.fig_specs.margin.panel = [5 5 2 2];
        end
        
        if isempty(settings.fig_specs.margin.slice)
            settings.fig_specs.margin.slice = [0 0 0 0];
        end
        
        if isempty(settings.fig_specs.margin.colorbar)
            settings.fig_specs.margin.colorbar = [5 5 2 2];
        end
        
        % settings.fig_specs.width
        % -----------------------------------------------------------------
        
        if isempty(settings.fig_specs.width.figure)
            settings.fig_specs.width.figure = 180;
        end
        
        if isempty(settings.fig_specs.width.map_panel)
            settings.fig_specs.width.map_panel = settings.fig_specs.width.figure - ...
                                                 settings.fig_specs.margin.figure(1) - ...
                                                 settings.fig_specs.margin.figure(3);
        end
        
        if isempty(settings.fig_specs.width.legend_panel)
            settings.fig_specs.width.legend_panel = settings.fig_specs.width.figure - ...
                                                    settings.fig_specs.margin.figure(1) - ...
                                                    settings.fig_specs.margin.figure(3);
        end
        
        % settings.fig_specs.height
        % -----------------------------------------------------------------
        if ~isempty(pf)
            settings.fig_specs.height.map_panel = settings.fig_specs.height.figure - ...
                                                  settings.fig_specs.margin.figure(2) - ...
                                                  settings.fig_specs.margin.figure(4);
        end
        
        if isempty(settings.fig_specs.height.colorbar)
            
        end
        
        % settings.fig_specs.width_constraints
        % -----------------------------------------------------------------
        
        if isempty(settings.fig_specs.width_constraints.slice)
            settings.fig_specs.width_constraints.slice = [10,40];
        end
        
        if isempty(settings.fig_specs.width_constraints.colorbar)
            settings.fig_specs.width_constraints.colorbar = [20,100];
        end
        
        % settings.fig_specs.height_constraints
        % -----------------------------------------------------------------
        
        if isempty(settings.fig_specs.height_constraints.colorbar)
            settings.fig_specs.height_constraints.colorbar = [5,10];
        end
        
        % settings.fig_specs.n
        % -----------------------------------------------------------------
        
        if isempty(settings.fig_specs.n.slice)
            settings.fig_specs.n.slice = numel(settings.slice.disp_slices);
        end
        
        % settings.paper
        % =================================================================
        if isempty(settings.paper.type)
            settings.paper.type = 'A4';
        end
        
        if isempty(settings.paper.orientation)
            settings.paper.orientation = 'portrait';
        end
        
    otherwise
        error('First element must be ''init'' or ''fill-defaults''. Type ''help sd_config_settings''.')
end


