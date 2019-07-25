% Quick convenience function to convert stimulus size in pixels to degrees
% visual angle. If the screen and distance parameters are undefined, we use
% the CBU scanner settings (see 
% http://imaging.mrc-cbu.cam.ac.uk/mri/CbuStimulusDelivery). If using default
% CBU scanner parameters, the sizey input is also optional.
% use: [visanglex,visangley] = stimsize2visangle(sizex,[sizey],[totdistmm],[screenwidthmm],[screenres])
% 25/9/2009 J Carlin

function size_deg = pix2deg(size_pix,view_dist_mm,screenwidth_mm,screenres)

if nargin < 2
	% mm
	distscreenmirror=823;
	distmirroreyes=90;
	view_dist_mm=distscreenmirror+distmirroreyes;
	screenwidth_mm=268;

	% pixels
	screenres=1024;
end

visang_rad = 2 * atan(screenwidth_mm/2/view_dist_mm);
visang_deg = visang_rad * (180/pi);

visang_perpix = visang_deg / screenres;

size_deg = size_pix * visang_perpix;

end
