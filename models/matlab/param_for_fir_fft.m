fs = 500;                % частота дискретизации
fc = 80;                 % частота среза
numtaps = 101;           % порядок фильтра
b = fir1(numtaps-1, fc/(fs/2), 'low', hamming(numtaps));