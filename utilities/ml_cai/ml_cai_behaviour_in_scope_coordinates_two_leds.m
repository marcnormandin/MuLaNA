function [scopeLedPos1, scopeLedPos2, scopePos, scopeLookRad, scopeLookRadOther] = ml_cai_behaviour_in_scope_coordinates_two_leds(scopeTime, behavTime, behavPosLed1, behavPosLed2)


pos = 0.5*(behavPosLed1 + behavPosLed2);

a = atan2(behavPosLed2(:,1)-behavPosLed1(:,1), behavPosLed2(:,2)-behavPosLed1(:,2));
b = find(a < 0);
a(b) = a(b) + 2*pi;
behavLookRad = a;
%behavLookDeg = rad2deg( behavLookRad );

% Interpolation of behaviour from behavTime to scopeTime
uxq = unwrap(behavLookRad, 0);
extendLeft = find(scopeTime < behavTime(1));
extendRight = find(scopeTime > behavTime(end));
NL = length(extendLeft);
NU = length(extendRight);
NM = length(behavTime);
N = NL + NM + NU;
X = zeros(N,1);
Y = zeros(N,1);
P_i = zeros(N,1);
P_j = zeros(N,1);
LP1_i = zeros(N,1);
LP1_j = zeros(N,1);
LP2_i = zeros(N,1);
LP2_j = zeros(N,1);
for i = 1:NL
    X(i) = scopeTime(extendLeft(i));
    Y(i) = uxq(1);
    P_i(i) = pos(1,1);
    P_j(i) = pos(1,2);
    
    LP1_i(i) = behavPosLed1(1,1);
    LP1_j(i) = behavPosLed1(1,2);
    
    LP2_i(i) = behavPosLed2(1,1);
    LP2_j(i) = behavPosLed2(1,2);
end

for i = 1:NM
    X(i+NL) = behavTime(i);
    Y(i+NL) = uxq(i);
    P_i(i+NL) = pos(i,1);
    P_j(i+NL) = pos(i,2);
    
    LP1_i(i+NL) = behavPosLed1(i,1);
    LP1_j(i+NL) = behavPosLed1(i,2);
    
    LP2_i(i+NL) = behavPosLed2(i,1);
    LP2_j(i+NL) = behavPosLed2(i,2);
end

for i = 1:NU
    X(i+NL+NM) = scopeTime(extendRight(i));
    Y(i+NL+NM) = uxq(end);
    P_i(i+NL+NM) = pos(end,1);
    P_j(i+NL+NM) = pos(end,2);
    
    LP1_i(i+NL+NM) = behavPosLed1(end,1);
    LP1_j(i+NL+NM) = behavPosLed1(end,2);
    
    LP2_i(i+NL+NM) = behavPosLed2(end,1);
    LP2_j(i+NL+NM) = behavPosLed2(end,2);
end

interpKind = 'cubic';
uy = interp1(X,Y,scopeTime, interpKind); % angle

scope_pos_i = interp1(X, P_i, scopeTime, interpKind );
scope_pos_j = interp1(X, P_j, scopeTime, interpKind );
scopePos = zeros(size(scope_pos_i,1), 2);
scopePos(:,1) = scope_pos_i;
scopePos(:,2) = scope_pos_j;

scope_led_pos_1_i = interp1(X, LP1_i, scopeTime, interpKind );
scope_led_pos_1_j = interp1(X, LP1_j, scopeTime, interpKind );
scopeLedPos1 = zeros(size(scope_led_pos_1_i,1), 2);
scopeLedPos1(:,1) = scope_led_pos_1_i;
scopeLedPos1(:,2) = scope_led_pos_1_j;

scope_led_pos_2_i = interp1(X, LP2_i, scopeTime, interpKind );
scope_led_pos_2_j = interp1(X, LP2_j, scopeTime, interpKind );
scopeLedPos2 = zeros(size(scope_led_pos_2_i,1), 2);
scopeLedPos2(:,1) = scope_led_pos_2_i;
scopeLedPos2(:,2) = scope_led_pos_2_j;

scopeLookRad = mod((uy + 2*pi), 2*pi);
%scopeLookDeg = rad2deg(scopeLookRad);

% Alternative to see if the angles are similar since we will need to
% eventually map using a homographic transformation
aa = atan2(scopeLedPos2(:,1)-scopeLedPos1(:,1), scopeLedPos2(:,2)-scopeLedPos1(:,2));
bb = find(aa < 0);
aa(bb) = aa(bb) + 2*pi;
scopeLookRadOther = aa;

end % function
