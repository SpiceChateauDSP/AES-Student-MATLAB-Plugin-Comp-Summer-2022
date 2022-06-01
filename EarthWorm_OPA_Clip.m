classdef EarthWorm_OPA_Clip< handle
    % Emulation "hard clipping"-style diode distortion circuit
    % Matched pair of generic Silicon diodes
    properties (Access = private)
        % Diode Qualities
        Is2 = 2*10e-15;
        Vt = 0.02585;
        % Components
        C1 = 4.7e-6;
        R1 = 0;
        R2 = 1e3;
        % Substitutions
        G1 = 0;
        G2 = 0;
        J1 = 0;
        % Coefficients
        b1 = 0;
        b2 = 0;
        b3 = 0;
        % States
        x1 = [0 0];
        Vo = [0 0];
    end

    methods
       % DSP
        function out = process(o,in)
            [N,C] = size(in);
            out = zeros(N,C);
            % Process Sample Loop
            for c = 1:C
                for n = 1:N
                    out(n,c) = o.processSample(in(n,c),c);
                end
            end
        end

        function y = processSample(o,x,c)
            % Transfer Function
            p = -x/o.b1 + o.x1(c)/o.b2;
            num = o.Is2*sinh(o.Vo(c)/o.Vt) + o.Vo(c)*o.G2 + p;
            % Newton Raphson Loop
            b = 1; % Error Value
            count = 1;
            if (abs(num) > .000000001 && count < 10)
                % Derivate of Transfer Function for Vo
                den = o.Is2/o.Vt*cosh(o.Vo(c)/o.Vt) + o.G2;
                Vnew = o.Vo(c) - b*num/den;
                num2 = o.Is2*sinh(Vnew/o.Vt) + Vnew*o.G2 + p;
                % Damp the Newton Raphson to eliminate divergence
                if (abs(num2) > abs(num))
                    b = b/2;
                else
                    o.Vo(c) = Vnew;
                    b = 1;
                end
                % Recalculate numerator
                num = o.Is2*sinh(o.Vo(c)/o.Vt) + o.Vo(c)*o.G2+ p;
                count = count + 1;
            end
            % Update States
            Va = x/o.b3 + o.Vo(c)/o.b2 - o.x1(c)/o.G1;
            o.x1(c) = o.J1*(x - Va) - o.x1(c);
            % Return
            y = o.Vo(c);
        end

        function PrepareToPlay(o,Fs)
            Ts = 1/Fs;
            % Discrete Kirchhoff
            o.R1 = Ts/(2*o.C1);
            % Substitutions
            o.G1 = 1/o.R1 + 1/o.R2;
            o.G2 = 1/o.R2 - 1/((o.R2^2)*o.G1);
            o.J1 = 2/o.R1;
            % Coefficients
            o.b1 = o.R1*o.R2*o.G1;
            o.b2 = o.R2*o.G1;
            o.b3 = o.R1*o.G1;
        end
    end
end