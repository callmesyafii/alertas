<?php

include "koneksi.php";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Validasi
    $username = trim($_POST['username'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');
    $kode_alat = trim($_POST['kodeAlat'] ?? '');

    if (empty($username) || empty($email) || empty($password) || empty($kode_alat)) {
        echo json_encode(["message" => "Semua field harus diisi."]);
        exit;
    }

    // Update
    
    $updateSql = "UPDATE users SET username = ?, sandi = ?, kode = ?, email = ? WHERE email = ?";
    $updateStmt = $conn->prepare($updateSql);

    if ($updateStmt === false) {
        echo json_encode(["message" => "Kesalahan pada server: " . $conn->error]);
        exit;
    }

    $hashedPassword = $password;
    $updateStmt->bind_param("sssss", $username, $hashedPassword, $kode_alat, $email, $email);

    if ($updateStmt->execute()) {
        echo json_encode(["message" => "Profile updated successfully"]);
    } else {
        echo json_encode(["message" => "Error updating profile: " . $conn->error]);
    }
} else {
    echo json_encode(["message" => "Invalid request method"]);
}

$conn->close();
?>
