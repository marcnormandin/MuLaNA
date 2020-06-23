function ml_cai_cnmfe_plot_cell_timeseries(cnmfe, nid)
y1 = cnmfe.RawTraces(:,nid);
y2 = cnmfe.FiltTraces(:,nid);
y3 = cnmfe.neuron.S(nid,:);

si = find(y3 ~= 0);
x1 = 1:length(y1);
x2 = x1;
x3 = x1(si);
y3 = y3(si);

figure
plot(x1,y1,'k-')
hold on
plot(x2,y2,'m-','linewidth',4)
stem(x3,y3,'r')
grid on
grid minor
title(sprintf('nid = %d', nid))
end % function
