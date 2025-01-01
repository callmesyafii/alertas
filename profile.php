<?php

include "koneksi.php";

// Ambil data pengguna berdasarkan email
$email = $_POST['email'] ?? null;
if ($email) {
    $sql = "SELECT * FROM users WHERE email = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo json_encode($user);
    } else {
        echo json_encode(["message" => "User not found"]);
    }
} else {
    echo json_encode(["message" => "Email not provided"]);
}

$conn->close();
?>