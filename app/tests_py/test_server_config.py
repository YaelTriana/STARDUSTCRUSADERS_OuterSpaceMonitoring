"""Dirección y puerto donde escucha el servidor local."""

from main import bind_host, bind_port


def test_por_defecto_escucha_solo_en_localhost():
    assert bind_host({}) == "127.0.0.1"
    assert bind_host({"TIRELUS_HOST": "  "}) == "127.0.0.1"


def test_en_docker_se_puede_abrir_a_todas_las_interfaces():
    assert bind_host({"TIRELUS_HOST": "0.0.0.0"}) == "0.0.0.0"


def test_puerto_por_defecto_y_por_variable():
    assert bind_port({}) == 8765
    assert bind_port({"TIRELUS_PORT": "9000"}) == 9000
