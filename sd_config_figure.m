function [h_figure, p, settings] = sd_config_figure(layers, settings)
    % SD_SETUP_FIGURE Configures the figure window
    %
    % DESCRIPTION
    % This function computes the figure dimensions and the layout of the
    % figure.
    % If a panel object was provided, optimal layout is computed.
    %
    % SYNTAX
    % [h_figure, p, settings] = SD_SETUP_FIGURE(layers, settings);
    %
    % layers        - Nx1 struct, specifying the N layers to be displayed (see)
    % settings      - 1x1 struct, specifying the figure and display settings (see)
    %
    % h_figure      - figure handle
    % p             - panel object (for details, type 'help panel')
    %
    % .........................................................................
    % Bram Zandbelt (bramzandbelt@gmail.com), Radboud University
    % Modified by Pieter Vandemaele (pieter.vandemaele@gmail.com), Ghent University

    
    % Check which layers need colorbar
    has_colorbar            = zeros(1:numel(layers));
    has_standard_colorbar   = zeros(1:numel(layers));
    has_dual_colorbar       = zeros(1:numel(layers));
    
    for i_layer = 1:numel(layers)
        if ~isempty(layers(i_layer).color.label())% && layers(i_layer).color.show
            has_colorbar(i_layer) = 1;
            
            switch lower(layers(i_layer).type)
                case {'truecolor','blob'}
                    has_standard_colorbar(i_layer) = 1;
                case 'dual'
                    has_dual_colorbar(i_layer) = 1;
            end
        end
    end
    
    i_colorbar = find(has_colorbar);
    settings.fig_specs.i.colorbar = i_colorbar;
    settings.fig_specs.n.colorbar = numel(find(find(has_colorbar)));
    settings.fig_specs.n.colorbar_standard = numel(find(find(has_standard_colorbar)));
    settings.fig_specs.n.colorbar_dual = numel(find(find(has_dual_colorbar)));
    
    % Get settings
    m           = settings.fig_specs.margin;
    w           = settings.fig_specs.width;
    h           = settings.fig_specs.height;
    wc          = settings.fig_specs.width_constraints;
    hc          = settings.fig_specs.height_constraints;
    hw_ratio    = settings.fig_specs.height_width_ratio;
    n           = settings.fig_specs.n;
    p           = settings.fig_specs.panel;
    t           = settings.fig_specs.title;
    
    % Legend panel
    % =====================================================================
    if n.colorbar >= 1
        n.colorbar_row      = 1;
        n.colorbar_column   = n.colorbar;
        if n.colorbar_dual >= 1
            h.legend_panel  = 10;
        else
            h.legend_panel  = 5;
        end
    end
    
    % Map panel
    % =====================================================================
    % Calculate the map_panel parameters depending on the parent object
    % Contains some redundancy for clear separation
    
    % 
    if ~isempty(p)
        % Parent panel provided
        % -----------------------------------------------------------------
        parent_type = 1;
        
   
        % Map panel height (take care of presence of legend panel
        % -----------------------------------------------------------------
        h_map_panel = h.map_panel;
        h_legend_panel = h.legend_panel;
        h_title_panel = h.title_panel;
               
        if n.colorbar == 0
            h_legend_panel = 0;
        end
        
        if isempty(t)
            h_title_panel = 0;
        end

        h.map_panel = h_map_panel - h_legend_panel - h_title_panel;
        prop_h_map      = h_map_panel / (h_map_panel + h_legend_panel + h_title_panel);
        prop_h_colorbar = h_legend_panel / (h_map_panel + h_legend_panel + h_title_panel);
        prop_h_title = h_title_panel / (h_map_panel + h_legend_panel + h_title_panel);

%         if n.colorbar >= 1 && 
%             h.map_panel = h.map_panel - h.legend_panel - h.title_panel;
%             prop_h_map      = h.map_panel / (h.map_panel + h.legend_panel + h.title_panel);
%             prop_h_colorbar = h.legend_panel / (h.map_panel + h.legend_panel + h.title_panel);
%             prop_h_title = h.title_panel / (h.map_panel + h.legend_panel + h.title_panel);
%         end
        
        % Calculate number of rows and columns
        % -----------------------------------------------------------------
        % code below is copied and adapted from https://imaging.mrc-cbu.cam.ac.uk/imaging/DisplaySlices
        asz = [w.map_panel, h.map_panel];
        min_nr_panels = settings.fig_specs.n.slice;
        if all([isempty(n.slice_row),isempty(n.slice_column)])
            % calculate optimal number of rows and cols
            % iteration needed to optimize, surprisingly.  Thanks to Ian NS
            [X, Y, Z] = deal(1,2,3);
            axlen(X,:)=asz(1):-1:1;
            axlen(Y,:)=hw_ratio.slice*axlen(X,:);
            panels = floor(asz'*ones(1,size(axlen,2))./axlen);
            
            est_nr_panels = prod(panels);
            
            tmp = find(est_nr_panels >= min_nr_panels);
            if isempty(tmp)
                error('Whoops, cannot fit panels onto figure');
            end
            idx = tmp(1); % best fitting scaling
            panels = panels(:,idx);
            axlen = axlen(:, idx);
        else
            if all([~isempty(n.slice_row),isempty(n.slice_column)])
                % calculate number of cols for given number of rows
                n.slice_column = ceil(min_nr_panels/ n.slice_row);
            elseif all([isempty(n.slice_row),~isempty(n.slice_column)])
                % calculate number of rows for given number of cols
                n.slice_row = ceil(min_nr_panels/ n.slice_column);
            elseif all([~isempty(n.slice_row),~isempty(n.slice_column)])
                % fixed number of rows and cols
                if n.slice_row*n.slice_column < min_nr_panels
                    error('Not enough panels for amount of slices')
                end
            end
            panels = [n.slice_column; n.slice_row];

            axlen = diag([asz(1)/n.slice_column, asz(2)/n.slice_row]);
            ratios = diag([hw_ratio.slice, 1/hw_ratio.slice ]) + flipud(diag([1,1]));
            axlen = axlen * ratios;
            delta_map_size = repmat(asz', 1, 2) - axlen.*repmat([n.slice_column, n.slice_row]', 1, 2);
            i = find(all(delta_map_size>=0, 2), 1);
            axlen = axlen(:,i);
        end

        n.slice_column = panels(1);
        n.slice_row = panels(2);
        w.slice = axlen(1);
        h.slice = axlen(2);
        w.map_panel = n.slice_column * w.slice;
        h.map_panel = n.slice_row * h.slice;
   
    else
        % Calculate number of rows and columns
        % -----------------------------------------------------------------
        % Slice constraints are respected when number of slice rows and 
        % columns remain unspecified. If user has specified number of 
        % slices rows and/or columns, slice constraints are ignored.
        parent_type = 2;
        if all([isempty(n.slice_row),isempty(n.slice_column)])
            
            % Estimate number of slice panel rows and columns
            n.slice_column    = ceil(sqrt(n.slice/(hw_ratio.slice)));
            
            % Slice panel width
            w.slice                 = w.map_panel / n.slice_column;
            
            % If not within constraints, set to min or max width
            if all(w.slice >= wc.slice(1) & ...
                    w.slice <= wc.slice(2))
            elseif w.slice < wc.slice(1)
                w.slice         = wc.slice(1);
                n.slice_column  = floor(w.map_panel / w.slice);
            elseif w.slice > wc.slice(2)
                w.slice         = wc.slice(2);
                if ceil(w.map_panel / w.slice) * w.slice <= w.map_panel
                    n.slice_column  = ceil(w.map_panel / w.slice);
                else
                    n.slice_column  = floor(w.map_panel / w.slice);
                end
            end
            
            n.slice_row         = ceil(n.slice / n.slice_column);
            
        elseif all([~isempty(n.slice_row),isempty(n.slice_column)])
            n.slice_column      = ceil(n.slice / n.slice_row);
            w.slice             = w.map_panel / n.slice_column;
        elseif all([isempty(n.slice_row),~isempty(n.slice_column)])
            w.slice             = w.map_panel / n.slice_column;
            n.slice_row         = ceil(n.slice / n.slice_column);
        elseif all([~isempty(n.slice_row),~isempty(n.slice_column)])
            w.slice             = w.map_panel / n.slice_column;
        end
        
        h.slice             = w.slice * hw_ratio.slice;
        h.map_panel         = h.slice * n.slice_row;
        
        % Figure height
        % -----------------------------------------------------------------
        if n.colorbar >= 1
            prop_h_map      = h.map_panel / (h.map_panel + h.legend_panel);
            prop_h_colorbar = h.legend_panel / (h.map_panel + h.legend_panel);
            h.figure        = h.map_panel + h.legend_panel + ...
                m.figure(2) + m.figure(4);
        elseif n.colorbar == 0
            h.figure = h.map_panel + m.figure(2) + m.figure(4);
        end
    end
    
    % Setup figure
    % =====================================================================
    h_figure = [];
    if isempty(p)
        
        % Make new figure
        % -----------------------------------------------------------------
        h_figure = figure;
        
        % Get screen size
        % -----------------------------------------------------------------
        screen_size = get(0,'ScreenSize');
        
        wf_pix = w.figure .* unitsratio('inches','mm') .* get(0,'ScreenPixelsPerInch');
        hf_pix = h.figure .* unitsratio('inches','mm') .* get(0,'ScreenPixelsPerInch');
        
        if wf_pix > screen_size(3) | hf_pix > screen_size(4)
            screen_wh_ratio = screen_size(3:4);
            pos = get(h_figure,'Position');
            pos(3:4) = min(screen_wh_ratio ./ [w.figure, h.figure]) .* [w.figure, h.figure];
            set(h_figure,'Position',[pos(3)/2,pos(4)/2,pos(3),pos(4)])
        else
            left_pos = screen_size(3)/2 - wf_pix/2;
            bottom_pos = screen_size(4)/2 - hf_pix/2;
            set(h_figure,'Position',[left_pos,bottom_pos,wf_pix,hf_pix])
        end
        
        % Center figure on paper
        % -----------------------------------------------------------------
        set(h_figure, 'PaperType', settings.paper.type);
        set(h_figure, 'PaperUnits', 'centimeters');
        
        switch lower(settings.paper.orientation)
            case 'landscape'
                orient landscape
            case 'portrait'
                orient portrait
            otherwise
                orient portrait
        end
        
        % Paper settings
        % -----------------------------------------------------------------
        paper_dim = get(h_figure,'PaperSize');
        paper_w = paper_dim(1);
        paper_h = paper_dim(2);
        x_left = (paper_w-w.figure/10)/2;
        y_top = (paper_h-h.figure/10)/2;
        set(h_figure,'PaperPosition',[x_left, y_top, w.figure/10, h.figure/10]);
        
        % Setup panels
        % -----------------------------------------------------------------
        
        figure(h_figure);
        p = panel();
    end
    
    % Pack the parent panel with or without colorbar
    poff = 0;
    if n.colorbar >= 1
        if isempty(t) || isempty(settings.fig_specs.panel)
            p.pack('v',[prop_h_map, prop_h_colorbar]);
        else
            poff = 1;
            p.pack('v',[prop_h_title prop_h_map, prop_h_colorbar]);
        end
    else
        if isempty(t) || isempty(settings.fig_specs.panel)
            p.pack('v',1);
        else
            poff = 1;
            p.pack('v',[prop_h_title prop_h_map]);
        end

    end

    % Add subpanels
    norm_width  = 1/n.slice_column;
    norm_height = 1/n.slice_row;
    off_w = 0;
    off_h = 0;
           
    pcnt = 1;
    for i_row = 1:n.slice_row
        for i_col = 1:n.slice_column
            norm_left = i_col/n.slice_column  - norm_width + off_w;
            norm_bottom = (n.slice_row - i_row)/n.slice_row  + off_h;
            p(1+poff).pack({[norm_left, norm_bottom, norm_width, norm_height]});
            pcnt=pcnt + 1;
        end
    end

% Setup margins
if n.colorbar >= 1
    p(2+poff).pack(n.colorbar_row,n.colorbar_column);
    p.margin = m.figure;
    p.de.margin = m.panel;
    p(1+poff).margin = m.slice;
    p(1+poff).de.margin = m.slice;
    p(2+poff).de.margin = m.colorbar;
    
else
    p.de.margin = m.figure;
    p(1+poff).de.margin = m.slice;
end
    % Update settings structure
    settings.fig_specs.margin = m;
    settings.fig_specs.width = w;
    settings.fig_specs.height = h;
    settings.fig_specs.width_constraints = wc;
    settings.fig_specs.height_constraints = hc;
    settings.fig_specs.width_height_ratio = hw_ratio;
    settings.fig_specs.n = n;
    settings.fig_specs.panel = p;
    settings.fig_specs.parent_type = parent_type; 
end
