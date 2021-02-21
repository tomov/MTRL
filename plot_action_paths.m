function plot_action_paths(env, w_test, as, action_paths, model_names)

    % histogram of final test states
    %
    % plot performance on test tasks, fig for each algo
    task_names = {};
    for t = 1:length(w_test)
        task_names{t} = sprintf('w = [%s]', sprintf('%.0f ', w_test{t}));
    end

    figure('position', [500 500 1000 1000]);

    plot_idx = 0;
    for i = 1:length(model_names)

        for t = 1:length(w_test)
            
            cnt = [];
            for j = 1:length(action_paths)
                which = strcmp(squeeze(as(t, i, :)), action_paths{j});
                cnt(j) = sum(which);
            end

            plot_idx = plot_idx + 1;
            subplot(length(model_names), length(w_test), plot_idx);

            bar(cnt);

            title(task_names{t});
            set(gca, 'xtick', 1:length(action_paths), 'xticklabel', action_paths);
            %xticklabels(action_paths);
            xtickangle(40);
            xlabel('action sequence');
            if t == 1
                ylabel(model_names{i});
            end
        end
    end
