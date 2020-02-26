function S = ml_nlx_mclust_load_spikes_32bit(tfilelist)
%
% S = LoadSpikes(tfilelist)
%
% inp: tfilelist is a cellarray of strings, each of which is a
% 	tfile to open.  Note: this is incompatible with version unix3.1.
% out: Returns a cell array such that each cell contains a ts 
% 	object (timestamps which correspond to times at which the cell fired)

% ADR 1998
%  version L4.0
%  status: PROMOTED
% ADR 2012/12 removed flags.  Now only returns in seconds.


%-------------------
% Check input type
%-------------------
if isa(tfilelist, 'char')
    tfilelist = {tfilelist};
end
if ~isa(tfilelist, 'cell')
   error('LoadSpikes: tfilelist should be a cell array.');
end

nFiles = length(tfilelist);

%--------------------
% Read files
%--------------------

fprintf(2, 'Reading %d files.', nFiles);

% for each tfile
% first read the header, the read a tfile 
% note: uses the bigendian modifier to ensure correct read format.

S = cell(nFiles, 1);
for iF = 1:nFiles
	tfn = tfilelist{iF};
    [fd, fn, xt] = fileparts(tfn);
    
	if ~isempty(tfn)
		tfp = fopen(tfn, 'rb','b');
		if (tfp == -1)
			warning('MClust:LoadSpikes', 'Could not open tfile %s.', tfn);
		end
		
		MClust.ReadHeader(tfp);    

        % Force to load as 32 bit
        S{iF} = fread(tfp,inf,'uint32');	%read as 32 bit ints             
            
		fclose(tfp);		

		% Set appropriate time units.
        S{iF} = S{iF}/10000;
		
        % convert to ts object
		S{iF} = ts(S{iF});
	end 		% if tfn valid
end		% for all files
fprintf(2,'\n');
