"""Smoke tests reais da API didática: python -m unittest discover -s scripts -p test_demo_api.py"""
import json
import tempfile
import threading
import unittest
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import demo_api


class DemoApiTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='tasklink-api-')
        demo_api.DB = Path(self.temp.name) / 'test.sqlite3'
        self.server = demo_api.ThreadingHTTPServer(('127.0.0.1', 0), demo_api.Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f'http://127.0.0.1:{self.server.server_port}/todos'

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.temp.cleanup()

    def request(self, method, path='', body=None):
        payload = None if body is None else json.dumps(body).encode()
        with urlopen(Request(self.base + path, data=payload, method=method,
                             headers={'Content-Type': 'application/json'}), timeout=5) as response:
            return response.status, json.load(response)

    def test_crud_persistente_e_post_idempotente(self):
        payload = {'localId': 't1', 'title': 'Preparar entrega', 'completed': False}
        code, created = self.request('POST', body=payload)
        self.assertEqual(code, 201)
        _, repeated = self.request('POST', body=payload)
        self.assertEqual(created['id'], repeated['id'])
        _, rows = self.request('GET')
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['title'], payload['title'])
        payload['title'] = 'Entrega revisada'
        self.request('PUT', f'/{created["id"]}', payload)
        _, rows = self.request('GET')
        self.assertEqual(rows[0]['title'], 'Entrega revisada')
        self.request('DELETE', f'/{created["id"]}')
        _, rows = self.request('GET')
        self.assertEqual(rows, [])

    def test_titulo_invalido_retorna_400(self):
        with self.assertRaises(HTTPError) as error:
            self.request('POST', body={'localId': 't1', 'title': 'ab'})
        self.assertEqual(error.exception.code, 400)

    def test_atualizacao_inexistente_retorna_404(self):
        with self.assertRaises(HTTPError) as error:
            self.request('PUT', '/999', {'title': 'Tarefa inexistente'})
        self.assertEqual(error.exception.code, 404)


if __name__ == '__main__':
    unittest.main()
