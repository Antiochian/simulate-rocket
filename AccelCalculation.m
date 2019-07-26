function [ OUT ] = AccelCalculation( posRocketNOW , posMoonNOW, args )
%calculate the acceleration of a body in the Moon/Earth system given its position
%optional ability to specify moving Earth/Moon positions, but system
%defaults to static Earth + Moon at original positions
%by HEIRON, 2k18, cDc Production

%% - Detect ONLY RELEVANT args
marssystem = 0;
if nargin == 3 %if at least one optional arguments is passed
        if strfind(args, 'P')>0
            marssystem = 1;
        end
        if strfind(args, 'm')>0
            marssystem = 1;
        end
else
end
%% - Optional Args / set constants
G = 9.63E-7;
posEarth = [0 0 0];
if marssystem ==1;
        mM = 1.45178E-7; %NOTE: "mM" is PHOBOS mass, NOT MARS
        mE = 8.74026;
    else %Earth/Moon values
        mM = 1;
        mE = 83.3;
end
%%

%actual computation
rE= norm(posEarth(1:2) - posRocketNOW(1:2));
rM = norm(posMoonNOW(1:2) - posRocketNOW(1:2));

accelX = -rE^(-3)*G*mE*(posRocketNOW(1)- posEarth(1)) - rM^(-3)*G*mM*(posRocketNOW(1)- posMoonNOW(1));
accelY = -rE^(-3)*G*mE*(posRocketNOW(2) - posEarth(2)) - rM^(-3)*G*mM*(posRocketNOW(2) - posMoonNOW(2));
OUT = [accelX accelY];
end