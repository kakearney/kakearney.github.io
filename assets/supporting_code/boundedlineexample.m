% boundedlineexample.m

count = load('count.dat');

x = (1:size(count,1))';
y = mean(count,2);
e = std(count,1,2);


errorbar(x,y,e,'rx');

set(gca, 'box', 'off', 'color', 'none');
set(gcf, 'color', 'none');
export_fig(gcf, 'boundedline1', '-png', '-r150');


%%

close all

lo = y - e;
hi = y + e;

hp = patch([x; x(end:-1:1); x(1)], [lo; hi(end:-1:1); lo(1)], 'r');
hold on;
hl = line(x,y);

set(hp, 'facecolor', [1 0.8 0.8], 'edgecolor', 'none');
set(hl, 'color', 'r', 'marker', 'x');

set(gca, 'box', 'off', 'color', 'none');
set(gcf, 'color', 'none');
export_fig(gcf, 'boundedline2', '-png', '-r150');


%%

close all

[hl,hp] = boundedline(x,y,e, '-rx')

set(gca, 'box', 'off', 'color', 'none');
set(gcf, 'color', 'none');
export_fig(gcf, 'boundedline3', '-png', '-r150');

%%

% x = linspace(0,2*pi,100);
% y = [sin(x); cos(x); 5*sin(x); 4*cos(x)];
% e = rand(100,2,4)*0.2+1;
% 
% % Gaps
% 
% y(1,[1 10 20 end]) = NaN;
% y(2,25:30) = NaN;
% e(35,1,3) = NaN;
% 
% e(40:45,1:2,4) = 0;
% e(46:50,1:2,4) = NaN;
% e(end-5:end,2,4) = NaN;
% e(1:5,1:2,4) = NaN;
% 
% h = plotgrid('setup', cell(3,2));
% 
% orient = {'vert', 'horiz'};
% nanflag = {'gap', 'fill', 'remove'};
% 
% for io = 1:2
%     for in = 1:3
%         axes(h.ax(in,io));
%         if io == 1
%             [hl, hp] = boundedline(x,y,e, 'alpha', 'nan', nanflag{in}, 'orientation', orient{io});
%         else
%             [hl, hp] = boundedline(y,x,e, 'alpha', 'nan', nanflag{in}, 'orientation', orient{io});
%         end
%         set(hl, 'marker', '.');
%         htmp = outlinebounds(hl(4), hp(4));
%         set(hl(4), 'linestyle', ':', 'marker', 'none');
%     end
% end
% set(h.ax(:,1), 'xlim', [0 2*pi]);
% set(h.ax(:,2), 'ylim', [0 2*pi]);

%% Line gap example

x = linspace(0,2*pi,100);
y = [sin(x); cos(x); 5*sin(x); 4*cos(x)];
e = rand(100,2,4);

y(randperm(numel(y),5)) = NaN;
y(randperm(numel(y),5)) = Inf;

plot(x,y);

set(gca, 'box', 'off', 'color', 'none');
set(gcf, 'color', 'none');
export_fig(gcf, 'boundedline4', '-png', '-r150');

%% A single line with all the types of gaps

clear all
close all

x = linspace(0, 2*pi, 100);
y = sin(x);
e = rand(100,2)*0.2+1;
e(60:65,:) = 0;

ln = [5 12 25:30];
lo = [35 50:55 66:70 95:100];
hi = [40 50:55 66:70];

y(ln) = NaN;
e(lo,1) = NaN;
e(hi,2) = NaN;


nanflag = {'gap', 'fill', 'remove'};
for ii = 1:length(nanflag)
    ax(ii) = subplot(3,1,ii);
    [hl(ii), hp(ii)] = boundedline(x,y,e, 'nan', nanflag{ii});
end
ho = outlinebounds(hl, hp);
set(hl, 'linestyle', ':');

multitextloc(ax, nanflag, 'southwest');

hold(ax(1), 'on');

hm(1) = plot(ax(1), x(ln), ones(size(ln))*4, 'kx');
hm(2) = plot(ax(1), x(lo), ones(size(lo))*5, 'kv');
hm(3) = plot(ax(1), x(hi), ones(size(hi))*6, 'k^');

set(ax, 'ylim', [-1 1]*4);
set(hm, 'clipping', 'off');

legendflex(hm, {'NaN in line', 'NaN in lower bound', 'NaN in upper bound'}, ...
    'ref', gcf, 'anchor', {'s','s'}, 'buffer', [0 0], 'box', 'off', ...
    'nrow', 1, 'xscale', 0.5);

set(gcf, 'color', 'none');
export_fig(gcf, 'boundedline5', '-png', '-r150');


%%


x = rand(100,1) * 10;
y = x.^2 + 5*rand(size(x));

p = polyfit(x,y,2);


% legend([hl,hp], 'line', 'patch');

hg = hggroup;
set([hp,hl], 'parent', hg);
