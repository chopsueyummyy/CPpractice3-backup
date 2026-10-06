<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Content-Type: application/json");
require_once 'cors.php';
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

$jsonFile = __DIR__ . '/course_catalog.json';
$courses = [];

if (file_exists($jsonFile)) {
    $catalogData = json_decode(file_get_contents($jsonFile), true);
    if (is_array($catalogData)) {
        $id = 1;
        foreach ($catalogData as $clusterName => $courseList) {
            foreach ($courseList as $cName) {
                $courses[] = [
                    "courseId"    => $id++,
                    "courseCode"  => "",
                    "courseName"  => $cName,
                    "clusterName" => $clusterName,
                    "category"    => $clusterName
                ];
            }
        }
    }
}

// Fallback to DB if JSON file empty or missing
if (empty($courses)) {
    @include_once 'db_connect.php';
    if (isset($conn) && $conn) {
        $result = $conn->query("SELECT CourseID, CourseCode, CourseName, RIASECCategory, ClusterName FROM riasec_courses");
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $courses[] = [
                    "courseId"    => (int)$row['CourseID'],
                    "courseCode"  => $row['CourseCode'] ?? '',
                    "courseName"  => $row['CourseName'] ?? '',
                    "clusterName" => $row['ClusterName'] ?? '',
                    "category"    => $row['RIASECCategory'] ?? ''
                ];
            }
        }
    }
}

echo json_encode([
    "status"  => "success",
    "courses" => $courses
]);
?>
