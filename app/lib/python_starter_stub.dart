/// Web: serious_python usa dart:ffi y Pyodide no puede abrir un servidor HTTP
/// local, así que en web no se arranca nada. La vista previa web usa el
/// servidor de desarrollo (`python python_app/main.py`).
void startEmbeddedPython(int port) {}
