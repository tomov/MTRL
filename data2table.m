function tbl = data2table(data)

r = [];
s = [];
g = {};
len = [];
group = [];
dir = []; % direction = 2nd state on path
ord = []; % ordinal of trial type within ph (e.g. "first 1->6", "second 1->6", etc)
subj_group = [];
subj_len = [];
s_id = [];
trial = [];
c1 = [];
c2 = [];
phase = [];
for subj = 1:size(data,1) % for each subject
    for ph = 1:2
        for i = 1:length(data(subj, ph).s) % for each trial 
            which = find(data(subj, ph).s == data(subj, ph).s(i) & strcmp(data(subj, ph).g, data(subj, ph).g(i)));
            clear o;
            o(which) = find(which);
            ord = [ord; o(i)];
            r = [r; data(subj, ph).r(i)];
            s = [s; data(subj, ph).s(i)];
            g = [g; data(subj, ph).g(i)];
            len = [len; data(subj, ph).len(i)];
            c1 = [c1; data(subj, ph).path{i}(2)];
            c2 = [c2; data(subj, ph).path{i}(3)];
            group = [group; data(subj, ph).group(i)];
            s_id = [s_id; subj];
            trial = [trial; i];
            phase = [phase; ph];
        end
    end
    subj_group = [subj_group; data(subj,1).group(1)];
    subj_len = [subj_len; mean(data(subj, 1).len)];
end

tbl = table(trial, s_id, group, phase, r, s, g, c1, c2, ord);
