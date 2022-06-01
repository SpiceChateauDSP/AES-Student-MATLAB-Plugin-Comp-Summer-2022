classdef EarthWorm_OPA_Effect < handle
    properties(Access = private)
        % Objects
        inputStage;
        gainStage;
        clipStage;
        filterStage;
        outputStage;
        hpf;
        % Resampling
        RS = 16; % Oversampling multiplier
        a = 0;
        b = 0;
        Z = zeros(4,2);
        Z2 = zeros(4,2);
        % Bypass
        bypass = false;
    end

    methods
        % Constructor
        function o = EarthWorm_OPA_Effect()
            o.inputStage = EarthWorm_OPA_Input;
            o.gainStage = EarthWorm_OPA_Gain;
            o.clipStage = EarthWorm_OPA_Clip;
            o.filterStage = EarthWorm_OPA_Filter;
            o.outputStage = EarthWorm_OPA_Output;
            o.hpf = BQHPF;
        end

        % Process
        function out = process(o,in)
            [N,C] = size(in);
            upBufferSize = N*o.RS;
            outUp = zeros(upBufferSize,C);
            % Upsample
            inUp = o.interpolate(in,C,upBufferSize);
            % Process Sample Loop
            for c = 1:C
                for n = 1:upBufferSize
                    outUp(n,c) = processSample(o,inUp(n,c),c);
                end
            end
            % Downsample
            out = o.decimate(outUp,C,upBufferSize,N);
        end

        % DSP
        function y = processSample(o,x,c)
            if (o.bypass == false)
                xIn = o.inputStage.processSample(x,c);
                xGain = o.gainStage.processSample(xIn,c);
                xClip = o.clipStage.processSample(xGain,c);
                xFilter = o.filterStage.processSample(xClip,c);
                xOut = o.outputStage.processSample(xFilter,c);
                y = o.hpf.processSample(xOut,c);
            else
                y = x;
            end
        end

        % Prepare To Play
        function PrepareToPlay(o,Fs)
            o.inputStage.PrepareToPlay(Fs*o.RS);
            o.gainStage.PrepareToPlay(Fs*o.RS);
            o.clipStage.PrepareToPlay(Fs*o.RS);
            o.filterStage.PrepareToPlay(Fs*o.RS);
            o.outputStage.PrepareToPlay(Fs*o.RS);
            o.hpf.setParams(Fs*o.RS,50,0.7071);
            o.setAntiAliasFilters(Fs);
        end
        
        % Resampling
        function setAntiAliasFilters(o,Fs)
            Nyq = Fs/2;
            Nyq2 = o.RS * Nyq;
            Wn = Nyq/Nyq2;
            [o.b,o.a] = ellip(4,3,96,0.0625);
        end

        function out = interpolate(o,in,C,upBufferSize)
            upBuffer = zeros(upBufferSize,C); % array for upsampled signal
            outFilt = zeros(upBufferSize,C);
            % Interpolate
            for c = 1:C
                for n = 0:o.RS:upBufferSize-1
                    upWrite = n+1; % Write pointer for upsampled buffer
                    bufferRead = (n/o.RS)+1; % Read pointer for input buffer
                    upBuffer(upWrite,c) = in(bufferRead,c);
                end
                % Apply IIR Anti-Aliasing Filter
                [outFilt(:,c),o.Z(:,c)] =...
                    filter(o.b,o.a,upBuffer(:,c),o.Z(:,c));
            end
            out = outFilt * o.RS;
        end

        function out = decimate(o,in,C,upBufferSize,N)
            inFilt = zeros(upBufferSize,C);
            out = zeros(N,C);
            % Decimate
            for c = 1:C
                % Apply IIR Anti-Aliasing Filter
                [inFilt(:,c),o.Z2(:,c)] =...
                    filter(o.b,o.a,in(:,c),o.Z2(:,c));
                for p = 0:N-1
                    bufferWrite = p+1;
                    upRead = (p*o.RS)+1; % Read Pointer for upsampled buffer
                    out(bufferWrite,c) = inFilt(upRead,c);
                end
            end
        end

        % Set Parameters
        function setDistortion(o,distortionNormalized)
            % Convert normalized value to potentiometer value
            distortionPotValue = distortionNormalized*99.8e3 + 1e3;
            o.gainStage.setDistortionPot(distortionPotValue);
        end

        function selectOPA(o,opaChoice)
            o.gainStage.selectOPA(opaChoice);
        end

        function setSupplyVoltage(o,voltageNormalized)
            supplyVoltage = (1 - voltageNormalized)*7.5 + 4.5;
            o.inputStage.setSupplyVoltage(supplyVoltage);
        end

        function setTone(o,toneNormalized)
            % Convert normalized value to potentiometer value
            tonePotValue = (1 - toneNormalized)*100e3;
            o.filterStage.setTonePot(tonePotValue);
        end

        function setVolume(o,volumeNormalized)
            % Convert normalized value to potentiometer value
            volumePotValue = volumeNormalized*99.8e3 + 100;
            o.outputStage.setVolumePot(volumePotValue);
        end

        function setBypass(o,bypass)
            o.bypass = bypass;
        end
    end
end