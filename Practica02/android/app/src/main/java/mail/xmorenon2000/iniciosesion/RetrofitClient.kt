package mail.xmorenon2000.iniciosesion

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

object RetrofitClient {
    // 10.0.0.2 si se ejecuta en el emulador de la computadora, que corre docker
    // IPv4 del Adaptador de LAN inalámbrica Wi-Fi de la computadora si se ejecuta en un dispositivo externo como emulador
    private const val BASE_URL = "http://10.0.0.9:5000/"

    private val logger = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val cliente = OkHttpClient.Builder()
        .addInterceptor(logger)
        .build()

    val api: ApiService = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(cliente)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
        .create(ApiService::class.java)
}

object Sesion {
    var token: String? = null
    var usuario: Usuario? = null

    val estaAutenticado: Boolean get() = token != null
    val esAdmin: Boolean get() = usuario?.role == "admin"

    fun autorizacion(): String = "Bearer ${token ?: ""}"

    fun limpiar() {
        token = null
        usuario = null
    }
}