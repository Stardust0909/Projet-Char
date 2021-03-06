% Camera - Mesure de position d'objets
%--------------------------------------
%
% version � traduire en C++ pour �tre directement plac�e sur la raspberry
%
%      Cam�ra sur Rasberry pi                            PC                
%  ������������������������������        ����������������������������������
%  Prend les images en continu    <---   Fournit nom de fichier contenant                               
%  Utilise zones pour d�terminer          zones et couleurs pour d�tection d'objets (une zone par objet)
%   centroides d'objets                  ______                                                         
%  Renvoie chaque fois im.ir      --->  |pix2yz| �quation du plan du terrain + hauteur de centroide  \
%                        .ic             ��T���  |                                                    |
%                                        __V_____V_                                                   | 
%                                       |xfyz2objco|                                                  |          _________
%                                        �����T����positions xyz des centroides                        >   <=>  |pix2objro|
%                                           __V__   dans le rep�re cam�ra                             |          ���������
%                                          |co2ro|                                                    |
%                                           ��|��                                                     |
%                                             V  coordonn�es des centroides dans le rep�re robot     /

% Attention! Il faut peut-�tre un effet miroir sur les ir !

% Il faut fournir
im.ic; % Centroide sur l'image
im.ir;
H; % Hauteur suppos�e du centroide de l'objet (coord Z dans le rep�re du robot)

% et fournir �galement les param�tres d�duits de l'�talonnage
ABC; % vecteur perpendiculaire au plan horizontal dans le rep�re cam�ra
cam;

%                 ______
%% [imyz, sens] = pix2yz(im, 'picam_384x256')
%                 ������
sens = struct('W', 1.4e-3*6.7500, 'H', 1.4e-3*7.5938, 'F', 3.6, 'k2', 0e-3, 'cmax', 384, 'rmax', 256, 'dc0', 0, 'dr0', 0);
% Points cibles en tenant compte des dimensions des pixels et de la distortion
C = (im.ic-double(sens.cmax)/2-sens.dc0)*sens.W + j*(im.ir-double(sens.rmax)/2-sens.dr0)*sens.H;
C = abs(C) .* (1 + sens.k2 * abs(C)) .* exp(j*angle(C));
yz = -C; % Sur capteur, comme sur image o� positif � gauche (suivant axe Y) et au-dessus (suivant axe Z) de l'image
imyz.y = real(yz);
imyz.z = imag(yz);

%          __________
%% objco = xfyz2objco(sens.F, imyz, ABC);
%          ����������
y = imyz.y;
z = imyz.z;
[r, c] = size(y);
x = xf * ones(r, c); % xf doit �tre positif
k = -1 ./ (ABC(1)*x + ABC(2)*y + ABC(3)*z); % Plan  k*(A*x + B*y + C*z) + 1 = 0
objco.x = k .* x;
objco.y = k .* y;
objco.z = k .* z;

%          _____
%% objro = co2ro(objco, cam); % Position de l'objet dans le rep�re du robot
%          �����
% Il faudrait veiller � ce que objco.x, .y, .z  soit une matrice de bonne dimension
%   alors seule est n�cessaire la ligne
%       xyzw = cam.hommatall * [objco.x; objco.y; objco.z; ones(1,r*c)];
[r,c] = size(objco.x);
if length(objco.y)>1
   [r,c] = size(objco.y);
elseif length(objco.z)>1
   [r,c] = size(objco.z);
end
if max(r,c)>1
   if length(objco.x)==1
      objco.x = objco.x * ones(r,c);
   end
   if length(objco.y)==1
      objco.y = objco.y * ones(r,c);
   end
   if length(objco.z)==1
      objco.z = objco.z * ones(r,c);
   end
end
if r>1
   objco.x = reshape(objco.x, 1, r*c);
   objco.y = reshape(objco.y, 1, r*c);
   objco.z = reshape(objco.z, 1, r*c);
end
xyzw = cam.hommatall * [objco.x; objco.y; objco.z; ones(1,r*c)];
objro.x = reshape(xyzw(1,:), r, c);
objro.y = reshape(xyzw(2,:), r, c);
objro.z = reshape(xyzw(3,:), r, c);
