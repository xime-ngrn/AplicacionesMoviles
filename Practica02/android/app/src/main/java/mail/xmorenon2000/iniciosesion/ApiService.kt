package mail.xmorenon2000.iniciosesion

import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path

interface ApiService {
    @POST("api/register")
    suspend fun register(@Body body: RegisterRequest): MensajeResponse

    @POST("/api/login")
    suspend fun login(@Body body: LoginRequest): LoginResponse

    @GET("api/me")
    suspend fun me(@Header("Authorization") token: String): MeResponse

    @GET("api/users")
    suspend fun listarUsuarios(@Header("Authorization") token: String): UsuariosResponse

    @POST("api/users")
    suspend fun crearUsuario(
        @Header("Authorization") token: String,
        @Body body: UsuarioRequest
    ): MensajeResponse

    @PUT("api/users/{id}")
    suspend fun actualizarUsuario(
        @Header("Authorization") token: String,
        @Path("id") id: Int,
        @Body body: UsuarioRequest
    ): MensajeResponse

    @DELETE("api/users/{id}")
    suspend fun eliminarUsuario(
        @Header("Authorization") token: String,
        @Path("id") id: Int
    ): MensajeResponse

}