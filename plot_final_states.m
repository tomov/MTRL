function plot_final_states(env, w_test, term_s, model_names)

    % histogram of final test states
    %
    % plot performance on test tasks, fig for each algo
    task_names = {};
    for t = 1:length(w_test)
        task_names{t} = sprintf('w = [%s]', sprintf('%.0f ', w_test{t}));
    end

    figure;

    plot_idx = 0;
    for i = 1:length(model_names)

        for t = 1:length(w_test)
            
            cnt = [];
            for s = 5:13 % TODO hardcoded
                which = squeeze(term_s(t, i, :)) == s;
                cnt(s) = sum(which);
            end

            plot_idx = plot_idx + 1;
            subplot(4, length(w_test), plot_idx);

            bar(cnt);

            title(task_names{t});
            xticks(5:13);
            xlim([4.5 13.5]);
            xlabel('final state');
            if t == 1
                ylabel(model_names{i});
            end
        end
    end
