<?php
include "koneksi.php";

// Query untuk mengambil data
$sql = "SELECT sensor_value FROM sensor_history";
$result = $conn->query($sql);

$data = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
}

// Menghitung jumlah sensor_value yang lebih besar dari 3
$count = 0;
foreach ($data as $item) {
    if ($item['sensor_value'] > 3) {
        $count++;
    }
}

// Mengembalikan hasil dalam format JSON
echo json_encode(['count' => $count]);

$conn->close();
?>