classdef OPA_GBP < handle
    properties (Access = private)
        % Utility
        Ts = 0;
        % Components
        C = 1.6e-7;
        R = [0;...
             3.1623];
        P = 0;
        % Substitutions
        G = 0;
        J = 0;
        % Coefficients
        b = zeros(2,1);
        % Memory
        m = [0 0];
        % OPA Selection
        choice = 1;
        LM308 = 3.5e-9;
        LM741 = 3.5e-10;
        JRC4558 = 1.5e-9;
        TL072 = 1e-9;
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

        function y = processSample(o,x,c)
            y = o.b(1)*x + o.b(2)*o.m(c);
            o.m(c) = o.J*y - o.m(c);
        end

        function PrepareToPlay(o,Fs)
            o.Ts = 1/Fs;
            % Discrete Kirchhoff 
            switch(o.choice)
                case 1
                    o.C = o.LM308;
                case 2
                    o.C = o.LM741;
                case 3
                    o.C = o.JRC4558;
                case 4
                    o.C = o.TL072;
            end
            o.R(1) = o.Ts/(2*o.C);
            o.J = 2/o.R(1);
            o.findCoefficients;
        end

        function findCoefficients(o)
            % Calculation Substitutions
            o.G = 1/o.P + 1/o.R(1);
            % Filter Coefficients
            o.b(1) = 1/(o.P*o.G);
            o.b(2) = 1/o.G;
        end

        function setFrequencyPot(o,potValue)
            o.P = potValue;
            o.findCoefficients;
        end

        function selectOPA(o,opaChoice)
            o.choice = opaChoice;
            % Discrete Kirchhoff 
            switch(o.choice)
                case 1
                    o.C = o.LM308;
                case 2
                    o.C = o.LM741;
                case 3
                    o.C = o.JRC4558;
                case 4
                    o.C = o.TL072;
            end
            o.R(1) = o.Ts/(2*o.C);
            o.J = 2/o.R(1);
            o.findCoefficients;
        end
    end
end