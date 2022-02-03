function [X] = ml_alg_possible_patterns(symbols, numDraws)
    X = [];
    for i = 1:numDraws
        x = possible_patterns_helper(X, symbols);
        X = x;
    end
    X = unique(X,'rows');
end % function


function [X] = possible_patterns_helper(T, symbols)
    X = [];
    for i = 1:length(symbols)
        s = symbols(i);
        x = T;
        x(:, end+1) = s;
        X = cat(1, X,x);
    end
end % function