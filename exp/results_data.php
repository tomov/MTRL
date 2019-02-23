<?php
    print "Test";
    ini_set('display_errors', 1);
    print_r(json_encode($_POST));
    $file = $_POST['postfile'];
    $result_string = $_POST['postresult'];
    //print_r($_POST);
    //if(isset($_POST['postfile'])) print "yes!";
    //$file_csv = fopen($file,"w");
    //$headers = ['Group', 'ID', 'Type', 'Displayed', 'Goals', 'Path', 'Length', 'RT_Path', 'Final_RT'];
    //fputcsv($file_csv, $headers);
    //fclose($file_csv);
    file_put_contents($file, $result_string, FILE_APPEND);
 ?>
