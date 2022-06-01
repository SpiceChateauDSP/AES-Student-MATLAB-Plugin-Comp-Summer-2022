classdef OPA_SlewRate < handle
    properties (Access = public)
        OPA_type = 1;
    end

    properties (Access = private)
        Fs = 0;
        choice = 1;
        slope = 0;
        m = [0 0];
        % OPA Slew Rates
        LM308_slewRate = 0.2e6;
        LM741_slewRate = 0.5e6;
        JRC4558_slewRate = 1.7e6;
        TL072_slewRate = 20e6;
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
            delta = x - o.m(c);
            if delta > o.slope
                delta = o.slope;
            elseif delta < -o.slope
                delta = -o.slope;
            end
            y = o.m(c) + delta;
            % Update Memory
            o.m(c) = y;
        end

        function PrepareToPlay(o,Fs)
            o.Fs = Fs;
            switch(o.choice)
                case 1
                    o.slope = o.LM308_slewRate/o.Fs;
                case 2
                    o.slope = o.LM741_slewRate/o.Fs;
                case 3
                    o.slope = o.JRC4558_slewRate/o.Fs;
                case 4
                    o.slope = o.TL072_slewRate/o.Fs;
            end
        end

        function selectOPA(o,opaChoice)
            o.choice = opaChoice;
            switch(o.choice)
                case 1
                    o.slope = o.LM308_slewRate/o.Fs;
                case 2
                    o.slope = o.LM741_slewRate/o.Fs;
                case 3
                    o.slope = o.JRC4558_slewRate/o.Fs;
                case 4
                    o.slope = o.TL072_slewRate/o.Fs;
            end
        end
    end
end