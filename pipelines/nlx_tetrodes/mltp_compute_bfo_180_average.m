function mltp_compute_bfo_180_average(obj)

   mltp_compute_bfo_general_average(obj, 180, 'same');
   mltp_compute_bfo_general_average(obj, 180, 'different');
   mltp_compute_bfo_general_average(obj, 180, 'all');
   
   numContexts = obj.Experiment.getNumContexts();
   for iContext = 1:numContexts
    mltp_compute_bfo_general_average(obj, 180, sprintf('context%d', iContext));
   end

end % function