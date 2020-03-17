<?php
/*
Gibbon, Flexible & Open School System
Copyright (C) 2010, Ross Parker

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

// Setup the composer autoloader
require_once __DIR__.'/../vendor/autoload.php';

// New PDO DB connection
$mysqlConnector = new Gibbon\Database\MySqlConnector();
$pdo = $mysqlConnector->connect([
    'databaseServer'   => 'localhost',
    'databaseName'     => 'gibbon-strings',
    'databaseUsername' => 'root',
    'databasePassword' => 'root',
]);

if (empty($pdo)) {
    die('Your request failed due to a database error.');
}

print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />" ;

$queries = [
    ['gibbonAction', 'category'],
    ['gibbonAction', 'name'],
    ['gibbonAction', 'description'],
    ['gibbonAlertLevel', 'name'],
    ['gibbonAlertLevel', 'description'],
    ['gibbonCountry', 'printable_name'],
    ['gibbonDaysOfWeek', 'name'],
    ['gibbonExternalAssessment', 'name'],
    ['gibbonExternalAssessment', 'nameShort'],
    ['gibbonExternalAssessment', 'description'],
    ['gibbonExternalAssessmentField', 'name'],
    ['gibbonExternalAssessmentField', 'category'],
    ['gibbonFileExtension', 'type'],
    ['gibbonFileExtension', 'name'],
    ['gibbonINDescriptor', 'name'],
    ['gibbonINDescriptor', 'nameShort'],
    ['gibbonINDescriptor', 'description'],
    ['gibbonLibraryType', 'name'],
    ['gibbonLibraryType', 'fields'],
    ['gibbonMedicalCondition', 'name'],
    ['gibbonModule', 'name'],
    ['gibbonModule', 'description'],
    ['gibbonModule', 'category'],
    ['gibbonRole', 'category'],
    ['gibbonRole', 'name'],
    ['gibbonRole', 'nameShort'],
    ['gibbonRole', 'description'],
    ['gibbonScale', 'name'],
    ['gibbonScale', 'nameShort'],
    ['gibbonScale', 'usage'],
    ['gibbonScale', 'name'],
    ['gibbonScaleGrade', 'value'],
    ['gibbonScaleGrade', 'descriptor'],
    ['gibbonSetting', 'nameDisplay'],
    ['gibbonSetting', 'description'],
    ['gibbonYearGroup', 'name'],
    ['gibbonYearGroup', 'nameShort'],
    ['gibbonNotificationEvent', 'event'],
];

foreach ($queries as $query) {
    list($tableName, $fieldName) = $query;
    $strings = [];

    $result = $pdo->select("SELECT DISTINCT `" . $fieldName . "` FROM `" . $tableName . "` WHERE NOT `" . $fieldName . "`='' ORDER BY `" . $fieldName . "`");
    
    while ($databaseString = $result->fetchColumn(0)) {
        // Deal with special case of gibbonAction names
        if ($tableName=='gibbonAction' && $fieldName=='name') {
            $strings[] = $databaseString;
            if (strpos($databaseString, '_') !== false) {
                $strings[] = substr($databaseString, 0, strpos($databaseString, '_'));
            }
        }

        // Omit numeric and percentage values and descriptors from gibbonScaleGrade
        elseif ($tableName=='gibbonScaleGrade' && ($fieldName=='value' || $fieldName=='descriptor')) {
            if (strpos($databaseString, '%') === false && strpos($databaseString, '–') === false && !is_numeric($databaseString)) {
                $strings[] = $databaseString;
            }
        }
        
        // Deal with special case of gibbonExternalAssessmentField categories
        elseif ($tableName == 'gibbonExternalAssessmentField' && $fieldName=='category') {
            if (strpos($databaseString, '_') === false) {
                $strings[] = $databaseString;
            } else {
                $strings[] = substr($databaseString, (strpos($databaseString, '_')+1));
            }
        }

        // Deal with special case of gibbonExternalAssessmentField categories
        elseif ($tableName == 'gibbonLibraryType' && $fieldName=='fields') {
            $fields = unserialize($databaseString) ;
            foreach ($fields as $field) {
                $strings[] = $field['name'];
            }
        }

        // Deal with all other cases
        else {
            $strings[] = $databaseString;
        }
    }

    print "// " . $tableName . " - " . $fieldName . "<br/>" ;

    // Trim out duplicate strings, then add slashes and output
    foreach (array_unique($strings) as $string) {
        print "__('" . str_replace("'", "\'", $string) . "');<br/>";
    }

    print "<br/>" ;
}
