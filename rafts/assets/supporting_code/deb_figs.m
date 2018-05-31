

file = '/Users/kakearney/Documents/Research/Working/EcopathModels/d3/DividedEdgeBundling/examples/3-3.graphml';

G33data = parseXML(file);
isg = strcmp({G33data.Children.Name}, 'graph');
isn = strcmp({G33data.Children(isg).Children.Name}, 'node');
ise = strcmp({G33data.Children(isg).Children.Name}, 'edge');

x = arrayfun(@(X) str2num(X.Children(2).Children.Data), G33data.Children(isg).Children(isn));
y = arrayfun(@(X) str2num(X.Children(4).Children.Data), G33data.Children(isg).Children(isn));
id = arrayfun(@(X) X.Attributes(1).Value, G33data.Children(isg).Children(isn), 'uni', 0);

src = arrayfun(@(X) X.Attributes(2).Value, G33data.Children(isg).Children(ise), 'uni', 0);
tar = arrayfun(@(X) X.Attributes(3).Value, G33data.Children(isg).Children(ise), 'uni', 0);

%%

N = table(x',y',id', 'variablenames', {'x','y','id'});
E = table(src', tar', 'variablenames', {'src', 'tar'});

[~, sidx] = ismember(E.src, N.id);
[~, tidx] = ismember(E.tar, N.id);

nnode = length(N.x);
nedge = length(E.src);
adj = sparse(sidx, tidx, ones(nedge,1), nnode, nnode);
adj = full(adj);

G = digraph(adj, id);
G.Nodes.x = x(:);
G.Nodes.y = y(:);

figure('color', 'none');
h = plot(G, 'XData', G.Nodes.x, 'YData', G.Nodes.y, ...
    'NodeColor', 'r', 'MarkerSize', 8);
axis equal;

export_fig('deb1', gcf, '-png', '-r150', '-nocrop');

set(h, 'LineStyle', 'none');
he = plotdeb(G, 'initial', true);
hcb = colorbar('south');

export_fig('deb2', gcf, '-png', '-r150', '-nocrop');

delete(he);
G.Edges.Weight(9) = 2;
he = plotdeb(G, 'initial', true);

export_fig('deb2b', gcf, '-png', '-r150', '-nocrop');

%%

G = debundle(G, 'l', 50);

delete(he);
he2 = plotdeb(G);

export_fig('deb3', gcf, '-png', '-r150', '-nocrop');

%% 


