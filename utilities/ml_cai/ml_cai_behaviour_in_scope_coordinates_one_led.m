function [scopeLedPos1, scopePos] = ml_cai_behaviour_in_scope_coordinates_one_led(scopeTime, behavTime, behavPosLed1)

pos = 1.0*(behavPosLed1);

% Interpolation of behaviour from behavTime to scopeTime
extendLeft = find(scopeTime < behavTime(1));
extendRight = find(scopeTime > behavTime(end));
NL = length(extendLeft);
NU = length(extendRight);
NM = length(behavTime);
N = NL + NM + NU;
X = zeros(N,1);
P_i = zeros(N,1);
P_j = zeros(N,1);
LP1_i = zeros(N,1);
LP1_j = zeros(N,1);
for i = 1:NL
    X(i) = scopeTime(extendLeft(i));
    P_i(i) = pos(1,1);
    P_j(i) = pos(1,2);
    
    LP1_i(i) = behavPosLed1(1,1);
    LP1_j(i) = behavPosLed1(1,2);
end

for i = 1:NM
    X(i+NL) = behavTime(i);
    P_i(i+NL) = pos(i,1);
    P_j(i+NL) = pos(i,2);
    
    LP1_i(i+NL) = behavPosLed1(i,1);
    LP1_j(i+NL) = behavPosLed1(i,2);
end

for i = 1:NU
    X(i+NL+NM) = scopeTime(extendRight(i));
    P_i(i+NL+NM) = pos(end,1);
    P_j(i+NL+NM) = pos(end,2);
    
    LP1_i(i+NL+NM) = behavPosLed1(end,1);
    LP1_j(i+NL+NM) = behavPosLed1(end,2);
end

interpKind = 'cubic';

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

end % function
