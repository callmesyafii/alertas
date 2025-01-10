<?php
include "koneksi.php";

$sql = "SELECT MAX(prediction_value) AS max_value FROM predictions";
$result = $conn->query($sql);

$data = array();
if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $data['max_value'] = $row['max_value'];
}

header('Content-Type: application/json');
echo json_encode($data);

$conn->close();
?>