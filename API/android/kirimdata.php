<?php
include "../koneksi.php";

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

if (isset($_GET['action'])) {
    if ($_GET['action'] == 'getSensorHistory') {
        $sql = "SELECT timestamp, sensor_value FROM sensor_history ORDER BY timestamp";
        $result = $conn->query($sql);

        $data = [];
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $data[] = $row;
            }
            echo json_encode($data);
        } else {
            echo json_encode([]);
        }
        mysqli_close($conn);
        exit;
    }
    if ($_GET['action'] == 'getPPM') {
        $sql = "SELECT nilaiLpg FROM users LIMIT 1"; 
        $result = $conn->query($sql);

        if ($result && $result->num_rows > 0) {
            $row = $result->fetch_assoc();
            echo json_encode(['nilaiLpg' => $row['nilaiLpg']]);
        } else {
            echo json_encode(['nilaiLpg' => null]); 
        }
        mysqli_close($conn);
        exit; 
    } elseif ($_GET['action'] == 'checkConnection') {
        echo json_encode(['status' => 'connected']);
        mysqli_close($conn);
        exit;
    }
}

// Filter and validate input for updating nilaiLpg
$nilai_lpg = filter_input(INPUT_GET, 'nilaiLpg', FILTER_VALIDATE_FLOAT);
$kode_alat = filter_input(INPUT_GET, 'kode_alat', FILTER_SANITIZE_STRING);

if ($nilai_lpg === null || $nilai_lpg === false || !$kode_alat) {
    echo json_encode(['success' => false, 'message' => 'Parameter tidak valid']);
    exit;
}

if (!$conn) {
    echo json_encode(['success' => false, 'message' => 'Koneksi database gagal']);
    exit;
}

// Update data tabel users
$stmt = $conn->prepare("UPDATE users SET nilaiLpg = ? WHERE kode = ?");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Gagal menyiapkan query: ' . $conn->error]);
    exit;
}

$stmt->bind_param("ds", $nilai_lpg, $kode_alat);

if (!$stmt->execute()) {
    echo json_encode(['success' => false, 'message' => 'Gagal update data: ' . $stmt->error]);
    $stmt->close();
    exit;
}

$stmt->close();

// Insert data ke tabel sensor_history
$sql_history = "INSERT INTO sensor_history (kode_alat, sensor_value) VALUES (?, ?)";
$stmt_history = $conn->prepare($sql_history);
if (!$stmt_history) {
    echo json_encode(['success' => false, 'message' => 'Gagal menyiapkan query history: ' . $conn->error]);
    exit;
}

$stmt_history->bind_param("sd", $kode_alat, $nilai_lpg);

if (!$stmt_history->execute()) {
    echo json_encode(['success' => false, 'message' => 'Gagal menyimpan data histori: ' . $stmt_history->error]);
    $stmt_history->close();
    mysqli_close($conn);
    exit;
}

$stmt_history->close();

// Batas Baris Sensor
$sql_limit_history = "
    DELETE FROM sensor_history
    WHERE id NOT IN (
        SELECT id FROM (
            SELECT id FROM sensor_history ORDER BY id DESC LIMIT 3600
        ) AS subquery
    )
";

$sql_limit_predictions = "
    DELETE FROM predictions
    WHERE id NOT IN (
        SELECT id FROM (
            SELECT id FROM predictions ORDER BY id DESC LIMIT 1500
        ) AS subquery
    )
";

// Execute deletion for sensor_history
if ($conn->query($sql_limit_history) === false) {
    echo json_encode(['success' => false, 'message' => 'Gagal membatasi jumlah data sensor history: ' . $conn->error]);
    mysqli_close($conn);
    exit;
}

// Execute deletion for predictions
if ($conn->query($sql_limit_predictions) === false) {
    echo json_encode(['success' => false, 'message' => 'Gagal membatasi jumlah data predictions: ' . $conn->error]);
    mysqli_close($conn);
    exit;
} else {
    echo json_encode(['success' => true, 'message' => 'Data predictions berhasil dibatasi!']);
}

echo json_encode(['success' => true, 'message' => 'Data histori berhasil disimpan dan dibatasi!']);
mysqli_close($conn);
?>
