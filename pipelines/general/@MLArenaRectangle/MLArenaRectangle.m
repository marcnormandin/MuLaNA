classdef MLArenaRectangle < MLArena
    properties
        x_length_cm;
        y_length_cm;
        
    end % properties
    
    methods
        function obj = MLArenaRectangle(referencePointsVideo, x_length_cm, y_length_cm)
            % Validate the inputs
            if ~all(size(referencePointsVideo) == [2, 4])
                error('Must referencePointsVideo must be size [2, 4]');
            end
            if any([x_length_cm <= 0, y_length_cm <= 0])
                error('Arena lengths must be > 0, but are (%f) and (%f)', x_length_cm, y_length_cm)
            end
            
            referencePointsCanon = nan(2,4);
            referencePointsCanon(1,:) = [x_length_cm, 0, 0, x_length_cm];
            referencePointsCanon(2,:) = [0, 0, y_length_cm, y_length_cm];
            
            % Call MLArena constructor
            obj@MLArena('rectangle', referencePointsVideo, referencePointsCanon);
            
            % Store the inputs
            obj.x_length_cm = x_length_cm;
            obj.y_length_cm = y_length_cm; 
        end % function
        
        % Plot the arena shape in canonical frame
        function plotVideo(obj)
            % r, g, b, m
            x = obj.referencePointsVideo(1,:);
            y = obj.referencePointsVideo(2,:);
            
            % Draw the north/feature
            tf = ishold;
            plot([x(2), x(1)], [y(2), y(1)], 'k-', 'linewidth', 2);
            hold on
            plot(x(1), y(1), 'ro', 'markerfacecolor', 'r', 'markeredgecolor', 'k');
            plot(x(2), y(2), 'go', 'markerfacecolor', 'g', 'markeredgecolor', 'k');
            plot(x(3), y(3), 'bo', 'markerfacecolor', 'b', 'markeredgecolor', 'k');
            plot(x(4), y(4), 'mo', 'markerfacecolor', 'm', 'markeredgecolor', 'k');
            
            % resume the hold state
            if tf
                hold on
            else
                hold off
            end
        end % function
        
        % Plot the arena shape in canonical frame
        function plotCanon(obj)
            % r, g, b, m
            x = obj.referencePointsCanon(1,:);
            y = obj.referencePointsCanon(2,:);
            
            % Draw the north/feature
            tf = ishold;
            plot([x(2), x(1)], [y(2), y(1)], 'k-', 'linewidth', 2);
            hold on
            plot(x(1), y(1), 'ro', 'markerfacecolor', 'r', 'markeredgecolor', 'k');
            plot(x(2), y(2), 'go', 'markerfacecolor', 'g', 'markeredgecolor', 'k');
            plot(x(3), y(3), 'bo', 'markerfacecolor', 'b', 'markeredgecolor', 'k');
            plot(x(4), y(4), 'mo', 'markerfacecolor', 'm', 'markeredgecolor', 'k');
            
            % resume the hold state
            if tf
                hold on
            else
                hold off
            end
        end % function
        
        % Plot the arena shape in canonical frame (but centered about the
        % origin
        function plotCanonCentered(obj)
            % r, g, b, m
            x = obj.referencePointsCanon(1,:) - obj.x_length_cm/2;
            y = obj.referencePointsCanon(2,:) - obj.y_length_cm/2;
            
            
            % Draw the north/feature
            tf = ishold;
            hold on
            
            % Plot the boundary
            p = zeros(length(x)+1,1);
            q = zeros(length(y)+1,1);
            p(1:length(x)) = x;
            p(end) = x(1);
            q(1:length(y)) = y;
            q(end) = y(1);
            plot(p,q,'k:','linewidth', 4);
            
            % Plot the feature
            plot([x(2), x(1)], [y(2), y(1)], 'k-', 'linewidth', 4);
            
            % Plot the corners
            plot(x(1), y(1), 'ro', 'markerfacecolor', 'r', 'markeredgecolor', 'k');
            plot(x(2), y(2), 'go', 'markerfacecolor', 'g', 'markeredgecolor', 'k');
            plot(x(3), y(3), 'bo', 'markerfacecolor', 'b', 'markeredgecolor', 'k');
            plot(x(4), y(4), 'mo', 'markerfacecolor', 'm', 'markeredgecolor', 'k');
            
            
            
            
            % resume the hold state
            if tf
                hold on
            else
                hold off
            end
        end % function
    end % methods
end % classdef