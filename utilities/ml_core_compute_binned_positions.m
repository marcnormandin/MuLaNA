function [x, y, xi, yi, xedges, yedges] = ml_core_compute_binned_positions(x, y, boundsx, boundsy, nbinsx, nbinsy) %
%     p = inputParser;
%     p.CaseSensitive = false;
%     
%     addRequired(p,'x');
%     addRequired(p,'y');
%     addRequired(p,'boundsx');
%     addRequired(p,'boundsy');
%     addRequired(p,'nbinsx');
%     addRequired(p,'nbinsy');
%     
%     
%     addParameter(p, 'OutsidePointMethod', checkOutsidePointMethod);
%    
%     parse(p, x, y, boundsx, boundsy, nbinsx, nbinsy, varargin{:});
%     
%     if p.Results.verbose
%         fprintf('Using the following settings:\n');
%         disp(p.Results)
%     end
    
    xedges = linspace( boundsx(1), boundsx(2), nbinsx+1);
    yedges = linspace( boundsy(1), boundsy(2), nbinsy+1);
    
    % Force (should be optional) each outside point to the closest interior
    % point so that they are all used
    x(x < boundsx(1)) = boundsx(1);
    x(x > boundsx(2)) = boundsx(2);
    y(y < boundsy(1)) = boundsy(1);
    y(y > boundsy(2)) = boundsy(2);

    xi = discretize(x, xedges);
    yi = discretize(y, yedges);

    % Check if there are any points outside the desired edges
    % which signals an error
    xi_outside = find(isnan(xi));
    yi_outside = find(isnan(yi));
    i_outside = union(xi_outside, yi_outside);

    % The math fails if any points are outside, so if there are, remove them
    if ~isempty(i_outside)
        error('Algorithm can not work with points outside the bounds')
    end
end


% function result = checkOutsidePointMethod(x)    
%     result = false;
%     if strcmpi(x, 'clip')
%         result = true;
%     elseif strcmpi(x, 'project')
%         result = true;
%     end
% end

