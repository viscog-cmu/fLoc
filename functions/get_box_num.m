function b = get_box_num
% Checks connected USB devices and returns the device number corresponding
% to the scanner button box (box_id should be set the the productID of
% the button box used locally).
% Written by KGS Lab
% Edited by AS 8/2014

% change to productID number of local button box
box_id = 8; b = 0; d = PsychHID('Devices');
for nn = 1:length(d)
    %scanner box does not report as 'Keyboard'
%     if (d(nn).productID == box_id) && (strcmp(d(nn).usageName, 'Keyboard')) 
    if (d(nn).productID == box_id)
        b = nn;
    end
end
b = -2;
if b == 0
    fprintf('\nButton box not found.\n');
end

end
