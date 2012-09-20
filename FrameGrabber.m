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
            % TODO: Check required commands like epstopdf exist?
        end              
        
        function [] = set.transparency(obj, transparency)
            if ~islogical(transparency)
                error('transparency must be true or false');
            end
            obj.transparency = transparency;
        end
        
        function [] = set.fh(obj, fh)            
            if  length(fh) ~= 1 || ~ishandle(fh)
                error('Must specify single valid file handle');
            end
            obj.fh = fh;
        end
        
        function [] = rm(obj)
            % Delete all files associated with path and prefix
            delete(sprintf('%s/%s*.pdf', obj.path, obj.prefix));
            delete(sprintf('%s/%s*.jpg', obj.path, obj.prefix));
            delete(sprintf('%s/%s*.eps', obj.path, obj.prefix));
        end
        
        function [] = grab(obj)
            % Save figure to disk as a PDF
            %
            % -Uses current value of ind to add a suffix index
            % -If overwrite is false, will not delete existing file
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
                plot2svg(svg, obj.fh)
                cmd = sprintf('rsvg-convert -f pdf -o %s %s', pdf, svg);
                obj.system(cmd)
                delete(svg);
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


