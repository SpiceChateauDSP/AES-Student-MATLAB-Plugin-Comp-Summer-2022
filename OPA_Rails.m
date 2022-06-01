classdef OPA_Rails < handle
    properties (Access = private)
        posRail = 9;
    end

    methods
        % DSP
        function out = process(o,in)
            [N,C] = size(in);
            out = zeros(N,C);
            
            for c = 1:C
                for n = 1:N
                    out(n,c) = processSample(o,in(n,c),c);
                end
            end
        end

        function y = processSample(o,x)
           if (x > o.posRail)
                y = o.posRail;
            elseif (x < 0)
                y = 0;
            else
                y = x;
           end
        end
    end
end