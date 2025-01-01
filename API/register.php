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

// Validasi apakah kode alat ada di database
$query = "SELECT * FROM alat WHERE kode_alat='$kodeAlat'";
$result = mysqli_query($conn, $query);

if (mysqli_num_rows($result) == 0) {
    echo json_encode(['status' => 'error', 'message' => 'Kode alat tidak ditemukan']);
    exit;
}

// Query simpan data pengguna baru
$query = "INSERT INTO users (email, sandi, kode) VALUES ('$email', '$password', '$kodeAlat')";
if (mysqli_query($conn, $query)) {
    echo json_encode(['status' => 'success', 'message' => 'Registrasi berhasil']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Registrasi gagal: ' . mysqli_error($conn)]);
}

mysqli_close($conn);
?>