package com.example.myttmi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Canal de los avisos push del servidor ("te toca jugar", mesa, cola…).
        // El backend manda channelId "myttm_partidos" (notifications/push.ts);
        // importancia alta = sonido + aviso emergente arriba de la pantalla.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "myttm_partidos",
                "Partidos y campeonatos",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Avisos de tus partidos: mesa asignada, cambios en la cola y resultados." }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
