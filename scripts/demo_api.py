"""API REST didática persistente, separada do app. Somente biblioteca padrão.

Execute: python scripts/demo_api.py
Android emulator: --dart-define=API_URL=http://10.0.2.2:8080/todos
Windows: --dart-define=API_URL=http://127.0.0.1:8080/todos
"""
import argparse
import json
import sqlite3
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

DB = Path(__file__).with_name('demo_api.sqlite3')


@contextmanager
def connect():
    db = sqlite3.connect(DB)
    try:
        with db:
            db.execute('CREATE TABLE IF NOT EXISTS todos(id INTEGER PRIMARY KEY AUTOINCREMENT, local_id TEXT UNIQUE, payload TEXT NOT NULL)')
            yield db
    finally:
        db.close()


class Handler(BaseHTTPRequestHandler):
    def respond(self, code, body):
        data = json.dumps(body, ensure_ascii=False).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def dispatch(self):
        parts = urlsplit(self.path).path.strip('/').split('/')
        if not parts or parts[0] != 'todos' or len(parts) > 2:
            return self.respond(404, {'error': 'Rota inexistente'})
        item_id = int(parts[1]) if len(parts) == 2 else None
        with connect() as db:
            if self.command == 'GET':
                rows = db.execute('SELECT id,payload FROM todos ORDER BY id LIMIT 10').fetchall()
                return self.respond(200, [dict(json.loads(payload), id=i) for i, payload in rows])
            if self.command == 'DELETE':
                if item_id is None:
                    return self.respond(400, {'error': 'ID obrigatório'})
                db.execute('DELETE FROM todos WHERE id=?', (item_id,))
                return self.respond(200, {})
            size = int(self.headers.get('Content-Length', '0'))
            if size > 1048576:
                return self.respond(413, {'error': 'Payload muito grande'})
            payload = json.loads(self.rfile.read(size))
            if not isinstance(payload, dict) or not isinstance(payload.get('title'), str) or len(payload['title'].strip()) < 3:
                return self.respond(400, {'error': 'Título inválido'})
            if self.command == 'POST':
                local_id = payload.get('localId')
                if not isinstance(local_id, str) or not local_id:
                    return self.respond(400, {'error': 'localId obrigatório'})
                # Idempotência: repetir POST após perda de resposta não duplica.
                db.execute('INSERT INTO todos(local_id,payload) VALUES(?,?) ON CONFLICT(local_id) DO UPDATE SET payload=excluded.payload', (local_id, json.dumps(payload)))
                item_id = db.execute('SELECT id FROM todos WHERE local_id=?', (local_id,)).fetchone()[0]
                return self.respond(201, dict(payload, id=item_id))
            if self.command == 'PUT' and item_id is not None:
                changed = db.execute('UPDATE todos SET payload=? WHERE id=?', (json.dumps(payload), item_id)).rowcount
                return self.respond(200, dict(payload, id=item_id)) if changed else self.respond(404, {'error': 'Não encontrado'})
            return self.respond(400, {'error': 'Operação inválida'})

    def handle_request(self):
        try:
            self.dispatch()
        except (ValueError, TypeError, json.JSONDecodeError):
            self.respond(400, {'error': 'Requisição inválida'})
        except sqlite3.Error:
            self.respond(500, {'error': 'Falha no armazenamento'})

    do_GET = do_POST = do_PUT = do_DELETE = handle_request


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8080)
    args = parser.parse_args()
    with connect() as db:
        for i, title in enumerate(['Preparar a reunião da equipe', 'Revisar as entregas do quadro', 'Planejar a próxima semana']):
            db.execute('INSERT OR IGNORE INTO todos(local_id,payload) VALUES(?,?)',
                       (f'modelo-{i}', json.dumps({'title': title, 'completed': False, 'userId': 1})))
    print(f'API didática: http://{args.host}:{args.port}/todos', flush=True)
    ThreadingHTTPServer((args.host, args.port), Handler).serve_forever()
