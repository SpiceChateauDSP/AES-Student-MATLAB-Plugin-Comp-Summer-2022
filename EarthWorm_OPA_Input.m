classdef EarthWorm_OPA_Input < handle
    properties (Access = private)
        % Power Supply
        supplyVoltage = 0;
        % Components
        C = [22e-9;... % Capacitors
             1e-9];
        R = [0;... % Resistors
             0;...
             2e6;...
             1e3];

        % Calculating Substitutions
        G = zeros(3,1);
        J = zeros(2,1);

        % Coefficients
        b = zeros(4,1);

        % States
        m = zeros(2,2);
    end

    methods
        % Constructor
        function o = EarthWorm_OPA_Input()
        end

        % DSP
        function out = process(o,in)
            [N,C] = size(in);
            out = zeros(N,C);

            for c = 1:C
                for n = 1 : N
                    out(n,c) = processSample(o,in(n,c),c);
                end
            end
        end

        function y = processSample(o,x,c)
            % Transfer Function
            Vo = o.b(1)*x + o.b(2)*o.m(1,c) + o.b(3)*o.m(2,c)...
                + o.b(4)*o.supplyVoltage;

            % State Updates
            Va = Vo * o.G(2) - o.m(2,c) * o.R(4);
            o.m(1,c) = o.J(1) * (x - Va) - o.m(1,c);
            o.m(2,c) = o.J(2) * Vo - o.m(2,c);

            % Return y
            y = Vo;
        end

        function PrepareToPlay(o,Fs)
            Ts = 1/Fs;
            % Sample Rate Dependent Components
            o.R(1) = Ts/(2*o.C(1));
            o.R(2) = Ts/(2*o.C(2));
            % Calculating Substitutions
            o.G(1) = 1/o.R(1) + 1/o.R(3) + 1/o.R(4);
            o.G(2) = o.R(4)/o.R(2) + 1;
            o.G(3) = o.G(2) - 1/(o.R(4) * o.G(1));
            % Optimizing Substitutions
            o.J(1) = 2/o.R(1);
            o.J(2) = 2/o.R(2);
            % Coefficients
            o.b(1) = 1/(o.R(1)*o.G(1)*o.G(3));
            o.b(2) = -1/(o.G(1)*o.G(3));
            o.b(3) = o.R(4)/o.G(3);
            o.b(4) = 1/(o.R(3)*o.G(1)*o.G(3));
        end

        function setSupplyVoltage(o,supplyVoltage)
            o.supplyVoltage = supplyVoltage;
        end
    end
end