package mail.xmorenon2000.iniciosesion

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier

enum class Pantalla { LOGIN, REGISTRO, PERFIL, USUARIOS }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainApp() {
    var pantalla by remember { mutableStateOf(Pantalla.LOGIN) }
    var menuAbierto by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("LoginApp") },
                actions = {
                    Box {
                        IconButton(onClick = { menuAbierto = true }) {
                            Icon(Icons.Default.Menu, contentDescription = "Menu")
                        }
                        DropdownMenu(
                            expanded = menuAbierto,
                            onDismissRequest = { menuAbierto = false }
                        ) {
                            if(!Sesion.estaAutenticado) {
                                DropdownMenuItem(
                                    text = { Text("Iniciar Sesión") },
                                    onClick = { pantalla = Pantalla.LOGIN; menuAbierto = false }
                                )
                                DropdownMenuItem(
                                    text = { Text("Registro") },
                                    onClick = { pantalla = Pantalla.REGISTRO; menuAbierto = false }
                                )
                            } else {
                                DropdownMenuItem(
                                    text = { Text("Mi Perfil") },
                                    onClick = { pantalla = Pantalla.PERFIL; menuAbierto = false }
                                )

                                if (Sesion.esAdmin) {
                                    DropdownMenuItem(
                                        text = { Text("Usuarios") },
                                        onClick = { pantalla = Pantalla.USUARIOS; menuAbierto = false }
                                    )
                                }

                                DropdownMenuItem(
                                    text = { Text("Salir") },
                                    onClick = {
                                        Sesion.limpiar()
                                        pantalla = Pantalla.LOGIN
                                        menuAbierto = false
                                    }
                                )
                            }
                        }
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding)) {
            when (pantalla) {
                Pantalla.LOGIN ->  LoginScreen(
                    onLoginExitoso = {
                        pantalla = if(Sesion.esAdmin) Pantalla.USUARIOS else Pantalla.PERFIL
                    }
                )
                Pantalla.REGISTRO -> RegistroScreen(
                    onIrALogin = { pantalla = Pantalla.LOGIN }
                )
                Pantalla.PERFIL -> PerfilScreen()
                Pantalla.USUARIOS -> UsuariosScreen()
            }
        }
    }
}