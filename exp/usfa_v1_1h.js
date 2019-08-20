check_fails = 0;
in_trial = 0; // 0 = not in trial; 1 = new trial page; 2 = in trial
bonus_scale = 0.01; // USD per point

function initExp() {
    console.log("initExp");

    exp = readExp();
    exp = genExp(exp);

    subj_id = "1" + Math.random().toString().substring(3,15);
    dirname = 'results/usfa_v1_1h_batch3';
    file_name = dirname + '/' + subj_id + ".csv";
    bonus_filename = dirname + '/bonus.csv';

    stage = "train";
    trial_idx = -1;
    in_trial = 0;

    RTs = [];
    keys = [];
    path = [];
    rewards = [];
    cur = -1;
    start = -1;
    goal = -1;

    $.post("results_data.php", {postresult: "group, subj_id, stage, start, goal, path, length, RTs, keys, valid_keys, RT_tot, reward, timestamp, datetime, check_fails\n", postfile: file_name })

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

    // shuffle state names
    exp.names = shuffle(exp.names);

    // generate training trials
    exp.train_trials = genTrials(exp.train);

    // generate test trials
    exp.test_trials = genTrials(exp.test);

    // randomly shuffle next states
    for (var i = 0; i < exp.N; i++) {
        exp.adj[i] = shuffle(exp.adj[i]);
    }

    // shuffle feature names
    exp.feature_names = shuffle(exp.feature_names);

    // shuffle state features
    var fid = [];
    for (var j = 0; j < exp.D; j++) {
        fid.push(j);
    }
    fid = shuffle(fid);
    exp.fid = fid;
    shuffleStateFeatures(exp.phi, fid);
    shuffleTrialFeatures(exp.train_trials, fid);
    shuffleTrialFeatures(exp.test_trials, fid);

    return exp;
}


function shuffleStateFeatures(phi, fid) {
    for (var i = 0; i < phi.length; i++) {
        var b = [];
        for (var j = 0; j < phi[i].length; j++) {
            b.push(phi[i][fid[j]]);
        }
        phi[i] = b;
    }
}

function shuffleTrialFeatures(trials, fid) {
    for (var i = 0; i < trials.length; i++) {
        w_new = [];
        for (var j = 0; j < trials[i].w.length; j++) {
            w_new.push(trials[i].w[fid[j]]);
        }
        trials[i].w_orig = trials[i].w;
        trials[i].w = w_new;
    }
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
    in_trial = 0;

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

            //$("#test_page").show();
            nextTrial(); // directly advance to next trial
        } else {
            // finished
            bonus = rewards[Math.floor(Math.random() * rewards.length)];
            if (bonus < 0) {
                bonus = 0;
            }
            $('#bonus').text((bonus * bonus_scale).toFixed(2));
            $("#final_page").show();
            logBonus();
        }
        return;
    }

    start = trials[trial_idx].s;
    cur = start;
    goal = trials[trial_idx].w;
    goal_orig = trials[trial_idx].w_orig;

    if (stage == "train") {
        trials_left = exp.train_trials.length + exp.test_trials.length - trial_idx;
    } else {
        trials_left = exp.test_trials.length - trial_idx;
    }
    $('#trials_left').html(trials_left.toString());

    RT_tot = 0;
    RTs = [];
    keys = [];
    valid_keys = [];
    path = [cur];

    redraw();
    in_trial = 1;
    $("#new_trial_page").show();
}


function checkKeyPressed(e) {
    var e = window.event || e;

    console.log("key press " + e.which);

    if (in_trial == 1) { // new trial page (prices)

        if ((e).key === ' ' || (e).key === 'Spacebar') {

            // begin trial (previously countdown in nextTrial)
            $("#new_trial_page").hide();
            $("#trial_page").show();
            in_trial = 2;
            last_keypress_time = (new Date()).getTime();
        }

    } else if (in_trial == 2) { // in trial

        RT = (new Date()).getTime() - last_keypress_time;
        last_keypress_time = (new Date()).getTime();
        RTs.push(RT);
        keys.push((e).keyCode);
        RT_tot += RT;
        var next = -1;

        // get next state
        if ((e).key == "1") {
            next = exp.adj[cur - 1][0];
        } else if ((e).key == "2") {
            next = exp.adj[cur - 1][1];
        } else if ((e).key == "3") {
            next = exp.adj[cur - 1][2];
        } 

        // move to next state 
        if (next >= 0) {

            valid_keys.push(keys.length - 1);

            if (next == exp.adj[cur - 1][0]) {
                $("#door1").css("border", "10px solid white");
            } else if (next == exp.adj[cur - 1][1]) {
                $("#door2").css("border", "10px solid white");
            } else if (next == exp.adj[cur - 1][2]) {
                $("#door3").css("border", "10px solid white");
            }

            cur = next;
            in_trial = 0;
            path.push(next);

            sleep(1000).then(() => {
                $("#door1").css("border", "");
                $("#door2").css("border", "");
                $("#door3").css("border", "");
                in_trial = 2;
                redraw();
            });
        }

        // if goal is reached => start next trial
        if ((e).key === ' ' || (e).key === 'Spacebar') {
            if (exp.is_term[cur - 1]) {
                rewards.push(reward);
                in_trial = 0;
                logTrial();
                nextTrial();
            }
        }
    }

    return true;
}

// check answers on check_page page
// return true if all correct
function instructionsCheck() {
    checked = 1;
    //check if correct answers are provided
    if (document.getElementById('icheck1').checked) {var ch1 = 1}
    if (document.getElementById('icheck2').checked) {var ch2 = 1}
    if (document.getElementById('icheck3').checked) {var ch3 = 1}
    //are all of the correct
    var checksum=ch1+ch2+ch3;

    if (checksum === 3){
        return true;
    } else{
        return false;
    }
}


// Retrieve assignmentID, workerID, ScenarioID, and environment from URL
//    assignmentID = turkGetParam(‘assignmentId’);
//       workerID = turkGetParam(‘workerId’);

var fullurl = window.location.href;

// extract URL parameters (FROM: https://s3.amazonaws.com/mturk-public/externalHIT_v1.js)
function turkGetParam(name) {
  var regexS = "[\?&]" + name + "=([^&#]*)";
  var regex = new RegExp(regexS);
  var tmpURL = fullurl;
  var results = regex.exec(tmpURL);
  if (results == null) {
    return "";
  } else {
    return results[1];
  }
}

function logTrial() {
    var RT_str = (RTs.toString()).replace(/,/g, ' ');
    var path_str = (path.toString()).replace(/,/g, ' ');
    var key_str = (keys.toString()).replace(/,/g, ' ');
    var valid_key_str = (valid_keys.toString()).replace(/,/g, ' ');
    var goal_str = ("[" + goal_orig.toString() + "]").replace(/,/g, ' ');
    var d = new Date();
    var t = d.getTime() / 1000;
    var row = "A," + subj_id + "," + stage + "," + start.toString() + "," + goal_str + "," + path_str + "," + path.length.toString() + "," + RT_str + "," + key_str + "," + valid_key_str + "," + RT_tot.toString() + "," + reward.toString() + "," + t.toString() + "," + d.toString() + "," + check_fails.toString() + "\n";
    console.log(row);
    $.post("results_data.php", {postresult: row, postfile: file_name});
}

function logBonus() {
    assignmentID = turkGetParam('assignmentId');
    workerID = turkGetParam('workerId');
    var row = workerID.toString() + "," + (bonus * bonus_scale).toFixed(2) + "\n";
    console.log(row);
    $.post("results_data.php", {postresult: row, postfile: bonus_filename});
}


function redraw() {
    // calculate reward
    if (exp.is_term[cur - 1]) {
        reward = 0;
        for (var i = 0; i < exp.D; i++) {
            reward += goal[i] * exp.phi[cur - 1][i];
        }
    }

    // generate goal and reward strings
    goal_str = "";
    goal_str_small = "";
    sum_str = "";
    for (var i = 0; i < exp.D; i++) {
        if (i > 0) { 
            goal_str += "<br />";
            sum_str += " + ";
        }
        // TODO less hacky with img
        goal_str += "$" + goal[i].toString() + " / <img src='" + exp.feature_names[i] + "' height='50px'>";
        goal_str_small += "$" + goal[i].toString() + " / <img src='" + exp.feature_names[i] + "' height='20px'><br />";
        sum_str += exp.phi[cur - 1][i].toString() + " <img src='" + exp.feature_names[i] + "' height='20px'> x $" + goal[i].toString();
    }
    
    // show goal / prices
    $("#goal_state").html("Prices:<br />" + goal_str_small);
    $("#prices").html(goal_str);

    // show doors or resources
    $("#cur_door").attr("src", exp.names[cur - 1]);
    if (!exp.is_term[cur - 1]) {
        $("#message").html("");
        // TODO dynamic DOM
        $("#phi1").html("");
        $("#phi2").html("");
        $("#phi3").html("");
        $("#door1").attr("src", exp.names[exp.adj[cur - 1][0] - 1]);
        $("#door2").attr("src", exp.names[exp.adj[cur - 1][1] - 1]);
        $("#door3").attr("src", exp.names[exp.adj[cur - 1][2] - 1]);
        $("#doors").show();
        $("#phis").hide();
    } else {
        if (reward < 0)
        {
            color = "red";
        }
        else
        {
            color = "green";
        }
        $("#message").html("You earned " + sum_str + "<br /> = <span style='font-size: 50px; color: " + color + ";'> $" + reward.toString() + "</span>");
        // TODO dynamic DOM
        $("#phi1").html(exp.phi[cur - 1][0].toString() + " &emsp; <img src='" + exp.feature_names[0] + "' height='50px'>");
        $("#phi2").html(exp.phi[cur - 1][1].toString() + " &emsp; <img src='" + exp.feature_names[1] + "' height='50px'>");
        $("#phi3").html(exp.phi[cur - 1][2].toString() + " &emsp; <img src='" + exp.feature_names[2] + "' height='50px'>");
        $("#doors").hide();
        $("#phis").show();
    }
}


// helper f'n
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

