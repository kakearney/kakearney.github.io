% cptcmap post

%%

figure('position', [0 0 200 300], 'color', 'w')
ax = axes;
cptcmap('GMT_globe', 'mapping', 'direct');
cb1 = colorbar('location', 'west');
cb2 = cptcbar(ax, 'GMT_globe', 'east', false);

title(ax, 'Full range');
export_fig('cbar1', gcf, '-png', '-nocrop', '-r150');

title(ax, 'Zoomed in');
set([cb1 cb2.ax], 'ylim', [-800 800]);

export_fig('cbar2', gcf, '-png', '-nocrop', '-r150');

%%


figure('color', 'w');
[lat,lon,z] = satbath(10);
worldmap('World');
pcolorm(lat,lon,z);
cptcmap('GMT_globe', 'mapping', 'direct');

export_fig('cptres1', gcf, '-png', '-r150');

figure('color', 'w');
h = usamap('Florida');
[lat,lon,z] = satbath(1, getm(h, 'MapLatLim'), getm(h, 'MapLonLim'));
pcolorm(lat,lon,z);
cptcmap('GMT_globe', 'mapping', 'direct');

export_fig('cptres2', gcf, '-png', '-r150');

cptcmap('GMT_globe', 'mapping', 'direct', 'ncol', 2000);

export_fig('cptres3', gcf, '-png', '-r150');

%% Example one

% Create example image

hh.fig = figure('color', 'w');

% Display all the included colormaps

hh.pan1 = uipanel('Title', 'Example color palette tables', ...
                 'position', [.02 .5 .96 .48], ...
                 'backgroundcolor', 'w', ...
                 'fontsize', 10);
 

cptcmap('showall');
set(findall(gca, 'type', 'text'), 'fontsize', 8);
copyobj(gca, hh.pan1);
close(gcf);

% An example map

hh.pan2 = uipanel('Title', 'Bathymetry with GMT_relief', ...
                 'position', [.02 .02 .96 .46], ...
                 'backgroundcolor', 'w', ...
                 'fontsize', 10);
hh.ax = axes('parent', hh.pan2, 'fontsize', 8);
[lat, lon, z] = satbath(10);
pcolor(lon, lat, z);
shading flat;
cptcmap('GMT_relief', 'mapping', 'direct');
cb = colorbar;
cbtk = get(cb, 'ytick');
set(cb, 'yticklabel', num2str(cbtk', '%g'));

export_fig('cptcmapexample', hh.fig, '-png', '-r150');
% set(hh.fig, 'renderer', 'zbuffer')
% setpos(hh.fig, '# # 800px 600px')