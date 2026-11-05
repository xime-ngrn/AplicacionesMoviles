import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Código específico de iOS para elegir carpetas (ver CarpetasIos abajo).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CarpetasIos") {
      CarpetasIos.register(with: registrar)
    }
  }
}

/// Selector de carpetas de iOS (app Archivos) con acceso "security-scoped".
/// iOS solo deja leer una carpeta externa después de startAccessingSecurityScopedResource(),
/// y para conservar el acceso al reabrir la app se guarda un marcador (bookmark).
/// Se comunica con Dart por el canal "gestorarchivos/carpetas_ios".
class CarpetasIos: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  private var resultadoPendiente: FlutterResult?
  private var accesos: [String: URL] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let canal = FlutterMethodChannel(
      name: "gestorarchivos/carpetas_ios", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(CarpetasIos(), channel: canal)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "elegirCarpeta":
      elegirCarpeta(result: result)
    case "abrirMarcador":
      guard let datos = call.arguments as? FlutterStandardTypedData else {
        result(FlutterError(code: "ARGUMENTO", message: "Marcador inválido.", details: nil))
        return
      }
      abrirMarcador(datos.data, result: result)
    case "liberar":
      if let ruta = call.arguments as? String, let url = accesos.removeValue(forKey: ruta) {
        url.stopAccessingSecurityScopedResource()
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func elegirCarpeta(result: @escaping FlutterResult) {
    if resultadoPendiente != nil {
      result(FlutterError(code: "OCUPADO", message: "Ya hay un selector abierto.", details: nil))
      return
    }
    guard let vista = CarpetasIos.controladorVisible() else {
      result(FlutterError(code: "SIN_VISTA", message: "No se pudo mostrar el selector.", details: nil))
      return
    }
    let selector = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder])
    selector.delegate = self
    selector.allowsMultipleSelection = false
    resultadoPendiente = result
    vista.present(selector, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = resultadoPendiente else { return }
    resultadoPendiente = nil
    guard let url = urls.first else {
      result(nil)
      return
    }
    guard url.startAccessingSecurityScopedResource() else {
      result(FlutterError(code: "PERMISO", message: "iOS no concedió acceso a la carpeta.", details: nil))
      return
    }
    accesos[url.path] = url
    var respuesta: [String: Any] = ["ruta": url.path, "nombre": url.lastPathComponent]
    if let marcador = try? url.bookmarkData(
      options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
    {
      respuesta["marcador"] = FlutterStandardTypedData(bytes: marcador)
    }
    result(respuesta)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    resultadoPendiente?(nil)  // el usuario canceló: Dart recibe null
    resultadoPendiente = nil
  }

  private func abrirMarcador(_ marcador: Data, result: FlutterResult) {
    do {
      var obsoleto = false
      let url = try URL(
        resolvingBookmarkData: marcador, options: [], relativeTo: nil,
        bookmarkDataIsStale: &obsoleto)
      guard url.startAccessingSecurityScopedResource() else {
        result(FlutterError(code: "PERMISO", message: "Se perdió el acceso a la carpeta.", details: nil))
        return
      }
      accesos[url.path] = url
      result(["ruta": url.path, "nombre": url.lastPathComponent])
    } catch {
      result(
        FlutterError(
          code: "PERMISO", message: "Se perdió el acceso a la carpeta.",
          details: error.localizedDescription))
    }
  }

  /// Controlador visible para presentar el selector (la app usa escenas, UIScene).
  private static func controladorVisible() -> UIViewController? {
    let escenas = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let escena =
      escenas.first(where: { $0.activationState == .foregroundActive }) ?? escenas.first
    let ventana =
      escena?.windows.first(where: { $0.isKeyWindow }) ?? escena?.windows.first
    var vista = ventana?.rootViewController
    while let presentada = vista?.presentedViewController {
      vista = presentada
    }
    return vista
  }
}
