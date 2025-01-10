<?php

include "koneksi.php";

$kode_alat = $_POST['kode_alat'] ?? ''; 


$sql = "SELECT sensor_value FROM sensor_history WHERE kode_alat = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $kode_alat); 
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $sensorData = [];
    while ($row = $result->fetch_assoc()) {
        $sensorData[] = $row; 
    }
    echo json_encode($sensorData); 
} else {
    echo json_encode(["message" => "No data found for kode_alat: $kode_alat"]); // Provide more context
}

$stmt->close();
$conn->close();
?>