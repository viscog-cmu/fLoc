% Provides x,y size in pixels to produce a given size in visual angle. 
% If the screen and distance parameters are undefined, we use the CBU
% scanner settings (see 
% http://imaging.mrc-cbu.cam.ac.uk/mri/CbuStimulusDelivery). If using default
% CBU scanner parameters, the sizey input is also optional.
% use: [sizex,sizey] = visangle2stimsize(visanglex,[visangley],[totdistmm],[screenwidthmm],[screenres])
% 25/9/2009 J Carlin

function size_pix = deg2pix(size_deg,viewdist_mm,screenwidth_mm,screenwidth_pix)

if nargin < 3
	% mm
% 	distscreenmirror=823;
% 	distmirroreyes=90;
% 	viewdist_mm=distscreenmirror+distmirroreyes;
% 	screenwidth_mm=268;
    viewdist_mm=1000;
    screenwidth_mm = 370;

	% pixels
	screenwidth_pix=1024;
end

visang_rad = 2 * atan(screenwidth_mm/2/viewdist_mm);
visang_deg = visang_rad * (180/pi);

pix_pervisang = screenwidth_pix / visang_deg;

size_pix = round(size_deg * pix_pervisang);

end
