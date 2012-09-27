classdef FrameConverter < handle
    %FRAMECONVERTER Make a movie from a folder of PDFs
    
    properties
        path = ''; % Path to directory containing PDFs
        fmt = '%03d.jpg'; % Format string for symlinked JPGs made by link()
        % max_jobs - Max number of jobs to run in parallel.
        %
        % Set to 0 to use all available cores.
        max_jobs = 1;
    end
    
    methods
        function [obj] = FrameConverter(path)
            [success, data] = fileattrib(path);
            if ~success
                error('%s: %s', path, data);
            elseif ~isdir(data.Name)
                error('%s is not a directory', data.Name);
            end
            obj.path = data.Name;
        end
        
        function [] = set.max_jobs(obj, jobs)
            if ~isnumeric(jobs) || jobs < 0 || int32(jobs) ~= jobs
                error('max_jobs must be a non-negative integer')
            end
            obj.max_jobs = jobs;
        end
        
        function [jpg] = jpg_name(~, pdf)
            % Convert PDF source path to JPG destination path
            jpg = strrep(pdf, '.pdf', '.jpg');
        end
        
        function [convert] = need_convert(obj, args, force)
            % Get cell array of paths to PDFs that need to be converted
            [success, pdfs] = fileattrib([obj.path '/*.pdf']);
            if ~success
                warning('No pdfs found');
                return;
            end
            % Read command that was used last time
            arg_file = [obj.path '/.conv_arg'];
            if exist(arg_file, 'file')
                fid = fopen(arg_file, 'r');
                cleanup = onCleanup(@()fclose(fid));
                old_args = fgetl(fid);
            else
                old_args = '';
            end
            if ~strcmp(old_args, args)
                force = true;
            end
            fid = fopen(arg_file, 'w');
            cleanup = onCleanup(@()fclose(fid));
            fprintf(fid, '%s\n', args);
            fid = -1; % This causes file to be closed immediately
            
            % Build list of files that need to be converted
            convert = {};
            for k = 1:length(pdfs)
                pdf = pdfs(k).Name;
                jpg = obj.jpg_name(pdf);
                if ~exist(jpg, 'file') || force
                    convert{end+1} = pdf;
                else
                    jpgd = dir(jpg);
                    pdfd = dir(pdf);
                    if jpgd.datenum < pdfd.datenum
                        convert{end + 1} = pdf;
                    end
                end
            end
        end
        
        function [] = convert(obj, args, force)
            % Convert all files in folder to JPG
            %
            % Default is to convert each PDF to 512x512 image.
            %
            % Caches results so that if a JPG has already been made for a
            % PDF with the passed in arguments, no action is taken
            %
            % args: String that gets passed to convert
            % force: If true, ignore cache and convert all PDFs to JPGs
            if nargin < 2
                args = '-resize 512x512\!';
            end
            if nargin < 3
                force = false;
            end
            
            convert = obj.need_convert(args, force);
            if isempty(convert)
                return
            end
            
            convert_cmd = sprintf('convert %s', args);
            if obj.max_jobs == 1
                for k = 1:length(convert)
                    pdf = convert{k};
                    cmd = sprintf('%s %s %s', convert_cmd, pdf, obj.jpg_name(pdf));
                    obj.system(cmd);
                end
            else
                % Get space separate list of files
                dest(1:length(convert)*2 - 1) = {' '};
                dest(1:2:end) = convert;
                files = [dest{:}];
                cmd = sprintf('ls -1 %s | parallel -j %i --halt 1 %s {} {.}.jpg', ...
                    files, obj.max_jobs, convert_cmd);
                obj.system(cmd);
            end
        end
        
        function [] = link(obj)
            % Create symlinks to JPGs in folder called 'frames'
            %
            % You must run this before running ffmpeg()
            [success, jpgs] = fileattrib([obj.path '/*.jpg']);
            if ~success
                warning('No JPGs found');
                return;
            end
            
            % Build frames directory, clearing content if necessary
            framepath = [obj.path '/frames/'];
            if exist(framepath, 'dir')
                rmdir(framepath, 's')
            end
            [success, message] = mkdir(framepath);
            if success ~= 1
                error(message);
            end
            
            obj.fmt = sprintf('%%0%dd.jpg', length(int2str(length(jpgs))));
            ind = 0;
            for k = 1:length(jpgs)
                jpg = jpgs(k).Name;
                [~, filename, ext] = fileparts(jpg);
                
                link = [framepath sprintf(obj.fmt, ind)];
                cmd = sprintf('ln -sf ../%s %s', [filename ext], link);
                obj.system(cmd);
                ind = ind + 1;
            end
        end
        
        function [] = ffmpeg(obj, args)
            % Create movie using JPGs located in frames/
            %
            % args: String that gets passed to ffmpeg
            if nargin < 2
                args = '';
            end
            fmt_str = sprintf('%s/frames/%s', obj.path, obj.fmt);
            output = sprintf('%s/output.mp4', obj.path);
            cmd = sprintf('ffmpeg -y %s -i %s %s', args, fmt_str, output);
            
            obj.system(cmd);
            fprintf('Created %s\n', output);
        end
    end
    
    methods(Static)
        function [result] = system(cmd)
            [stat, result] = system(cmd);
            if stat ~= 0
                error('Error executing "%s"\n%s', cmd, result);
            end
        end
    end
end

