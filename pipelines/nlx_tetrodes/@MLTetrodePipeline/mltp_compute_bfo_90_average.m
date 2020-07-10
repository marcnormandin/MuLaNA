function mltp_compute_bfo_90_average(obj)

   mltp_compute_bfo_general_average(obj, 90, 'same');
   mltp_compute_bfo_general_average(obj, 90, 'different');
   mltp_compute_bfo_general_average(obj, 90, 'all');
   
   numContexts = obj.Experiment.getNumContexts();
   for iContext = 1:numContexts
       mltp_compute_bfo_general_average(obj, 90, sprintf('context%d', iContext));
   end

end % function