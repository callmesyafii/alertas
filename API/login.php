<?php
include "koneksi.php";

// Validasi data yang diterima
if (!isset($_POST['email']) || !isset($_POST['password']) || !isset($_POST['kodeAlat'])) {
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
    exit;
}

$email = $_POST['email'];
$password = $_POST['password'];
$kodeAlat = $_POST['kodeAlat'];

// Menghindari SQL Injection
$email = mysqli_real_escape_string($conn, $email);
$password = mysqli_real_escape_string($conn, $password);
$kodeAlat = mysqli_real_escape_string($conn, $kodeAlat);

// Query untuk memeriksa email dan password
$query = "SELECT * FROM users WHERE email='$email' AND sandi='$password'";
$result = mysqli_query($conn, $query);

if (mysqli_num_rows($result) > 0) {
    $user = mysqli_fetch_assoc($result);
    
    
    if ($password === $user['sandi']) {
       
        if ($user['kode'] === $kodeAlat) {
            echo json_encode(['status' => 'success', 'message' => 'Login berhasil']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Kode alat tidak cocok']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Password salah']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Email tidak ditemukan']);
}

mysqli_close($conn);
?>