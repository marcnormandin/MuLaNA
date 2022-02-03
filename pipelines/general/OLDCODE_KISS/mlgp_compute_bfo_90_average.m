function mlgp_compute_bfo_90_average(obj)

   mlgp_compute_bfo_general_average(obj, 90, 'same');
   mlgp_compute_bfo_general_average(obj, 90, 'different');
   mlgp_compute_bfo_general_average(obj, 90, 'all');
   
   numContexts = obj.Experiment.getNumContexts();
   for iContext = 1:numContexts
       mlgp_compute_bfo_general_average(obj, 90, sprintf('context%d', iContext));
   end

end % function