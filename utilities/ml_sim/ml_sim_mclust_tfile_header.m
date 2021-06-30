function ExampleHeader = ml_sim_mclust_tfile_header(tfileBits)
    t = datestr(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss'));

    ExampleHeader = cell(1, 10);
    ExampleHeader{1} = '%%BEGINHEADER';
    ExampleHeader{2} = '% Program: matlab';
    %ExampleHeader{3} = '% MClust version: MClust 4.0.6; 2014/Feb/11 (BETA)';
    ExampleHeader{3} = '% MuLaNA: 2021';
    ExampleHeader{4} = ['% Date: ' t];
    ExampleHeader{5} = '% Directory: C:\MuzzioLab\MarcNormandin';
    ExampleHeader{6} = '% T-file';
    ExampleHeader{7} = '% Output from Marc E. Normandin Simulator';
    ExampleHeader{8} = '% Time of spiking stored in timestamps (tenths of msecs)';

    if tfileBits == 64
        ExampleHeader{9} = '% as unsigned integer: uint64';
    else
        ExampleHeader{9} = '% as unsigned integer: uint32';
    end

    ExampleHeader{10} = '%%ENDHEADER';
end
