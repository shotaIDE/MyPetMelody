# coding: utf-8

from pathlib import Path

import pytest
from my_project import create_app


@pytest.fixture()
def app():
    app = create_app()
    app.config.update({
        'TESTING': True,
    })

    yield app


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture()
def runner(app):
    return app.test_cli_runner()


resources = Path(__file__).parent / "resources"


def test_detect(client):
    response = client.post("/detect", data={
        "name": "Flask",
        "theme": "dark",
        "picture": (resources / "picture.png").open("rb"),
    })
    assert response.status_code == 200
