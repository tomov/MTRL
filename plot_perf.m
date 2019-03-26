function plot_perf(env, w_test, tot_r, model_names)

    figure;


    sem = @(x) std(x) / sqrt(length(x));

    % plot performance on test tasks, fig for each test task
    for t = 1:length(w_test)
        subplot(3, length(w_test), t);

        clear m;
        clear se;
        for i = 1:length(model_names)
            r = squeeze(tot_r(t, i, :));
            m(i) = mean(r);
            se(i) = sem(r);
        end

        hold on;
        bar([1:length(model_names)], m);
        errorbar([1:length(model_names)], m, se, 'color', [0 0 0], 'linestyle', 'none');
        xticks([1:length(model_names)]);
        xticklabels(model_names);
        ylabel('reward');
        title(sprintf('w = [%s]', sprintf('%.0f ', w_test{t})));
    end

    % plot performance on test tasks, fig for each algo
    labels = {};
    for t = 1:length(w_test)
        labels{t} = sprintf('w = [%s]', sprintf('%.0f ', w_test{t}));
    end
    for i = 1:length(model_names) 
        subplot(3, length(model_names), length(model_names) + i);

        clear m;
        clear se;
        for t = 1:length(w_test)
            r = squeeze(tot_r(t, i, :));
            m(t) = mean(r);
            se(t) = sem(r);
        end

        hold on;
        bar(m);
        errorbar(m, se, 'color', [0 0 0], 'linestyle', 'none');
        xticks(1:length(m));

        xticklabels(labels);
        xtickangle(40);
        ylabel('test reward');
        title(model_names{i});
        xlabel('test task');
    end

    % plot MDP as graph
    E = zeros(env.N, env.N);
    for s = 1:env.N
        for s_new = 1:env.N
            if sum(squeeze(env.T(s,:,s_new))) > 0
                E(s, s_new) = 1;
            end
        end
    end
    G = digraph(E);

    subplot(3, 1, 3);
    h = plot(G);
    for s = 1:env.N
        labelnode(h, s, sprintf('phi(%d) = [%s]', s, sprintf('%.0f ', env.phi{s} * 10)));
    end
    ylim([-0.5 4]);
    xlim([0.5 11]);
    set(gca, 'xtick', []);
    set(gca, 'ytick', []);
    title('MDP');
    xlabel('note: all features x 10 (for vizualization)');

