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
//
function readExp() {
    console.log("readExp");

    var exp = {};
    var lines = $("#experiment").val().split("\n");
    exp.N = parseInt(lines[0], 10);

    // read adjacency 
    exp.adj = [];
    for (var i = 1; i <= exp.N; i++) {
        var a = lines[i].trim().split(" ");
        var b = [];
        for (var j = 0; j < 4; j++) {
            b.push(parseInt(a[j], 10));
        }
        exp.adj.push(b);
    }
    l = exp.N + 1; // current line

    // read state names
    exp.names = [];
    for (var i = 0; i < exp.N; i++) {
        exp.names.push(lines[l].trim());
        l++;
    }

    // read training tasks
    //exp.ntrain = parseInt(lines[l], 10);
    //l++;
    //exp.train = [];
    //for (var i = 0; i < exp.ntrain; i++) {
    //    var a = lines[l].trim().split(" ");
    //    l++;
    //    var task = {};
    //    task.s = parseInt(a[0], 10);
    //    task.g = parseInt(a[1], 10);
    //    task.n = parseInt(a[2], 10);
    //    exp.train.push(task);
    //}
    exp.ntrain = parseInt(lines[l], 10);
    l++;
    exp.train = readTasks(lines, l, exp.ntrain);
    l += exp.ntrain;

    // read test tasks
    //exp.ntest = parseInt(lines[l], 10);
    //l++;
    //exp.test = [];
    //for (var i = 0; i < exp.ntest; i++) {
    //    var a = lines[l].trim().split(" ");
    //    l++;
    //    var task = {};
    //    task.s = parseInt(a[0], 10);
    //    task.g = parseInt(a[1], 10);
    //    task.n = parseInt(a[2], 10);
    //    exp.test.push(task);
    //}
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

        task.g = [];
        g = b[1].trim().split(" ");
        for (var j = 0; j < g.length; j++) {
            task.g.push(parseInt(g[j], 10));
        }

        tasks.push(task);
        l++;
    }
    return tasks;
}


function genExp(exp) {
    console.log("genExp");

    // shuffle state names
    exp.names.sort(function(a, b) {return 0.5 - Math.random()});

    // generate training trials
    exp.train_trials = genTrials(exp.train);

    // generate test trials
    exp.test_trials = genTrials(exp.test);

    // randomly flip graph
    exp.flip_horiz = Math.floor(Math.random() * 2);
    if (exp.flip_horiz) {
        for (var i = 0; i < exp.N; i++) {
            var tmp = exp.adj[i][0];
            exp.adj[i][0] = exp.adj[i][2];
            exp.adj[i][2] = tmp;
        }
    }
    exp.flip_vert = Math.floor(Math.random() * 2);
    if (exp.flip_vert) {
        for (var i = 0; i < exp.N; i++) {
            var tmp = exp.adj[i][1];
            exp.adj[i][1] = exp.adj[i][3];
            exp.adj[i][3] = tmp;
        }
    }

    // optionally rotate graph
    // DON'T do it -- left/right arrow keys are symmetrical; up/down not so much
    //exp.rotate = Math.floor(Math.random() * 4);
    //for (var i = 0; i < exp.N; i++) {
    //    var a = exp.adj[i].slice();
    //    for (var j = 0; j < 4; j++) {
    //        exp.adj[i][j] = a[(j + exp.rotate) % 4];
    //    }
    //}
    return exp;
}


function genTrial(desc, j) {
    var task = {};
    do {
        task.s = desc.s[Math.floor(Math.random() * desc.s.length)];
        task.g = desc.g[Math.floor(Math.random() * desc.g.length)];
        task.j = j;
        if (task.s <= 0) {
            task.s = Math.floor(Math.random() * exp.N) + 1;
        }
        if (task.g <= 0) {
            task.g = Math.floor(Math.random() * exp.N) + 1;
        }
    } while (task.s == task.g);
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
    trials.sort(function(a, b) {return 0.5 - Math.random()});

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
    goal = trials[trial_idx].g;

    RT_tot = 0;
    RTs = [];
    keys = [];
    path = [cur];

    redraw();
    $("#new_trial_page").show();

    // countdown
    sleep(2000).then(() => {
        $("#new_trial_page").hide();
        $("#trial_page").show();
        $("#countdown").text("3...");
        stateColor("grey");
        sleep(1000).then(() => {
            $("#countdown").text("2...");
            sleep(1000).then(() => {
                $("#countdown").text("1...");
                sleep(1000).then(() => {
                    $("#countdown").text("GO!");
                    stateColor("white");
                    in_trial = true;
                    last_keypress_time = (new Date()).getTime();
                    sleep(1000).then(() => {
                        $("#countdown").text("");
                    });
                });
            });
        });
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
        var next = -1;
        $("#message").text("");

        // get next state
        if ((e).keyCode == "39") {
            next = exp.adj[cur - 1][0];
        } else if ((e).keyCode == "38") {
            next = exp.adj[cur - 1][1];
        } else if ((e).keyCode == "37") {
            next = exp.adj[cur - 1][2];
        } else if ((e).keyCode == "40") {
            next = exp.adj[cur - 1][3];
        }

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
                if (cur == goal) {
                    $("#message").css("color", "green");
                    $("#message").text("SUCCESS!!");
                    in_trial = false;
                    logTrial();
                    sleep(1000).then(() => {
                        nextTrial();
                    });
                } else {
                    $("#message").css("color", "red");
                    $("#message").text("Incorrect");
                }
            }
        } else { // stage == "test"
            // end trial after first button press
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
    start_name = exp.names[start - 1]; // + " (" + start.toString() + ")";
    goal_name = exp.names[goal - 1]; // + " (" + goal.toString() + ")";
    var adj_names = [];
    for (var i = 0; i < 4; i++) {
        if (exp.adj[cur - 1][i] <= 0) {
            adj_names.push("&#11044;");
        } else {
            adj_names.push(exp.names[exp.adj[cur - 1][i] - 1]);
        }
    }

    $("#cur_state").text(cur_name);
    $("#goal_state").text("Go to " + goal_name);
    $("#right_state").html(adj_names[0]);
    $("#up_state").html(adj_names[1]);
    $("#left_state").html(adj_names[2]);
    $("#down_state").html(adj_names[3]);

    $("#from_state").text(start_name);
    $("#to_state").text(goal_name);
}


// helper f'n
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

