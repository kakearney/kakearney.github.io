%% Tampa Bay

% Read model and trophic groups from file

Tmp = load('~/Documents/Research/Working/foodWebDiagrams/foodwebpaper.mat', 'Tb'); 
Tb.EM = Tmp.Tb.EM;

[~,imax] = max(Tmp.Tb.tgmetric);
Tb.tg = Tmp.Tb.tg(:,imax);

clear Tmp;

% Sort trophic groups based on fraction of input originating from
% phytoplankton (vs benthic/detritus) 

detfrac = sourcefraction(Tb.EM.graph('oos', false, 'det', false), {'Phytoplankton'});

dfracavg = accumarray(Tb.tg, detfrac, [max(Tb.tg) 1], @mean);
[~,isrt] = sort(dfracavg);
[~, Tb.tgsorted] = ismember(Tb.tg, isrt);

% Initial graph (for layout tool)

Tb.Ginit = Tb.EM.graph('oos', false);
fwgraph2json(Tb.Ginit, Tb.tgsorted, fullfile('jsonfiles', 'tb_init.json'));

% Layout for slide

[Tb.Gpos, Tb.Ax, Tb.P] = foodweblayout(Tb.Ginit, Tb.tgsorted);
fwgraph2json(Tb.Gpos, Tb.tgsorted, fullfile('jsonfiles', 'tb_positioned.json'));

% Bundle

wlim = minmax(log10(Tb.Gpos.Edges.Weight), 'expand', 0.01);
wtfun = @(x) log10(x) - wlim(1);
Tb.Gbdl = debundle(Tb.Gpos, 'edgefun', wtfun, 'l', 100);

fwgraph2json(Tb.Gbdl, Tb.tgsorted, fullfile('jsonfiles', 'tb_bundled.json'));

save tbgraphdata -struct Tb;


%% Albatross Bay

% Read model and trophic groups from file

Tmp = load('~/Documents/Research/Working/foodWebDiagrams/foodwebpaper.mat', 'Alb'); 
Alb.EM = Tmp.Alb.EM;

[~,imax] = max(Tmp.Alb.tgmetric);
Alb.tg = Tmp.Alb.tg(:,imax);

clear Tmp;

isdem = strcmp('DetachedEstuarineMacrophytesestuarine', Alb.EM.name);
Alb.EM.name{isdem} = 'DetachedEstuarineMacrophytes';

% Sort trophic groups based on fraction coming from estuarine vs marine

src = {'DetachedEstuarineMacrophytes', ...
    'EstuarineWatercolumnDetritus', ...
    'EstuarineSedimentDetritus'};

efrac = sourcefraction(Alb.EM.graph('oos', false, 'det', false), src);

efracavg = accumarray(Alb.tg, efrac, [max(Alb.tg) 1], @mean);
[~,isrt] = sort(efracavg);
[~, Alb.tgsorted] = ismember(Alb.tg, isrt);

% Initial graph (for layout tool)
% Won't use flow to detritus here, but will add later

Alb.Ginit = Alb.EM.graph('oos', false, 'det', false);

% Add color to highlight banana prawns

isbp = strcmp(Alb.Ginit.Nodes.Name, 'BananaPrawnAdult');
isprey = ismember(Alb.Ginit.Nodes.Name, predecessors(Alb.Ginit, 'BananaPrawnAdult'));
ispred = ismember(Alb.Ginit.Nodes.Name, successors(Alb.Ginit, 'BananaPrawnAdult'));
cval = zeros(numnodes(Alb.Ginit),1);
cval(isbp) = 1;
cval(isprey) = 0.25;
cval(ispred) = 0.5;

Alb.Ginit.Nodes.cval = cval;

fwgraph2json(Alb.Ginit, Alb.tgsorted, fullfile('jsonfiles', 'albatross_init.json'));

% Relive some crowding at the TL = 1 level

Alb.Ginit.Nodes.TL(Alb.Ginit.Nodes.type == 1) = 1.2; 
Alb.Ginit.Nodes.TL(Alb.Ginit.Nodes.type == 2) = 0.8;

% Layout for slide

[Alb.Gpos, Alb.Ax, Alb.P] = foodweblayout(Alb.Ginit, Alb.tgsorted);
fwgraph2json(Alb.Gpos, Alb.tgsorted, fullfile('jsonfiles', 'albatross_positioned.json'));

% Bundle: add back in the detrital flow links

Alb.Gposdet = Alb.EM.graph('oos', false, 'det', true);
Alb.Gposdet.Nodes = Alb.Gpos.Nodes;

wlim = minmax(log10(Alb.Gposdet.Edges.Weight), 'expand', 0.01);
wtfun = @(x) log10(x) - wlim(1);
Alb.Gbdl = debundle(Alb.Gposdet, 'edgefun', wtfun, 'l', 100);

% Change colors to reflect original EwE colors

Alb.Gbdl.Nodes.cval(1:Alb.EM.ngroup) = (1:Alb.EM.ngroup)';
Alb.Gbdl.Nodes.cval(Alb.Gbdl.Nodes.type == 3) = Alb.EM.ngroup + 1;

fwgraph2json(Alb.Gbdl, Alb.tgsorted, fullfile('jsonfiles', 'albatross_bundled.json'));

[~,EpData] = mdb2ecopathmodel('~/Documents/Research/Working/EcopathModels/Albatross Bay 3.ewemdb');
col = EpData.EcopathGroup.PoolColor;
col = cellfun(@(x) ['#' x(3:end)], col, 'uni', 0);
col = [col; rgb2hex(rgb('gray'))];

domainstr = sprintf('%d,', 1:length(col));
rangestr = sprintf('"%s",', col{:});

save albgraphdata -struct Alb;

%% Bering Sea

% Read model and trophic groups from file

Tmp = load('~/Documents/Research/Working/foodWebDiagrams/foodwebpaper.mat', 'A'); 
Ber.EM = Tmp.A(1).EM;

[~,imax] = max(Tmp.A(1).tgmetric);
Ber.tg = Tmp.A(1).tg(:,imax);

clear Tmp;

% Sort trophic groups based on fraction coming from benthos

src = {'BenthicDetritus', 'Macroalgae'};

dfrac = sourcefraction(Ber.EM.graph('oos', false, 'det', false), src);

dfracavg = accumarray(Ber.tg, dfrac, [max(Ber.tg) 1], @mean);
[~,isrt] = sort(dfracavg);
[~, Ber.tgsorted] = ismember(Ber.tg, isrt);

% Initial graph (for layout tool)

Ber.Ginit = Ber.EM.graph('oos', false, 'det', false);

% Add color to from benthic vs pelagic calculation

Ber.Ginit.Nodes.cval = dfrac;

fwgraph2json(Ber.Ginit, Ber.tgsorted, fullfile('jsonfiles', 'bering_init.json'));

% Layout for slide

[Ber.Gpos, Ber.Ax, Ber.P] = foodweblayout(Ber.Ginit, Ber.tgsorted);
fwgraph2json(Ber.Gpos, Ber.tgsorted, fullfile('jsonfiles', 'bering_positioned.json'));

% Bundle

wlim = minmax(log10(Ber.Gpos.Edges.Weight), 'expand', 0.01);
wtfun = @(x) log10(x) - wlim(1);
Ber.Gbdl = debundle(Ber.Gpos, 'edgefun', wtfun, 'l', 100);

fwgraph2json(Ber.Gbdl, Ber.tgsorted, fullfile('jsonfiles', 'bering_bundled.json'));

save bergraphdata -struct Ber;
