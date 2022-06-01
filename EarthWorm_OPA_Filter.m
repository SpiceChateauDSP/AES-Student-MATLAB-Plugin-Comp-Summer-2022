classdef EarthWorm_OPA_Filter < handle
    properties (Access = private)
        % Components
        C = [3.3e-9;...
             22e-9];
        R = [zeros(2,1);...
             1e6];
        P = 51.5e3; % Tone Knob
        % G Substitutions
        G = zeros(4,1);
        J = zeros(2,1);
        % Coefficients
        b = zeros(3,1);
        % States
        m = zeros(2,2);
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
            Vo = o.b(1)*x + o.b(2)*o.m(1,c) + o.b(3)*o.m(2,c);
            % Node
            Va = o.G(2)*Vo + o.R(2)*o.m(2,c);
            % State Updates
            o.m(1,c) = o.J(1)*Va - o.m(1,c);
            o.m(2,c) = o.J(2)*(Va - Vo) - o.m(2,c);
            % Return y
            y = Vo;
        end

        function PrepareToPlay(o,Fs)
            Ts = 1/Fs;
            % Sample Rate Dependent Components
            o.R(1) = Ts/(2*o.C(1));
            o.R(2) = Ts/(2*o.C(2));
            % Optimizing Subsitutions
            o.J(1) = (2/o.R(1));
            o.J(2) = (2/o.R(2));
            % G Substitutions
            o.G(1) = 1/o.P + 1/o.R(1) + 1/o.R(2);
            o.G(2) = 1 + o.R(2)/o.R(3);
            o.G(3) = o.G(2) - 1/(o.R(2)*o.G(1));
            o.G(4) = 1/o.G(1) - o.R(2);
            % Coefficients
            o.b(1) = 1/(o.P*o.G(1)*o.G(3));
            o.b(2) = 1/(o.G(1)*o.G(3));
            o.b(3) = o.G(4)/o.G(3);
        end
        
        % Set Parameters
        function setTonePot(o,tonePotValue)
            o.P = tonePotValue + 1.5e3;
            % G Substitutions
            o.G(1) = 1/o.P + 1/o.R(1) + 1/o.R(2);
            o.G(3) = o.G(2) - 1/(o.R(2)*o.G(1));
            o.G(4) = 1/o.G(1) - o.R(2);
            % Coefficients
            o.b(1) = 1/(o.P*o.G(1)*o.G(3));
            o.b(2) = 1/(o.G(1)*o.G(3));
            o.b(3) = o.G(4)/o.G(3);
        end
    end
end