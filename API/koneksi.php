<?php

$conn = mysqli_connect("localhost", "root", "", "alertas_db");
if (!$conn) {
    echo "Koneksi gagal: " . mysqli_connect_error();
}

?>