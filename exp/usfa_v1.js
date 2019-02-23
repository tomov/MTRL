in_trial = false;

function initExp() {
    console.log("initExp");

    exp = readExp();
    exp = genExp(exp);

    subj_id = "1" + Math.random().toString().substring(3,8);
    file_name = 'results/' + subj_id + ".csv";

    stage = "train";
    trial_idx = -1;
    in_trial = false;

    RTs = [];
    keys = [];
    path = [];
    cur = -1;
    start = -1;
    goal = -1;

    $.post("results_data.php", {postresult: "group, subj_id, stage, start, goal, path, length, RTs, keys, RT_tot, timestamp, datetime\n", postfile: file_name })

    nextTrial();
}


// Read experiment template from textarea
// N
// l u r is_term
// ...
// name
// ...
// D
// feature name
// ...
// phi
// ...
// ntrain
// s -> w x reps
// ...
// ntest
// s -> w x reps
//
function readExp() {
    console.log("readExp");

    var exp = {};
    var lines = $("#experiment").val().split("\n");
    exp.N = parseInt(lines[0], 10);

    // read adjacency 
    exp.adj = [];
    exp.is_term = [];
    for (var i = 1; i <= exp.N; i++) {
        var a = lines[i].trim().split(" ");
        var b = [];
        for (var j = 0; j < 3; j++) {
            b.push(parseInt(a[j], 10));
        }
        exp.adj.push(b);
        exp.is_term.push(parseInt(a[3], 10));
    }
    l = exp.N + 1; // current line

    // read state names
    exp.names = [];
    for (var i = 0; i < exp.N; i++) {
        exp.names.push(lines[l].trim());
        l++;
    }

    // # of features
    exp.D = parseInt(lines[l], 10);
    l++;

    // read feature names
    exp.feature_names = [];
    for (var i = 0; i < exp.D; i++) {
        exp.feature_names.push(lines[l].trim());
        l++;
    }

    // read state features
    exp.phi = [];
    for (var i = 0; i < exp.N; i++) {
        var a = lines[l].trim().split(" ");
        l++;
        var b = [];
        for (var j = 0; j < exp.D; j++) {
            b.push(parseFloat(a[j]));
        }
        exp.phi.push(b);
    }

    // read training tasks
    exp.ntrain = parseInt(lines[l], 10);
    l++;
    exp.train = readTasks(lines, l, exp.ntrain);
    l += exp.ntrain;

    // read test tasks
    exp.ntest = parseInt(lines[l], 10);
    l++;
    exp.test = readTasks(lines, l, exp.ntest);
    l += exp.ntest;

    return exp;
}

function readTasks(lines, l, n) {
    var tasks = [];
    for (var i = 0; i < n; i++) {
        var a = "";
        var task = {};

        if (lines[l].includes("@")) {
            // e.g. 1 -> 2 @ 10 
            // means put this task on trial #10
            //
            a = lines[l].trim().split("@");

            task.n = 1;
            task.pos = parseInt(a[1], 10) - 1;

        } else {
            // e.g. 1 -> 2 @ 10
            // means repeat this task 10 times at random trials
            //
            a = lines[l].trim().split("x");

            task.n = parseInt(a[1], 10);
            task.pos = -1;
        }
        var b = a[0].trim().split("->");

        task.s = [];
        s = b[0].trim().split(" ");
        for (var j = 0; j < s.length; j++) {
            task.s.push(parseInt(s[j], 10));
        }

        task.w = [];
        w = b[1].trim().split(" ");
        for (var j = 0; j < w.length; j++) {
            task.w.push(parseFloat(w[j]));
        }

        tasks.push(task);
        l++;
    }
    return tasks;
}


function genExp(exp) {
    console.log("genExp");

    // shuffle state names for nonterminal states only
    var non_term_names = [];
    for (var i = 0; i < exp.N; i++) {
        if (!exp.is_term[i]) {
            non_term_names.push(exp.names[i]);
        }
    }
    //non_term_names = shuffle(non_term_names); TODO uncomm
    var j = 0;
    for (var i = 0; i < exp.N; i++) {
        if (!exp.is_term[i]) {
            exp.names[i] = non_term_names[j];
            j++;
        }
    }

    // generate training trials
    exp.train_trials = genTrials(exp.train);

    // generate test trials
    exp.test_trials = genTrials(exp.test);

    // randomly shuffle next states
    // TODO enable
    for (var i = 0; i < exp.N; i++) {
    //    exp.adj[i] = shuffle(exp.adj[i]);
    }

    // shuffle feature names
    // exp.feature_names = shuffle(exp.feature_names); TODO uncomm

    return exp;
}


function genTrial(desc, j) {
    var task = {};
    task.s = desc.s[Math.floor(Math.random() * desc.s.length)];
    task.w = desc.w;
    task.j = j;
    if (task.s <= 0) {
        task.s = Math.floor(Math.random() * exp.N) + 1;
    }
    return task;
}

function genTrials(desc) {
    trials = [];
    for (var i = 0; i < desc.length; i++) {
        for (var j = 0; j < desc[i].n; j++) {
            if (desc[i].pos != -1) {
                continue;
            }
            trials.push(genTrial(desc[i], j));
        }
    }
    trials = shuffle(trials);

    for (var i = 0; i < desc.length; i++) {
        if (desc[i].pos == -1) {
            continue;
        }
        trials.splice(desc[i].pos, 0, genTrial(desc[i], 1));
    }
    return trials;
}


// Fisher-Yates (aka Knuth) Shuffle, from 
// https://stackoverflow.com/questions/2450954/how-to-randomize-shuffle-a-javascript-array
//
function shuffle(array) {
  var currentIndex = array.length, temporaryValue, randomIndex;

  // While there remain elements to shuffle...
  while (0 !== currentIndex) {

    // Pick a remaining element...
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;

    // And swap it with the current element.
    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }

  return array;
}


function nextTrial() {
    console.log("nextTrial " + trial_idx);

    $("#trial_page").hide();
    $("#message").text("");
    in_trial = false;

    trial_idx++;
    if (stage == "train") {
        trials = exp.train_trials;
    } else {
        trials = exp.test_trials;
    }

    if (trial_idx >= trials.length) {
        if (stage == "train") {
            // kick off test phase
            stage = "test";
            trial_idx = -1;
            $("#test_page").show();
        } else {
            // fin
            $("#final_page").show();
        }
        return;
    }

    start = trials[trial_idx].s;
    cur = start;
    goal = trials[trial_idx].w;

    RT_tot = 0;
    RTs = [];
    keys = [];
    path = [cur];
    // TODO reward from exp_4

    redraw();
    $("#new_trial_page").show();

    // countdown
    sleep(2000).then(() => {
        $("#new_trial_page").hide();
        $("#trial_page").show();
        stateColor("white");
        in_trial = true;
        last_keypress_time = (new Date()).getTime();
    });
}


function stateColor(color) {
    $("#cur_state").css("color", color);
    $("#right_state").css("color", color);
    $("#up_state").css("color", color);
    $("#left_state").css("color", color);
    $("#down_state").css("color", color);
}


function checkKeyPressed(e) {
    var e = window.event || e;

    if (in_trial) {
        console.log("key press " + e.which);

        RT = (new Date()).getTime() - last_keypress_time;
        last_keypress_time = (new Date()).getTime();
        RTs.push(RT);
        keys.push((e).keyCode);
        RT_tot += RT;
        // TODO cum reward -- see exp_v4
        var next = -1;
        $("#message").text("");

        // get next state
        if ((e).keyCode == "37") {
            next = exp.adj[cur - 1][0];
        } else if ((e).keyCode == "38") {
            next = exp.adj[cur - 1][1];
        } else if ((e).keyCode == "39") {
            next = exp.adj[cur - 1][2];
        } 

        // TODO stuff
        if (stage == "train") {
            // move to next state 
            if (next >= 0) {
                cur = next;
                stateColor("grey");
                in_trial = false;
                path.push(next);
               // sleep(750).then(() => {
                    stateColor("white");
                    in_trial = true;
                    redraw();
               // });
            }

            // if goal is reached => start next trial
            if ((e).key === ' ' || (e).key === 'Spacebar') {
                if (exp.is_term[cur - 1]) {
                    var total = 0;
                    for (var i = 0; i < exp.D; i++) {
                        total += goal[i] * exp.phi[cur - 1][i];
                    }
                    $("#message").css("color", "green");
                    $("#message").text("You earned $" + total.toString() + "!!");
                    in_trial = false;
                    logTrial();
                    sleep(2000).then(() => {
                        nextTrial();
                    });
                } else {
                    $("#message").css("color", "red");
                    $("#message").text("Incorrect");
                }
            }
        } else { // stage == "test"
            // end trial after first button press TODO remove
            if (next >= 0) {
                path.push(next);
                stateColor("grey");
                in_trial = false;
                logTrial();
                sleep(1000).then(() => {
                    stateColor("white");
                    nextTrial();
                });
            }
        }
    }

    return true;
}


function logTrial() {
    // TODO logBonus from exp_v4
    var RT_str = (RTs.toString()).replace(/,/g, ' ');
    var path_str = (path.toString()).replace(/,/g, ' ');
    var key_str = (keys.toString()).replace(/,/g, ' ');
    var d = new Date();
    var t = d.getTime() / 1000;
    var row = "A," + subj_id + "," + stage + "," + start.toString() + "," + goal.toString() + "," + path_str + "," + path.length.toString() + "," + RT_str + "," + key_str + "," + RT_tot.toString() + "," + t.toString() + "," + d.toString() + "\n";
    console.log(row);
    $.post("results_data.php", {postresult: row, postfile: file_name});
}


function redraw() {
    cur_name = exp.names[cur - 1]; // + " (" + cur.toString() + ")";

    goal_str = "";
    for (var i = 0; i < exp.D; i++) {
        if (i > 0) { 
            goal_str += "<br />";
        }
        goal_str += "$" + goal[i].toString() + " / " + exp.feature_names[i];
    }
    $("#goal_state").html(goal_str);
    $("#prices").html(goal_str);

    if (!exp.is_term[cur - 1]) {
        $("#cur_state").text(cur_name);
        $("#phi1").text("");
        $("#phi2").text("");
        $("#phi3").text("");
    } else {
        $("#cur_state").text(""); // TODO rm 
        // TODO dynamic DOM
        $("#phi1").text(exp.phi[cur - 1][0].toString() + " x " + exp.feature_names[0]);
        $("#phi2").text(exp.phi[cur - 1][1].toString() + " x " + exp.feature_names[1]);
        $("#phi3").text(exp.phi[cur - 1][2].toString() + " x " + exp.feature_names[2]);
    }
}


// helper f'n
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

