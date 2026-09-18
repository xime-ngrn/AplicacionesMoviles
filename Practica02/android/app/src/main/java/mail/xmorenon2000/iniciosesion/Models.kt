package mail.xmorenon2000.iniciosesion

import com.google.gson.annotations.SerializedName

// Modelo del usuario
data class Usuario(
    val id: Int,
    val username: String,
    val email: String,
    val role: String
)

data class LoginRequest(val username: String, val password: String)
data class RegisterRequest(val username: String, val email: String, val password: String)
data class UsuarioRequest(val username: String, val email: String, val role: String, val password: String? = null)

data class LoginResponse(
    @SerializedName("access_token") val accessToken: String,
    val user: Usuario
)

data class MeResponse(val user: Usuario)
data class UsuariosResponse(val users: List<Usuario>)
data class MensajeResponse(val message: String, val user: Usuario? = null)