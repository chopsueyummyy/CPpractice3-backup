<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Content-Type: application/json");
require_once 'cors.php';
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

require_once 'db_connect.php';
require_once __DIR__ . '/services/CacheService.php';

$filter = $_GET['filter'] ?? 'all'; 

$response = CacheService::remember("dashboard_stats_" . $filter, 60, function() use ($conn, $filter) {
    $dateCondition = "1=1";
    switch ($filter) {
        case 'today':
            $dateCondition = "DATE(a.SubmittedAt) = CURDATE()";
            break;
        case 'week':
            $dateCondition = "a.SubmittedAt >= DATE_SUB(NOW(), INTERVAL 1 WEEK)";
            break;
        case 'month':
            $dateCondition = "a.SubmittedAt >= DATE_SUB(NOW(), INTERVAL 1 MONTH)";
            break;
    }

    $pendingPsychometrician = (int)$conn->query("
        SELECT COUNT(*) as count FROM assessments a WHERE a.Status IN ('pending_psychometrician', 'pending_review') AND $dateCondition
    ")->fetch_assoc()['count'];

    $pendingCounselor = (int)$conn->query("
        SELECT COUNT(*) as count FROM assessments a WHERE a.Status = 'pending_counselor' AND $dateCondition
    ")->fetch_assoc()['count'];

    $pending = $pendingPsychometrician;

    $totalStudents = $conn->query("SELECT COUNT(*) as count FROM students")->fetch_assoc()['count'];

    $assessmentsToday = $conn->query("
        SELECT COUNT(*) as count FROM assessments WHERE DATE(SubmittedAt) = CURDATE()
    ")->fetch_assoc()['count'];

    $feedbackGiven = $conn->query("
        SELECT COUNT(*) as count FROM counselor_feedback cf
        JOIN assessments a ON a.AssessmentID = cf.AssessmentID
        WHERE $dateCondition
    ")->fetch_assoc()['count'];

    $approved = $conn->query("
        SELECT COUNT(*) as count FROM assessments a WHERE a.Status = 'approved' AND $dateCondition
    ")->fetch_assoc()['count'];

    $total = $conn->query("
        SELECT COUNT(*) as count FROM assessments a WHERE a.Status != 'in_progress' AND $dateCondition
    ")->fetch_assoc()['count'];

    $approvalRate = $total > 0 ? round(($approved / $total) * 100, 1) : 0;

    // 1. Strand distribution (normalized and aggregated)
    $strandAgg = [];
    $res = $conn->query("
        SELECT pi.Strand, COUNT(*) as count 
        FROM assessments a
        JOIN personal_information pi ON pi.PI_ID = a.PI_ID
        WHERE a.Status = 'approved' AND $dateCondition
        GROUP BY pi.Strand
    ");
    while ($row = $res->fetch_assoc()) {
        $raw = trim($row['Strand'] ?? '');
        $canonical = $raw;
        if (stripos($raw, 'STEM') !== false) {
            $canonical = 'STEM (Science, Technology, Engineering, Mathematics)';
        } elseif (stripos($raw, 'ABM') !== false) {
            $canonical = 'ABM (Accountancy, Business, Management)';
        } elseif (stripos($raw, 'HUMSS') !== false) {
            $canonical = 'HUMSS (Humanities and Social Sciences)';
        } elseif (stripos($raw, 'GAS') !== false || stripos($raw, 'General Academic') !== false) {
            $canonical = 'GAS (General Academic Strand)';
        } elseif (stripos($raw, 'TVL') !== false || stripos($raw, 'Technical-Vocational') !== false) {
            $canonical = 'TVL (Technical-Vocational-Livelihood)';
        } elseif (stripos($raw, 'ICT') !== false) {
            $canonical = 'ICT (Information and Communications Technology)';
        } elseif (stripos($raw, 'Arts') !== false) {
            $canonical = 'Arts and Design Track';
        } elseif (stripos($raw, 'Sports') !== false) {
            $canonical = 'Sports Track';
        }
        if (!empty($canonical)) {
            $strandAgg[$canonical] = ($strandAgg[$canonical] ?? 0) + (int)$row['count'];
        }
    }
    arsort($strandAgg);
    $strandStats = [];
    foreach ($strandAgg as $sName => $sCount) {
        $strandStats[] = [
            "strand" => $sName,
            "count"  => $sCount
        ];
    }

    // 2. RIASEC dominant types distribution
    $riasecStats = [];
    $res = $conn->query("
        SELECT ar.PrimaryType, COUNT(*) as count 
        FROM assessments a
        JOIN assessment_results ar ON ar.AssessmentID = a.AssessmentID
        WHERE a.Status = 'approved' AND $dateCondition
        GROUP BY ar.PrimaryType
    ");
    while ($row = $res->fetch_assoc()) {
        if ($row['PrimaryType']) {
            $riasecStats[] = [
                "type" => $row['PrimaryType'],
                "count" => (int)$row['count']
            ];
        }
    }

    // 3. Self-esteem levels distribution
    $rseStats = [];
    $res = $conn->query("
        SELECT r.Level, COUNT(*) as count 
        FROM assessments a
        JOIN rse_results r ON r.AssessmentID = a.AssessmentID
        WHERE a.Status = 'approved' AND $dateCondition
        GROUP BY r.Level
    ");
    while ($row = $res->fetch_assoc()) {
        if ($row['Level']) {
            $rseStats[] = [
                "level" => $row['Level'],
                "count" => (int)$row['count']
            ];
        }
    }

    // 4. Career Decision Self-Efficacy (CDSES) levels distribution
    $cdsesStats = [];
    $res = $conn->query("
        SELECT c.SelfEfficacyLevel, COUNT(*) as count 
        FROM assessments a
        JOIN cdses_results c ON c.AssessmentID = a.AssessmentID
        WHERE a.Status = 'approved' AND $dateCondition
        GROUP BY c.SelfEfficacyLevel
    ");
    while ($row = $res->fetch_assoc()) {
        if ($row['SelfEfficacyLevel']) {
            $cdsesStats[] = [
                "level" => $row['SelfEfficacyLevel'],
                "count" => (int)$row['count']
            ];
        }
    }

    // 5. Recent activity logs
    $recentActivity = [];
    $res = $conn->query("
        SELECT a.AssessmentID, a.SubmittedAt, a.Status, pi.FirstName, pi.LastName, pi.Strand 
        FROM assessments a
        JOIN personal_information pi ON pi.PI_ID = a.PI_ID
        WHERE a.Status != 'in_progress'
        ORDER BY a.SubmittedAt DESC
        LIMIT 5
    ");
    while ($row = $res->fetch_assoc()) {
        $recentActivity[] = [
            "assessmentId" => (int)$row['AssessmentID'],
            "studentName"  => $row['FirstName'] . ' ' . $row['LastName'],
            "strand"       => $row['Strand'],
            "submittedAt"  => $row['SubmittedAt'],
            "status"       => $row['Status']
        ];
    }

    // 6. Cumulative Grade Level distribution (deduplicated per student with assessment records)
    $gradeStats = [];
    $res = $conn->query("
        SELECT 
            COALESCE(NULLIF(TRIM(pi.GradeLevel), ''), 'Unassigned') as GradeLevel,
            COUNT(*) as count
        FROM (
            SELECT a.StudentID, MAX(a.AssessmentID) as latest_assessment_id
            FROM assessments a
            WHERE a.Status != 'in_progress'
            GROUP BY a.StudentID
        ) latest
        JOIN assessments a ON a.AssessmentID = latest.latest_assessment_id
        JOIN personal_information pi ON pi.PI_ID = a.PI_ID
        GROUP BY COALESCE(NULLIF(TRIM(pi.GradeLevel), ''), 'Unassigned')
        ORDER BY count DESC
    ");
    while ($row = $res->fetch_assoc()) {
        if ($row['GradeLevel']) {
            $gradeStats[] = [
                "gradeLevel" => $row['GradeLevel'],
                "count"      => (int)$row['count']
            ];
        }
    }

    // 7. Cumulative Gender distribution (deduplicated per student with assessment records)
    $genderStats = [];
    $res = $conn->query("
        SELECT 
            COALESCE(NULLIF(TRIM(pi.Gender), ''), 'Not Specified') as Gender,
            COUNT(*) as count
        FROM (
            SELECT a.StudentID, MAX(a.AssessmentID) as latest_assessment_id
            FROM assessments a
            WHERE a.Status != 'in_progress'
            GROUP BY a.StudentID
        ) latest
        JOIN assessments a ON a.AssessmentID = latest.latest_assessment_id
        JOIN personal_information pi ON pi.PI_ID = a.PI_ID
        GROUP BY COALESCE(NULLIF(TRIM(pi.Gender), ''), 'Not Specified')
        ORDER BY count DESC
    ");
    while ($row = $res->fetch_assoc()) {
        if ($row['Gender']) {
            $genderStats[] = [
                "gender" => $row['Gender'],
                "count"  => (int)$row['count']
            ];
        }
    }

    // 8. Priority Endorsements awaiting Counselor advisory
    $priorityEndorsements = [];
    $res = $conn->query("
        SELECT a.AssessmentID, a.SubmittedAt, a.StudentID, pi.FirstName, pi.LastName, pi.Strand, pi.GradeLevel,
               cf.FeedbackNotes as PsychometricianNotes, cf.ReviewedAt as EndorsedAt
        FROM assessments a
        JOIN personal_information pi ON pi.PI_ID = a.PI_ID
        LEFT JOIN counselor_feedback cf ON cf.AssessmentID = a.AssessmentID AND cf.ReviewerRole = 'psychometrician'
        WHERE a.Status = 'pending_counselor'
        ORDER BY a.SubmittedAt DESC
        LIMIT 5
    ");
    while ($row = $res->fetch_assoc()) {
        $priorityEndorsements[] = [
            "assessmentId"         => (int)$row['AssessmentID'],
            "studentId"            => $row['StudentID'],
            "studentName"          => $row['FirstName'] . ' ' . $row['LastName'],
            "strand"               => $row['Strand'],
            "gradeLevel"           => $row['GradeLevel'],
            "endorsedAt"           => $row['EndorsedAt'] ?? $row['SubmittedAt'],
            "psychometricianNotes" => $row['PsychometricianNotes'] ?? ''
        ];
    }

    // 9. Recent Released Advisories (Official Counseling releases)
    $recentReleased = [];
    $res = $conn->query("
        SELECT a.AssessmentID, a.SubmittedAt, a.StudentID, pi.FirstName, pi.LastName, pi.Strand, pi.GradeLevel,
               cf.FeedbackNotes as CounselorNotes, cf.ReviewedAt as ReleasedAt
        FROM assessments a
        JOIN personal_information pi ON pi.PI_ID = a.PI_ID
        LEFT JOIN counselor_feedback cf ON cf.AssessmentID = a.AssessmentID AND cf.ReviewerRole = 'guidance_counselor'
        WHERE a.Status = 'approved'
        ORDER BY a.AssessmentID DESC
        LIMIT 5
    ");
    while ($row = $res->fetch_assoc()) {
        $recentReleased[] = [
            "assessmentId"   => (int)$row['AssessmentID'],
            "studentId"      => $row['StudentID'],
            "studentName"    => $row['FirstName'] . ' ' . $row['LastName'],
            "strand"         => $row['Strand'],
            "gradeLevel"     => $row['GradeLevel'],
            "releasedAt"     => $row['ReleasedAt'] ?? $row['SubmittedAt'],
            "counselorNotes" => $row['CounselorNotes'] ?? ''
        ];
    }

    // 10. Activity trend (submissions vs. released advisories)
    //     today/week -> last 7 days, month -> last 30 days, all -> last 12 weeks
    $trendMode = ($filter === 'all') ? 'weekly' : 'daily';
    $trendDays = ($filter === 'month') ? 30 : 7;
    $today = new DateTime('today');
    if ($trendMode === 'weekly') {
        $firstBucket = (clone $today)->modify('monday this week')->modify('-11 weeks');
    } else {
        $firstBucket = (clone $today)->modify('-' . ($trendDays - 1) . ' days');
    }
    $startStr = $firstBucket->format('Y-m-d');

    $submittedByDay = [];
    $res = $conn->query("
        SELECT DATE(SubmittedAt) AS d, COUNT(*) AS c
        FROM assessments
        WHERE SubmittedAt IS NOT NULL AND SubmittedAt >= '$startStr'
        GROUP BY DATE(SubmittedAt)
    ");
    while ($res && $row = $res->fetch_assoc()) { $submittedByDay[$row['d']] = (int)$row['c']; }

    $releasedByDay = [];
    $res = $conn->query("
        SELECT DATE(ReviewedAt) AS d, COUNT(DISTINCT AssessmentID) AS c
        FROM counselor_feedback
        WHERE ReviewerRole = 'guidance_counselor' AND Action <> 'declined' AND ReviewedAt >= '$startStr'
        GROUP BY DATE(ReviewedAt)
    ");
    while ($res && $row = $res->fetch_assoc()) { $releasedByDay[$row['d']] = (int)$row['c']; }

    $activityTrend = [];
    if ($trendMode === 'weekly') {
        for ($i = 0; $i < 12; $i++) {
            $ws = (clone $firstBucket)->modify("+$i weeks");
            $sub = 0; $rel = 0;
            for ($d = 0; $d < 7; $d++) {
                $k = (clone $ws)->modify("+$d days")->format('Y-m-d');
                $sub += $submittedByDay[$k] ?? 0;
                $rel += $releasedByDay[$k] ?? 0;
            }
            $we = (clone $ws)->modify('+6 days');
            $activityTrend[] = [
                "label"     => $ws->format('M j'),
                "rangeText" => $ws->format('M j') . ' - ' . $we->format('M j'),
                "submitted" => $sub,
                "released"  => $rel
            ];
        }
    } else {
        for ($i = 0; $i < $trendDays; $i++) {
            $day = (clone $firstBucket)->modify("+$i days");
            $k = $day->format('Y-m-d');
            $activityTrend[] = [
                "label"     => $day->format('M j'),
                "rangeText" => $day->format('D, M j'),
                "submitted" => $submittedByDay[$k] ?? 0,
                "released"  => $releasedByDay[$k] ?? 0
            ];
        }
    }
    $activeStrandsCount = count($strandStats);

    return [
        "status"                      => "success",
        "pendingCount"                => (int)$pending,
        "pendingPsychometricianCount" => (int)$pendingPsychometrician,
        "pendingCounselorCount"       => (int)$pendingCounselor,
        "pendingTotalCount"           => (int)($pendingPsychometrician + $pendingCounselor),
        "totalStudents"               => (int)$totalStudents,
        "approved"                    => (int)$approved,
        "assessmentsToday"            => (int)$assessmentsToday,
        "feedbackGiven"               => (int)$feedbackGiven,
        "approvalRate"                => $approvalRate,
        "inProgress"                  => (int)$conn->query("SELECT COUNT(*) as count FROM live_sessions ls JOIN assessments a ON a.AssessmentID = ls.AssessmentID WHERE ls.IsActive = TRUE AND a.Status = 'in_progress'")->fetch_assoc()['count'],
        "strandStats"                 => $strandStats,
        "gradeStats"                  => $gradeStats,
        "genderStats"                 => $genderStats,
        "priorityEndorsements"        => $priorityEndorsements,
        "recentReleased"              => $recentReleased,
        "activeStrandsCount"          => $activeStrandsCount,
        "riasecStats"                 => $riasecStats,
        "rseStats"                    => $rseStats,
        "cdsesStats"                  => $cdsesStats,
        "recentActivity"              => $recentActivity,
        "activityTrend"               => $activityTrend,
        "trendMode"                   => $trendMode
    ];
});

echo json_encode($response);

$conn->close();
?>
