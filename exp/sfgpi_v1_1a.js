check_fails = 0;
in_trial = -1; // -1 = not in trial, or pause; 0 = new block page; 1 = new trial page; 2 = in trial; 3 = features, rewards
bonus_scale = 0.01; // USD per point

function initExp() {
    console.log("initExp");

    exp = readExp();
    exp = genExp(exp);

    subj_id = "1" + Math.random().toString().substring(3,15);
    dirname = 'results/sfgpi_v1_1a';
    file_name = dirname + '/' + subj_id + ".csv";
    extra_file_name = dirname + '/' + subj_id + "_extra.csv";
    bonus_filename = dirname + '/bonus.csv';

    in_trial = -1;
    rewards = []; // rewards across all blocks were competing bonus
    block_idx = -1;

    $.post("results_data.php", {postresult: "group, subj_id, block, stage, start, goal, path, length, RTs, keys, valid_keys, RT_tot, reward, timestamp, datetime, check_fails\n", postfile: file_name })

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

    var a = lines[0].trim().split(" ");
    exp.N = parseInt(a[0], 10);
    exp.M = parseInt(a[1], 10);
    exp.D = parseInt(a[2], 10);

    exp.adj = [];
    for (var i = 0; i < exp.N; i++) {
        exp.adj.push([]);
    }

    for (var i = 0; i < exp.M; i++) {
        var a = lines[i + 1].trim().split(" ");
        var adj = {};
        adj.s = parseInt(a[0], 10);
        //adj.a = parseInt(a[1], 10); // TODO action shuffling is broken
        adj.s_next = parseInt(a[2], 10);
        var phi = [];
        for (var j = 0; j < exp.D; j++) {
            phi.push(parseFloat(a[j + 3]));
        }
        adj.phi = phi;
        adj.door_id = parseInt(a[exp.D + 3], 10);
        exp.adj[adj.s - 1].push(adj);
    }
    l = exp.M + 1;

    exp.is_term = [];
    var a = lines[l].trim().split(" ");
    for (var i = 0; i < exp.N; i++) {
        exp.is_term.push(parseInt(a[i], 10));
    }
    l++;

    exp.nblocks = parseInt(lines[l++], 10);

    exp.blocks = [];
    for (var b = 0; b < exp.nblocks; b++) {
        var block = {};

        block.castle_name = lines[l++].trim();
        block.castle_image = lines[l++].trim();

        // read state colors of non terminal states
        block.non_term_colors = [];
        for (var i = 0; i < exp.N; i++) {
            if (exp.is_term[i]) {
                // skip terminal states, we deal with them later after we shuffle
            } else {
                block.non_term_colors.push(lines[l++].trim());
            }
        }

        // read state doors
        block.doors = [];
        for (var i = 0; i < exp.M; i++) {
            block.doors.push(lines[l].trim());
            l++;
        }

        // read feature names
        block.features = [];
        for (var i = 0; i < exp.D; i++) {
            block.features.push(lines[l].trim());
            l++;
        }

        exp.blocks.push(block); 
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

    // for every block
    for (var b = 0; b < exp.nblocks; b++) {
        
        // preload castle image
        preloadImage(exp.blocks[b].castle_image);

        // shuffle non_term_colors
        exp.blocks[b].non_term_colors = shuffle(exp.blocks[b].non_term_colors);

        // assign all colors
        exp.blocks[b].colors = [];
        for (var i = 0, j = 0; i < exp.N; i++) {
            if (exp.is_term[i]) {
                exp.blocks[b].colors.push("black");
            } else {
                exp.blocks[b].colors.push(exp.blocks[b].non_term_colors[j++]);
            }
        }

        // shuffle doors
        exp.blocks[b].doors = shuffle(exp.blocks[b].doors);

        // preload doors
        for (var i = 0; i < exp.blocks[b].doors.length; i++) {
            preloadImage(exp.blocks[b].doors[i]);
        }

        // generate training trials
        exp.blocks[b].train_trials = genTrials(exp.train);

        // generate test trials
        exp.blocks[b].test_trials = genTrials(exp.test);

        // randomly shuffle next states TODO action shuffling is based on indices
        exp.blocks[b].adj = JSON.parse(JSON.stringify(exp.adj)); // deep copy adjacency structure
        for (var i = 0; i < exp.N; i++) {
            exp.blocks[b].adj[i] = shuffle(exp.blocks[b].adj[i]);
        }

        // shuffle feature names
        exp.blocks[b].features = shuffle(exp.blocks[b].features);

        // preload features
        for (var i = 0; i < exp.blocks[b].features.length; i++) {
            preloadImage(exp.blocks[b].features[i]);
        }

        // shuffle state features
        var fid = [];
        for (var j = 0; j < exp.D; j++) {
            fid.push(j);
        }
        fid = shuffle(fid);
        exp.fid = fid;
        shuffleStateFeatures(exp.blocks[b].adj, fid);
        shuffleTrialFeatures(exp.blocks[b].train_trials, fid);
        shuffleTrialFeatures(exp.blocks[b].test_trials, fid);
    }

    // Shuffle blocks
    exp.blocks = shuffle(exp.blocks);

    // remove global adjacency structure
    delete exp.adj;

    return exp;
}


function shuffleStateFeatures(adj, fid) {
    for (var i = 0; i < adj.length; i++) {
        for (var j = 0; j < adj[i].length; j++) {
            var phi = adj[i][j].phi;
            var b = [];
            for (var k = 0; k < phi.length; k++) {
                b.push(phi[fid[k]]);
            }
            adj[i][j].phi = b;
        }
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

function nextBlock() {
    console.log("nextBlock " + block_idx);

    block_idx++;
    trial_idx = -1;
    stage = "train";
    in_trial = 0;

    // reset everything else
    RTs = [];
    keys = [];
    path = [];
    cur = -1;
    start = -1;
    goal = -1;
    reward = 0;
    delta_reward = -1;
    last_a = -1;
    last_a_index = -1;
    next = -1;

    $("#welcome").html("Welcome to " + exp.blocks[block_idx].castle_name + "!");
    $(".new_block_background").css('background-image', 'url("' + exp.blocks[block_idx].castle_image + '")');
    //$(".new_block .shady").css('background-image', 'url("' + exp.blocks[block_idx].castle_image + '")');
    $("#new_block_page").show();
}

function nextTrial() {
    console.log("nextTrial " + trial_idx);

    $("#trial_page").hide();
    $("#message").text("");

    //in_trial = -1; TODO potentially remove
    trial_idx++;

    if (stage == "train") {
        trials = exp.blocks[block_idx].train_trials;
    } else {
        trials = exp.blocks[block_idx].test_trials;
    }

    if (trial_idx >= trials.length) {
        if (stage == "train") {
            // kick off test phase
            stage = "test";
            trial_idx = -1;

            //$("#test_page").show();
            nextTrial(); // directly advance to next trial

        } else {
            console.assert(stage.localeCompare("test"));

            if (block_idx + 1 < exp.nblocks) {
                // new block
                nextBlock();

            } else {
                // finished
                bonus = rewards[Math.floor(Math.random() * rewards.length)];
                if (bonus < 0) {
                    bonus = 0;
                }
                $('#bonus').text((bonus * bonus_scale).toFixed(2));
                //$("#final_page").show();
                logBonus();
                $("#cheat_page").show();
            }
        }
        return;
    }

    start = trials[trial_idx].s;
    cur = start;
    goal = trials[trial_idx].w;
    goal_orig = trials[trial_idx].w_orig;

    if (stage == "train") {
        trials_left = exp.blocks[block_idx].train_trials.length + exp.blocks[block_idx].test_trials.length - trial_idx;
    } else {
        trials_left = exp.blocks[block_idx].test_trials.length - trial_idx;
    }
    $('#trials_left').html(trials_left.toString());

    RT_tot = 0;
    RTs = [];
    keys = [];
    valid_keys = [];
    path = [cur];
    reward = 0;
    delta_reward = -1;
    last_a = -1;
    last_a_index = -1;
    next = -1;

    in_trial = 1;
    redraw();
    $("#new_trial_page").show();
}

function checkKeyPressed(e) {
    var e = window.event || e;

    console.log("key press " + e.which + ", in_trial " + in_trial.toString());

    if (in_trial == 0) { // new block page

        if ((e).key === '\n' || (e).which === 13) {

            // begin block
            $("#new_block_page").hide();
            nextTrial();
        }

    }  else if (in_trial == 1) { // new trial page (prices)

        if ((e).key === ' ' || (e).key === 'Spacebar') {

            // begin trial (previously countdown in nextTrial)
            $("#new_trial_page").hide();
            $("#trial_page").show();
            in_trial = 2;
            //redraw();
            last_keypress_time = (new Date()).getTime();
        }

    } else if (in_trial == 2) { // in trial
        RT = (new Date()).getTime() - last_keypress_time;
        last_keypress_time = (new Date()).getTime();
        RTs.push(RT);
        keys.push((e).keyCode);
        RT_tot += RT;
        var next = -1;
        var adj = {};

        // get next state
        if ((e).key == "1") {
            last_a = 1;
        } else if ((e).key == "2") {
            last_a = 2;
        } else if ((e).key == "3") {
            last_a = 3;
        }

        //  TODO action shuffling is broken, we currently index based on position in the adjacency structure
        /*
        for (var i = 0; i < exp.blocks[block_idx].adj[cur - 1].length; i++) {
            if (exp.blocks[block_idx].adj[cur - 1][i].a == last_a) {
                adj = exp.blocks[block_idx].adj[cur - 1][i];
                next = adj.s_next;
                last_a_index = i;
            }
        }
        */
        i = last_a - 1;
        adj = exp.blocks[block_idx].adj[cur - 1][i];
        next = adj.s_next;
        last_a_index = i;

        // move to next state 
        if (next >= 0) {
            console.assert(adj.s == cur);

            if (last_a == 1) {
                $("#door1").css("border", "10px solid white");
            } else if (last_a == 2) {
                $("#door2").css("border", "10px solid white");
            } else if (last_a == 3) {
                $("#door3").css("border", "10px solid white");
            }

            delta_reward = calculate_reward(goal, adj.phi);
            reward += delta_reward;
            path.push(next);
            valid_keys.push(keys.length - 1);

            in_trial = -1; // disable keypresses

            sleep(1000).then(() => {
                $("#door1").css("border", "");
                $("#door2").css("border", "");
                $("#door3").css("border", "");

                in_trial = 3;
                redraw();

                console.assert(next != 1);
                cur = next;
                last_a = -1;
                next = -1;
            });

        }

    } else if (in_trial == 3) {

        // if goal is reached => start next trial
        // if not, continue trial
        if ((e).key === ' ' || (e).key === 'Spacebar') {
            if (exp.is_term[cur - 1]) {
                rewards.push(reward);
                in_trial = 0;
                logTrial();
                nextTrial();
            } else {
                in_trial = 2;
                redraw();
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

function preloadImage(src) {
    var image = new Image();
    image.src = src;
}

function logTrial() {
    var RT_str = (RTs.toString()).replace(/,/g, ' ');
    var path_str = (path.toString()).replace(/,/g, ' ');
    var key_str = (keys.toString()).replace(/,/g, ' ');
    var valid_key_str = (valid_keys.toString()).replace(/,/g, ' ');
    var goal_str = ("[" + goal_orig.toString() + "]").replace(/,/g, ' ');
    var d = new Date();
    var t = d.getTime() / 1000;
    var row = "A," + subj_id + "," + block_idx.toString() + "," + stage + "," + start.toString() + "," + goal_str + "," + path_str + "," + path.length.toString() + "," + RT_str + "," + key_str + "," + valid_key_str + "," + RT_tot.toString() + "," + reward.toString() + "," + t.toString() + "," + d.toString() + "," + check_fails.toString() + "\n";
    console.log(row);
    $.post("results_data.php", {postresult: row, postfile: file_name});
}

function logExtra(cheated) {
    var assignmentID = turkGetParam('assignmentId');
    var workerID = turkGetParam('workerId');
    var row = workerID.toString() + "," + assignmentID.toString() + "," + cheated.toString() + "\n";
    console.log(row);
    $.post("results_data.php", {postresult: row, postfile: extra_file_name});
}

function logBonus() {
    //var assignmentID = turkGetParam('assignmentId');
    var workerID = turkGetParam('workerId');
    var row = workerID.toString() + "," + (bonus * bonus_scale).toFixed(2) + "\n";
    console.log(row);
    $.post("results_data.php", {postresult: row, postfile: bonus_filename});
}

function calculate_reward(goal, phi) {
    var reward = 0;
    for (var i = 0; i < exp.D; i++) {
        reward += goal[i] * phi[i];
    }
    return reward;
}

function redraw() {

    // generate goal and reward strings
    var goal_str = "";
    var goal_str_small = "";
    var sum_str = "";
    var phi_objects = [];
    if (last_a != -1) {
        var phi = exp.blocks[block_idx].adj[cur - 1][last_a_index].phi;
        var door_id = exp.blocks[block_idx].adj[cur - 1][last_a_index].door_id;
    }
    for (var i = 0; i < exp.D; i++) {
        if (i > 0) { 
            goal_str += "<br />";
        }
        // TODO less hacky with img
        goal_str += "$" + goal[i].toString() + " / <img src='" + exp.blocks[block_idx].features[i] + "' height='70px'>";
        goal_str_small += "$" + goal[i].toString() + " / <img src='" + exp.blocks[block_idx].features[i] + "' height='30px'><br />";
        
        if (last_a != -1) {
            //sum_str += phi[i].toString() + " <img src='" + exp.blocks[block_idx].features[i] + "' height='20px'> x $" + goal[i].toString();
            var phi_object = "";
            if (phi[i] > 0) {
                if (sum_str != "") {
                    sum_str += " + ";
                }
                for (var j = 0; j < phi[i]; j++) {
                    phi_object += "<img src='" + exp.blocks[block_idx].features[i] + "' height='70px'>";
                    sum_str += "<img src='" + exp.blocks[block_idx].features[i] + "' height='30px'>";
                }
                sum_str += " x $" + goal[i].toString();
            }
            phi_objects.push(phi_object);
        }
    }
    
    // show goal / prices
    $("#goal_state").html("Prices:<br />" + goal_str_small);
    $("#prices").html(goal_str);
    var day;
    if (stage == "train") {
        day = trial_idx + 1;
    } else {
        day = trial_idx + 1 + exp.blocks[block_idx].train_trials.length;
    }
    $("#castle_day").html("Day " + day.toString() + " in " + exp.blocks[block_idx].castle_name);

    // show doors or resources
    if (last_a != -1) {
        $("#cur_door").attr("src", exp.blocks[block_idx].doors[door_id - 1]);
        $("#cur_door").show();
    } else {
        $("#cur_door").hide();
    }
    if (in_trial == 1 || in_trial == 2) {
        // doors
        //
        $("#trial_page").css("background-color", exp.blocks[block_idx].colors[cur - 1]);

        var adj = exp.blocks[block_idx].adj[cur - 1];
        $("#message").html("");
        // TODO dynamic DOM
        $("#phi1").html("");
        $("#phi2").html("");
        $("#phi3").html("");
        var door_objects = ["#door1", "#door2", "#door3"];
        var number_objects = ["#number_one", "#number_two", "#number_three"];
        for (var i = 0; i < door_objects.length; i++) {
            $(door_objects[i]).hide();
            $(number_objects[i]).hide();
        }
        for (var i = 0; i < adj.length; i++) {
            var a = i + 1; //adj[i].a; TODO action shuffling is broken
            $(door_objects[a - 1]).attr("src", exp.blocks[block_idx].doors[adj[i].door_id - 1]);
            $(door_objects[a - 1]).show();
            $(number_objects[a - 1]).show();
        }
        $("#door1").attr("src", exp.blocks[block_idx].doors[adj[cur - 1][0] - 1]);
        $("#door2").attr("src", exp.blocks[block_idx].doors[adj[cur - 1][1] - 1]);
        $("#door3").attr("src", exp.blocks[block_idx].doors[adj[cur - 1][2] - 1]);
        $("#doors").show();
        $("#phis").hide();
        $("#tip").html("Choose doors using the <b>number keys 1, 2, 3</br>");
    } else {
        // rewards
        //
        $("#trial_page").css("background-color", "black");
        if (delta_reward < 0)
        {
            color = "red";
        }
        else
        {
            color = "green";
        }
        $("#message").html("You earned " + sum_str + "<br /> = <span style='font-size: 50px; color: " + color + ";'> $" + delta_reward.toString() + "</span> <br /> for a total of $" + reward.toString() + " for the day");
        // TODO dynamic DOM
        $("#phi1").html(phi_objects[0]);
        $("#phi2").html(phi_objects[1]);
        //$("#phi1").html(phi[0].toString() + " &emsp; <img src='" + exp.blocks[block_idx].features[0] + "' height='50px'>");
        //$("#phi2").html(phi[1].toString() + " &emsp; <img src='" + exp.blocks[block_idx].features[1] + "' height='50px'>");
        //$("#phi3").html(phi[2].toString() + " &emsp; <img src='" + exp.blocks[block_idx].features[2] + "' height='50px'>");
        $("#doors").hide();
        $("#phis").show();
        $("#tip").html("Press <b>space</b> to sell the resouces.<br/>");
    }
}


// helper f'n
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
