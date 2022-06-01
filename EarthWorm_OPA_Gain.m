classdef EarthWorm_OPA_Gain < handle
    properties (Access = private)
        % Objects
        gainBandwidth;
        slewRate;
        rails;
        % Capacitors
        C1 = 100e-12;
        C2 = 2.2e-6;
        C3 = 4.7e-6;
        % Resisitors
        R1 = 0;
        R2 = 0;
        R3 = 0;
        R4 = 47;
        R5 = 560;
        % Potentiometers
        P = 1e3;
        % Calculation Substitutions
        G1 = 0;
        G2 = 0;
        G3 = 0;
        G4 = 0;
        G5 = 0;
        G6 = 0;
        J1 = 0;
        J2 = 0;
        J3 = 0;
        % States
        x1 = [0 0];
        x2 = [0 0];
        x3 = [0 0];
        % Coefficients
        b1 = 0;
        b2 = 0;
        b3 = 0;
    end
    
    methods
        % Constructor
        function o = EarthWorm_OPA_Gain()
            o.rails = OPA_Rails;
            o.slewRate = OPA_SlewRate;
            o.gainBandwidth = OPA_GBP;
        end
        
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
        % Node Calculations
        Va = x/o.G5 + o.x2(c)/o.G3; % Voltage at Node A
        Vb = x/o.G6 + o.x3(c)/o.G4; % Voltage at Node B
        % Transfer Function
        Vo = x*o.b1 - Va/o.b2 - Vb/o.b3 - o.x1(c)/o.G1; % Voltage Out
        % Non-Ideal Characteristics
        gbpOut = o.gainBandwidth.processSample(Vo,c);
        slewOut = o.slewRate.processSample(gbpOut,c);
        y = o.rails.processSample(slewOut);
        % State Update
        o.x1(c) = o.J1*(x - y) - o.x1(c);
        o.x2(c) = o.J2*Va - o.x2(c);
        o.x3(c) = o.J3*Vb - o.x3(c);
        end

        function PrepareToPlay(o,Fs)
            Ts = 1/Fs;
            o.slewRate.PrepareToPlay(Fs);
            o.gainBandwidth.PrepareToPlay(Fs);
            % Discrete Kirchhoff Substitution
            o.R1 = Ts/(2*o.C1);
            o.R2 = Ts/(2*o.C2);
            o.R3 = Ts/(2*o.C3);
            % Optimizing Substitutions
            o.G1 = 1/o.P + 1/o.R1;
            o.G2 = o.G1 + 1/o.R4 + 1/o.R5;
            o.G3 = 1/o.R2 + 1/o.R4;
            o.G4 = 1/o.R3 + 1/o.R5;
            o.G5 = o.R4 * o.G3;
            o.G6 = o.R5 * o.G4;
            o.J1 = 2/o.R1;
            o.J2 = 2/o.R2;
            o.J3 = 2/o.R3;
            % Coefficients
            o.b1 = o.G2/o.G1;
            o.b2 = o.R4 * o.G1;
            o.b3 = o.R5 * o.G1;
        end

        % Set Parameters
        function setDistortionPot(o,distortionPotValue)
            o.P = distortionPotValue;
            o.gainBandwidth.setFrequencyPot(distortionPotValue);
            % Substitutions
            o.G1 = 1/o.P + 1/o.R1;
            o.G2 = o.G1 + 1/o.R4 + 1/o.R5;
            % Coefficients
            o.b1 = o.G2/o.G1;
            o.b2 = o.R4 * o.G1;
            o.b3 = o.R5 * o.G1;
        end

        function selectOPA(o,opaChoice)
            o.slewRate.selectOPA(opaChoice);
            o.gainBandwidth.selectOPA(opaChoice);
        end
    end
end