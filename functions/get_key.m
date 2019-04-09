function get_key(key, laptop_key)
% Waits until user presses the key specified in first argument.
% Written by KGS Lab
% Edited by AS 8/2014

laptop_key = [];

while 1
    while 1
        [key_is_down, ~, key_code] = KbCheck(laptop_key);
        if key_is_down
            break
        end
    end
    pressed_key = KbName(key_code);
    if any(ismember(key, pressed_key))
        break
    end
end

end
