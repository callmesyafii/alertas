import pandas as pd
import requests
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from sklearn.metrics import mean_squared_error
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import numpy as np
from statsmodels.tsa.statespace.sarimax import SARIMAX
import mysql.connector
from statsmodels.tsa.stattools import adfuller  # Tambahkan import ini
from flask import Flask, jsonify
from flask_socketio import SocketIO
import threading
import time
import logging

app = Flask(__name__)
socketio = SocketIO(app)

# Configure logging
logging.basicConfig(level=logging.INFO)

# Fungsi untuk menjalankan model SARIMAX
def run_sarimax():
    logging.info("Starting SARIMAX thread...")
    while True:
        logging.info("Fetching sensor history...")
        # Ambil data dari API
        response = requests.get('http://localhost/alertasAndro/android/kirimdata.php?action=getSensorHistory')
        data = response.json()
        df = pd.DataFrame(data)

        # Log ukuran DataFrame setelah pengambilan data
        logging.info(f"Data fetched: {len(df)} rows")

        # Proses data
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df.set_index('timestamp', inplace=True)
        df['sensor_value'] = pd.to_numeric(df['sensor_value'], errors='coerce')

        # Hapus nilai NaN tetapi simpan data yang valid
        df.dropna(subset=['sensor_value'], inplace=True)
        logging.info(f"Data after cleaning: {len(df)} rows")

        # Penanganan Outlier dengan batas yang lebih fleksibel
        if len(df) > 0:
            Q1 = df['sensor_value'].quantile(0.25)  # Menggunakan kuartil 1
            Q3 = df['sensor_value'].quantile(0.75)  # Menggunakan kuartil 3
            IQR = Q3 - Q1
            
            # Dynamic bounds based on the data
            lower_bound = Q1 - 2 * IQR  # Lower bound as 2 * IQR below Q1
            upper_bound = Q3 + 2 * IQR  # Upper bound as 2 * IQR above Q3
            
            # Hanya hapus data yang berada di luar batas
            df = df[(df['sensor_value'] >= lower_bound) & (df['sensor_value'] <= upper_bound)]
            logging.info(f"Data after outlier removal: {len(df)} rows")

            # Tambahkan kode untuk mencetak nilai min dan max
            min_value = df['sensor_value'].min()  # Hitung nilai minimum
            max_value = df['sensor_value'].max()  # Hitung nilai maksimum
            logging.info(f"Min value after outlier removal: {min_value}")  # Print nilai min
            logging.info(f"Max value after outlier removal: {max_value}")  # Print nilai max

        # Pastikan ada data setelah pembersihan dan penanganan outlier
        if len(df) == 0:
            logging.error("Data setelah pembersihan dan penanganan outlier kosong. Tidak dapat melanjutkan.")
            continue  # Skip iteration if df is empty

        # Normalisasi data dengan aman
        df['sensor_value'] = np.log1p(df['sensor_value'].clip(lower=0))  # Menghindari log dari nilai negatif

        # Pembagian data menjadi train dan test
        train_size = int(len(df) * 0.8)
        train = df['sensor_value'][:train_size]
        test = df['sensor_value'][train_size:]

        # Validasi ukuran train dan test
        if len(train) == 0 or len(test) == 0:
            logging.error("Data pelatihan atau pengujian kosong. Tidak dapat melanjutkan.")
            break  # Hentikan iterasi jika train atau test kosong

        # Pastikan ukuran test sesuai
        logging.info(f"Train size: {len(train)}, Test size: {len(test)}")  # Log ukuran train dan test

        # Model SARIMAX
        p, d, q = 1, 1, 1
        P, D, Q, S = 1, 1, 1, 24
        model = SARIMAX(train, order=(p, d, q), seasonal_order=(P, D, Q, S), 
                        start_params=[0.0] * (p + q + P + Q))
        model_fit = model.fit()

        # Print model summary
        print(model_fit.summary())  # Print the SARIMAX model summary

        # Hitung RMSE
        predictions_train = model_fit.predict(start=0, end=len(train)-1)

        # Debugging: Print sizes
        print(f"Train size: {len(train)}, Predictions size: {len(predictions_train)}")

        # Pastikan ukuran sama sebelum menghitung RMSE
        if len(train) == len(predictions_train):
            mse = mean_squared_error(train, predictions_train)  # Hitung MSE
            print(f"MSE: {mse}")  # Print the MSE
            
            # Tambahkan perhitungan MAE dan MAPE
            mae = np.mean(np.abs(train - predictions_train))  # Hitung MAE
            mape = np.mean(np.abs((train - predictions_train) / train)) * 100  # Hitung MAPE
            
            print(f"MAE: {mae}")  # Print the MAE
            print(f"MAPE: {mape}%")  # Print the MAPE
            
            # Tambahkan perhitungan SMAPE
            smape = np.mean(2 * np.abs(predictions_train - train) / (np.abs(predictions_train) + np.abs(train))) * 100  # Hitung SMAPE
            print(f"SMAPE: {smape}%")  # Print the SMAPE
            
            # Tambahkan perhitungan R²
            ss_res = np.sum((train - predictions_train) ** 2)  # Residual sum of squares
            ss_tot = np.sum((train - np.mean(train)) ** 2)  # Total sum of squares
            r2 = 1 - (ss_res / ss_tot)  # Hitung R²
            print(f"R²: {r2}")  # Print R²
        else:
            logging.error("Ukuran data tidak konsisten untuk MSE.")
            logging.error(f"Train size: {len(train)}, Predictions size: {len(predictions_train)}")  # Log sizes

        # Prediksi
        predictions = model_fit.forecast(steps=1500)
        predictions_denormalized = np.expm1(predictions)

        # Tambahkan kode untuk mencetak nilai min dan max dari prediksi
        min_prediction = predictions_denormalized.min()  # Hitung nilai minimum dari prediksi
        max_prediction = predictions_denormalized.max()  # Hitung nilai maksimum dari prediksi
        print(f"Min prediction value: {min_prediction}")  # Print nilai min prediksi
        print(f"Max prediction value: {max_prediction}")  # Print nilai max prediksi

        # Kirim prediksi ke Flutter
        socketio.emit('new_prediction', {'predictions': predictions_denormalized.tolist()})

        # Kirim nilai hasil prediksi ke database
        save_predictions_to_db(predictions_denormalized)

        # Tunggu 10 detik sebelum iterasi berikutnya
        time.sleep(10)

        # # Fungsi untuk memvisualisasikan data asli dan hasil prediksi
        # def visualize_predictions(train, test, predictions):
        #     plt.figure(figsize=(12, 6))
            
        #     # Plot data asli
        #     plt.plot(train.index, train, label='Data Asli (Train)', color='blue')
        #     plt.plot(test.index, test, label='Data Asli (Test)', color='green')
            
        #     # Plot prediksi
        #     plt.plot(test.index, predictions, label='Prediksi', color='red', linestyle='--')
            
        #     # Menambahkan judul dan label
        #     plt.title('Visualisasi Data Asli dan Hasil Prediksi')
        #     plt.xlabel('Waktu')
        #     plt.ylabel('Nilai Sensor')
        #     plt.legend()
        #     plt.grid()
            
        #     # Tampilkan grafik
        #     plt.show()

        # # Panggil fungsi ini setelah model dilatih dan prediksi dihasilkan
        # # Misalnya, setelah bagian prediksi di fungsi run_sarimax
        # visualize_predictions(train, test, predictions_denormalized)

# Fungsi untuk menyimpan prediksi ke database
def save_predictions_to_db(predictions):
    try:
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='',
            database='alertas_db'
        )
        cursor = conn.cursor()
        
        # Print the predictions being saved
        print(f"Saving predictions: {predictions}")

        # Insert predictions into the database
        for value in predictions:
            cursor.execute('INSERT INTO predictions (prediction_value) VALUES (%s)', (value,))
        
        # Limit the number of entries in the predictions table to 300
        cursor.execute("DELETE FROM predictions WHERE id NOT IN (SELECT id FROM (SELECT id FROM predictions ORDER BY id DESC LIMIT 1500) AS temp)")

        conn.commit()
    except Exception as e:
        logging.error(f"Error saving predictions to database: {e}")
    finally:
        conn.close()

# Fungsi untuk mendapatkan prediksi terbaru
@app.route('/predictions', methods=['GET'])
def get_predictions():
    try:
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='',
            database='alertas_db'
        )
        cursor = conn.cursor()
        cursor.execute("SELECT prediction_value FROM predictions ORDER BY id DESC LIMIT 1")
        result = cursor.fetchone()
        return jsonify({'latest_prediction': result[0] if result else None})
    except Exception as e:
        logging.error(f"Error fetching predictions: {e}")
        return jsonify({'latest_prediction': None}), 500
    finally:
        conn.close()

# Jalankan thread untuk model SARIMAX
threading.Thread(target=run_sarimax, daemon=True).start()

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000)