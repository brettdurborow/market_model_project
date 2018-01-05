function share = bassDiffusion(t, p, q, s0, s1, doPlot)
% s0 - (Scalar) Starting market share between 0 and 1
% s1 - (Scalar) Ending market share between 0 and 1
% p  - (Scalar) Coefficient of innovation
% q  - (Scalar) Coefficient of imitation
% t  - Vector positive values, representing integer + fractional years since "event"

% Example: 
% t = (1:5295) / 365.25;
% share = bassDiffusion(t, 0.22, 0.28, 0.5, 0.75, true);

    if ~exist('doPlot', 'var')
        doPlot = false;
    end
    if isnan(s0)
        s0 = 0;
    end
    if isnan(s1)
        s1 = 0;
    end

    y =(1-exp(-(p+q)*(t))) ./ (1+(q/p)*exp(-(p+q)*(t)));
    share = s0 + y * (s1 - s0);

    if doPlot
        figure; 
        plot(t, share); grid on; title('Market Share over time'); xlabel('time (Years)');
        ylim([0, 1]);
    end
    
end