function timeCursor(cursorOn, fig)
% timeCursor(true, ax(1), ax(2))  sets timecursor for axes in arguments
% 2...n

    if ~exist('cursorOn', 'var')
        cursorOn = true;
    end
    
    if ~exist('fig', 'var')
        fig = gcf;
    end
    
    dcm_obj = datacursormode(fig);
    set(dcm_obj, 'DisplayStyle', 'window');
    set(dcm_obj, 'Updatefcn', @psDataCursorCallback);
    
    if cursorOn
        set(dcm_obj, 'Enable', 'on');        
    else
        set(dcm_obj, 'Enable', 'off');
    end
    
    h = zoom(fig);
    set(h, 'rightclickaction', 'inversezoom')    
    set(h, 'ActionPostCallback', @psPostZoom);

    function psPostZoom(obh, event_obj)
        for m = 1:length(fig.Children)
            if isa(fig.Children(m), 'matlab.graphics.axis.Axes')
                datetick(fig.Children(m), 'keeplimits');
            end
        end
    end
        

    function output_txt = psDataCursorCallback(obj, event_obj)
        
        pos = get(event_obj, 'Position');
        indx = get(event_obj, 'DataIndex');
        [daynum, dayname] = weekday(pos(1));
        
        ms = rem(pos(1), datenum(0,0,0,0,0,1)) / datenum(0,0,0,0,0,1);
        msStr = sprintf('%0.3f', ms);
        msStr = msStr(2:end);
        
        output_txt = {['Y: ', num2str(pos(2), 8)], ...
                      [dayname, ' ', datestr(pos(1), 13), msStr], ...
                      [datestr(pos(1),29)], ...
                      ['Indx: ', num2str(indx, 12)]};
        
        if length(pos) > 2
            output_txt(end+1) = ['Z: ' num2str(pos(3),8)];        
        end
    end
end