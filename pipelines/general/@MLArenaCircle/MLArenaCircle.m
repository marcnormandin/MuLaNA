classdef MLArenaCircle < MLArena
    properties
        diameter_cm;
        
    end % properties
    
    methods
        function obj = MLArenaCircle(referencePointsVideo, diameter_cm)
            % Validate the inputs
            if ~all(size(referencePointsVideo) == [2, 4])
                error('Must referencePointsVideo must be size [2, 4]');
            end
            if diameter_cm <= 0
                error('Arena diameter must be > 0, but is (%f).', length_cm);
            end
            
            radius_cm = diameter_cm / 2.0;
            
            referencePointsCanon = nan(2,4);
            referencePointsCanon(1,:) = [diameter_cm, radius_cm, 0, radius_cm];
            referencePointsCanon(2,:) = [radius_cm, 0, radius_cm, diameter_cm];
            
            % Call MLArena constructor
            obj@MLArena('circle', referencePointsVideo, referencePointsCanon);
            
            % Store the inputs
            obj.diameter_cm = diameter_cm;
        end % function
        
        % Plot the arena shape in video frame
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
    end % methods
end % classdef