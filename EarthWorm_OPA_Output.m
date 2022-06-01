classdef EarthWorm_OPA_Output < handle
    % Output section of a Proco Rat without JFET
    properties (Access = private)
        % Components
        C1 = 1e-6;
        R = [0;...
             50e3;...
             50e3];
        % G Substitutions
        G = zeros(3,1);
        J = 0;
        % Coefficients
        b = zeros(2,1);
        % States
        m = [0 0];
    end

    methods
        % DSP
        function out = process(o,in)
            [N,C] = size(in);
            out = zeros(N,C);
            % Process Sample Loop
            for c = 1:C
                for n = 1:N
                    out(n,c) = processSample(o,in(n,c),c);
                end
            end
        end

        function y = processSample(o,x,c)
            % Transfer Function
            Vo = o.b(1)*x + o.b(2)*o.m(c);
            % Nodes
            Va = Vo*o.G(2);
            % State Updates
            o.m(c) = o.J*(x - Va) - o.m(c);
            % Return
            y = Vo;
        end

        function PrepareToPlay(o,Fs)
            Ts = 1/Fs;
            % Sample Rate Dependent Components
            o.R(1) = Ts/(2*o.C1);
            % G Substitutions
            o.G(1) = 1/o.R(1) + 1/o.R(2);
            o.G(2) = 1 + o.R(2)/o.R(3);
            o.G(3) = o.G(2) - 1/(o.G(1)*o.R(2));
            o.J = 2/o.R(1);
            % Coefficients
            o.b(1) = 1/(o.G(1)*o.G(3)*o.R(1));
            o.b(2) = -1/(o.G(1)*o.G(3));
        end

        % Set Parameters
        function setVolumePot(o,volumePotValue)
            % Potentiometer
            o.R(2) = 100e3 - volumePotValue;
            o.R(3) = volumePotValue;
            % G Substitutions
            o.G(1) = 1/o.R(1) + 1/o.R(2);
            o.G(2) = 1 + o.R(2)/o.R(3);
            o.G(3) = o.G(2) - 1/(o.G(1)*o.R(2));
            % Coefficients
            o.b(1) = 1/(o.G(1)*o.G(3)*o.R(1));
            o.b(2) = -1/(o.G(1)*o.G(3));
        end
    end
end