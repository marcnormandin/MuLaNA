classdef MLBehaviourInterface < handle
    %MLBehaviourInterface Interface class for animal behaviour
    %   An interface class for the fundamental animal behaviour
    
    methods (Abstract)
        % Returns the common length of the arrays
        getArrayLength(obj)
        
        % Returns the x coordinate of the animal position as an array
        getPositionX(obj)
        
        % Returns the y coordinate of the animal position as an array
        getPositionY(obj)
        
        % Return the speed of the animal as an array
        getSpeed(obj)
        
        % Returns the head direction angle of the animal as an array
        getHeadDirection(obj)
        
        % Returns the timestamps of the animal in milliseconds as an array
        getTimestampsMs(obj)
    end
       
    methods
        % Returns positions as a 2xN matrix
        function [p] = getPositionMatrix(obj)
            p = nan(2, obj.getArrayLength());
            p(1,:) = obj.getPositionX();
            p(2,:) = obj.getPositionY();
        end
        
        % Returns timestamps in seconds
        function [ts] = getTimestampsS(obj)
            ts = obj.getTimestampsMs() ./ 1000.0;
        end
        
        function plotPath(obj)
           plot(obj.getPositionX(), obj.getPositionY(), 'k.-'); 
        end
        
        function plotTimeseriesPositionX(obj)
            plot(obj.getTimestampsS(), obj.getPositionX(), 'r.-');
        end
        
        function plotTimeseriesPositionY(obj)
            plot(obj.getTimestampsS(), obj.getPositionY(), 'g.-');
        end
        
        function plotTimeseriesSpeed(obj)
            plot(obj.getTimestampsS(), obj.getSpeed(), 'b.-');
        end
        
        function plotTimeseriesHeadDirection(obj)
            plot(obj.getTimestampsS(), obj.getHeadDirection(), 'm.-');
        end
        
        
        function [h] = plotFigureSummary(obj)
            h = figure('position', get(0, 'screensize'));
            p = 4; q = 2;
            ax(1) = subplot(p,q,1);
            obj.plotTimeseriesPositionX();
            ylabel('Position x')
            
            ax(2) = subplot(p,q,3);
            obj.plotTimeseriesPositionY();
            ylabel('Position y')
            
            ax(3) = subplot(p,q,5);
            obj.plotTimeseriesSpeed();
            ylabel('Speed')
            
            ax(4) = subplot(p,q,7);
            obj.plotTimeseriesHeadDirection();
            xlabel('Time, t [s]')
            ylabel('Speed, s [unit/s]')
            
            bx(1) = subplot(p,q,[2,4,6,8]);
            obj.plotPath()
            
            linkaxes(ax, 'x');
        end
            
    end % methods
end % classdef

