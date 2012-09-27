classdef FrameGrabber < handle
    % FRAMER An easy way to make frames for movies
    
    properties
        path = '';            % Path to directory where images are saved
        prefix = '';          % Prefix of saved images
        ind = 0;              % Index of next frame to be saved
        fh = -1;              % Figure handle used to grab images
        transparency = false; % If true, preserve transparencies when grabbing
        fmt = '%07d';         % Format string for index suffix
        overwrite = false;    % If true, overwrite existing imageswhen grabbing
        grabevery = 1;        % Saves every grabevery frames to disk
    end
    
    methods(Static)
        function [obj] = CreateDir(fh, dirpath, prefix)
            % Create a Framer object and the directory it will use
            [success, message] = mkdir(dirpath);
            if success ~= 1
                error(message);
            elseif ~isempty(message)
                warning('Directory "%s" already exists', dirpath);
            end
            if nargin < 3
                obj = FrameGrabber(fh, dirpath);
            else
                obj = FrameGrabber(fh, dirpath, prefix);
            end
        end
    end
    
    methods
        function [obj] = FrameGrabber(fh, dirpath, prefix)
            % Create a Framer
            if nargin < 3
                prefix = obj.prefix;
            end
            if ~isdir(dirpath)
                error('Folder "%s" does not exist or is not a folder', dirpath);
            end
            [~, attr] = fileattrib(dirpath);
            obj.fh = fh;
            obj.path = attr.Name;
            obj.prefix = prefix;
        end
        
        function [] = set.transparency(obj, trans)
            if ~islogical(trans) && trans ~= 1 && trans ~= 0
                error('transparency must be true/false/0/1');
            end
            obj.transparency = logical(trans);
        end
        
        function [] = set.overwrite(obj, ov)
            if ~islogical(ov) && ov ~= 1 && ov ~= 0
                error('overwrite must be true/false/0/1');
            end
            obj.overwrite = logical(ov);
        end
        
        function [] = set.fh(obj, fh)
            if  length(fh) ~= 1 || ~ishandle(fh)
                error('Must specify single valid file handle');
            end
            obj.fh = fh;
        end
        
        function [] = rm(obj)
            % Delete all files associated with path and prefix
            suffixes = {'.pdf', '.jpg', '.eps', '.svg'};
            glob = sprintf('%s/%s*', obj.path, obj.prefix);
            cellfun(@(suffix) delete([glob suffix]), suffixes);
        end
        
        function [] = grab(obj)
            % Save figure to disk as a PDF if internal index is multiple of
            % grabevery
            %
            % -Uses current value of ind to add a suffix index
            % -If overwrite is false, will not delete existing file
            
            if (obj.grabevery > 0)  &&  (mod(obj.ind,obj.grabevery) == 0)
                
                if ~isempty(obj.prefix)
                    fmt_str = ['%s/%s' obj.fmt];
                    fname = sprintf(fmt_str, obj.path, obj.prefix, obj.ind);
                else
                    fmt_str = ['%s/' obj.fmt];
                    fname = sprintf(fmt_str, obj.path, obj.ind);
                end
                
                % Check if result already exists
                pdf = [fname '.pdf'];
                if ~obj.overwrite && exist(pdf, 'file')
                    error('File %s already exists', pdf);
                end
                
                % Grab file and produce PDF
                if ~obj.transparency
                    eps = [fname '.eps'];
                    print(obj.fh, eps, '-depsc');
                    cmd = sprintf('epstopdf %s', eps);
                    obj.system(cmd);
                    delete(eps);
                else
                    svg = [fname '.svg'];
                    % Suppress annoying output from plot2svg
                    text_output = evalc('plot2svg(svg, obj.fh)');
                    if ~strcmp(text_output(4:41),'Matlab/Octave to SVG converter version')
                        disp(text_output);
                    end
                    cmd = sprintf('rsvg-convert -f pdf -o %s %s', pdf, svg);
                    obj.system(cmd)
                    delete(svg);
                end
            end
            obj.ind = obj.ind + 1;
        end
    end
    
    methods(Static, Access = private)
        function [] = system(cmd)
            [stat, result] = system(cmd);
            if stat ~= 0
                error('Error executing "%s"\n%s', cmd, result);
            end
        end
    end
    
end


