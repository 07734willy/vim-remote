import json
import socket
import sys
import threading
import socketserver

# Replace the below with actual implementations
def read(*, path, arg1):
	print('reading: {path}'.format(path=path))
	return "this is the data read from {path}".format(path=path)
	
def write(*, text, path, arg2):
	print('writing: {path} {text}'.format(path=path, text=text))
	return
	
def autocomplete(*, file_expr, arg1, arg2):
	print('autocompleting: {file_expr}'.format(file_expr=file_expr))
	return ['path1', 'path2', 'path3']
	
def diff(*, text, path, arg1):
	print('diffing stuff')
	return {'added': [1,2,5], 'modified': [3, 6], 'deleted': [8,9,10]}

ACTIONS = {
	'read': read,
	'write': write,
	'autocomplete': autocomplete,
	'diff': diff,
}

def handle_request(request):
	data = json.loads(request)
	action = data.pop('action')
	
	try:
		result = ACTIONS[action](**data) or ''
		response = dict(error="", result=result)
	except Exception as error:
		response = dict(error=str(error), result='')
	return json.dumps(response)

class ThreadedTCPRequestHandler(socketserver.BaseRequestHandler):

	def handle(self):
		data = ""
		while True:
			try:
				data += self.request.recv(4096).decode('utf-8')
				msg_id, msg_data = json.loads(data)
			except ValueError:
				continue
			except (socket.error, IOError):
				break

			if msg_id > 0:
				response = handle_request(msg_data)
				encoded = json.dumps([msg_id, response])
				self.request.sendall(encoded.encode('utf-8'))
			data = ""

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
	pass

if __name__ == "__main__":
	HOST, PORT = "localhost", 8765

	server = ThreadedTCPServer((HOST, PORT), ThreadedTCPRequestHandler)
	ip, port = server.server_address

	server.serve_forever()
